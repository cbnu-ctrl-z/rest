import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final FocusNode _nameFocusNode;
  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _nameFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 필드를 입력하세요!')),
      );
      return;
    }

    const url = 'http://10.0.2.2:5000/signup';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
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
      appBar: AppBar(title: Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              decoration: InputDecoration(labelText: '이름'),
            ),
            TextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              decoration: InputDecoration(labelText: '이메일'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              decoration: InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signUp,
              child: Text('회원가입'),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: Text('이미 계정이 있나요? 로그인'),
            ),
          ],
        ),
      ),
    );
  }
}