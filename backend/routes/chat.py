from flask import Blueprint, request, jsonify, current_app
from flask_socketio import emit, join_room
import datetime
import uuid

chat_bp = Blueprint('chat', __name__)

def init_socket(socketio):
    @socketio.on('join_chat_room')
    def on_join(data):
        with current_app.app_context():
            db = current_app.db
            chat_collection = db['chats']

            sender_id = data.get('senderId')
            receiver_id = data.get('receiverId')

            room_id = '_'.join(sorted([sender_id, receiver_id]))
            join_room(room_id)

            previous_messages = list(chat_collection.find({'room_id': room_id})
                                     .sort('timestamp', 1).limit(50))

            for msg in previous_messages:
                msg['_id'] = str(msg['_id'])
                if isinstance(msg['timestamp'], datetime.datetime):
                    msg['timestamp'] = msg['timestamp'].isoformat()

            emit('load_previous_messages', previous_messages, room=room_id)

    @socketio.on('send_message')
    def handle_message(data):
        print(f"📩 [DEBUG] 메시지 받음: {data}")
        with current_app.app_context():
            db = current_app.db
            chat_collection = db['chats']

            sender_id = data.get('senderId')
            receiver_id = data.get('receiverId')
            message_text = data.get('message')

            room_id = '_'.join(sorted([sender_id, receiver_id]))

            message = {
                'message_id': str(uuid.uuid4()),
                'room_id': room_id,
                'senderId': sender_id,
                'receiverId': receiver_id,
                'message': message_text,
                'timestamp': datetime.datetime.utcnow().isoformat(),
                'read': False,
                'postTitle':data.get('postTitle'),
                'postContent':data.get('postContent'),
            }

            result = chat_collection.insert_one(message)
            message['_id'] = str(result.inserted_id)

            print(f"✅ 저장된 메시지: {message}")
            emit('receive_message', message, room=room_id)




@chat_bp.route('/chat/rooms', methods=['GET'])
def get_chat_rooms():
    with current_app.app_context():
        db = current_app.db
        chat_collection = db['chats']
        users_collection = db['users']

        user_id = request.args.get('userId')

        chat_rooms = chat_collection.aggregate([
            {'$match': {'$or': [{'senderId': user_id}, {'receiverId': user_id}] }},
            {'$group': {
                '_id': '$room_id',
                'lastMessage': {'$last': '$message'},
                'lastTimestamp': {'$last': '$timestamp'},
                'lastPostTitle': {'$last': '$postTitle'},
                'lastPostContent': {'$last': '$postContent'}
            }},
            {'$sort': {'lastTimestamp': -1}}
        ])

        rooms = []
        for room in chat_rooms:
            participants = room['_id'].split('_')
            other_user_id = [p for p in participants if p != user_id][0]

            other_user = users_collection.find_one({'id': other_user_id})
            if not other_user:
                print(f"[⚠️] 사용자 ID '{other_user_id}'에 해당하는 회원을 찾을 수 없습니다.")
                other_user_name = "알 수 없는 사용자"
                profile_url = None
            else:
                other_user_name = other_user.get('name', '알 수 없는 사용자')
                profile_url = other_user.get('profile_image')  # <-- 프로필 URL 가져오기

            rooms.append({
                'roomId': room['_id'],
                'otherUserId': other_user_id,
                'otherUserName': other_user_name,
                'otherUserProfileUrl': profile_url,  # <-- 응답에 포함
                'lastMessage': room['lastMessage'],
                'lastTimestamp': room['lastTimestamp'],
                'postTitle': room.get('lastPostTitle'),
                'postContent': room.get('lastPostContent'),
            })

        return jsonify(rooms)
    
    

@chat_bp.route('/chat/messages', methods=['GET'])
def get_chat_messages():
    with current_app.app_context():
        db = current_app.db
        chat_collection = db['chats']

        room_id = request.args.get('roomId')
        page = int(request.args.get('page', 1))
        limit = int(request.args.get('limit', 50))

        messages = list(chat_collection.find({'room_id': room_id})
                        .sort('timestamp', -1)
                        .skip((page - 1) * limit)
                        .limit(limit))

        for msg in messages:
            msg['_id'] = str(msg['_id'])

        return jsonify(messages)

@chat_bp.route('/chat/mark_read', methods=['POST'])
def mark_messages_read():
    with current_app.app_context():
        db = current_app.db
        chat_collection = db['chats']

        data = request.json
        room_id = data.get('roomId')
        user_id = data.get('userId')

        chat_collection.update_many(
            {
                'room_id': room_id,
                'receiverId': user_id,
                'read': False
            },
            {'$set': {'read': True}}
        )

        return jsonify({'status': 'success'})
