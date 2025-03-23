from flask import Flask  # Flask 프레임워크 가져오기
from pymongo import MongoClient  # MongoDB와 연결하기 위한 라이브러리
from routes.auth import auth_bp  # 인증 관련 블루프린트 가져오기
from routes.freetime import freetime_bp  # 자유시간 관련 블루프린트 가져오기
from dotenv import load_dotenv  # .env 파일에서 환경 변수 로드하기
import os  # 환경 변수를 다루기 위한 os 모듈

load_dotenv() # 환경 변수 로드 (.env 파일에서 값을 가져올 수 있도록 설정)
app = Flask(__name__) # Flask 애플리케이션 객체 생성

# MongoDB 연결
client = MongoClient(os.getenv('MONGO_URI')) # 환경 변수에서 MongoDB 주소 가져오기
app.db = client['signup_db'] # 'signup_db' 데이터베이스에 접근

# 블루프린트 등록 (라우트를 모듈화하여 관리/ 기능별로 파일 분리리)
app.register_blueprint(auth_bp) # 인증 관련 블루프린트 추가
app.register_blueprint(freetime_bp) # 자유시간 관련 블루프린트 추가

# Flask 애플리케이션 실행
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
    # debug=True: 코드 변경 시 자동으로 서버 재시작
    # host='0.0.0.0': 모든 네트워크에서 접근 가능하도록 설정 <-추후 변경경
    # port=5000: 서버를 5000번 포트에서 실행