import 'package:flutter/material.dart';
import 'dart:async';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  double opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // 페이드 인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        opacity = 1.0;
      });
    });

    // 2초 후 페이드 아웃
    Timer(Duration(seconds: 2), () {
      setState(() {
        opacity = 0.0;
      });
    });

    // 3초 후 다음 화면으로 이동
    Timer(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/signup');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 흰 배경
      body: Center(
        child: AnimatedOpacity(
          opacity: opacity,
          duration: Duration(seconds: 1),
          child: Image.asset(
            "assets/logo.jpg",
            width: 120,
            height: 120,
          ),
        ),
      ),
    );
  }
}
