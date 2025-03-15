from flask import Flask, jsonify, request
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # CORS 활성화

# 기본 테스트 API
@app.route('/api/hello', methods=['GET'])
def hello():
    return jsonify({'message': 'Hello from Flask!'})

# POST 요청을 받아 JSON 데이터 처리
@app.route('/api/data', methods=['POST'])
def get_data():
    data = request.json  # 요청에서 JSON 데이터 가져오기
    return jsonify({'received': data, 'message': 'Data received successfully'})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)