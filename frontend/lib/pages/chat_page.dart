import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../pages/voice_call_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  late IO.Socket _socket;
  bool _isLoading = true;
  bool _isInVoiceCall = false;
  bool _isMuted = false;
  bool _isRemoteMuted = false;
  bool _isSpeakerOn = false;

  late String senderId;
  late String receiverId;
  late String receiverName;
  late String roomId;

  final VoiceCallService _voiceCallService = VoiceCallService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      senderId = args['id'] ?? '';
      receiverId = args['receiverId'] ?? '';
      receiverName = args['name'] ?? '';
      roomId = args['roomId'] ?? '';
    }

    _initSocket();
    _initVoiceCall();
  }

  void _initVoiceCall() {
    _voiceCallService.onUserJoined = (uid) {
      setState(() {
        _isInVoiceCall = true;
      });
      _showSnackBar('${receiverName}님이 통화에 참여했습니다');
    };

    _voiceCallService.onUserOffline = (uid) {
      _endVoiceCall();
      _showSnackBar('${receiverName}님이 통화를 종료했습니다');
    };

    _voiceCallService.onRemoteAudioStateChanged = (muted) {
      setState(() {
        _isRemoteMuted = muted;
      });
    };

    _voiceCallService.onError = (errorMsg) {
      _showSnackBar('오류: $errorMsg');
    };
  }

  void _initSocket() {
    String apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:5000';

    _socket = IO.io(
      apiUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket.onConnect((_) {
      print("✅ [DEBUG] 소켓 연결 성공");

      List<String> ids = [senderId, receiverId]..sort();
      String roomId = ids.join('_');

      _socket.emit('join_chat_room', {
        'senderId': senderId,
        'receiverId': receiverId,
        'roomId': roomId,
      });
    });

    _socket.on('load_previous_messages', (data) {
      setState(() {
        _messages = List.from(data);
        _isLoading = false;
      });
      _scrollToBottom();
    });

    _socket.on('receive_message', (data) {
      setState(() {
        _messages.add(data);
      });
      _scrollToBottom();
    });

    // 음성 통화 관련 이벤트
    _socket.on('voice_call_request', (data) {
      _showIncomingCallDialog(data);
    });

    _socket.on('voice_call_accepted', (data) {
      _startVoiceCall(data['channelName'], data['token']);
    });

    _socket.on('voice_call_rejected', (_) {
      _showSnackBar('통화가 거절되었습니다');
    });

    _socket.on('voice_call_ended', (_) {
      _endVoiceCall();
    });

    _socket.connect();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': _messageController.text.trim(),
    };

    _socket.emit('send_message', messageData);
    _messageController.clear();
  }

  void _initiateVoiceCall() {
    if (_isInVoiceCall) return;

    _socket.emit('voice_call_request', {
      'senderId': senderId,
      'receiverId': receiverId,
      'roomId': roomId,
    });

    _showSnackBar('${receiverName}님에게 전화를 걸고 있습니다...');
  }

  void _showIncomingCallDialog(dynamic data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('음성 통화'),
        content: Text('${receiverName}님으로부터 전화가 왔습니다'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _socket.emit('voice_call_rejected', {
                'senderId': senderId,
                'receiverId': receiverId,
              });
            },
            child: Text('거절'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _socket.emit('voice_call_accepted', {
                'senderId': senderId,
                'receiverId': receiverId,
                'roomId': roomId,
              });
            },
            child: Text('수락'),
          ),
        ],
      ),
    );
  }

  Future<void> _startVoiceCall(String channelName, String token) async {
    setState(() {
      _isInVoiceCall = true;
    });

    await _voiceCallService.joinChannel(channelName, token);
  }

  Future<void> _endVoiceCall() async {
    if (!_isInVoiceCall) return;

    _socket.emit('voice_call_ended', {
      'senderId': senderId,
      'receiverId': receiverId,
    });

    await _voiceCallService.leaveChannel();

    setState(() {
      _isInVoiceCall = false;
      _isMuted = false;
    });
  }

  Future<void> _toggleMute() async {
    await _voiceCallService.toggleMute();
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  Future<void> _toggleSpeaker() async {
    await _voiceCallService.switchSpeakerphone();
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _socket.disconnect();
    _socket.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _voiceCallService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(receiverName),
        actions: [
          if (!_isInVoiceCall)
            IconButton(
              icon: Icon(Icons.phone),
              onPressed: _initiateVoiceCall,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isInVoiceCall) _buildVoiceCallControls(),
          if (_isLoading) LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                bool isCurrentUser = message['senderId'] == senderId;

                return Align(
                  alignment: isCurrentUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['message'],
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          _formatTimestamp(message['timestamp']),
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  child: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCallControls() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      color: Colors.green[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Icon(Icons.phone_in_talk, color: Colors.green),
              Text('통화 중', style: TextStyle(fontSize: 12)),
            ],
          ),
          IconButton(
            icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
            onPressed: _toggleMute,
            color: _isMuted ? Colors.red : Colors.green,
          ),
          IconButton(
            icon: Icon(_isSpeakerOn ? Icons.volume_up : Icons.volume_down),
            onPressed: _toggleSpeaker,
            color: _isSpeakerOn ? Colors.green : Colors.grey,
          ),
          IconButton(
            icon: Icon(Icons.call_end),
            onPressed: _endVoiceCall,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      DateTime utcTime = DateTime.parse(timestamp);
      DateTime kstTime = utcTime.add(Duration(hours: 9));
      return '${kstTime.hour}:${kstTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '시간 없음';
    }
  }
}

