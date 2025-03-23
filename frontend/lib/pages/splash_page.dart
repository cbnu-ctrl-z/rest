import 'package:flutter/material.dart';
import 'dart:async';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  double opacity = 0.0; // 초기 투명도

  @override
  void initState() {
    super.initState();
    // 화면이 그려진 후 애니메이션 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        opacity = 1.0; // 페이드 인
      });
    });
    // 2초 후 페이드 아웃 시작, 3초 후 회원가입 화면으로 이동
    Timer(Duration(seconds: 2), () {
      setState(() {
        opacity = 0.0; // 페이드 아웃
      });
    });
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Align(
        alignment: Alignment.center, // 가로와 세로 모두 중앙 정렬
        child: AnimatedOpacity(
          opacity: opacity,
          duration: Duration(seconds: 1),
          child: Text(
            ',',
            style: TextStyle(
              fontSize: 500,
              color: Color(0xFF0066FF),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}