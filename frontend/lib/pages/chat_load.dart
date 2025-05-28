import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:async';
import 'events.dart';

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
    // ChatPage에서 프로젝트 생성 이벤트가 발생하면 채팅방 목록을 새로고침
    eventBus.on<ProjectCreatedEvent>().listen((_) {
      print("[DEBUG] ProjectCreatedEvent 수신, 채팅방 목록 새로고침");
      fetchChatRooms();
    });
    fetchChatRooms();
  }

  Future<void> fetchChatRooms() async {
    setState(() {
      isLoading = true; // 데이터를 다시 불러올 때 로딩 상태로 설정
    });

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
        throw Exception('채팅방 정보를 불러오지 못했습니다. (상태 코드: ${response.statusCode})');
      }
    } catch (e) {
      print('에러 발생: $e');
      setState(() {
        isLoading = false;
        // 오류 발생 시 사용자에게 메시지 표시 (선택 사항)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('채팅방 로딩 중 오류가 발생했습니다: $e')),
        );
      });
    }
  }

  String formatKSTTime(String utcTimeStr) {
    try {
      final utcTime = DateTime.parse(utcTimeStr);
      final kstTime = utcTime.add(const Duration(hours: 9));
      return DateFormat('yyyy-MM-dd HH:mm').format(kstTime);
    } catch (e) {
      print("Chatbutton 시간 파싱 오류: $e (원본 타임스탬프: $utcTimeStr)");
      return '시간 오류';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // HomePage와 동일한 배경색
      body: Column(
        children: [
          SizedBox(height: 20), // 상단 여백 (HomePage와 동일)
          Expanded(
            child: isLoading
                ? Center(
              child: CircularProgressIndicator(),
            )
                : chatRooms.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '아직 시작된 채팅이 없습니다.',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '게시글에서 멘토/멘티에게 채팅을 시작해보세요!',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: fetchChatRooms,
              child: ListView.builder(
                padding: const EdgeInsets.all(16), // HomePage와 동일한 패딩
                itemCount: chatRooms.length,
                itemBuilder: (context, index) {
                  final room = chatRooms[index];
                  final String otherUserName = room['otherUserName'] ?? '알 수 없음';
                  final String lastMessage = room['lastMessage'] ?? '대화 기록 없음';
                  final String lastTimestamp = room['lastTimestamp'] ?? '';
                  final String? otherUserProfileUrl = room['otherUserProfileUrl'];

                  return Card(
                    elevation: 4, // HomePage와 동일한 elevation
                    margin: const EdgeInsets.symmetric(vertical: 12), // HomePage와 동일한 마진
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // HomePage와 동일한 모양
                    color: Colors.white, // HomePage와 동일한 배경색
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16), // HomePage와 동일한 모양
                      onTap: () {
                        Navigator.pushNamed(context, '/chat', arguments: {
                          'roomId': room['roomId'],
                          'id': widget.id,
                          'receiverId': room['otherUserId'],
                          'name': otherUserName,
                          'profile': otherUserProfileUrl,
                          'postTitle': room['postTitle'],
                          'postContent': room['postContent'],
                        }).then((_) {
                          // 채팅 페이지에서 돌아왔을 때 채팅방 목록 새로고침
                          fetchChatRooms();
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16), // HomePage와 동일한 패딩
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundImage: (otherUserProfileUrl != null && otherUserProfileUrl.isNotEmpty)
                                      ? NetworkImage(otherUserProfileUrl)
                                      : const AssetImage('assets/basic.png') as ImageProvider,
                                  backgroundColor: Colors.grey[200],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        otherUserName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16, // HomePage 제목과 동일한 크기
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        lastMessage,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.black87, // HomePage와 동일한 컬러
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.access_time, color: Colors.grey, size: 14), // HomePage와 동일한 아이콘
                                SizedBox(width: 4),
                                Text(
                                  formatKSTTime(lastTimestamp),
                                  style: TextStyle(color: Colors.grey, fontSize: 12), // HomePage와 동일한 스타일
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Divider(color: Colors.grey[300], thickness: 1), // HomePage와 동일한 구분선
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}