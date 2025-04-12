import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
    final uri = Uri.parse('http://192.168.219.100:5000/chat/rooms?userId=${widget.id}');

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
      final kstTime = utcTime.add(Duration(hours: 9)); // UTC + 9시간 = KST
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
              fetchChatRooms(); // 채팅방에서 돌아오면 새로고침
            });
          },
        );
      },
    );
  }
}
