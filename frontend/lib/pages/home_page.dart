import 'package:flutter/material.dart';
import 'project_page.dart';
import 'chat_button.dart'; // Chatbutton이 있는 파일
import 'profile_page.dart'; // 추가한 프로필 페이지 import
import 'mentor_board_page.dart';
import 'mentee_board_page.dart';
// 필요 시 다른 import 추가

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
          if (_selectedIndex == 1) return FreeTimePage(); // index 1은 push로 처리됨
          if (_selectedIndex == 2) return Chatbutton(id: id); // ✅ id 전달
          return ProfilePage(id: id); // ✅ id 전달 (필요한 경우)
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home), 
            label: '홈'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article),
            label: '프로젝트',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat), 
            label: '채팅'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}

// ✅ 각 탭 위젯들
class HomeTab extends StatelessWidget {
  final String id;
  final String name;
  const HomeTab({required this.id, required this.name});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('환영합니다, $name님!', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            _buildBoardPreview(
              context,
              title: '멘토 게시판',
              onViewAll: () {
                Navigator.pushNamed(context, '/mentorBoard', arguments: {'id': id,'name':name});
              },
              posts: ['멘토1: C언어 도와드려요', '멘토2: 자료구조 설명 가능'],
            ),
            SizedBox(height: 20),
            _buildBoardPreview(
              context,
              title: '멘티 게시판',
              onViewAll: () {
                Navigator.pushNamed(context, '/menteeBoard', arguments: {'id': id,'name':name});
              },
              posts: ['멘티1: 파이썬 질문 있어요', '멘티2: 웹 개발 배우고 싶어요'],
            ),
          ],
        ),
      ),
    );
  }

  /// 🔧 게시판 미리보기 위젯
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
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: onViewAll, child: Text('전체보기')),
              ],
            ),
            Divider(),
            ...posts.map((post) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text('• $post'),
            )),
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

// ✅ Chatbutton은 별도 파일로 분리되어 있고, import 되어야 함 (chat_button.dart)
/// 이 파일에서 더 이상 Chatbutton 정의하지 마세요!

// ✅ ProfilePage도 id를 필요로 하면 이렇게 수정하세요:
class ProfilePage extends StatelessWidget {
  final String id;
  const ProfilePage({required this.id});

  @override
  Widget build(BuildContext context) {
    // ProfilePageDetailed 위젯을 반환
    return ProfilePageDetailed();
  }
}