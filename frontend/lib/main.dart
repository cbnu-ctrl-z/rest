import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/signup_page.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/splash_page.dart';
import 'pages/find_idpw.dart';
import 'pages/chat_page.dart';
import 'pages/mentor_write_page.dart';
import 'pages/mentee_write_page.dart';
import 'pages/mentee_post_detail_page.dart';
import 'pages/mentor_post_detail_page.dart';
import 'pages/project_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); //flutter 엔진 및 위젯트리 연결
  await dotenv.load(fileName: ".env"); //환경변수 등록
  runApp(MyApp());
}

class ThemeNotifier with ChangeNotifier {
  //앱의 테마를 관리하는 클래스
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
    //해당 함수 안 쓰는거 같은데
    await Future.delayed(Duration(seconds: 2)); // 스플래시 화면 표시 시간 (2초)
    Navigator.pushReplacementNamed(context, '/signup'); // 회원가입 화면으로 이동
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier(), //테마조정 인스턴스 생성
      child: Consumer<ThemeNotifier>(
        //ThemeNotifier가 바뀔때마다 하위 위젯 테마 변경
        builder: (context, themeNotifier, child) {
          return MaterialApp(

            title: '멘톡',

            theme: ThemeData(
              primarySwatch: Colors.green,
              brightness: themeNotifier.brightness,
            ),
            initialRoute: '/splash', // 항상 스플래시 화면을 첫 화면으로 설정
            routes: {
              '/splash': (context) => SplashPage(),
              '/signup': (context) => SignUpPage(),
              '/login': (context) => LoginPage(),
              '/home': (context) => HomePage(),
              '/chat': (context) => ChatPage(),
              '/find': (context) => FindAccountpage(),
              '/mentorWrite': (context) => MentorWritePage(),
              '/menteeWrite': (context) => MenteeWritePage(),
              '/mentee_post_detail': (context) => MenteePostDetailPage(),
              '/mentor_post_detail': (context) => MentorPostDetailPage(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/project') {
                final args = settings.arguments as Map<String, dynamic>;
                final id = args['id'] as String;
                return MaterialPageRoute(
                  builder: (context) => ProjectPage(id: id),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
