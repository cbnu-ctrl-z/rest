from flask import Flask
from pymongo import MongoClient
from flask_mail import Mail
from dotenv import load_dotenv  # .env 파일에서 환경 변수 로드하기
import os  # 환경 변수를 다루기 위한 os 모듈
from routes.auth import auth_bp
from routes.freetime import freetime_bp
from routes.chat import chat_bp  # 채팅 블루프린트 추가
from routes.findidpw import findidpw_bp #idpw찾기 블루프린트 추가
from flask_socketio import SocketIO
from flask_cors import CORS
from routes.chat import init_socket

load_dotenv() # 환경 변수 로드 (.env 파일에서 값을 가져올 수 있도록 설정)
app = Flask(__name__)
CORS(app)

# WebSocket 설정
socketio = SocketIO(app, cors_allowed_origins="*",transports=["websocket"])   


# Flask 애플리케이션 설정
app.config['MAIL_SERVER'] = 'smtp.gmail.com'  # Gmail SMTP 서버
app.config['MAIL_PORT'] = 587  # SMTP 포트 (TLS)
app.config['MAIL_USE_TLS'] = True  # TLS 사용
app.config['MAIL_USE_SSL'] = False  # SSL 사용하지 않음
app.config['MAIL_USERNAME'] = 'simpyo2025@gmail.com'  # 발신 이메일 주소
app.config['MAIL_PASSWORD'] = os.getenv('SMTP_PW')  # 발신 이메일 비밀번호 / 환경변수에서 SMTP이메일 PW가져오기
app.config['MAIL_DEFAULT_SENDER'] = 'simpyo2025@gmail.com'  # 기본 발신자

# Flask-Mail 인스턴스 생성
mail = Mail(app)

# MongoDB 연결
client = MongoClient('mongodb://localhost:27017/')
app.db = client['signup_db']

# 블루프린트 등록
app.register_blueprint(auth_bp)
app.register_blueprint(freetime_bp)
app.register_blueprint(chat_bp)  # 채팅 블루프린트 등록
app.register_blueprint(findidpw_bp)  # findidpw 블루프린트 등록
init_socket(socketio)

@socketio.on('connect')
def test_connect():
    print("Client connected")

# 서버 실행
if __name__ == '__main__':
    socketio.run(app, debug=True, host='0.0.0.0', port=5000)
