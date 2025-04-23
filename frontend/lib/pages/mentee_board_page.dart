import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'mentee_post_detail_page.dart'; // 상세 페이지 임포트

class MenteeBoardPage extends StatefulWidget {
  @override
  _MenteeBoardPageState createState() => _MenteeBoardPageState();
}

class _MenteeBoardPageState extends State<MenteeBoardPage> {
  List<dynamic> menteePosts = [];
  String? userId;
  String? userName;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        if (args['id'] is String) {
          userId = args['id'];
        }
        if (args['name'] is String) {
          userName = args['name']; // 👈 name도 같이 저장
        }
      }

      fetchMenteePosts();
      _initialized = true;
    }
  }

  Future<void> fetchMenteePosts() async {
    final url = dotenv.env['API_URL'];
    final uri = Uri.parse('$url/mentee/posts');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      setState(() {
        menteePosts = json.decode(response.body);
      });
    } else {
      print('멘티 게시글 불러오기 실패');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('멘티 게시판'),
        actions: [
          IconButton(
            icon: Icon(Icons.create),
            onPressed: () async {
              if (userId != null) {
                final result = await Navigator.pushNamed(
                  context,
                  '/menteeWrite',
                  arguments: {'id': userId, 'name': userName},
                );

                if (result == true) {
                  fetchMenteePosts(); // 글 작성 성공했을 때만 다시 불러오기
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('사용자 정보를 불러오는 중입니다.')),
                );
              }
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: menteePosts.length,
        itemBuilder: (context, index) {
          final post = menteePosts[index];
          final title = post['title'] ?? '제목 없음';
          final content = post['content'] ?? '내용 없음';
          final writerName = post['writerName'] ?? '익명';
          final writer = post['writer'] ?? '알수없음'; // ✅ writerId → writer
          final rawDate = post['timestamp']; // ✅ createdAt → timestamp

          // 날짜 포맷 변경
          String formattedDate = '';
          if (rawDate != null && rawDate.isNotEmpty) {
            try {
              final parsedDate = DateTime.parse(rawDate);
              formattedDate = DateFormat('yyyy.MM.dd HH:mm').format(parsedDate);
            } catch (e) {
              formattedDate = rawDate;
            }
          }

          return ListTile(
            title: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(content),
                SizedBox(height: 8),
                Text(
                  '$writerName($writer) · $formattedDate',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            isThreeLine: true,
            onTap: () {
              // 게시글 상세 페이지로 이동
              Navigator.pushNamed(
                context,
                '/mentee_post_detail',
                arguments: {
                  'postId': post['id'],
                  'title': post['title'],
                  'content': post['content'],
                  'writerName': post['writerName'],
                  'writerId': post['writer'],
                  'timestamp': post['timestamp'], // 원하는 형식으로 전달
                  'userID':userId,
                  'userName':userName,
                },
              );
            },
          );
        },
      ),
    );
  }
}
