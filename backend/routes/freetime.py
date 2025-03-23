from flask import Blueprint, request, jsonify
from flask import current_app  # 추가

freetime_bp = Blueprint('freetime', __name__)

@freetime_bp.route('/add_freetime', methods=['POST'])
def add_freetime():
    data = request.get_json()
    print("Received data:", data) #이거 왜 있는거임?
    email = data.get('email')
    day = data.get('day')
    start_time = data.get('start_time')
    end_time = data.get('end_time')
    users_collection = current_app.db['users']  # request.app.db → current_app.db

    if not all([email, day, start_time, end_time]): #하나라도 값이 없으면 에러메세지 반환환
        return jsonify({'error': '모든 필드를 입력해야 합니다'}), 400

    user = users_collection.find_one({'email': email})
    if not user:
        return jsonify({'error': '사용자를 찾을 수 없습니다'}), 404

    freetime = {'day': day, 'start_time': start_time, 'end_time': end_time}
    users_collection.update_one(
        {'email': email},
        {'$push': {'freetimes': freetime}} #회원가입때 users 컬렉션에 freetime배열 형태를 생성했었음, push연산자를 usrs의 freetimes 배열에 freetime값 추가
    )
    return jsonify({'message': '공강 시간 추가 성공'}), 201

@freetime_bp.route('/match_freetime', methods=['POST'])
def match_freetime():
    data = request.get_json()
    email = data.get('email') # 클라이언트가 보낸 이메일 값을 가져옴
    users_collection = current_app.db['users']  # request.app.db → current_app.db

    user = users_collection.find_one({'email': email})
    if not user or 'freetimes' not in user or not user['freetimes']: # 공강 시간이 없는 사용자이거나 해당 필드가 비어있으면 빈 배열 반환
        return jsonify([]), 200

    matches = [] # 일치하는 공강 시간을 저장할 리스트
    for other_user in users_collection.find({'email': {'$ne': email}}): #다른 사용자의 데이터 확인 / ('$ne': email) email과 같지않은 email을 가진 사용자 찾기
        if 'freetimes' in other_user: #other_user 객체에 freetimes가 있으면 
            for freetime in other_user['freetimes']:
                for my_freetime in user['freetimes']:
                    if (freetime['day'] == my_freetime['day'] and
                        freetime['start_time'] == my_freetime['start_time'] and
                        freetime['end_time'] == my_freetime['end_time']): #날짜 시작시간, 끝나는 시간이 완전히 같아야 매칭칭
                        matches.append({ #리스트에 매칭된 다른사용자 데이터 저장
                            'name': other_user['name'],
                            'day': freetime['day'],
                            'start_time': freetime['start_time'],
                            'end_time': freetime['end_time']
                        })

    return jsonify(matches), 200