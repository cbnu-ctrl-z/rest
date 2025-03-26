from flask import Blueprint, request, jsonify
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