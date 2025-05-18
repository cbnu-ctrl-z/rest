from flask import Blueprint, request, jsonify
from datetime import datetime

review_bp = Blueprint('review', __name__)

@review_bp.route('/submit_review', methods=['POST'])
def submit_review():
    db = request.environ['app'].db  # DB 접근

    data = request.get_json()
    rating = data.get('rating')
    review_text = data.get('review', '')
    user_id = data.get('user_id', 'anonymous')

    if rating is None:
        return jsonify({'error': 'Rating is required'}), 400

    review_doc = {
        'user_id': user_id,
        'rating': float(rating),
        'review': review_text,
        'timestamp': datetime.utcnow()
    }

    result = db.reviews.insert_one(review_doc)

    return jsonify({'message': 'Review saved', 'id': str(result.inserted_id)}), 201
