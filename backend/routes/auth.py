from flask import Blueprint, request, jsonify, current_app
import os
from werkzeug.utils import secure_filename
import time

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

@auth_bp.route('/user_profile', methods=['GET'])
def user_profile():
    user_id = request.args.get('id')
    
    if not user_id:
        return jsonify({'error': '사용자 ID가 필요합니다'}), 400
    
    users_collection = current_app.db['users']
    user = users_collection.find_one({'id': user_id})
    
    if not user:
        return jsonify({'error': '사용자를 찾을 수 없습니다'}), 404
    
    profile_data = {
        'name': user.get('name', ''),
        'email': user.get('email', ''),
        'profile_image': user.get('profile_image', None)
    }
    
    return jsonify(profile_data), 200

# 프로필 이미지 업데이트 API
@auth_bp.route('/update_profile_image', methods=['POST'])
def update_profile_image():
    if 'profile_image' not in request.files:
        return jsonify({'error': '이미지 파일이 없습니다'}), 400
        
    user_id = request.form.get('id')
    if not user_id:
        return jsonify({'error': '사용자 ID가 필요합니다'}), 400
    
    users_collection = current_app.db['users']
    user = users_collection.find_one({'id': user_id})
    
    if not user:
        return jsonify({'error': '사용자를 찾을 수 없습니다'}), 404
    
    file = request.files['profile_image']
    if file.filename == '':
        return jsonify({'error': '선택된 파일이 없습니다'}), 400
    
    # 업로드 폴더가 없으면 생성
    upload_folder = os.path.join(os.getcwd(), 'uploads')
    if not os.path.exists(upload_folder):
        os.makedirs(upload_folder)
    
    # 파일명 보안 처리 및 중복 방지
    filename = secure_filename(file.filename)
    filename = f"{int(time.time())}_{filename}"  # 타임스탬프 추가
    file_path = os.path.join(upload_folder, filename)
    
    # 파일 저장
    file.save(file_path)
    
    # 서버에서 접근 가능한 URL 생성
    file_url = f"http://192.168.219.115:5000/uploads/{filename}"
    
    # 사용자 데이터 업데이트
    users_collection.update_one(
        {'id': user_id},
        {'$set': {'profile_image': file_url}}
    )
    
    return jsonify({
        'message': '프로필 이미지가 업데이트되었습니다',
        'profile_image_url': file_url
    }), 200