import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
<<<<<<< HEAD
=======
import 'package:flutter_dotenv/flutter_dotenv.dart';
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50
import 'dart:convert';

class FreeTimeInputPage extends StatefulWidget {
  @override
  _FreeTimeInputPageState createState() => _FreeTimeInputPageState();
}

class _FreeTimeInputPageState extends State<FreeTimeInputPage> {
  String? selectedDay; // 선택된 요일
  TimeOfDay? startTime; // 시작 시간
  TimeOfDay? endTime; // 종료 시간

  final List<String> days = [
    '월요일',
    '화요일',
    '수요일',
    '목요일',
    '금요일',
    '토요일',
    '일요일'
  ];

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 9, minute: 0), // 기본값을 09:00으로 설정
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // 분을 00으로 고정
      final fixedTime = TimeOfDay(hour: picked.hour, minute: 0);
      if (fixedTime != startTime) {
        setState(() {
          startTime = fixedTime;
        });
      }
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: startTime ?? TimeOfDay(hour: 9, minute: 0), // 시작 시간이 없으면 09:00
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      // 분을 00으로 고정
      final fixedTime = TimeOfDay(hour: picked.hour, minute: 0);
      if (fixedTime != endTime) {
        setState(() {
          endTime = fixedTime;
        });
      }
    }
  }

  Future<void> _submitFreeTime() async {
    if (selectedDay == null || startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 필드를 선택하세요!')),
      );
      return;
    }

    // 'id' 값을 Map<String, dynamic>에서 안전하게 추출
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final id = args['id'] as String? ?? 'user@example.com'; // Map에서 'id' 값을 추출

<<<<<<< HEAD
    const url = 'http://10.0.2.2:5001/add_freetime';
=======
    final url = '${dotenv.env['API_URL']}/add_freetime';
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id, // 여기서 email을 id로 변경
          'day': selectedDay,
          'start_time': '${startTime!.hour.toString().padLeft(2, '0')}:00', // HH:00 형식
          'end_time': '${endTime!.hour.toString().padLeft(2, '0')}:00', // HH:00 형식
        }),
      );

      print('Response: ${response.statusCode}, ${response.body}');
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공강 시간 등록 성공! 매칭 페이지로 이동합니다.')),
        );
        setState(() {
          selectedDay = null;
          startTime = null;
          endTime = null;
        });
        Navigator.pushNamed(context, '/match', arguments: id); // 변경된 부분
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공강 등록 실패: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('에러 발생: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('공강 시간 입력')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              hint: Text('요일을 선택하세요'),
              value: selectedDay,
              onChanged: (String? newValue) {
                setState(() {
                  selectedDay = newValue;
                });
              },
              items: days.map<DropdownMenuItem<String>>((String day) {
                return DropdownMenuItem<String>(
                  value: day,
                  child: Text(day),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Text(
                  '시작 시간: ${startTime != null ? '${startTime!.hour.toString().padLeft(2, '0')}:00' : '선택 안 됨'}',
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _selectStartTime(context),
                  child: Text('시간 선택'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Text(
                  '종료 시간: ${endTime != null ? '${endTime!.hour.toString().padLeft(2, '0')}:00' : '선택 안 됨'}',
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _selectEndTime(context),
                  child: Text('시간 선택'),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitFreeTime,
              child: Text('공강 등록'),
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50
