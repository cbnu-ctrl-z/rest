from flask import Blueprint, request, jsonify, current_app
import os
from werkzeug.utils import secure_filename
import time

profile_bp = Blueprint('profile', __name__)

@profile_bp.route('/user_profile', methods=['GET'])
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

@profile_bp.route('/update_profile_image', methods=['POST'])
def update_profile_image():
    print("프로필 이미지 업데이트 요청 받음")
    
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
        print(f"업로드 폴더 생성: {upload_folder}")
    
    # 파일명 보안 처리 및 중복 방지
    filename = secure_filename(file.filename)
    filename = f"{int(time.time())}_{filename}"  # 타임스탬프 추가
    file_path = os.path.join(upload_folder, filename)
    
    # 파일 저장
    try:
        file.save(file_path)
        print(f"파일 저장 완료: {file_path}")
    except Exception as e:
        print(f"파일 저장 중 오류 발생: {e}")
        return jsonify({'error': f'파일 저장 중 오류 발생: {e}'}), 500
    
    # 서버에서 접근 가능한 URL 생성
    file_url = f"http://172.30.73.82:5000/uploads/{filename}"
    
    # 사용자 데이터 업데이트
    try:
        users_collection.update_one(
            {'id': user_id},
            {'$set': {'profile_image': file_url}}
        )
        print(f"DB 업데이트 완료: {file_url}")
    except Exception as e:
        print(f"DB 업데이트 중 오류 발생: {e}")
        return jsonify({'error': f'데이터베이스 업데이트 중 오류 발생: {e}'}), 500
    
    return jsonify({
        'message': '프로필 이미지가 업데이트되었습니다',
        'profile_image_url': file_url
    }), 200