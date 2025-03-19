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
  String? _initialRoute;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // 로그인 상태에 따라 initialRoute 값 설정
    setState(() {
      _initialRoute = isLoggedIn ? '/home' : '/splash';
    });
  }

  @override
  Widget build(BuildContext context) {
    // _initialRoute가 null인 경우 로딩 화면을 표시하여 null 오류 방지
    if (_initialRoute == null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

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
            initialRoute: _initialRoute!, // 이제 _initialRoute는 null이 아님
            routes: {
              '/splash': (context) => SplashPage(),
              '/signup': (context) => SignUpPage(),
              '/login': (context) => LoginPage(),
              '/freetime': (context) => FreeTimeInputPage(),
              '/match': (context) => MatchingPage(),
              '/home': (context) => HomePage(),
              '/settings': (context) => SettingsPage(),
            },
          );
        },
      ),
    );
  }
}
