import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // 날짜/시간 포맷팅을 위해 추가
import 'events.dart'; // EventBus 임포트

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
  bool _isCreatingProject = false;

  late String senderId;
  late String receiverId;
  late String receiverName;
  late String roomId;
  String? receiverProfile; // 상대방 프로필 URL
  String? postTitle;
  String? postContent;

  // 그라데이션 색상 정의
  final List<Color> _gradientColors = const [Color(0xFF36eff4), Color(0xFF8A6FF0)];
  late LinearGradient _appBarGradient;
  late LinearGradient _buttonGradient;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      senderId = args['id'] ?? '';
      receiverId = args['receiverId'] ?? '';
      receiverName = args['name'] ?? '';
      roomId = args['roomId'] ?? '';
      receiverProfile = args['profile'] ?? ''; // 프로필 URL 가져오기
      postTitle = args['postTitle'];
      postContent = args['postContent'];
    }

    // 그라데이션 초기화
    _appBarGradient = LinearGradient(
      colors: _gradientColors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    _buttonGradient = LinearGradient(
      colors: _gradientColors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

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

    _socket.onConnectError((err) => print('❌ [DEBUG] Socket Connect Error: $err'));
    _socket.onError((err) => print('❌ [DEBUG] Socket Error: $err'));

    _socket.connect();
    print("🔵 [DEBUG] 소켓 연결 시도");
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': _messageController.text.trim(),
      'postTitle': postTitle,
      'postContent': postContent,
      'timestamp': DateTime.now().toIso8601String(),
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _createCollaborationProject() async {
    String chatHistorySummary = _messages.map((msg) => "${msg['senderId'] == senderId ? '나' : receiverName}: ${msg['message']}").join('\n');
    if (chatHistorySummary.length > 500) {
      chatHistorySummary = chatHistorySummary.substring(0, 500) + '...';
    }

    try {
      setState(() {
        _isCreatingProject = true;
      });

      final url = '${dotenv.env['API_URL']}/projects/create';

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'title': postTitle ?? '새 협업 프로젝트',
          'description': postContent ?? '채팅에서 시작된 협업 프로젝트입니다.\n\n[채팅 요약]\n$chatHistorySummary',
          'members': [senderId, receiverId],
          'creatorId': senderId,
          'roomId': roomId,
        }),
      );

      if (response.statusCode == 200) {
        final projectData = json.decode(response.body);
        eventBus.fire(ProjectCreatedEvent());
        _showProjectCreatedDialog(projectData['id']);
      } else {
        _showErrorDialog('프로젝트 생성에 실패했습니다. (상태 코드: ${response.statusCode})');
        print('Error Response: ${response.body}');
      }
    } catch (e) {
      _showErrorDialog('오류가 발생했습니다: $e');
      print('Exception: $e');
    } finally {
      setState(() {
        _isCreatingProject = false;
      });
    }
  }

  void _showProjectCreatedDialog(String projectId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('🎉 프로젝트 생성 완료', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('프로젝트가 성공적으로 생성되었습니다.\n프로젝트 탭에서 확인하세요.', textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8A6FF0), // 그라데이션의 끝 색상
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('⚠️ 오류 발생', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8A6FF0), // 그라데이션의 끝 색상
            ),
            child: const Text('확인'),
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
    // 프로젝트 생성 중 로딩 화면
    if (_isCreatingProject) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('프로젝트 생성 중...', style: TextStyle(color: Colors.black)),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_gradientColors[0]), // 그라데이션 시작 색상
              ),
              const SizedBox(height: 20),
              const Text(
                'AI가 게시글 및 채팅 내용을 분석하여\n 프로젝트를 생성 중입니다.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              const Text(
                '잠시만 기다려주세요...',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container( // AppBar 배경에 그라데이션 적용
          decoration: BoxDecoration(
            gradient: _appBarGradient,
          ),
        ),
        elevation: 1,
        title: Row(
          children: [
            // --- 프로필 이미지 로직 수정 시작 ---
            CircleAvatar(
              backgroundImage: (receiverProfile != null && receiverProfile!.isNotEmpty)
                  ? NetworkImage(receiverProfile!)
                  : const AssetImage('assets/basic.png') as ImageProvider, // 기본 이미지 경로 사용
              radius: 18,
            ),
            // --- 프로필 이미지 로직 수정 끝 ---
            const SizedBox(width: 10),
            Text(
              receiverName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), // 텍스트 색상 변경
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task, color: Colors.white), // 아이콘 색상 변경
            tooltip: '협업 프로젝트 생성',
            onPressed: () {
              if (_messages.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('채팅 내용이 있어야 프로젝트를 생성할 수 있습니다.'),
                    backgroundColor: const Color(0xFF8A6FF0), // 그라데이션 끝 색상 사용
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
                return;
              }

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  title: const Text('🤝 협업 프로젝트 생성', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: const Text('현재 채팅 내용과 게시글 정보를 바탕으로 \n새로운 협업 프로젝트를 생성하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                      ),
                      child: const Text('취소'),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: _buttonGradient, // 버튼에도 그라데이션 적용
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _createCollaborationProject();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, // 배경 투명하게
                          shadowColor: Colors.transparent, // 그림자 제거
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('생성', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white), // 아이콘 색상 변경
      ),
      body: Column(
        children: [
          if (_isLoading)
            LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(_gradientColors[0]), // 그라데이션 시작 색상
              backgroundColor: Colors.grey[200],
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                bool isCurrentUser = message['senderId'] == senderId;
                String formattedTime = _formatTimestamp(message['timestamp']);

                return Align(
                  alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isCurrentUser)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0, bottom: 0),
                          child: CircleAvatar(
                            radius: 16,
                            // --- 프로필 이미지 로직 수정 시작 ---
                            backgroundImage: (receiverProfile != null && receiverProfile!.isNotEmpty)
                                ? NetworkImage(receiverProfile!)
                                : const AssetImage('assets/basic.png') as ImageProvider, // 기본 이미지 경로 사용
                            // --- 프로필 이미지 로직 수정 끝 ---
                          ),
                        ),
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF36eff4).withOpacity(0.9), // 보낸 메시지 색상 변경
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(18),
                              topRight: const Radius.circular(18),
                              bottomLeft: isCurrentUser ? const Radius.circular(18) : const Radius.circular(4),
                              bottomRight: isCurrentUser ? const Radius.circular(4) : const Radius.circular(18),
                            ),
                          ),
                          child: Text(
                            message['message'],
                            style: TextStyle(
                              fontSize: 15,
                              color: isCurrentUser ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          left: isCurrentUser ? 8.0 : 0,
                          right: isCurrentUser ? 0 : 8.0,
                          bottom: 4,
                        ),
                        child: Text(
                          formattedTime,
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: _buttonGradient, // 전송 버튼에도 그라데이션 적용
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
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
      DateTime kstTime = utcTime.add(const Duration(hours: 9));
      return DateFormat('HH:mm').format(kstTime);
    } catch (e) {
      return '시간 오류';
    }
  }
}