import 'package:flutter/material.dart';
import 'chat_button.dart'; // Chatbutton이 있는 파일
// 필요 시 다른 import 추가

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final id = args['id'] as String? ?? 'user@example.com';

    if (index == 1) {
      Navigator.pushNamed(context, '/freetime', arguments: {'id': id});
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: '공강 등록'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: '채팅'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: '프로필'),
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
    return Center(child: Text('환영합니다, $name님!'));
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
    return Center(child: Text('프로필: $id'));
  }
}
