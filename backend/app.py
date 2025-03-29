from flask import Flask, send_from_directory
from pymongo import MongoClient
from routes.auth import auth_bp
from routes.freetime import freetime_bp
from routes.chat import chat_bp
import os

app = Flask(__name__)

# 업로드 폴더 경로 설정
UPLOAD_FOLDER = os.path.join(os.getcwd(), 'uploads')
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

# MongoDB 연결
client = MongoClient('mongodb://localhost:27017/')
app.db = client['signup_db']

# 블루프린트 등록
app.register_blueprint(auth_bp)
app.register_blueprint(freetime_bp)
app.register_blueprint(chat_bp)

# 업로드된 파일 제공을 위한 라우트 추가
@app.route('/uploads/<path:filename>')
def uploaded_file(filename):
    return send_from_directory(UPLOAD_FOLDER, filename)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)