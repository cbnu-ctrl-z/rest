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
    """OpenAI API를 사용하여 측정 가능하고 행동 중심의 프로젝트 계획을 생성합니다."""
    try:
        prompt = f"""당신은 협업 프로젝트 계획 작성 전문가입니다. 아래 정보를 바탕으로 측정 가능하고 행동 중심의 계획을 간결하게 작성하세요.

[프로젝트 제목]
{title}

[프로젝트 설명]
{description}

[관련 채팅 내용]
{chat_history}

[요구사항]
- "최종 목표"는 반드시 수치적이고 측정 가능하며, 달성 여부가 명확히 판단 가능해야 합니다. 예: '12개월 내 스쿼트, 벤치프레스, 데드리프트 1RM 합계 500kg 달성'.
- "단계별 목표"는 최종 목표를 달성하기 위한 구체적이고 작은 작업 단위로 작성하세요.
- 각 단계는 '누가', '언제', '어떤 결과물'은 생략하고, 작업 내용만 간결히 기술하세요.
- 추상적 표현(예: 개선, 향상, 수립, 증가, 조정, 유지)은 절대 사용하지 말고, 구체적 행동(예: '중량 2.5kg 추가', '칼로리 3500kcal 식단 작성')으로 대체하세요.
- 각 단계는 명확한 작업(예: '1RM 테스트로 중량 측정', 'HTML 구조 작성')을 포함하고, 설명은 한 문장으로 유지하세요.
- 단계 수는 8개 이상으로 작성하며, 필요에 따라 더 많은 단계를 포함해도 됩니다.

[예시]
프로젝트 제목: 김신이 3대 500kg를 들 수 있게 만들기
1. 최종 목표
- 12개월 내 스쿼트, 벤치프레스, 데드리프트 1RM 합계 500kg 달성
2. 단계별 목표
- 1단계: 1RM 테스트로 스쿼트, 벤치프레스, 데드리프트 현재 중량 측정
- 2단계: 주 5회, 5분할 훈련(가슴, 등, 다리, 어깨, 팔) 스케줄 작성
- 3단계: 매주 3-5세트, 8-12회 반복으로 각 운동별 근력 훈련 시작
- 4단계: 매달 1RM 테스트로 중량 기록 후 훈련 강도 5%씩 조정
- 5단계: 일일 칼로리 3500kcal, 단백질 150g 식단 계획 작성
- 6단계: 매주 스쿼트, 벤치프레스, 데드리프트 중량 2.5kg 증가
- 7단계: 주간 코칭 세션으로 기술 피드백 및 동기 유지
- 8단계: 6개월 후 1RM 합계 400kg 달성 시 다음 중량 목표 설정
- 9단계: 매 훈련 전 동적 스트레칭과 폼롤러로 부상 예방
- 10단계: 12개월 후 1RM 합계 500kg 테스트 및 유지 훈련 계획 작성

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
                {
                    "role": "system",
                    "content": "당신은 목표를 수치화하고 행동 중심으로 명확히 설정하는 전문가입니다. 추상적 단어(개선, 향상, 수립, 증가, 조정, 유지)를 절대 사용하지 말고, 구체적이고 실행 가능한 작업으로 계획을 작성하세요."
                },
                {"role": "user", "content": prompt}
            ],
            max_tokens=1000
        )

        return response.choices[0].message.content.strip()

    except Exception as e:
        print(f"OpenAI API 오류: {e}")
        return "프로젝트 계획을 생성하는 중 오류가 발생했습니다."

