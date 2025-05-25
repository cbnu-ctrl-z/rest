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
import 'pages/project_detail.dart';
import 'pages/done_project_page.dart';
import 'pages/my_review_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          return MaterialApp(
            title: '멘톡',
            theme: ThemeData(
              primarySwatch: Colors.green,
              brightness: themeNotifier.brightness,
            ),
            initialRoute: '/splash',
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
              '/done_projects': (context) => DoneProjectPage(),
              '/my_reviews': (context) => MyReviewPage(),
              '/project': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
                final userId = args['userId'] ?? 'defaultUserId';
                return ProjectPage(userId: userId);
              },
              '/project_detail': (context) {
                final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
                final projectId = args['projectId'];
                final currentUserId = args['currentUserId'] ?? 'defaultUserId';
                if (projectId == null) {
                  return Scaffold(body: Center(child: Text('프로젝트 ID가 없습니다.')));
                }
                return ProjectDetailPage(
                  projectId: projectId,
                  currentUserId: currentUserId,
                );
              },

            },
          );
        },
      ),
    );
  }
}