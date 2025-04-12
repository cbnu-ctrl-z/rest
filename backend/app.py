from flask import Flask
from pymongo import MongoClient
from flask_socketio import SocketIO
from flask_cors import CORS
from routes.auth import auth_bp
from routes.freetime import freetime_bp
from routes.chat import chat_bp  # 채팅 블루프린트 추가
from routes.chat import init_socket

app = Flask(__name__)
CORS(app)

# WebSocket 설정
socketio = SocketIO(app, cors_allowed_origins="*",transports=["websocket"])   


# MongoDB 연결
client = MongoClient('mongodb://localhost:27017/')
app.db = client['signup_db']

# 블루프린트 등록
app.register_blueprint(auth_bp)
app.register_blueprint(freetime_bp)
app.register_blueprint(chat_bp)  # 채팅 블루프린트 등록
init_socket(socketio)

@socketio.on('connect')
def test_connect():
    print("Client connected")

# 서버 실행
if __name__ == '__main__':
    socketio.run(app, debug=True, host='0.0.0.0', port=5000)
