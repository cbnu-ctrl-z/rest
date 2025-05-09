import 'package:flutter/material.dart';
import 'project_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_button.dart'; // Chatbutton이 있는 파일
import 'profile_page.dart'; // 추가한 프로필 페이지 import
import 'mentor_board_page.dart';
import 'mentee_board_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};
    final id = args['id'] as String? ?? 'user@example.com';

    if (index == 1) {
      Navigator.pushNamed(context, '/project', arguments: {'id': id});
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};
    final id = args['id'] as String? ?? 'user@example.com';
    final name = args['name'] as String? ?? 'user';

    return Scaffold(
      appBar: AppBar(
        title: Text('홈'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings', arguments: {'id': id});
            },
            tooltip: '설정',
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (_selectedIndex == 0) return HomeTab(id: id, name: name);
          if (_selectedIndex == 1) return FreeTimePage();
          if (_selectedIndex == 2) return Chatbutton(id: id);
          return ProfilePage(id: id);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: '공강 등록'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: '채팅'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: '프로필'),
        ],
      ),
    );
  }
}

// ✅ 게시판 미리보기 포함 홈 탭 (StatefulWidget)
class HomeTab extends StatefulWidget {
  final String id;
  final String name;
  const HomeTab({required this.id, required this.name});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<String> mentorPosts = [];
  List<String> menteePosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    try {
      final mentorRes =
      await http.get(Uri.parse('${dotenv.env['API_URL']}/mentor/posts'));
      final menteeRes =
      await http.get(Uri.parse('${dotenv.env['API_URL']}/mentee/posts'));

      if (mentorRes.statusCode == 200 && menteeRes.statusCode == 200) {
        final mentorData = json.decode(mentorRes.body) as List;
        final menteeData = json.decode(menteeRes.body) as List;

        setState(() {
          mentorPosts = mentorData
              .map((post) => '${post['writerName']}: ${post['title']}')
              .cast<String>()
              .take(3)
              .toList();

          menteePosts = menteeData
              .map((post) => '${post['writerName']}: ${post['title']}')
              .cast<String>()
              .take(3)
              .toList();

          isLoading = false;
        });
      } else {
        throw Exception('불러오기 실패');
      }
    } catch (e) {
      print('에러 발생: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('환영합니다, ${widget.name}님!', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            _buildBoardPreview(
              context,
              title: '멘토 게시판',
              onViewAll: () {
                Navigator.pushNamed(context, '/mentorBoard',
                    arguments: {'id': widget.id, 'name': widget.name});
              },
              posts: mentorPosts,
            ),
            SizedBox(height: 20),
            _buildBoardPreview(
              context,
              title: '멘티 게시판',
              onViewAll: () {
                Navigator.pushNamed(context, '/menteeBoard',
                    arguments: {'id': widget.id, 'name': widget.name});
              },
              posts: menteePosts,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardPreview(
      BuildContext context, {
        required String title,
        required VoidCallback onViewAll,
        required List<String> posts,
      }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: onViewAll, child: Text('전체보기')),
              ],
            ),
            Divider(),
            ...posts.map(
                  (post) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text('• $post'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FreeTimePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('공강 등록 화면'));
  }
}

class ProfilePage extends StatelessWidget {
  final String id;
  const ProfilePage({required this.id});

  @override
  Widget build(BuildContext context) {
    return ProfilePageDetailed();
  }
}
