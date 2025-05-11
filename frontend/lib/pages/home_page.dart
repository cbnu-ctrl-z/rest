import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// 페이지 컴포넌트
import 'project_page.dart';
import 'chat_load.dart';
import 'profile_page.dart';
import 'mentor_board_page.dart';
import 'mentee_board_page.dart';

// --------------------- HomePage ---------------------

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  DateTime? _lastPressedTime;

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

    return WillPopScope(
      onWillPop: () async {
        final now = DateTime.now();
        if (_lastPressedTime == null || now.difference(_lastPressedTime!) > Duration(seconds: 2)) {
          _lastPressedTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('뒤로 버튼을 한 번 더 누르면 종료됩니다')),
          );
          return false;
        } else {
          SystemNavigator.pop();
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/logo.jpg', fit: BoxFit.contain),
          ),
          title: Row(
            children: [
              Text(
                '멘톡',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(width: 4),
              Text(
                '멘토 매칭 추천 서비스',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: Colors.red),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.settings_outlined, color: Colors.grey),
              onPressed: () {},
            ),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            HomeTab(id: id, name: name),
            ProjectTab(id: id),
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
      ),
    );
  }
}

// --------------------- HomeTab ---------------------

class HomeTab extends StatefulWidget {
  final String id;
  final String name;
  const HomeTab({required this.id, required this.name});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<dynamic> mentorPosts = [];
  List<dynamic> menteePosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    try {
      final mentorRes = await http.get(Uri.parse('${dotenv.env['API_URL']}/mentor/posts'));
      final menteeRes = await http.get(Uri.parse('${dotenv.env['API_URL']}/mentee/posts'));

      if (mentorRes.statusCode == 200 && menteeRes.statusCode == 200) {
        setState(() {
          mentorPosts = json.decode(mentorRes.body);
          menteePosts = json.decode(menteeRes.body);
          isLoading = false;
        });
      } else {
        throw Exception('불러오기 실패');
      }
    } catch (e) {
      print('에러 발생: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || _tabController == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        SizedBox(height: 20),
        TabBar(
          controller: _tabController!,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(colors: [Color(0xFF36eff4), Color(0xFF8A6FF0)]),
          ),
          tabs: [
            Tab(text: '멘토 게시판'),
            Tab(text: '멘티 게시판'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController!,
            children: [
              _buildPostList(mentorPosts),
              _buildPostList(menteePosts),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostList(List posts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final title = post['title'] ?? '제목 없음';
        final content = post['content'] ?? '내용 없음';
        final writerName = post['writerName'] ?? '익명';
        final writer = post['writer'] ?? '알수없음';
        final rawDate = post['timestamp'];

        String formattedDate = '';
        if (rawDate != null && rawDate.isNotEmpty) {
          try {
            final parsedDate = DateTime.parse(rawDate);
            formattedDate = DateFormat('yyyy.MM.dd HH:mm').format(parsedDate);
          } catch (e) {
            formattedDate = rawDate;
          }
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(content, maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 8),
                Text('$writerName($writer) · $formattedDate',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            isThreeLine: true,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/${_tabController!.index == 0 ? 'mentor' : 'mentee'}_post_detail',
                arguments: {
                  'postId': post['id'],
                  'title': title,
                  'content': content,
                  'writerName': writerName,
                  'writerId': writer,
                  'timestamp': rawDate,
                  'userID': widget.id,
                  'userName': widget.name,
                },
              );
            },
          ),
        );
      },
    );
  }
}

// --------------------- ProjectTab ---------------------

class ProjectTab extends StatelessWidget {
  final String id;
  const ProjectTab({required this.id});

  @override
  Widget build(BuildContext context) {
    return ProjectPage(); // id 넘기고 싶으면 여기서 넘김
  }
}

// --------------------- ProfilePage ---------------------

class ProfilePage extends StatelessWidget {
  final String id;
  const ProfilePage({required this.id});

  @override
  Widget build(BuildContext context) {
    return ProfilePageDetailed();
  }
}
