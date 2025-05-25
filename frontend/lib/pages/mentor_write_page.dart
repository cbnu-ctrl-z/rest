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

  // Focus nodes for better UX
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitPost(String id, String name) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
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

      if (response.statusCode == 200) {
        // Success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('글이 성공적으로 작성되었습니다!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('작성 실패: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('작성 실패: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final id = args?['id'] ?? 'unknown';
    final name = args?['name'] ?? 'unknown';

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // 키보드로 인한 레이아웃 변경 방지
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '멘토 글쓰기',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: () => _submitPost(id, name),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF36eff4), Color(0xFF8A6FF0)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '완료',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF36eff4)),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Column(
            children: [
              // Header section with user info
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF36eff4), Color(0xFF8A6FF0)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.school, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '멘토 게시판에 글을 작성합니다',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content section
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.05),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _titleController,
                            focusNode: _titleFocusNode,
                            decoration: InputDecoration(
                              hintText: '제목을 입력하세요',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                              prefixIcon: Icon(
                                Icons.title,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '제목을 입력해주세요';
                              }
                              if (value.trim().length < 2) {
                                return '제목은 2글자 이상 입력해주세요';
                              }
                              return null;
                            },
                            onFieldSubmitted: (value) {
                              FocusScope.of(context).requestFocus(_contentFocusNode);
                            },
                          ),
                        ),

                        SizedBox(height: 20),

                        // Content field
                        Container(
                          height: MediaQuery.of(context).size.height * 0.4,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.05),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _contentController,
                            focusNode: _contentFocusNode,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              hintText: '멘토링을 제공하고 싶은 분야나 경험, 전문성을 자세히 작성해주세요.\n\n예시:\n• 제공 가능한 멘토링 분야\n• 관련 경험 및 전문성\n• 멘토링 방식 및 스타일\n• 멘티에게 전하고 싶은 메시지',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                                height: 1.5,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(20),
                            ),
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.6,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '내용을 입력해주세요';
                              }
                              if (value.trim().length < 10) {
                                return '내용은 10글자 이상 입력해주세요';
                              }
                              return null;
                            },
                          ),
                        ),

                        SizedBox(height: 20),

                        // Bottom tip section
                        Container(
                          width: double.infinity,
                          child: Row(
                            children: [
                              Icon(
                                Icons.star_outline,
                                color: Colors.amber,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '전문성과 경험을 구체적으로 작성하면 더 많은 멘티들이 관심을 가져요!',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 키보드를 위한 추가 공간
                        SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}