from flask import Blueprint, request, jsonify
from bson import ObjectId
from datetime import datetime

board_bp = Blueprint('board', __name__)

# 멘토 글 작성
@board_bp.route('/mentor/write', methods=['POST'])
def write_mentor_post():
    data = request.json
    writer = data.get('writer')
    writer_name = data.get('writerName')  # writerName 받기
    title = data.get('title')
    content = data.get('content')

    if not writer or not title or not content or not writer_name:
        return jsonify({'error': '모든 항목을 입력해주세요.'}), 400

    post = {
        'writer': writer,
        'writerName': writer_name,  # writerName 추가
        'title': title,
        'content': content,
        'timestamp': datetime.now()
    }

    db = request.environ['app'].db
    db.mentor_posts.insert_one(post)
    return jsonify({'message': '멘토 게시글 작성 완료'}), 200

# 멘티 글 작성
@board_bp.route('/mentee/write', methods=['POST'])
def write_mentee_post():
    data = request.json
    writer = data.get('writer')
    writer_name = data.get('writerName')  # writerName 받기
    title = data.get('title')
    content = data.get('content')

    if not writer or not title or not content or not writer_name:
        return jsonify({'error': '모든 항목을 입력해주세요.'}), 400

    post = {
        'writer': writer,
        'writerName': writer_name,  # writerName 추가
        'title': title,
        'content': content,
        'timestamp': datetime.now()
    }

    db = request.environ['app'].db
    db.mentee_posts.insert_one(post)
    return jsonify({'message': '멘티 게시글 작성 완료'}), 200

# 멘토 게시글 조회
@board_bp.route('/mentor/posts', methods=['GET'])
def get_mentor_posts():
    db = request.environ['app'].db
    posts = db.mentor_posts.find().sort('timestamp', -1)  # 최신 순으로 정렬
    post_list = []

    for post in posts:
        post_list.append({
            'id': str(post['_id']),
            'writer': post['writer'],
            'writerName': post['writerName'],  # writerName 추가
            'title': post['title'],
            'content': post['content'],
            'timestamp': post['timestamp'].strftime('%Y-%m-%d %H:%M:%S')
        })
    
    return jsonify(post_list), 200

# 멘티 게시글 조회
@board_bp.route('/mentee/posts', methods=['GET'])
def get_mentee_posts():
    db = request.environ['app'].db
    posts = db.mentee_posts.find().sort('timestamp', -1)  # 최신 순으로 정렬
    post_list = []

    for post in posts:
        post_list.append({
            'id': str(post['_id']),
            'writer': post['writer'],
            'writerName': post['writerName'],  # writerName 추가
            'title': post['title'],
            'content': post['content'],
            'timestamp': post['timestamp'].strftime('%Y-%m-%d %H:%M:%S')
        })
    
    return jsonify(post_list), 200
