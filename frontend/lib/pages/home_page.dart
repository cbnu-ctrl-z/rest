import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'project_page.dart';
import 'chat_button.dart';
import 'profile_page.dart';
import 'mentor_board_page.dart';
import 'mentee_board_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final id = args['id'] as String? ?? 'user@example.com';
    final name = args['name'] as String? ?? 'user';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Color(0xFF36eff4), Color(0xFF8A6FF0)],
          ).createShader(bounds),
          child: Text(
            '멘톡',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeTab(id: id, name: name),
          ProjectTab(id:id),
          Chatbutton(id: id),
          ProfilePage(id: id),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xff36eff4),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: '프로젝트'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: '채팅'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '프로필'),
        ],
      ),
    );
  }
}

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
      final mentorRes = await http.get(Uri.parse('${dotenv.env['API_URL']}/mentor/posts'));
      final menteeRes = await http.get(Uri.parse('${dotenv.env['API_URL']}/mentee/posts'));

      if (mentorRes.statusCode == 200 && menteeRes.statusCode == 200) {
        final mentorData = json.decode(mentorRes.body) as List;
        final menteeData = json.decode(menteeRes.body) as List;

        setState(() {
          mentorPosts = mentorData
              .map((post) => '${post['writerName']}: ${post['title']}')
              .cast<String>()
              .take(5)
              .toList();
          menteePosts = menteeData
              .map((post) => '${post['writerName']}: ${post['title']}')
              .cast<String>()
              .take(5)
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
    if (isLoading) return Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '안녕하세요, ${widget.name}님!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '멘톡에서 배움을 시작해보세요.',
            style: TextStyle(fontSize: 16, color: Colors.black45),
          ),
          SizedBox(height: 30),
          _buildBoardCard(
            title: '멘토 게시판',
            posts: mentorPosts,
            icon: Icons.school,
            onViewAll: () {
              Navigator.pushNamed(context, '/mentorBoard',
                  arguments: {'id': widget.id, 'name': widget.name});
            },
          ),
          SizedBox(height: 20),
          _buildBoardCard(
            title: '멘티 게시판',
            posts: menteePosts,
            icon: Icons.group,
            onViewAll: () {
              Navigator.pushNamed(context, '/menteeBoard',
                  arguments: {'id': widget.id, 'name': widget.name});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBoardCard({
    required String title,
    required List<String> posts,
    required IconData icon,
    required VoidCallback onViewAll,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF36eff4), Color(0xFF8A6FF0)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Card(
        color: Colors.white,
        elevation: 5,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Color(0xff36eff4)),
                  SizedBox(width: 8),
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  Spacer(),
                  TextButton(
                    onPressed: onViewAll,
                    style: TextButton.styleFrom(foregroundColor: Color(0xFF8A6FF0)),
                    child: Text('전체보기'),
                  ),
                ],
              ),
              Divider(),
              ...posts.map((post) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text('• $post', style: TextStyle(fontSize: 14)),
              )),
            ],
          ),
        ),
      ),
    );
  }
}


class ProjectTab extends StatefulWidget {
  final String id;
  const ProjectTab({required this.id});

  @override
  State<ProjectTab> createState() => _ProjectTabState();
}

class _ProjectTabState extends State<ProjectTab> {
  @override
  Widget build(BuildContext context) {
    return ProjectPage();
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
