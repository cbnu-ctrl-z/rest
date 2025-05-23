import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _idFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _idFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
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

  Future<void> _signUp() async {
    _nameFocus.unfocus();
    _emailFocus.unfocus();
    _idFocus.unfocus();
    _passwordFocus.unfocus();
    _confirmPasswordFocus.unfocus();

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final id = _idController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        id.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showCustomSnackBar('모든 필드를 입력하세요!', Colors.red);
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      showCustomSnackBar('유효한 이메일을 입력하세요!', Colors.red);
      return;
    }

    if (password != confirmPassword) {
      showCustomSnackBar('비밀번호가 일치하지 않습니다!', Colors.red);
      return;
    }

    final url = '${dotenv.env['API_URL']}/signup';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'id': id,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        showCustomSnackBar('회원가입 성공! 로그인 페이지로 이동합니다.', Colors.blue);
        Navigator.pushNamed(context, '/login');
      } else {
        showCustomSnackBar('회원가입 실패: ${response.body}', Colors.red);
      }
    } catch (e) {
      showCustomSnackBar('에러 발생: $e', Colors.red);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black),
          labelText: label,
          border: UnderlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required bool isConfirm,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isConfirm ? _obscureConfirmPassword : _obscurePassword,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.lock, color: Colors.black),
          labelText: label,
          border: UnderlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(
              isConfirm
                  ? (_obscureConfirmPassword
                  ? Icons.visibility
                  : Icons.visibility_off)
                  : (_obscurePassword
                  ? Icons.visibility
                  : Icons.visibility_off),
            ),
            onPressed: () {
              setState(() {
                if (isConfirm) {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                } else {
                  _obscurePassword = !_obscurePassword;
                }
              });
            },
          ),
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
                        '멘톡에 오신걸 환영합니다!',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      _buildTextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        icon: Icons.person,
                        label: '이름',
                      ),
                      _buildTextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        icon: Icons.email,
                        label: '이메일',
                      ),
                      _buildTextField(
                        controller: _idController,
                        focusNode: _idFocus,
                        icon: Icons.account_circle,
                        label: '아이디',
                      ),
                      _buildPasswordField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        label: '비밀번호',
                        isConfirm: false,
                      ),
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocus,
                        label: '비밀번호 확인',
                        isConfirm: true,
                      ),
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
                          onPressed: _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text(
                            '회원가입',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '이미 계정이 있으신가요?',
                            style: TextStyle(color: Colors.black54),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/login'),
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [Color(0xFF36eff4), Color(0xFF8A6FF0)],
                              ).createShader(bounds),
                              child: Text(
                                '로그인',
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
