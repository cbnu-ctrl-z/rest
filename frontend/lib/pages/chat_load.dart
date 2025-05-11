import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class Chatbutton extends StatefulWidget {
  final String id;
  const Chatbutton({required this.id});

  @override
  _ChatbuttonState createState() => _ChatbuttonState();
}

class _ChatbuttonState extends State<Chatbutton> {
  List<dynamic> chatRooms = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChatRooms();
  }

  Future<void> fetchChatRooms() async {
    final url = dotenv.env['API_URL'];
    final uri = Uri.parse('$url/chat/rooms?userId=${widget.id}');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          chatRooms = data;
          isLoading = false;
        });
      } else {
        throw Exception('채팅방 정보를 불러오지 못했습니다.');
      }
    } catch (e) {
      print('에러 발생: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatKSTTime(String utcTimeStr) {
    try {
      final utcTime = DateTime.parse(utcTimeStr);
      final kstTime = utcTime.add(Duration(hours: 9));
      return DateFormat('yyyy-MM-dd HH:mm').format(kstTime);
    } catch (e) {
      return '시간 오류';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (chatRooms.isEmpty) {
      return Center(child: Text('채팅방이 없습니다.'));
    }

    return ListView.builder(
      itemCount: chatRooms.length,
      itemBuilder: (context, index) {
        final room = chatRooms[index];
        return ListTile(
          title: Text(room['otherUserName']),
          subtitle: Text(room['lastMessage']),
          trailing: Text(formatKSTTime(room['lastTimestamp'])),
          onTap: () {
            Navigator.pushNamed(context, '/chat', arguments: {
              'roomId': room['roomId'],
              'id': widget.id,
              'receiverId': room['otherUserId'],
              'name': room['otherUserName'],
            }).then((_) {
              fetchChatRooms();
            });
          },
        );
      },
    );
  }
}

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> _messages = [];
  String? senderId;
  String? receiverId;
  String? roomId;
  TextEditingController _messageController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 전달된 arguments 받기
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      print('전달된 arguments: $args'); // 디버깅용
      senderId = args['id'];            // senderId 설정
      receiverId = args['receiverId'];  // receiverId 설정
      roomId = args['roomId'];          // roomId 설정
      _fetchMessages();                 // 메시지 가져오기
    }
  }

  Future<void> _fetchMessages() async {
    if (senderId == null || receiverId == null || roomId == null) return;

    final url = Uri.parse('${dotenv.env['API_URL']}/chat/messages?roomId=$roomId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _messages = data.map((msg) => {
            'sender': msg['sender'],
            'receiver': msg['receiver'],
            'content': msg['message'],
          }).toList();
        });
      } else {
        print('메시지 가져오기 실패: ${response.body}');
      }
    } catch (e) {
      print('오류 발생: $e');
    }
  }

  Future<void> _sendMessage(String message) async {
    if (senderId == null || receiverId == null) return;

    final url = Uri.parse('${dotenv.env['API_URL']}/chat/send_message');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': senderId,
          'receiverId': receiverId,
          'message': message,
        }),
      );

      if (response.statusCode == 201) {
        setState(() {
          _messages.add({
            'sender': senderId,
            'receiver': receiverId,
            'content': message,
          });
        });
        _messageController.clear();
      } else {
        print('메시지 전송 실패: ${response.body}');
      }
    } catch (e) {
      print('메시지 전송 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('채팅')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['sender'] == senderId;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[200] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(msg['content']),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: '메시지 입력...'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    if (_messageController.text.trim().isNotEmpty) {
                      _sendMessage(_messageController.text.trim());
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
