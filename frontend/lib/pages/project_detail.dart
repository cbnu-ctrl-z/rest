import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'review_page.dart';

class ProjectDetailPage extends StatefulWidget {
  final String projectId;
  final String currentUserId; // currentUserId 추가
  const ProjectDetailPage({
    required this.projectId,
    required this.currentUserId,
    Key? key,
  }) : super(key: key);

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> with TickerProviderStateMixin {
  Map<String, dynamic>? project;
  bool isLoading = true;
  String? error;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressAnimationController, curve: Curves.easeInOut),
    );
    fetchProjectDetail();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    super.dispose();
  }

  Future<void> fetchProjectDetail() async {
    final url = Uri.parse('${dotenv.env['API_URL']}/projects/${widget.projectId}');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          project = data;
          isLoading = false;
          error = null;
        });
        _progressAnimationController.forward();
      } else {
        setState(() {
          isLoading = false;
          error = '프로젝트를 불러오는데 실패했습니다 (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        error = '네트워크 오류가 발생했습니다: ${e.toString()}';
      });
    }
  }

  Future<void> toggleStepCompletion(int index) async {
    if (project == null) return;

    final step = project!['steps'][index];
    final newCompleted = !(step['completed'] ?? false);

    // 이전 단계 체크 여부 확인 (index가 0이 아닌 경우에만)
    if (newCompleted && index > 0) {
      final previousStep = project!['steps'][index - 1];
      if (!(previousStep['completed'] ?? false)) {
        HapticFeedback.vibrate();
        _showErrorSnackBar('이전 단계를 먼저 완료해야 합니다');
        return;
      }
    }

    // 낙관적 업데이트
    setState(() {
      step['completed'] = newCompleted;
    });

    // 햅틱 피드백
    HapticFeedback.lightImpact();

    final url = Uri.parse('${dotenv.env['API_URL']}/projects/${widget.projectId}/step/$index');
    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'completed': newCompleted}),
      );

      if (response.statusCode != 200) {
        // 실패 시 되돌리기
        setState(() {
          step['completed'] = !newCompleted;
        });
        _showErrorSnackBar('단계 업데이트에 실패했습니다');
      } else {
        final data = json.decode(response.body);
        if (data['message']?.contains('done_projects로 이동되었습니다') ?? false) {
          // 모든 단계 완료 시 ReviewPage로 이동
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewPage(
                projectId: widget.projectId,
                members: List<String>.from(project!['members'] ?? []),
                currentUserId: widget.currentUserId, // currentUserId 전달
              ),
            ),
          );
          if (result == true) {
            // ReviewPage에서 제출 성공 시 ProjectPage로 돌아가며 갱신 플래그 전달
            Navigator.pop(context, true);
          }
        } else {
          _showSuccessSnackBar(newCompleted ? '단계를 완료했습니다' : '단계를 미완료로 변경했습니다');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      setState(() {
        step['completed'] = !newCompleted;
      });
      _showErrorSnackBar('네트워크 오류가 발생했습니다');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Color(0xFF36eff4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }

  double get _completionRate {
    if (project == null) return 0.0;
    final steps = project!['steps'] as List<dynamic>? ?? [];
    if (steps.isEmpty) return 0.0;
    final completedSteps = steps.where((step) => step['completed'] == true).length;
    return completedSteps / steps.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          if (isLoading) _buildLoadingSliver(),
          if (error != null) _buildErrorSliver(),
          if (project != null) ...[
            _buildProjectInfoSliver(),
            _buildStepsSliver(),
          ],
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 16, bottom: 16),
        title: Text(
          project?['title'] ?? '프로젝트 상세',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF36eff4).withOpacity(0.1),
                Color(0xFF8A6FF0).withOpacity(0.1),
              ],
            ),
          ),
        ),
      ),
      leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildLoadingSliver() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
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
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF36eff4)),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              '프로젝트를 불러오는 중...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSliver() {
    return SliverFillRemaining(
      child: Center(
        child: Container(
          margin: EdgeInsets.all(24),
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red[400],
                ),
              ),
              SizedBox(height: 24),
              Text(
                '오류 발생',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    error = null;
                  });
                  fetchProjectDetail();
                },
                icon: Icon(Icons.refresh),
                label: Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF36eff4),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectInfoSliver() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF36eff4), Color(0xFF8A6FF0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.flag_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '프로젝트 목표',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        project!['goal'] ?? '목표가 설정되지 않았습니다',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Text(
                  '전체 진행률',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Spacer(),
                Text(
                  '${(_completionRate * 100).round()}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF36eff4),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _completionRate * _progressAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF36eff4), Color(0xFF8A6FF0)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsSliver() {
    final steps = project!['steps'] as List<dynamic>? ?? [];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final step = steps[index];
          final completed = step['completed'] ?? false;

          return Container(
            margin: EdgeInsets.fromLTRB(20, 0, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => toggleStepCompletion(index),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: completed ? Color(0xFF36eff4) : Colors.transparent,
                          border: Border.all(
                            color: completed ? Color(0xFF36eff4) : Colors.grey[400]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: completed
                            ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                            : null,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          step['step'] ?? '단계 없음',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: completed ? Colors.grey[600] : Colors.black87,
                            decoration: completed ? TextDecoration.lineThrough : null,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        childCount: steps.length,
      ),
    );
  }
}