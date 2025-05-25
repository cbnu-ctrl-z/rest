import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReviewPage extends StatefulWidget {
  final String projectId;
  final List<String> members;
  final String currentUserId; // 현재 사용자 ID 추가
  const ReviewPage({
    required this.projectId,
    required this.members,
    required this.currentUserId,
    Key? key,
  }) : super(key: key);

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  Map<String, int> ratings = {};
  Map<String, String> comments = {};
  bool isSubmitting = false;
  String? error;

  @override
  void initState() {
    super.initState();
    // 현재 사용자를 제외한 멤버들만 초기화
    for (var member in widget.members.where((m) => m != widget.currentUserId)) {
      ratings[member] = 0;
      comments[member] = '';
    }
  }

  Future<void> submitReviews() async {
    setState(() {
      isSubmitting = true;
      error = null;
    });

    final url = Uri.parse('${dotenv.env['API_URL']}/projects/reviews/create');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'projectId': widget.projectId,
          'reviews': widget.members
              .where((m) => m != widget.currentUserId)
              .map((member) => {
            'memberId': member,
            'rating': ratings[member],
            'comment': comments[member],
          })
              .toList(),
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true); // ProjectDetailPage로 돌아가며 갱신 플래그 전달
      } else {
        setState(() {
          error = '리뷰 제출에 실패했습니다 (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        error = '네트워크 오류가 발생했습니다: ${e.toString()}';
      });
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 사용자를 제외한 멤버 리스트
    final reviewableMembers = widget.members.where((m) => m != widget.currentUserId).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('리뷰 작성', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: reviewableMembers.isEmpty
                  ? Center(
                child: Text(
                  '리뷰할 멤버가 없습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              )
                  : ListView(
                children: reviewableMembers.map((member) => _buildReviewCard(member)).toList(),
              ),
            ),
            if (error != null)
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  error!,
                  style: TextStyle(color: Colors.red[400], fontSize: 14),
                ),
              ),
            ElevatedButton(
              onPressed: isSubmitting || ratings.values.any((rating) => rating == 0) || reviewableMembers.isEmpty
                  ? null
                  : submitReviews,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF36eff4),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: isSubmitting
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('리뷰 제출', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(String memberId) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '멤버: $memberId',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          SizedBox(height: 12),
          Text(
            '별점',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          Row(
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < (ratings[memberId] ?? 0) ? Icons.star : Icons.star_border,
                  color: Color(0xFF36eff4),
                  size: 28,
                ),
                onPressed: () {
                  setState(() {
                    ratings[memberId] = index + 1;
                  });
                },
              );
            }),
          ),
          SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: '코멘트',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            maxLines: 3,
            onChanged: (value) {
              setState(() {
                comments[memberId] = value;
              });
            },
          ),
        ],
      ),
    );
  }
}