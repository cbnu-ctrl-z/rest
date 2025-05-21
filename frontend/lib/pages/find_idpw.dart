import 'package:flutter/material.dart';
import 'dart:convert'; // JSON 파싱
import 'package:http/http.dart' as http; // HTTP 요청
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FindAccountpage extends StatefulWidget {
  @override
  _FindAccountScreenState createState() => _FindAccountScreenState();
}

class _FindAccountScreenState extends State<FindAccountpage> {
  final TextEditingController _emailController = TextEditingController(); //TextEditingController()의 인스턴스 참조 변수 생성 해당 변수를 통해 TextEditingController()인스턴스 관리 가능
  //TextEditingController()를 통해 사용자가 입력한 텍스트필드의 값들을 읽기, 변경등 조작가능
  bool isFindID = true; // 현재 선택된 기능분리 부울변수 (true: 아이디 찾기, false: 비밀번호 찾기)
  String? _resultMessage; // 결과 메시지 (아이디 or 전송 완료 메시지) 초기값 NULL

  Future<void> sendAccountRecoveryRequest() async {//입력한 이메일을 통해 아이디 찾기 또는 비밀번호 재설정 요청을 백엔드에 보내는 역할
    String email = _emailController.text.trim(); //사용자가 입력한 이메일 값을 가져와 앞뒤 공백을 제거하고 변수에 저장.
    if (email.isEmpty) {//이메일이 공백이면 결과 메세지 -> 오류 메세지 
      setState(() {
        _resultMessage = "이메일을 입력해주세요.";
      });
      return;
    }

    String apiUrl = dotenv.env['API_URL'] ?? 'http://localhost:5000'; //API서버 주소(apiUrl NULL값 방지 위해 기본값 설정)
    String url = isFindID//true면 아이디 찾기, false면 비밀번호 찾기로 API주소 분리 
        ? '$apiUrl/find_id'
        : '$apiUrl/find_pw';

    try {//오류 발생시 앱이 멈추지 않고 함수블록 내에서 오류처리
            var response = await http.post(//백엔드로 POST 요청을 보내고 백엔드로부터 받은 응답(결과)을 저장하는 변수
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},//서버에게 JSON형식의 데이터를 보내겠다고 미리 알림 (애플리케이션데이터/JSON형태)
        body: jsonEncode({"email": email}),//사용자가 입력한 email을 JSON형태로 변환
      );

      if (response.statusCode == 200) {//서버의 정상처리 값(200)을 받음
        var data = jsonDecode(response.body);//서버로부터 받은 JSON형태의 데이터(사용자 아이디) 저장 변수
        setState(() {
          _resultMessage = isFindID//isFindId 값에 따라 아이디 또는 비밀번호 변경 이메일 전송 결과 메세지 결정
              ? "당신의 아이디: ${data['id']}" // 아이디 반환
              : "비밀번호 재설정 링크가 이메일로 전송되었습니다."; // 비밀번호 찾기
        });
      } else {//서버의 잘못된 응답을 받을 경우 오류메세지 반환
        setState(() {
          _resultMessage = "오류 발생: ${response.body}";
        });
      }
    } 
    catch (e) {//try 함수블록 내에서 백엔드와의 데이터 전송 과정에서 네트워크 오류, 서버 다운 등 예외가 발생하면 실행
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
              onPressed: sendAccountRecoveryRequest,
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
