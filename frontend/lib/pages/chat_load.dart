import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class Chatbutton extends StatefulWidget {
  final String id;
  const Chatbutton({Key? key, required this.id}) : super(key: key);

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
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: room['otherUserProfileUrl'] != null
                  ? NetworkImage(room['otherUserProfileUrl'])
                  : null,
              backgroundColor: Colors.blue[100],
              child: room['otherUserProfileUrl'] == null
                  ? Text(
                room['otherUserName'].substring(0, 1),
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              )
                  : null,
            ),
            title: Text(
              room['otherUserName'],
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              room['lastMessage'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              formatKSTTime(room['lastTimestamp']),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () {
              Navigator.pushNamed(context, '/chat', arguments: {
                'roomId': room['roomId'],
                'id': widget.id,
                'receiverId': room['otherUserId'],
                'name': room['otherUserName'],
                'profile' : room['otherUserProfileUrl'],
              }).then((_) {
                fetchChatRooms();
              });
            },
          ),
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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      senderId = args['id'];
      receiverId = args['receiverId'];
      roomId = args['roomId'];
      _fetchMessages();
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
      appBar: AppBar(
        title: Text('채팅', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['sender'] == senderId;
                return Container(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blueAccent : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(isMe ? 12 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 12),
                      ),
                    ),
                    child: Text(
                      msg['content'],
                      style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                    ),
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
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '메시지를 입력하세요...',
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      if (_messageController.text.trim().isNotEmpty) {
                        _sendMessage(_messageController.text.trim());
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
