import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _idFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _obscureText = true;

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

    final id = _idController.text.trim();
    final password = _passwordController.text.trim();

    if (id.isEmpty || password.isEmpty) {
      showCustomSnackBar('아이디와 비밀번호를 입력하세요!', Colors.red);
      return;
    }

    final url = '${dotenv.env['API_URL']}/login';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final name = data['name'];
        showCustomSnackBar('로그인 성공! 홈 화면으로 이동합니다.', Colors.blue);
        _idController.clear();
        _passwordController.clear();
        Navigator.pushNamed(context, '/home', arguments: {'id': id, 'name': name});
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

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black),
          labelText: label,
          border: UnderlineInputBorder(),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
      body: KeyboardVisibilityBuilder(
        builder: (context, isKeyboardVisible) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      Image.asset('assets/logo.jpg', width: 80, height: 80),
                      SizedBox(height: 7),
                      Text(
                        '멘톡',
                        style: TextStyle(fontSize: 20, fontWeight:FontWeight.bold,color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),

                      _buildTextField(
                        label: '아이디',
                        icon: Icons.person,
                        controller: _idController,
                        focusNode: _idFocusNode,
                      ),
                      _buildTextField(
                        label: '비밀번호',
                        icon: Icons.lock,
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        obscure: _obscureText,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      ),

                      SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF36eff4), Color(0xFF8A6FF0)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text(
                            '로그인',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),

                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('계정이 없으신가요?', style: TextStyle(color: Colors.black54)),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/signup'),
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [Color(0xFF36eff4), Color(0xFF8A6FF0)],
                              ).createShader(bounds),
                              child: Text(
                                '회원가입',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/find'),
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Color(0xFF36eff4), Color(0xFF8A6FF0)],
                          ).createShader(bounds),
                          child: Text(
                            'ID/PW 찾기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isKeyboardVisible)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    '© 2025 멘톡',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
