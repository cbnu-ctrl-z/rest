import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // ThemeNotifier 임포트

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void _toggleDarkMode(bool value) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    themeNotifier.setTheme(value ? Brightness.dark : Brightness.light);
  }

  void _logout(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final email = ModalRoute.of(context)?.settings.arguments as String? ?? 'user@example.com';
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(title: Text('설정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('현재 사용자: $email'),
            SizedBox(height: 20),
            SwitchListTile(
              title: Text('다크 모드'),
              value: themeNotifier.brightness == Brightness.dark,
              onChanged: _toggleDarkMode,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _logout(context),
              child: Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}