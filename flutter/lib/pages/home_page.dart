import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // arguments가 null일 수 있으니 안전하게 처리
    final email = ModalRoute.of(context)?.settings.arguments as String? ?? 'user@example.com';

    return Scaffold(
      appBar: AppBar(
        title: Text('홈'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings', arguments: email);
            },
            tooltip: '설정',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('환영합니다, $email!'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/freetime', arguments: email);
              },
              child: Text('나의 공강 등록!'),
            ),
          ],
        ),
      ),
    );
  }
}