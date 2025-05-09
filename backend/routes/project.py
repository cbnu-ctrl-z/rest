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
    """OpenAI API를 사용하여 구체적이고 수치화된 최종 목표와 단계별 목표를 생성합니다."""
    try:
        prompt = f"""당신은 협업 프로젝트 계획 작성 전문가입니다. 아래의 정보를 기반으로 현실적이고 수치 기반이며 명확한 행동 중심의 계획을 작성해주세요.

[프로젝트 제목]
{title}

[프로젝트 설명]
{description}

[관련 채팅 내용]
{chat_history}

[요구사항]
- "최종 목표"는 반드시 측정 가능하고 수치적이며, 달성 여부가 명확하게 판단 가능한 것으로 작성해주세요.
- "단계별 목표"는 최종 목표를 달성하기 위한 작고 구체적인 작업 단위여야 하며, 다음 요소를 포함해야 합니다:
  1. 누가 (이름 또는 역할)
  2. 무엇을 (명확한 작업)
  3. 어떤 결과물로 (파일, 코드, 문서 등)
  4. 언제까지 (기한)
- 각 단계는 1~2시간 내에 수행 가능한 수준으로 작게 쪼개주세요.
- 예시 (좋음): "앱 다운로드 수 1000건 달성", "유튜브 영상 5개 업로드", "웹사이트 트래픽 월 10,000회 이상"
  예시 (나쁨): "사용자 경험 개선", "인지도 상승", "기술력 향상"

[출력 형식]

1. 최종 목표
- [수치 기반 목표]

2. 단계별 목표
- 1단계: [작은 행동 단위]
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
