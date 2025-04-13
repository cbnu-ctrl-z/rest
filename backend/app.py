from flask import Flask, send_from_directory
from pymongo import MongoClient
from flask_mail import Mail
from dotenv import load_dotenv
import os
from routes.auth import auth_bp
from routes.freetime import freetime_bp
from routes.chat import chat_bp
from routes.findidpw import findidpw_bp
from routes.profile_api import profile_bp
from flask_socketio import SocketIO
from flask_cors import CORS
from routes.chat import init_socket

load_dotenv()
app = Flask(__name__)
CORS(app)

# WebSocket 설정
socketio = SocketIO(app, cors_allowed_origins="*", transports=["websocket"])

# 업로드 폴더 경로 설정
UPLOAD_FOLDER = os.path.join(os.getcwd(), 'uploads')
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

# Flask 애플리케이션 설정
app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 587
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USE_SSL'] = False
app.config['MAIL_USERNAME'] = 'simpyo2025@gmail.com'
app.config['MAIL_PASSWORD'] = os.getenv('SMTP_PW')
app.config['MAIL_DEFAULT_SENDER'] = 'simpyo2025@gmail.com'

# Flask-Mail 인스턴스 생성
mail = Mail(app)

# MongoDB 연결
client = MongoClient('mongodb://localhost:27017/')
app.db = client['signup_db']

# 블루프린트 등록
app.register_blueprint(auth_bp)
app.register_blueprint(freetime_bp)
app.register_blueprint(chat_bp)
app.register_blueprint(findidpw_bp)
app.register_blueprint(profile_bp)
init_socket(socketio)

# 업로드된 파일 제공을 위한 라우트 추가
@app.route('/uploads/<path:filename>')
def uploaded_file(filename):
    return send_from_directory(UPLOAD_FOLDER, filename)

@socketio.on('connect')
def test_connect():
    print("Client connected")

# 서버 실행
if __name__ == '__main__':
    socketio.run(app, debug=True, host='0.0.0.0', port=5000)