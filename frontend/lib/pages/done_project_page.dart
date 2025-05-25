import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DoneProjectPage extends StatefulWidget {
  @override
  _DoneProjectPageState createState() => _DoneProjectPageState();
}

class _DoneProjectPageState extends State<DoneProjectPage> {
  String? userId;
  List<dynamic> doneProjects = [];
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    userId = args['id'] as String? ?? 'unknown_user';
    print('User ID: $userId'); // 디버깅 로그
    _fetchDoneProjects();
  }

  Future<void> _fetchDoneProjects() async {
    if (userId == null) {
      print('Error: userId is null');
      setState(() {
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final baseUrl = dotenv.env['API_URL'];
      if (baseUrl == null) {
        print('Error: API_URL is not set in .env');
        setState(() {
          isLoading = false;
        });
        return;
      }
      final response = await http.get(
        Uri.parse('$baseUrl/projects/done/$userId'),
      );

      print('Response status: ${response.statusCode}'); // 디버깅 로그
      print('Response body: ${response.body}'); // 디버깅 로그

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Fetched data: $data'); // 디버깅 로그
        setState(() {
          doneProjects = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('완료한 프로젝트를 가져오는데 실패했습니다.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      print('Error fetching projects: $e'); // 디버깅 로그
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '날짜 없음';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy.MM.dd').format(date);
    } catch (e) {
      print('Date parsing error: $e'); // 디버깅 로그
      return '날짜 없음';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100.0,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
            flexibleSpace: FlexibleSpaceBar(
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '완료한 프로젝트',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              background: Container(
                color: Color(0xFF36eff4), // 단일 색상으로 변경
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: isLoading
                ? Padding(
              padding: const EdgeInsets.only(top: 100.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF36eff4)),
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '완료한 프로젝트를 불러오는 중...',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
                : doneProjects.isEmpty
                ? Padding(
              padding: const EdgeInsets.only(top: 100.0),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF36eff4).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 48,
                          color: Color(0xFF36eff4),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        '완료한 프로젝트가 없습니다',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '새로운 프로젝트를 완료해보세요!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
                : RefreshIndicator(
              color: Color(0xFF36eff4),
              onRefresh: _fetchDoneProjects,
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                itemCount: doneProjects.length,
                itemBuilder: (context, index) {
                  final project = doneProjects[index];
                  print('Rendering project: ${project['title']}'); // 디버깅 로그
                  return Container(
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        splashColor: Color(0xFF36eff4).withOpacity(0.1),
                        highlightColor: Color(0xFF36eff4).withOpacity(0.05),
                        onTap: () {
                          print('Tapped project: ${project['_id']}'); // 디버깅 로그
                          // 상세 페이지로 이동하려면 여기에 Navigator.push 추가
                        },
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF36eff4), Color(0xFF8A6FF0)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      project['title'] ?? '제목 없음',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '완료',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Text(
                                project['description'] ?? '설명 없음',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 12),
                              if (project['goal'] != null)
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF36eff4).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.flag,
                                        color: Color(0xFF36eff4),
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          project['goal'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Color(0xFF36eff4),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '멤버 ${project['members']?.length ?? 0}명',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '완료일: ${_formatDate(project['completedAt'])}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (project['steps'] != null && project['steps'].isNotEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 12),
                                    Text(
                                      '완료된 단계들:',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    ...project['steps'].take(3).map<Widget>((step) {
                                      return Padding(
                                        padding: EdgeInsets.only(left: 8, top: 2),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 12,
                                              color: Colors.green,
                                            ),
                                            SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                step['step'] ?? '',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    if (project['steps'].length > 3)
                                      Padding(
                                        padding: EdgeInsets.only(left: 26, top: 2),
                                        child: Text(
                                          '외 ${project['steps'].length - 3}개 단계',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}