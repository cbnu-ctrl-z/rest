from flask import Blueprint, request, jsonify
<<<<<<< HEAD
from flask import current_app  # 추가

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/signup', methods=['POST'])
def signup():
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    id = data.get('id')
    password = data.get('password')
    users_collection = current_app.db['users']  # request.app.db → current_app.db

    if not name or not id or not email or not password:
        return jsonify({'error': '모든 필드를 입력해야 합니다'}), 400

    if users_collection.find_one({'id': id}):
        return jsonify({'error': '이미 존재하는 아이디입니다'}), 409
    
    if users_collection.find_one({'email': email}):  # 이메일 중복 검사
        return jsonify({'error': '이미 존재하는 이메일입니다'}), 409

    user_data = {'name': name, 'email':email, 'id': id, 'password': password, 'freetimes': []}
    result = users_collection.insert_one(user_data)

    return jsonify({'message': '회원가입 성공!', 'id': str(result.inserted_id)}), 201
=======
from flask import current_app  

# 'auth'라는 블루프린트 생성 (회원가입 및 로그인 관련 라우트 관리)
auth_bp = Blueprint('auth', __name__)


#회원가입 API,post 방식
@auth_bp.route('/signup', methods=['POST'])
def signup():
    data = request.get_json() #data에 클라이언트가 보낸 데이터를 json형태로 저장(request : 클라이언트로부터 들어오는 HTTP 요청 처리 객체)
    name = data.get('name') #key값을 통해 찾은 데이터 name에 저장
    email = data.get('email')
    id = data.get('id')
    password = data.get('password')
    users_collection = current_app.db['users']  # request.app.db → current_app.db / #mongodb의 users 컬렉션에 있는 데이터를 가져옴
    
    if not name or not id or not email or not password: #세개중 하나라도 값이 없으면 에러메세지 반환환
        return jsonify({'error': '모든 필드를 입력해야 합니다'}), 400

    if users_collection.find_one({'id': id}): #이미 존재하는 이메일이면 에러메세지 반환, find_one으로 email기준 db에서 검색을 한 뒤 일치하는 사용자의 전체 정보를 가져옴!!
        return jsonify({'error': '이미 존재하는 이메일입니다'}), 409

    user_data = {'name': name, 'email':email, 'id': id, 'password': password, 'freetimes': []} #딕셔너리 형태로 user_data에 저장

    result = users_collection.insert_one(user_data) #user_dat의 값을 users_collection객체를 통해 users컬렉션에 삽입, 삽입된 문서(mongodb 데이터)ID를 result에 저장

    return jsonify({'message': '회원가입 성공!', 'id': str(result.inserted_id)}), 201 #result를 사용해서 클라이언트에게 json형식으로 반환, 새로 삽입된 문서ID도 같이 전달달
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    id = data.get('id')
    password = data.get('password')
    
    users_collection = current_app.db['users']  # request.app.db → current_app.db

    if not id or not password:
        return jsonify({'error': '아이디와 비밀번호를 입력해야 합니다'}), 400

    user = users_collection.find_one({'id': id})
    if not user or user['password'] != password:
        return jsonify({'error': '아이디 또는 비밀번호가 잘못되었습니다'}), 401

    return jsonify({'message': '로그인 성공!', 'name': user['name'],'email':user['email']}), 200