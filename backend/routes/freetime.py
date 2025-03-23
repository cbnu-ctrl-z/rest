from flask import Blueprint, request, jsonify
from flask import current_app  # 추가

freetime_bp = Blueprint('freetime', __name__)

@freetime_bp.route('/add_freetime', methods=['POST'])
def add_freetime():
    data = request.get_json()
    print("Received data:", data)
    user_id = data.get('id')
    day = data.get('day')
    start_time = data.get('start_time')
    end_time = data.get('end_time')
    users_collection = current_app.db['users']

    if not all([user_id, day, start_time, end_time]):
        return jsonify({'error': '모든 필드를 입력해야 합니다'}), 400

    user = users_collection.find_one({'id': user_id})
    if not user:
        return jsonify({'error': '사용자를 찾을 수 없습니다'}), 404

    freetime = {'day': day, 'start_time': start_time, 'end_time': end_time}
    users_collection.update_one(
        {'id': user_id},
        {'$push': {'freetimes': freetime}}
    )
    return jsonify({'message': '공강 시간 추가 성공'}), 201

@freetime_bp.route('/match_freetime', methods=['POST'])
def match_freetime():
    data = request.get_json()
    user_id = data.get('id')
    users_collection = current_app.db['users']

    user = users_collection.find_one({'id': user_id})
    if not user or 'freetimes' not in user or not user['freetimes']:
        return jsonify([]), 200

    matches = []
    for other_user in users_collection.find({'id': {'$ne': user_id}}):
        if 'freetimes' in other_user:
            for freetime in other_user['freetimes']:
                for my_freetime in user['freetimes']:
                    if (freetime['day'] == my_freetime['day'] and
                        freetime['start_time'] == my_freetime['start_time'] and
                        freetime['end_time'] == my_freetime['end_time']):
                        matches.append({
                            'name': other_user['name'],
                            'day': freetime['day'],
                            'start_time': freetime['start_time'],
                            'end_time': freetime['end_time']
                        })

    return jsonify(matches), 200