import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MentorWritePage extends StatefulWidget {
  @override
  _MentorWritePageState createState() => _MentorWritePageState();
}

class _MentorWritePageState extends State<MentorWritePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitPost(String id, String name) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final url = '${dotenv.env['API_URL']}/mentor/write';
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        'writer': id,
        'writerName': name,
        'title': _titleController.text,
        'content': _contentController.text,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      Navigator.pop(context, true); // 작성 성공 시 true 반환
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('작성 실패: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final id = args?['id'] ?? 'unknown';
    final name = args?['name'] ?? 'unknown';

    return Scaffold(
      appBar: AppBar(
        title: Text('멘토 글쓰기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: '제목'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '제목을 입력하세요';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(labelText: '내용'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '내용을 입력하세요';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(height: 16),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: () => _submitPost(id, name),
                child: Text('작성 완료'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
