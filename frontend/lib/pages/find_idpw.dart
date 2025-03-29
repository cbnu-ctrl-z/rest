import 'package:flutter/material.dart';
import 'dart:convert'; // JSON 파싱
import 'package:http/http.dart' as http; // HTTP 요청

class FindAccountpage extends StatefulWidget {
  @override
  _FindAccountScreenState createState() => _FindAccountScreenState();
}

class _FindAccountScreenState extends State<FindAccountpage> {
  final TextEditingController _emailController = TextEditingController();
  bool isFindID = true; // 현재 선택된 기능 (true: 아이디 찾기, false: 비밀번호 찾기)
  String? _resultMessage; // 결과 메시지 (아이디 or 전송 완료 메시지)

  Future<void> handleRequest() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _resultMessage = "이메일을 입력해주세요.";
      });
      return;
    }

    String url = isFindID
        ? 'http://10.0.2.2:5000/find_id' // 아이디 찾기 API
        : 'http://10.0.2.2:5000/find_pw'; // 비밀번호 찾기 API (추후 구현)

    try {
            var response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body); 
        setState(() {
          _resultMessage = isFindID
              ? "당신의 아이디: ${data['id']}" // 아이디 반환
              : "비밀번호 재설정 링크가 이메일로 전송되었습니다."; // 비밀번호 찾기
        });
      } else {
        setState(() {
          _resultMessage = "오류 발생: ${response.body}";
        });
      }
    } 
    catch (e) {
      setState(() {
        _resultMessage = "서버 연결 실패: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("아이디 / 비밀번호 찾기")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => setState(() => isFindID = true),
                  child: Text("아이디 찾기",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: isFindID ? FontWeight.bold : FontWeight.normal,
                          color: isFindID ? Colors.blue : Colors.black)),
                ),
                SizedBox(width: 20),
                TextButton(
                  onPressed: () => setState(() => isFindID = false),
                  child: Text("비밀번호 찾기",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: !isFindID ? FontWeight.bold : FontWeight.normal,
                          color: !isFindID ? Colors.blue : Colors.black)),
                ),
              ],
            ),
            Divider(thickness: 1, color: Colors.grey),

            SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "이메일 입력",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: handleRequest,
              child: Text(isFindID ? "아이디 찾기" : "비밀번호 찾기"),
            ),

            if (_resultMessage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _resultMessage!,
                  style: TextStyle(fontSize: 16, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
