import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomeTab(),         // index 0
    FreeTimePage(),    // index 1
    ChatPage(),        // index 2
    ProfilePage(),     // index 3
  ];

  void _onItemTapped(int index) {
    final args = ModalRoute
        .of(context)
        ?.settings
        .arguments as Map<String, dynamic>? ?? {};
    final id = args['id'] as String? ?? 'user@example.com'; // Map에서 'id' 값을 추출
    if (index == 1) {
      Navigator.pushNamed(
          context, '/freetime', arguments: {'id': id}); // id를 전달
    }
    else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final id = args['id'] as String? ?? 'user@example.com'; // Map에서 'id' 값을 추출

    return Scaffold(
      appBar: AppBar(
        title: Text('홈'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings', arguments: {'id': id}); // id를 전달
            },
            tooltip: '설정',
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // 4개 이상일 때 필요
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: '공강 등록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: '채팅',
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

// 각 탭의 위젯들 정의
class HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final id = args['id'] as String? ?? 'user@example.com'; // Map에서 'id' 값을 추출
    final name = args['name'] as String ?? 'user';
    return Center(child: Text('환영합니다, $name님!')); // name으로 수정
  }
}

class FreeTimePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('공강 등록 화면'));
  }
}

class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('채팅 화면'));
  }
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('프로필 화면'));
  }
}