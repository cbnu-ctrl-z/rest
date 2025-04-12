import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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

  late String senderId;
  late String receiverId;
  late String receiverName;
  late String roomId;

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
  }

  void _initSocket() {
    _socket = IO.io(
      'http://192.168.219.100:5000',
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
      print("📤 [DEBUG] join_chat_room 이벤트 전송: $senderId, $receiverId");
    });

    _socket.on('load_previous_messages', (data) {
      print("📩 [DEBUG] 이전 메시지 로드: $data");
      setState(() {
        _messages = List.from(data);
        _isLoading = false;
      });
      _scrollToBottom();
    });

    _socket.on('receive_message', (data) {
      print("📩 [DEBUG] 새 메시지 수신: $data");

      setState(() {
        _messages.add(data);
      });
      _scrollToBottom();
    });

    _socket.connect();
    print("🔵 [DEBUG] 소켓 연결 시도");
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': _messageController.text.trim(),
    };

    print("📤 [DEBUG] 메시지 전송: $messageData");
    _socket.emit('send_message', messageData);

    _messageController.clear();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(receiverName),
      ),
      body: Column(
        children: [
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

  String _formatTimestamp(String timestamp) {
    try {
      DateTime utcTime = DateTime.parse(timestamp);
      DateTime kstTime = utcTime.add(Duration(hours: 9)); // UTC → KST
      return '${kstTime.hour}:${kstTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '시간 없음';
    }
  }
}
