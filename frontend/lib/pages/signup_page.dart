import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _signUp() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String id = _idController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || id.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 필드를 입력하세요!')),
      );
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('유효한 이메일을 입력하세요!')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호가 일치하지 않습니다!')),
      );
      return;
    }

    const url = 'http://192.168.219.100:5000/signup';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 성공! 로그인 페이지로 이동합니다.')),
        );
        Navigator.pushNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 실패: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('에러 발생: $e')),
      );
    }
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
                    Image.asset(
                      'assets/simpo_b.jpg',
                      width: 80,
                      height: 80,
                    ),
                    Text(
                      '쉼표',
                      style: TextStyle(fontSize: 28, color: Colors.black),
                    ),
                    SizedBox(height: 7),
                    Text(
                      '공강 매칭 앱 쉼표에 오신걸 환영합니다!',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    _buildTextField(_nameController, Icons.person, '이름'),
                    _buildTextField(_emailController, Icons.email, '이메일'),
                    _buildTextField(_idController, Icons.account_circle, '아이디'),
                    _buildPasswordField(_passwordController, '비밀번호', true),
                    _buildPasswordField(_confirmPasswordController, '비밀번호 확인', false),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.fromHeight(55),
                        backgroundColor: Color(0xff36eff4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        '회원가입',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('이미 계정이 있으신가요?', style: TextStyle(color: Colors.black54)),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/login'),
                          child: Text(
                            '로그인',
                            style: TextStyle(color: Color(0xff36eff4), fontSize: 16, fontWeight: FontWeight.w600),
                          ),
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

  Widget _buildTextField(TextEditingController controller, IconData icon, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black),
          labelText: hint,
          filled: true,
          fillColor: Colors.transparent,
          border: UnderlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String hint, bool isPassword) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : _obscureConfirmPassword,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.lock, color: Colors.black),
          labelText: hint,
          filled: true,
          fillColor: Colors.transparent,
          border: UnderlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(isPassword ? (_obscurePassword ? Icons.visibility : Icons.visibility_off) : (_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off)),
            onPressed: () {
              setState(() {
                if (isPassword) _obscurePassword = !_obscurePassword;
                else _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
        ),
      ),
    );
  }
}
