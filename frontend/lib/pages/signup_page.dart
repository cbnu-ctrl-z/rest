import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

    if (name.isEmpty || email.isEmpty || id.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showCustomSnackBar('모든 필드를 입력하세요!', Colors.red);
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      showCustomSnackBar('유효한 이메일을 입력하세요!', Colors.red);
      return;
    }

    if (password != confirmPassword) {
      showCustomSnackBar('비밀번호가 일치하지 않습니다!', Colors.red);
      return;
    }

    const url = 'http://10.0.2.2:5001/signup';
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
    bool isPassword = false,
    bool isConfirm = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword ? (isConfirm ? _obscureConfirmPassword : _obscurePassword) : false,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black),
          labelText: label,
          border: UnderlineInputBorder(),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              isConfirm
                  ? (_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off)
                  : (_obscurePassword ? Icons.visibility : Icons.visibility_off),
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
          )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/simpo_b.jpg', width: 80, height: 80),
                    Text('쉼표', style: TextStyle(fontSize: 28, color: Colors.black)),
                    SizedBox(height: 7),
                    Text(
                      '공강 매칭 앱 쉼표에 오신걸 환영합니다!',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    _buildTextField(controller: _nameController, focusNode: _nameFocus, icon: Icons.person, label: '이름'),
                    _buildTextField(controller: _emailController, focusNode: _emailFocus, icon: Icons.email, label: '이메일'),
                    _buildTextField(controller: _idController, focusNode: _idFocus, icon: Icons.account_circle, label: '아이디'),
                    _buildTextField(controller: _passwordController, focusNode: _passwordFocus, icon: Icons.lock, label: '비밀번호', isPassword: true),
                    _buildTextField(controller: _confirmPasswordController, focusNode: _confirmPasswordFocus, icon: Icons.lock, label: '비밀번호 확인', isPassword: true, isConfirm: true),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.fromHeight(55),
                        backgroundColor: Color(0xff36eff4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text('회원가입', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('이미 계정이 있으신가요?', style: TextStyle(color: Colors.black54)),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/login'),
                          child: Text('로그인', style: TextStyle(color: Color(0xff36eff4), fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text('© 2025 쉼표', style: TextStyle(color: Colors.black54, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
