import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
<<<<<<< HEAD
=======
import 'package:flutter_dotenv/flutter_dotenv.dart';
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50
import 'dart:convert';

const String iconFont = CupertinoIcons.iconFont;
const String iconFontPackage = CupertinoIcons.iconFontPackage;
<<<<<<< HEAD
const IconData lock = IconData(0xf4c8, fontFamily: iconFont, fontPackage: iconFontPackage);
=======
const IconData lock = IconData(
  0xf4c8,
  fontFamily: iconFont,
  fontPackage: iconFontPackage,
);
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _idController;
  late final TextEditingController _passwordController;
  late final FocusNode _idFocusNode;
  late final FocusNode _passwordFocusNode;
<<<<<<< HEAD
=======
  bool _obscureText = true;
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController();
    _passwordController = TextEditingController();
    _idFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _idFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void showCustomSnackBar(String message, Color color) {
    final snackBar = SnackBar(
      content: Text(message, style: TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      duration: Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _login() async {
    _idFocusNode.unfocus();
    _passwordFocusNode.unfocus();

    String id = _idController.text.trim();
    String password = _passwordController.text.trim();

    if (id.isEmpty || password.isEmpty) {
      showCustomSnackBar('아이디와 비밀번호를 입력하세요!', Colors.red);
      return;
    }

<<<<<<< HEAD
    const url = 'http://10.0.2.2:5001/login'; // 에뮬레이터 사용 시

=======
    final url = '${dotenv.env['API_URL']}/login';
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
<<<<<<< HEAD
        body: jsonEncode({
          'id': id,
          'password': password,
        }),
=======
        body: jsonEncode({'id': id, 'password': password}),
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final name = data['name'];
        showCustomSnackBar('로그인 성공! 홈 화면으로 이동합니다.', Colors.blue);
        _idController.clear();
        _passwordController.clear();
<<<<<<< HEAD
        Navigator.pushNamed(context, '/home', arguments: {'id': id, 'name': name});
=======
        Navigator.pushNamed(
          context,
          '/home',
          arguments: {'id': id, 'name': name},
        );
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50
      } else {
        String errorMessage = '아이디 또는 비밀번호가 올바르지 않습니다.';
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data.containsKey('message')) {
            errorMessage = data['message'];
          } else if (data is Map && data.containsKey('error')) {
            errorMessage = data['error'];
          }
        } catch (_) {}
        showCustomSnackBar('로그인 실패: $errorMessage', Colors.red);
      }
    } catch (e) {
      showCustomSnackBar('네트워크 오류가 발생했습니다. 다시 시도해주세요.', Colors.red);
    }
  }

<<<<<<< HEAD
  bool _obscureText = true;

=======
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
<<<<<<< HEAD
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
=======
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50
      body: Stack(
        children: [
          SingleChildScrollView(
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/simpo_b.jpg',
                          width: 80,
                          height: 80,
                        ),
                        Text(
                          '쉼표',
<<<<<<< HEAD
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.black,
                          ),
=======
                          style: TextStyle(fontSize: 28, color: Colors.black),
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50
                        ),
                        SizedBox(height: 7),
                        Text(
                          '공강 매칭 앱 쉼표에 오신걸 환영합니다!',
<<<<<<< HEAD
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
=======
                          style: TextStyle(fontSize: 14, color: Colors.black54),
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),

                        TextFormField(
                          controller: _idController,
                          focusNode: _idFocusNode,
                          decoration: InputDecoration(
                            labelText: "아이디를 입력해주세요",
                            labelStyle: TextStyle(
                              fontSize: 14,
                              color: const Color.fromARGB(255, 78, 73, 73),
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            border: UnderlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),

                        SizedBox(height: 10),

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
                            fillColor: Colors.transparent,
                            border: UnderlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                            suffixIcon: IconButton(
<<<<<<< HEAD
                              icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
=======
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size.fromHeight(55),
                            backgroundColor: Color(0xff36eff4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
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
<<<<<<< HEAD
                            Text('계정이 없으신가요?', style: TextStyle(color: const Color.fromARGB(255, 155, 150, 150))),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/signup'),
=======
                            Text(
                              '계정이 없으신가요?',
                              style: TextStyle(
                                color: const Color.fromARGB(255, 155, 150, 150),
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  () => Navigator.pushNamed(context, '/signup'),
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50
                              child: Text(
                                '회원가입',
                                style: TextStyle(
                                  color: Color(0xff36eff4),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
<<<<<<< HEAD
=======
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed:
                                  () => Navigator.pushNamed(context, '/find'),
                              child: Text(
                                'ID/PW 찾기',
                                style: TextStyle(
                                  color: Color(0xff36eff4),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                '© 2025 쉼표',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
