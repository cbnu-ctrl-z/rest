from flask import Blueprint, request, jsonify, current_app
from flask_mail import Message, Mail
import random
import string

# 'findidpw' 블루프린트 생성
findidpw_bp = Blueprint('findidpw', __name__)

# Flask-Mail 인스턴스 생성
mail = Mail()  # 전역에서 선언

# 이메일 전송 설정
def send_reset_email(email, reset_url):
    msg = Message("비밀번호 재설정 요청", 
                  sender=current_app.config['MAIL_USERNAME'], 
                  recipients=[email])
    msg.body = f"비밀번호 재설정 요청을 받았습니다. 아래 링크를 통해 비밀번호를 변경하세요.\n\n{reset_url}"

    # 올바른 메일 인스턴스 사용
    with current_app.app_context():  
        mail.send(msg)

# 아이디 찾기 API
@findidpw_bp.route('/find_id', methods=['POST'])
def find_id():
    data = request.get_json()  # 클라이언트가 보낸 JSON 데이터 받기
    email = data.get('email')

    if not email:
        return jsonify({'error': '이메일을 입력해주세요.'}), 400

    users_collection = current_app.db['users']  # MongoDB 'users' 컬렉션 가져오기

    # 이메일로 유저 검색
    user = users_collection.find_one({"email": email})

    if user:
        return jsonify({'id': user['id']}), 200
    else:
        return jsonify({'error': '해당 이메일로 등록된 계정이 없습니다.'}), 404

# 비밀번호 재설정 이메일 보내기 API
@findidpw_bp.route('/find_pw', methods=['POST'])
def find_pw():
    data = request.get_json()  # 클라이언트가 보낸 JSON 데이터 받기
    email = data.get('email')

    if not email:
        return jsonify({'error': '이메일을 입력해주세요.'}), 400

    users_collection = current_app.db['users']  # MongoDB 'users' 컬렉션 가져오기

    # 이메일로 유저 검색
    user = users_collection.find_one({"email": email})

    if user:
        # 비밀번호 재설정 링크 생성 (예시: /reset_password/<token>)
        reset_token = ''.join(random.choices(string.ascii_letters + string.digits, k=16))  # 간단한 토큰 생성
        reset_url = f"http://10.0.2.2/reset_password/{reset_token}"

        # 이메일로 비밀번호 재설정 링크 전송
        send_reset_email(email, reset_url)

        return jsonify({'message': '비밀번호 재설정 링크가 이메일로 전송되었습니다.'}), 200
    else:
        return jsonify({'error': '해당 이메일로 등록된 계정이 없습니다.'}), 404
