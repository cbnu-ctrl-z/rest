import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> _messages = [];
  String? senderId;
  String? receiverId;
  TextEditingController _messageController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      print('전달된 arguments: $args'); // 디버깅용
      senderId = args['id'];
      receiverId = args['receiverId'];
      _fetchMessages();
    }
  }

  Future<void> _fetchMessages() async {
    if (senderId == null || receiverId == null) return;

    final url = Uri.parse('http://192.168.219.100:5000/get_messages?sender=$senderId&receiver=$receiverId');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _messages = data.map((msg) => {
            'sender': msg['sender'],
            'receiver': msg['receiver'],
            'content': msg['content'],
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

    const url = 'http://192.168.219.100:5000/send_message';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender': senderId,
          'receiver': receiverId,
          'content': message,
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
