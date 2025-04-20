import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
<<<<<<< HEAD
=======
import 'package:flutter_dotenv/flutter_dotenv.dart';
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50
import 'dart:convert';

class MatchingPage extends StatefulWidget {
  @override
  _MatchingPageState createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage> {
  List<dynamic> matches = [];
  String? id;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    id ??= ModalRoute.of(context)?.settings.arguments as String? ?? 'user@example.com';
    _fetchMatches(id!);
  }

  Future<void> _fetchMatches(String id) async {
<<<<<<< HEAD
    const url = 'http://10.0.2.2:5001/match_freetime';
=======
    final baseUrl = dotenv.env['API_URL'];
    final url = '$baseUrl/match_freetime';
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );

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
            title: Text(matches[index]['name'] ?? '알 수 없는 사용자'),
            subtitle: Text('${matches[index]['day']} ${matches[index]['start_time']} - ${matches[index]['end_time']}'),
            trailing: Icon(Icons.chat_bubble_outline, color: Colors.blue),
            onTap: () {
<<<<<<< HEAD
=======
              print('📦 넘기는 값 확인 → senderId: $id, receiverId: ${matches[index]['id']}, name: ${matches[index]['name']}');
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50
              Navigator.pushNamed(
                context,
                '/chat',
                arguments: {
                  'id': id,
                  'receiverId': matches[index]['id'] ?? '',
                  'name': matches[index]['name'] ?? '알 수 없는 사용자',
                },
              );
            },
          );
        },
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 7c1421b64e7d9f1c44977e7a459622126eb41e50
