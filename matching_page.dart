import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MatchingPage extends StatefulWidget {
  @override
  _MatchingPageState createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage> {
  List<dynamic> matches = [];
  String? email;

  @override
  void initState() {
    super.initState();
    // initState에서는 아무것도 안 함
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // context가 사용 가능한 시점에 email 가져오기
    email ??= ModalRoute.of(context)?.settings.arguments as String? ?? 'user@example.com';
    _fetchMatches(email!); // 최초 한 번만 호출
  }

  Future<void> _fetchMatches(String email) async {
    const url = 'http://10.0.2.2:5000/match_freetime';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('Match Response: ${response.statusCode}, ${response.body}');
      if (response.statusCode == 200) {
        setState(() {
          matches = jsonDecode(response.body);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('매칭 실패: ${response.body}')),
        );
      }
    } catch (e) {
      print('Match Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('매칭 에러: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('공강 매칭 결과')),
      body: matches.isEmpty
          ? Center(child: Text('매칭된 사용자가 없습니다.'))
          : ListView.builder(
        itemCount: matches.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(matches[index]['name']),
            subtitle: Text(
                '${matches[index]['day']} ${matches[index]['start_time']} - ${matches[index]['end_time']}'),
          );
        },
      ),
    );
  }
}