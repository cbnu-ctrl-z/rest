from flask import Flask
from pymongo import MongoClient
from dotenv import load_dotenv
import os
import urllib
from routes.auth import auth_bp
from routes.freetime import freetime_bp
from routes.chat import chat_bp  # 채팅 블루프린트 추가

load_dotenv()
app = Flask(__name__)

# MongoDB 연결
encoded_pw = urllib.parse.quote_plus(os.getenv('MONGO_PW')) #문자열 내 숫자, 특수문자등을 깨지지않게 안전하게 처리/env파일에서 비밀번호 get
MONGO_URI = f"mongodb+srv://{os.getenv('MONGO_ID')}:{encoded_pw}@{os.getenv('MONGO_HOST')}/simpyo?retryWrites=true&w=majority&appName=Cluster0" #env 파일에서 ID host명 get
client = MongoClient(MONGO_URI) #mongodb 연결
app.db = client['simpyo']

# 블루프린트 등록
app.register_blueprint(auth_bp)
app.register_blueprint(freetime_bp)
app.register_blueprint(chat_bp)  # 채팅 블루프린트 등록

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
