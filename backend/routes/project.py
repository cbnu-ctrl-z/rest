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
        return json.loads(content)

    except Exception as e:
        print(f"OpenAI API 오류: {e}")
        return None


#-----------------------------------------------------------------------------------------------------------------------------------------------------------------

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
        # status가 'active'인 프로젝트만 조회
        projects = list(app.db.projects.find({'members': user_id, 'status': 'active'}))
        
        # ObjectId를 문자열로 변환
        for project in projects:
            project['_id'] = str(project['_id'])
        
        return jsonify(projects)
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@project_bp.route('/<project_id>/step/<int:step_index>', methods=['PATCH'])
def update_step_completion(project_id, step_index):
    try:
        app = request.environ.get('app')
        completed = request.json.get('completed', False)

        # 단계 완료 상태 업데이트
        result = app.db.projects.update_one(
            {'_id': ObjectId(project_id)},
            {f'$set': {f'steps.{step_index}.completed': completed}}
        )

        if result.modified_count == 0:
            return jsonify({'success': False, 'message': '업데이트 실패'}), 400

        # 프로젝트의 모든 단계 완료 여부 확인
        project = app.db.projects.find_one({'_id': ObjectId(project_id)})
        if not project:
            return jsonify({'success': False, 'message': '프로젝트를 찾을 수 없습니다.'}), 404

        # 모든 단계가 완료되었는지 확인
        all_steps_completed = all(step['completed'] for step in project['steps'])

        if all_steps_completed:
            # 프로젝트를 done_projects로 이동
            project['completedAt'] = datetime.now()
            project['status'] = 'done'
            app.db.done_projects.insert_one(project)
            app.db.projects.delete_one({'_id': ObjectId(project_id)})
            return jsonify({
                'success': True,
                'message': '모든 단계 완료, 프로젝트가 done_projects로 이동되었습니다.'
            })

        return jsonify({'success': True})

    except Exception as e:
        print(f"단계 완료 업데이트 오류: {e}")
        return jsonify({'error': str(e)}), 500



#-----------------------------------------------------------------------------------------------------------------------------------------------------------------





@project_bp.route('/reviews/create', methods=['POST'])
def create_reviews():
    try:
        data = request.json
        project_id = ObjectId(data.get('projectId'))
        reviews = data.get('reviews', [])

        if not project_id or not reviews:
            return jsonify({'success': False, 'error': 'projectId 또는 reviews가 필요합니다.'}), 400

        # reviews 컬렉션에 저장
        review_doc = {
            'projectId': project_id,
            'reviews': [
                {
                    'memberId': review['memberId'],
                    'rating': review['rating'],
                    'comment': review['comment'],
                    'createdAt': datetime.now()
                } for review in reviews
            ],
            'createdAt': datetime.now()
        }

        app = request.environ.get('app')
        result = app.db.reviews.insert_one(review_doc)

        return jsonify({'success': True, 'id': str(result.inserted_id)})

    except Exception as e:
        print(f"리뷰 생성 오류: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

@project_bp.route('/done/<user_id>', methods=['GET'])
def get_done_projects(user_id):
    """사용자의 완료된 프로젝트 목록을 가져옵니다."""
    try:
        app = request.environ.get('app')
        
        done_projects = list(app.db.done_projects.find({'members': user_id}))
        
        for project in done_projects:
            project['_id'] = str(project['_id'])
            if 'createdAt' in project:
                project['createdAt'] = project['createdAt'].isoformat()
            if 'completedAt' in project:
                project['completedAt'] = project['completedAt'].isoformat()
        
        return jsonify(done_projects)
    
    except Exception as e:
        print(f"완료된 프로젝트 조회 오류: {e}")
        return jsonify({'error': str(e)}), 500

@project_bp.route('/reviews/<user_id>', methods=['GET'])
def get_user_reviews(user_id):
    """특정 사용자가 받은 모든 평가를 가져옵니다."""
    try:
        app = request.environ.get('app')
        
        pipeline = [
            {'$unwind': '$reviews'},
            {'$match': {'reviews.memberId': user_id}},
            {
                '$addFields': {
                    'projectId': {'$toObjectId': '$projectId'}  # 문자열 projectId를 ObjectId로 변환
                }
            },
            {
                '$lookup': {
                    'from': 'done_projects',
                    'localField': 'projectId',
                    'foreignField': '_id',
                    'as': 'project_info'
                }
            },
            {
                '$project': {
                    'rating': '$reviews.rating',
                    'comment': '$reviews.comment',
                    'createdAt': '$reviews.createdAt',
                    'projectTitle': {
                        '$ifNull': [
                            {'$arrayElemAt': ['$project_info.title', 0]},
                            '프로젝트명 없음'
                        ]
                    },
                    'reviewerName': '익명'
                }
            },
            {'$sort': {'createdAt': -1}}
        ]
        
        reviews = list(app.db.reviews.aggregate(pipeline))
        
        # 디버깅 로그
        print(f"User ID: {user_id}")
        print(f"Reviews found: {reviews}")
        
        # ObjectId를 문자열로 변환
        for review in reviews:
            if '_id' in review:
                review['_id'] = str(review['_id'])  # _id를 문자열로 변환
            if 'createdAt' in review and review['createdAt']:
                review['createdAt'] = review['createdAt'].isoformat()
        
        average_rating = 0.0
        if reviews:
            total_rating = sum(review['rating'] for review in reviews)
            average_rating = total_rating / len(reviews)
        
        response = {
            'reviews': reviews,
            'averageRating': round(average_rating, 1)
        }
        
        print(f"Final response: {response}")  # 최종 응답 디버깅
        return jsonify(response)
    
    except Exception as e:
        print(f"사용자 리뷰 조회 오류: {e}")
        return jsonify({'error': str(e)}), 500