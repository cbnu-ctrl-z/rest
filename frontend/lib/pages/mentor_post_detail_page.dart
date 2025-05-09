import 'package:flutter/material.dart';

class MentorPostDetailPage extends StatefulWidget {
  const MentorPostDetailPage({Key? key}) : super(key: key);

  @override
  _MentorPostDetailPageState createState() => _MentorPostDetailPageState();
}

class _MentorPostDetailPageState extends State<MentorPostDetailPage> {
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

    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      postId = args['postId'] ?? '';
      title = args['title'] ?? '';
      content = args['content'] ?? '';
      writerName = args['writerName'] ?? '';
      writer = args['writerId'] ?? '';
      timestamp = args['timestamp'] ?? '';
      userId = args['userID'] ?? '';
      userName = args['userName'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // MenteePostDetailPage.dart 수정 부분
          IconButton(
            icon: Icon(Icons.chat),
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
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              content,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              '작성자: $writerName ($writer) · 작성일: $timestamp',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
