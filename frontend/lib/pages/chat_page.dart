import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  bool _isCreatingProject = false; // 🔥 추가된 로딩 상태

  late String senderId;
  late String receiverId;
  late String receiverName;
  late String roomId;

  String? postTitle;
  String? postContent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      senderId = args['id'] ?? '';
      receiverId = args['receiverId'] ?? '';
      receiverName = args['name'] ?? '';
      roomId = args['roomId'] ?? '';

      postTitle = args['postTitle'];
      postContent = args['postContent'];
    }

    _initSocket();
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

  Future<void> _createCollaborationProject() async {
    String chatHistory = _messages.map((msg) =>
    "${msg['senderId'] == senderId ? '나' : receiverName}: ${msg['message']}"
    ).join('\n');

    try {
      setState(() {
        _isCreatingProject = true; // 🔥 로딩 시작
      });

      final url = '${dotenv.env['API_URL']}/projects/create';

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'title': postTitle ?? '새 협업 프로젝트',
          'description': postContent ?? '협업 프로젝트 설명',
          'chatHistory': chatHistory,
          'members': [senderId, receiverId],
          'creatorId': senderId,
          'roomId': roomId,
        }),
      );

      if (response.statusCode == 200) {
        final projectData = json.decode(response.body);
        _showProjectCreatedDialog(projectData['id']);
      } else {
        _showErrorDialog('프로젝트 생성에 실패했습니다.');
      }
    } catch (e) {
      _showErrorDialog('오류가 발생했습니다: $e');
    } finally {
      setState(() {
        _isCreatingProject = false; // 🔥 로딩 끝
      });
    }
  }

  void _showProjectCreatedDialog(String projectId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('프로젝트 생성 완료'),
        content: Text('협업 프로젝트가 성공적으로 생성되었습니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('닫기'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamed(
                context,
                '/project_detail',
                arguments: {'projectId': projectId},
              );
            },
            child: Text('프로젝트로 이동'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('오류'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
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
    if (_isCreatingProject) {
      return Scaffold(
        appBar: AppBar(title: Text('프로젝트 생성 중...')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('AI가 프로젝트를 분석하여 생성 중입니다...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(receiverName),
        actions: [
          IconButton(
            icon: Icon(Icons.add_task),
            tooltip: '협업 프로젝트 생성',
            onPressed: () {
              if (_messages.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('채팅 내용이 필요합니다.')),
                );
                return;
              }

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('협업 프로젝트 생성'),
                  content: Text('채팅 내용과 게시글 정보를 기반으로 협업 프로젝트를 생성하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('취소'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _createCollaborationProject();
                      },
                      child: Text('생성'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
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
      DateTime kstTime = utcTime.add(Duration(hours: 9));
      return '${kstTime.hour}:${kstTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '시간 없음';
    }
  }
}
