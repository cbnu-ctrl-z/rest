import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MyReviewPage extends StatefulWidget {
  @override
  _MyReviewPageState createState() => _MyReviewPageState();
}

class _MyReviewPageState extends State<MyReviewPage> {
  String? userId;
  List<dynamic> myReviews = [];
  bool isLoading = true;
  double averageRating = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    userId = args['id'] as String? ?? 'unknown_user';
    print('User ID: $userId'); // 디버깅 로그
    _fetchMyReviews();
  }

  Future<void> _fetchMyReviews() async {
    if (userId == null) {
      print('Error: userId is null'); // 디버깅 로그
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
        print('Error: API_URL is not set in .env'); // 디버깅 로그
        setState(() {
          isLoading = false;
        });
        return;
      }
      final response = await http.get(
        Uri.parse('$baseUrl/projects/reviews/$userId'),
      );

      print('Response status: ${response.statusCode}'); // 디버깅 로그
      print('Response body: ${response.body}'); // 디버깅 로그

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Fetched data: $data'); // 디버�инг 로그
        setState(() {
          myReviews = data['reviews'] ?? [];
          averageRating = (data['averageRating'] ?? 0.0).toDouble();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('평가를 가져오는데 실패했습니다.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      print('Error fetching reviews: $e'); // 디버깅 로그
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

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
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
                  '내 평가',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              background: Container(
                color: Colors.orange[600], // 원래 오렌지 색상 유지
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '평가를 불러오는 중...',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
                : Column(
              children: [
                // 평균 평점 섹션
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[600],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '평균 평점',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            averageRating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 12),
                          _buildStarRating(averageRating),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '총 ${myReviews.length}개의 평가',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // 평가 목록
                myReviews.isEmpty
                    ? Container(
                  padding: EdgeInsets.all(32),
                  margin: EdgeInsets.symmetric(horizontal: 16),
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
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.star_border,
                          size: 48,
                          color: Colors.orange[600],
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        '받은 평가가 없습니다',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '프로젝트를 완료하여 평가를 받아보세요!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                )
                    : RefreshIndicator(
                  color: Colors.orange[600],
                  onRefresh: _fetchMyReviews,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: myReviews.length,
                    itemBuilder: (context, index) {
                      final review = myReviews[index];
                      print('Rendering review: ${review['projectTitle']}'); // 디버깅 로그
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
                            splashColor: Colors.orange[100],
                            highlightColor: Colors.orange[50],
                            onTap: () {
                              print('Tapped review: ${review['_id']}'); // 디버깅 로그
                            },
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.orange[600]!,
                                                    Colors.orange[400]!
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Icons.star_outline,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Flexible(
                                              child: Text(
                                                review['projectTitle'] ?? '프로젝트명 없음',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _buildStarRating(review['rating']?.toDouble() ?? 0.0),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  if (review['comment'] != null && review['comment'].isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        review['comment'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.person,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              '평가자: ${review['reviewerName'] ?? '익명'}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Flexible(
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              _formatDate(review['createdAt']),
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}