# routes/project.py
from flask import Blueprint, request, jsonify
from openai import OpenAI
import os
from bson.objectid import ObjectId
from datetime import datetime
from dotenv import load_dotenv


project_bp = Blueprint('project', __name__)
load_dotenv()
# OpenAI 클라이언트 초기화
client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))

@project_bp.route('/create', methods=['POST'])
def create_project():
    try:
        # 요청에서 데이터 추출
        data = request.json
        title = data.get('title', '새 협업 프로젝트')
        description = data.get('description', '협업 프로젝트 설명')
        chat_history = data.get('chatHistory', '')
        members = data.get('members', [])
        creator_id = data.get('creatorId', '')
        room_id = data.get('roomId', '')

        # OpenAI API를 사용하여 프로젝트 계획 생성
        plan = generate_project_plan(title, description, chat_history)
        
        # MongoDB에 프로젝트 저장
        project = {
            'title': title,
            'description': description,
            'plan': plan,
            'members': members,
            'creatorId': creator_id,
            'roomId': room_id,
            'createdAt': datetime.now(),
            'status': 'active'
        }
        
        # 앱에서 db 가져오기
        app = request.environ.get('app')
        result = app.db.projects.insert_one(project)
        
        # 프로젝트 ID 반환
        return jsonify({'success': True, 'id': str(result.inserted_id)})
    
    except Exception as e:
        print(f"프로젝트 생성 오류: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@project_bp.route('/<project_id>', methods=['GET'])
def get_project(project_id):
    try:
        app = request.environ.get('app')
        project = app.db.projects.find_one({'_id': ObjectId(project_id)})
        
        if not project:
            return jsonify({'error': '프로젝트를 찾을 수 없습니다.'}), 404
        
        # ObjectId를 문자열로 변환
        project['_id'] = str(project['_id'])
        
        return jsonify(project)
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@project_bp.route('/user/<user_id>', methods=['GET'])
def get_user_projects(user_id):
    try:
        app = request.environ.get('app')
        projects = list(app.db.projects.find({'members': user_id}))
        
        # ObjectId를 문자열로 변환
        for project in projects:
            project['_id'] = str(project['_id'])
        
        return jsonify(projects)
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


def generate_project_plan(title, description, chat_history):
    """OpenAI API를 사용하여 최종 목표와 단계별 목표만 간결하게 출력합니다."""
    try:
        prompt = f"""당신은 협업 프로젝트 계획 작성 전문가입니다. 아래의 정보를 바탕으로 측정 가능하고 행동 중심의 계획을 간결하게 작성해주세요.

[프로젝트 제목]
{title}

[프로젝트 설명]
{description}

[관련 채팅 내용]
{chat_history}

[요구사항]
- "최종 목표"는 반드시 측정 가능하고 수치적이며, 달성 여부가 명확하게 판단 가능한 것으로 1개 작성해주세요.
- "단계별 목표"는 최종 목표를 달성하기 위한 작은 작업 단위로 작성하되, 누가, 언제, 어떤 결과물 등은 생략하고 간결하게 작성해주세요.
- 각 단계는 명확한 작업 내용을 포함하되, 설명은 짧게 유지해주세요.
- 전체적으로 불필요한 정보 없이 간결하고 실용적인 계획만 출력해주세요.

[출력 형식]

1. 최종 목표
- [수치 기반 목표 한 줄]

2. 단계별 목표
- 1단계: [간단한 작업 설명]
- 2단계: ...
- 3단계: ...
"""

        response = client.chat.completions.create(
            model="gpt-4-turbo",
            messages=[
                {"role": "system", "content": "당신은 목표를 수치화하고 행동 중심으로 명확하게 설정하는 전문가입니다."},
                {"role": "user", "content": prompt}
            ],
            max_tokens=1000
        )

        return response.choices[0].message.content.strip()

    except Exception as e:
        print(f"OpenAI API 오류: {e}")
        return "프로젝트 계획을 생성하는 중 오류가 발생했습니다."

