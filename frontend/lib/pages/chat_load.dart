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

  // 그라데이션 색상 정의 (HomePage 및 ChatPage와 동일)
  final List<Color> _gradientColors = const [Color(0xFF36eff4), Color(0xFF8A6FF0)];

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
      backgroundColor: Colors.white, // 배경색 통일
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0, // AppBar 그림자 제거
        title: const Text(
          '채팅',
          style: TextStyle(
            color: Colors.white, // 제목 색상 변경
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거 (탭 페이지이므로)
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_gradientColors[0]), // 그라데이션 시작 색상
        ),
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
          : RefreshIndicator( // 새로고침 기능 추가
        onRefresh: fetchChatRooms,
        color: _gradientColors[0], // 새로고침 아이콘 색상
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: chatRooms.length,
          itemBuilder: (context, index) {
            final room = chatRooms[index];
            final String otherUserName = room['otherUserName'] ?? '알 수 없음';
            final String lastMessage = room['lastMessage'] ?? '대화 기록 없음';
            final String lastTimestamp = room['lastTimestamp'] ?? '';
            final String? otherUserProfileUrl = room['otherUserProfileUrl'];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3, // 카드 그림자 추가
              child: InkWell( // 탭 효과를 위해 InkWell 사용
                borderRadius: BorderRadius.circular(16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // --- 프로필 이미지 로직 수정 시작 ---
                      CircleAvatar(
                        radius: 28, // 아바타 크기 확대
                        // otherUserProfileUrl이 null이거나 비어있으면 assets/basic.png 사용
                        backgroundImage: (otherUserProfileUrl != null && otherUserProfileUrl.isNotEmpty)
                            ? NetworkImage(otherUserProfileUrl)
                            : const AssetImage('assets/basic.png') as ImageProvider, // 기본 이미지 경로
                        backgroundColor: Colors.grey[200], // 프로필 이미지 없을 때 기본 배경

                      ),
                      // --- 프로필 이미지 로직 수정 끝 ---
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              otherUserName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatKSTTime(lastTimestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}