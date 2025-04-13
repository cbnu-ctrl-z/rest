import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/signup_page.dart';
import 'pages/login_page.dart';
import 'pages/freetime_input_page.dart';
import 'pages/matching_page.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'pages/splash_page.dart';



void main() {
  runApp(MyApp());
}

class ThemeNotifier with ChangeNotifier {
  Brightness _brightness = Brightness.light;

  Brightness get brightness => _brightness;

  void setTheme(Brightness brightness) {
    _brightness = brightness;
    notifyListeners();
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _goToLoginPage();
  }

  // 스플래시 화면 후 회원가입 화면으로 이동하는 함수
  Future<void> _goToLoginPage() async {
    await Future.delayed(Duration(seconds: 2)); // 스플래시 화면 표시 시간 (2초)
    Navigator.pushReplacementNamed(context, '/signup'); // 로그인 화면으로 이동
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            title: '공강 매칭 앱',
            theme: ThemeData(
              primarySwatch: Colors.green,
              brightness: themeNotifier.brightness,
            ),
            initialRoute: '/splash', // 항상 스플래시 화면을 첫 화면으로 설정
            routes: {
              '/splash': (context) => SplashPage(),
              '/signup': (context) => SignUpPage(),
              '/login': (context) => LoginPage(),
              '/freetime': (context) => FreeTimeInputPage(),
              '/match': (context) => MatchingPage(),
              '/home': (context) => HomePage(),
              '/settings': (context) => SettingsPage(),
              '/chat':(context) => ChatPage()
            },
          );
        },
      ),
    );
  }
}