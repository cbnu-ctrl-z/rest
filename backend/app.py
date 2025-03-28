from flask import Flask
from pymongo import MongoClient
from routes.auth import auth_bp
from routes.freetime import freetime_bp
from routes.chat import chat_bp  # 채팅 블루프린트 추가

app = Flask(__name__)

# MongoDB 연결
client = MongoClient('mongodb://localhost:27017/')
app.db = client['signup_db']

# 블루프린트 등록
app.register_blueprint(auth_bp)
app.register_blueprint(freetime_bp)
app.register_blueprint(chat_bp)  # 채팅 블루프린트 등록

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
