import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String iconFont = CupertinoIcons.iconFont;  
const String iconFontPackage = CupertinoIcons.iconFontPackage;  
const IconData lock = IconData(0xf4c8, fontFamily: iconFont, fontPackage: iconFontPackage);

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    _emailFocusNode.unfocus();
    _passwordFocusNode.unfocus();

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일과 비밀번호를 입력하세요!')),
      );
      return;
    }

    const url = 'http://10.0.2.2:5000/login';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 성공! 홈 화면으로 이동합니다.')),
        );
        _emailController.clear();
        _passwordController.clear();
        Navigator.pushNamed(context, '/home', arguments: email); // /freetime → /home
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('에러 발생: $e')),
      );
    }
  }

  bool _obscureText = true;

  @override
Widget build(BuildContext context) {
  return Scaffold(
    resizeToAvoidBottomInset: false, //배경화면 움직이지 않게 화면 스크롤 비활성화 
    extendBodyBehindAppBar: true, //  AppBar 뒤에도 배경 확장
    backgroundColor: Colors.transparent, //  Scaffold 배경 투명

    appBar: AppBar(
      backgroundColor: Colors.transparent, //  AppBar 투명
      elevation: 0, //  그림자 제거
    ),

    body: Stack(
      children: [
        //  배경 이미지 (화면 전체 적용)
        Positioned.fill(
          child: ColorFiltered(
          colorFilter: ColorFilter.mode(
          Colors.black.withAlpha(100), //  투명도 조절 (0.0 ~ 1.0)
          BlendMode.darken, //  배경을 어둡게 하는 효과
        ),
          child: Image.asset(
            'assets/login_Background_img.jpg', // 이미지 경로
            fit: BoxFit.cover, //  화면을 꽉 채우도록 설정
          ),
        ),
        ),
        //  본문 UI 요소들
        SingleChildScrollView(
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    children: [
                      Text(
                        '쉼표',
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,//  글자색 변경 (배경과 대비)
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        '공강 매칭 앱 쉼표에 오신걸 환영합니다!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70, //  글자색 변경
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),

                      // 이메일 입력 필드
                      TextFormField(
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        decoration: InputDecoration(
                          labelText: "이메일을 입력해주세요",
                          labelStyle: TextStyle(
                            fontSize: 14,
                            color: const Color.fromARGB(255, 78, 73, 73), //글자색 변경
                          ),
                          filled: true, //배경을 살짝 투명하게
                          fillColor: Colors.white.withAlpha(200),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),

                      SizedBox(height: 10),

                      //비밀번호 입력 필드
                      TextFormField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          labelText: "비밀번호를 입력해주세요",
                          labelStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          filled: true,
                          fillColor: Colors.white.withAlpha(200),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // 로그인 버튼
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size.fromHeight(55),
                          backgroundColor: Color(0xFF2962FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '로그인',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),

                      SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('계정이 없나요?', style: TextStyle(color: Colors.white)),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/signup'),
                            child: Text(
                              '회원가입',
                              style: TextStyle(
                                color: Color.fromARGB(255, 182, 179, 231),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ✅ 하단 텍스트 (bottom 부분도 배경과 함께 적용)
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20), // 하단 여백 추가
            child: Text(
              '© 2025 쉼표',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      ],
    ),
  );
}

}