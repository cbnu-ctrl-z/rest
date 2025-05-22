# routes/project.py
from flask import Blueprint, request, jsonify
from openai import OpenAI
from bson.objectid import ObjectId
from datetime import datetime
from dotenv import load_dotenv
import os
import json


project_bp = Blueprint('project', __name__)
load_dotenv()
# OpenAI 클라이언트 초기화
client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))

@project_bp.route('/create', methods=['POST'])
def create_project():
    try:
        data = request.json
        title = data.get('title', '새 협업 프로젝트')
        description = data.get('description', '협업 프로젝트 설명')
        chat_history = data.get('chatHistory', '')
        members = data.get('members', [])
        creator_id = data.get('creatorId', '')
        room_id = data.get('roomId', '')

        plan = generate_project_plan(title, description, chat_history)

        if not plan:
            return jsonify({'success': False, 'error': '프로젝트 계획 생성 실패'}), 500

        # 단계별로 completed 필드 추가
        step_list = [{'step': s, 'completed': False} for s in plan['steps']]

        project = {
            'title': title,
            'description': description,
            'goal': plan['goal'],
            'steps': step_list,
            'members': members,
            'creatorId': creator_id,
            'roomId': room_id,
            'createdAt': datetime.now(),
            'status': 'active'
        }

        app = request.environ.get('app')
        result = app.db.projects.insert_one(project)

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



import json  # 추가

def generate_project_plan(title, description, chat_history):
    """OpenAI API를 사용하여 측정 가능하고 행동 중심의 프로젝트 계획을 JSON 형식으로 생성합니다."""
    try:
        prompt = f"""당신은 협업 프로젝트 계획 작성 전문가입니다. 아래 정보를 바탕으로 측정 가능하고 행동 중심의 계획을 JSON 형식으로 간결하게 작성하세요.

[프로젝트 제목]
{title}

[프로젝트 설명]
{description}

[관련 채팅 내용]
{chat_history}

[요구사항]
- 최종 목표는 반드시 수치적이고 측정 가능하며, 달성 여부가 명확히 판단 가능해야 합니다.
- 단계별 목표는 최종 목표를 달성하기 위한 구체적이고 작은 작업 단위로 8개 이상 작성하세요.
- 각 단계는 '누가', '언제'는 생략하고, 작업 내용만 간결히 작성하세요.
- 추상적인 표현 대신 구체적이고 행동 중심의 표현을 사용하세요. (예: 'HTML 구조 작성', '중량 2.5kg 증가')
- 출력 형식은 반드시 JSON으로 하세요.

[출력 형식 예시]
{{
  "goal": "12개월 내 3대 운동 1RM 합계 500kg 달성",
  "steps": [
    "1RM 테스트로 스쿼트, 벤치프레스, 데드리프트 현재 중량 측정",
    "주 5회 5분할 훈련 계획 수립",
    ...
  ]
}}
"""

        response = client.chat.completions.create(
            model="gpt-4-turbo",
            messages=[
                {
                    "role": "system",
                    "content": "당신은 목표를 수치화하고 행동 중심으로 명확히 설정하는 전문가입니다. JSON 형식으로만 응답하세요."
                },
                {"role": "user", "content": prompt}
            ],
            max_tokens=4000
        )

        content = response.choices[0].message.content.strip()
        return json.loads(content)  # JSON 문자열을 파싱해서 Python dict로 반환

    except Exception as e:
        print(f"OpenAI API 오류: {e}")
        return None


