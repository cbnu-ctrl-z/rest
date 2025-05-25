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

  // 각 멤버의 프로필 데이터를 저장할 맵 추가
  Map<String, Map<String, dynamic>> _memberProfiles = {};

  // 그라데이션 색상 정의 (홈페이지 및 채팅 페이지와 통일)
  final List<Color> _gradientColors = const [Color(0xFF36eff4), Color(0xFF8A6FF0)];

  @override
  void initState() {
    super.initState();
    // 현재 사용자를 제외한 멤버들만 초기화
    for (var member in widget.members.where((m) => m != widget.currentUserId)) {
      ratings[member] = 0;
      comments[member] = '';
      _fetchUserProfile(member); // 각 멤버의 프로필 정보 가져오기
    }
  }

  // --- 추가된 함수: 사용자 프로필 가져오기 ---
  Future<void> _fetchUserProfile(String userId) async {
    final url = Uri.parse('${dotenv.env['API_URL']}/user_profile?id=$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _memberProfiles[userId] = {
            'name': data['name'],
            'profile_image': data['profile_image'],
          };
        });
      } else {
        print('Failed to load profile for $userId: ${response.body}');
        // 프로필을 불러오지 못했을 경우 기본 값 설정
        setState(() {
          _memberProfiles[userId] = {'name': '알 수 없음', 'profile_image': null};
        });
      }
    } catch (e) {
      print('Error fetching profile for $userId: $e');
      setState(() {
        _memberProfiles[userId] = {'name': '알 수 없음', 'profile_image': null};
      });
    }
  }
  // ------------------------------------

  Future<void> submitReviews() async {
    setState(() {
      isSubmitting = true;
      error = null;
    });

    final url = Uri.parse('${dotenv.env['API_URL']}/projects/reviews/create');
    try {
      // 모든 멤버가 0점 이상으로 평가되었는지 확인
      bool allRated = ratings.values.every((rating) => rating > 0);
      if (!allRated) {
        setState(() {
          error = '모든 팀원에 대한 별점을 1점 이상으로 평가해주세요.';
          isSubmitting = false;
        });
        return; // 함수 종료
      }

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
        // 성공적으로 리뷰 제출 후 사용자에게 알림
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('리뷰가 성공적으로 제출되었습니다!'),
            backgroundColor: Color(0xFF8A6FF0), // 그라데이션 끝 색상
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // ProjectDetailPage로 돌아가며 갱신 플래그 전달
      } else {
        setState(() {
          error = '리뷰 제출에 실패했습니다 (${response.statusCode}). 잠시 후 다시 시도해주세요.';
          print('Error Response: ${response.body}'); // 디버깅을 위해 응답 바디 출력
        });
      }
    } catch (e) {
      setState(() {
        error = '네트워크 오류가 발생했습니다: ${e.toString()}. 인터넷 연결을 확인해주세요.';
        print('Exception: $e'); // 디버깅을 위해 예외 출력
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
      backgroundColor: Colors.grey[50], // 부드러운 배경색
      appBar: AppBar(
        flexibleSpace: Container( // AppBar 배경에 그라데이션 적용
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          '리뷰 작성',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white, // 제목 색상 변경
          ),
        ),
        foregroundColor: Colors.white, // 뒤로가기 버튼 등 전경색
        elevation: 0, // 그림자 제거
      ),
      body: Padding(
        padding: const EdgeInsets.all(16), // 전체 패딩 조정
        child: Column(
          children: [
            Expanded(
              child: reviewableMembers.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_off_outlined, // 리뷰할 사람 없음을 나타내는 아이콘
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '리뷰할 팀원이 없습니다.',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '프로젝트에는 다른 팀원이 있어야 리뷰를 작성할 수 있습니다.',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                // 리뷰 카드 간의 간격을 주기 위해 builder 사용
                itemCount: reviewableMembers.length,
                itemBuilder: (context, index) {
                  return _buildReviewCard(reviewableMembers[index]);
                },
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  error!,
                  style: TextStyle(color: Colors.red[400], fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            Container( // 버튼에 그라데이션 적용을 위해 Container로 감쌈
              width: double.infinity, // 너비 가득 채움
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: isSubmitting || ratings.values.any((rating) => rating == 0) || reviewableMembers.isEmpty
                    ? null // 모든 별점 1점 이상이어야 활성화
                    : submitReviews,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, // 배경 투명하게
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent, // 그림자 제거
                  padding: const EdgeInsets.symmetric(vertical: 16), // 버튼 높이 조정
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0, // 기본 ElevatedButton의 그림자 제거
                ),
                child: isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  '리뷰 제출하기', // 버튼 텍스트 변경
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16), // 하단 여백 추가
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(String memberId) {
    // 해당 멤버의 프로필 데이터를 가져옴
    final memberProfile = _memberProfiles[memberId];
    final String memberName = memberProfile?['name'] ?? memberId; // 이름이 없으면 ID 사용
    final String? profileImageUrl = memberProfile?['profile_image'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16), // 카드 간 간격
      padding: const EdgeInsets.all(20), // 내부 패딩 확대
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25), // 모서리 둥글게
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08), // 그림자 색상 및 투명도 조정
            blurRadius: 20, // 그림자 확산 정도
            offset: const Offset(0, 8), // 그림자 위치 (아래쪽으로 더 길게)
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // --- 프로필 이미지 표시 로직 변경 ---
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[200], // 로딩 중 또는 이미지 없을 때 배경색
                backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                    ? NetworkImage(profileImageUrl)
                    : const AssetImage('assets/basic.png') as ImageProvider, // 기본 이미지
              ),
              // -------------------------------
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  memberName, // 실제 멤버 이름 표시
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '🌟 팀원과의 협업 만족도를 평가해주세요.', // 별점 안내 문구
            style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // 별점 중앙 정렬
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < (ratings[memberId] ?? 0) ? Icons.star_rounded : Icons.star_border_rounded, // 둥근 별 아이콘
                  color: (index < (ratings[memberId] ?? 0)) ? Colors.amber : Colors.grey[300], // 색상 변경
                  size: 36, // 별 아이콘 크기 확대
                ),
                onPressed: () {
                  setState(() {
                    ratings[memberId] = index + 1;
                  });
                },
                padding: EdgeInsets.zero, // IconButton의 기본 패딩 제거
                constraints: const BoxConstraints(), // IconButton의 최소 크기 제약 제거
              );
            }),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              labelText: '자유롭게 의견을 작성해주세요.', // 라벨 텍스트 변경
              alignLabelWithHint: true, // 라벨 힌트와 정렬
              hintText: '예: 팀원과의 협력이 매우 좋았습니다. 다음 프로젝트에서도 함께하고 싶어요!', // 힌트 텍스트 추가
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15), // 모서리 둥글게
                borderSide: BorderSide.none, // 테두리 없음
              ),
              filled: true,
              fillColor: Colors.grey[100], // 배경색
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLines: 4, // 여러 줄 입력 가능
            minLines: 3,
            onChanged: (value) {
              setState(() {
                comments[memberId] = value;
              });
            },
            keyboardType: TextInputType.multiline, // 멀티라인 키보드
          ),
        ],
      ),
    );
  }
}