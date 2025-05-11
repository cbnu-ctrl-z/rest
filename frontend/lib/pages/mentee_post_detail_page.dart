import 'package:flutter/material.dart';

class MenteePostDetailPage extends StatefulWidget {
  const MenteePostDetailPage({Key? key}) : super(key: key);

  @override
  _MenteePostDetailPageState createState() => _MenteePostDetailPageState();
}

class _MenteePostDetailPageState extends State<MenteePostDetailPage> {
  String postId = '';
  String title = '';
  String content = '';
  String writerName = '';
  String writer = '';
  String timestamp = '';
  String userId = '';
  String userName = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 전달된 arguments를 받아오기
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      postId = args['postId'] ?? '';
      title = args['title'] ?? '';
      content = args['content'] ?? '';
      writerName = args['writerName'] ?? '';
      writer = args['writerId'] ?? ''; // writerId 대신 writer로 변경
      timestamp = args['timestamp'] ?? '';
      userId = args['userID'] ?? '';
      userName = args['userName'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 제목 제거하고 깔끔한 앱바 디자인
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        // 상단에서 채팅 아이콘 제거
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목 (스타일 개선)
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),

            // 작성자 정보 (디자인 개선)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '작성자: $writerName',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const Spacer(),
                  const Icon(Icons.access_time, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    timestamp,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 내용 (스타일 개선)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // 우측 하단에 그라데이션 색상의 채팅 아이콘 추가
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF36eff4), Color(0xFF8A6FF0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8.0,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () {
            // 채팅 화면으로 - 게시글 정보도 함께 전달
            print("채팅 이동 인자: roomId=$postId, id=$userId, receiverId=$writer, name=$writerName");
            Navigator.pushNamed(context, '/chat', arguments: {
              'roomId': postId,
              'id': userId,
              'receiverId': writer,
              'name': writerName,
              'postTitle': title,    // 게시글 제목 추가
              'postContent': content, // 게시글 내용 추가
            });
          },
          child: const Icon(
            Icons.chat,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}