from flask import Blueprint, request, jsonify, current_app
from flask_socketio import emit, join_room
import os
import time
from dotenv import load_dotenv

# Agora 토큰 빌더 (설치 필요: pip install agora-token-builder)
try:
    from agora_token_builder import RtcTokenBuilder
    AGORA_TOKEN_AVAILABLE = True
except ImportError:
    AGORA_TOKEN_AVAILABLE = False
    print("Warning: agora-token-builder not installed. Using development mode.")

load_dotenv()

voice_call_bp = Blueprint('voice_call', __name__)

# Agora 설정 
AGORA_APP_ID = os.getenv('AGORA_APP_ID')
AGORA_APP_CERTIFICATE = os.getenv('AGORA_APP_CERTIFICATE')

def generate_agora_token(channel_name, uid=0):
    """Agora 토큰 생성"""
    # Certificate이 없거나 토큰 빌더가 없는 경우 개발 모드
    if not AGORA_APP_CERTIFICATE or not AGORA_TOKEN_AVAILABLE:
        print(f"Development mode: Certificate={'있음' if AGORA_APP_CERTIFICATE else '없음'}, TokenBuilder={'설치됨' if AGORA_TOKEN_AVAILABLE else '미설치'}")
        return None  # 토큰 없이 App ID만으로 접속
    
    try:
        # 토큰 유효 시간 (24시간)
        expiration_time_in_seconds = 86400
        current_timestamp = int(time.time())
        privilegeExpiredTs = current_timestamp + expiration_time_in_seconds
        
        # RTC 토큰 생성
        token = RtcTokenBuilder.buildTokenWithUid(
            AGORA_APP_ID,
            AGORA_APP_CERTIFICATE,
            channel_name,
            uid,
            RtcTokenBuilder.Role_Publisher,  # 송수신 가능
            privilegeExpiredTs
        )
        
        print(f"토큰 생성 성공: 채널={channel_name}, uid={uid}")
        return token
        
    except Exception as e:
        print(f"토큰 생성 실패: {e}")
        return None

def init_voice_socket(socketio):
    """음성 통화 소켓 이벤트 초기화"""
    
    @socketio.on('voice_call_request')
    def handle_voice_call_request(data):
        sender_id = data.get('senderId')
        receiver_id = data.get('receiverId')
        room_id = data.get('roomId')
        
        print(f"음성 통화 요청: {sender_id} → {receiver_id}")
        
        # 수신자에게 통화 요청 전달
        emit('voice_call_request', {
            'senderId': sender_id,
            'receiverId': receiver_id,
            'roomId': room_id
        }, room=receiver_id)
    
    @socketio.on('voice_call_accepted')
    def handle_voice_call_accepted(data):
        sender_id = data.get('senderId')
        receiver_id = data.get('receiverId')
        room_id = data.get('roomId')
        
        print(f"음성 통화 수락: {receiver_id} 수락됨")
        
        # Agora 채널명 생성 (roomId 사용)
        channel_name = f"voice_{room_id}"
        
        # 토큰 생성 (개발 모드에서는 None 반환 가능)
        token = generate_agora_token(channel_name, 0)
        
        # 발신자에게 응답
        emit('voice_call_accepted', {
            'channelName': channel_name,
            'token': token,  # None이어도 괜찮음
            'receiverId': receiver_id,
            'appId': AGORA_APP_ID  # App ID도 전달
        }, room=sender_id)
        
        # 수신자에게도 채널 정보 전송
        emit('voice_call_accepted', {
            'channelName': channel_name,
            'token': token,  # None이어도 괜찮음
            'senderId': sender_id,
            'appId': AGORA_APP_ID  # App ID도 전달
        }, room=receiver_id)
    
    @socketio.on('voice_call_rejected')
    def handle_voice_call_rejected(data):
        sender_id = data.get('senderId')
        receiver_id = data.get('receiverId')
        
        print(f"음성 통화 거절: {receiver_id} 거절함")
        
        # 발신자에게 거절 알림
        emit('voice_call_rejected', {
            'receiverId': receiver_id
        }, room=sender_id)
    
    @socketio.on('voice_call_ended')
    def handle_voice_call_ended(data):
        sender_id = data.get('senderId')
        receiver_id = data.get('receiverId')
        
        print(f"음성 통화 종료: {sender_id}")
        
        # 상대방에게 통화 종료 알림
        emit('voice_call_ended', {
            'userId': sender_id
        }, room=receiver_id)

# REST API 엔드포인트 (필요한 경우)
@voice_call_bp.route('/voice/token', methods=['POST'])
def get_voice_token():
    """음성 통화를 위한 토큰 발급"""
    data = request.get_json()
    channel_name = data.get('channelName')
    uid = data.get('uid', 0)
    
    if not channel_name:
        return jsonify({'error': '채널명이 필요합니다'}), 400
    
    token = generate_agora_token(channel_name, uid)
    
    return jsonify({
        'token': token,
        'channelName': channel_name,
        'uid': uid,
        'appId': AGORA_APP_ID
    }), 200