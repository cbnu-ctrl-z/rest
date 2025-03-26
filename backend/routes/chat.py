from flask import Blueprint, request, jsonify
from flask import current_app
from datetime import datetime

chat_bp = Blueprint('chat', __name__)

@chat_bp.route('/send_message', methods=['POST'])
def send_message():
    data = request.get_json()

    sender = data.get('sender')
    receiver = data.get('receiver')
    content = data.get('content')

    if not sender or not receiver or not content:
        return jsonify({'error': 'All fields are required!'}), 400

    message = {
        'sender': sender,
        'receiver': receiver,
        'content': content,
        'timestamp': datetime.utcnow()
    }

    try:
        current_app.db.chat_messages.insert_one(message)
        return jsonify({'message': 'Message sent successfully!'}), 201
    except Exception as e:
        return jsonify({'error': f'Error saving message: {str(e)}'}), 500

@chat_bp.route('/get_messages', methods=['GET'])
def get_messages():
    sender = request.args.get('sender')
    receiver = request.args.get('receiver')

    if not sender or not receiver:
        return jsonify({'error': 'Sender and Receiver are required!'}), 400

    try:
        messages = current_app.db.chat_messages.find({'$or': [
            {'sender': sender, 'receiver': receiver},
            {'sender': receiver, 'receiver': sender}
        ]})

        result = [{'sender': msg['sender'], 'receiver': msg['receiver'], 'content': msg['content']} for msg in messages]

        return jsonify(result), 200
    except Exception as e:
        return jsonify({'error': f'Error retrieving messages: {str(e)}'}), 500
