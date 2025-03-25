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
    // 2초 후 페이드 아웃 시작, 3초 후 로그인인 화면으로 이동
    Timer(Duration(seconds: 2), () {
      setState(() {
        opacity = 0.0; // 페이드 아웃
      });
    });
    Timer(Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/splash_Background_img.jpg"), // 원하는 배경 이미지
          fit: BoxFit.cover, // 이미지를 화면에 꽉 차게 설정
        ),
      ),
      child: Center(
        child: AnimatedOpacity(
          opacity: opacity,
          duration: Duration(seconds: 1),
          child: Image.asset(
            "assets/simpo_w.jpg",
            width:100,
            height:100,
          )
        ),
      ),
    ),
  );
}
}