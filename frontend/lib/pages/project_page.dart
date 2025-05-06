import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dotted_border/dotted_border.dart';

class ProjectPage extends StatefulWidget {
  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class stepItem {
  final String object;
  final List<String> text;
  List<bool> isChecked;

  stepItem({
    required this.object,
    required this.text,
  }) : isChecked = List<bool>.filled(text.length, false);

  int get completedCount => isChecked.where((v) => v).length;
  int get total => text.length;
}

class _ProjectPageState extends State<ProjectPage> {
  final url = '${dotenv.env['API_URL']}/project';

  final String step_in_DB = '''
  1. 최종 목표
  - 멘토멘티 매칭 프로그램을 완성하여 실제 사용자 100명에게 배포하기

  2.단계별 목표
  - 1단계 : 파이썬과 다트의 기본 사용법과 문법 학습하기
  - 2단계 : 간단한 예제 애플리케이션을 구현
  - 3단계 : 멘토멘티 매칭 알고리즘 설계 및 기본 로직 구현하기
  - 4단계 : 사용자 인터페이스(UI) 설계 및 프론트엔드 구현
  - 5단계 : 백엔드와 프론트엔드 통합 및 기능 테스트
  - 6단계 : 초기 사용자 테스트를 위한 베타 버전 출시 및 피드백 수집
''';

  late stepItem stepData;
  int currentStep = 0;
  int displayStep = 0; // 인디케이터 클릭 시 보여줄 단계
  bool _loading = true;
  static const String _prefsKey = 'step_isChecked';

  @override
  void initState() {
    super.initState();
    _initStepData();
  }

  Future<void> _initStepData() async {
    final parsed = _parseStepText(step_in_DB);
    final savedChecked = await _loadStepState(parsed.text.length);
    setState(() {
      stepData = stepItem(object: parsed.object, text: parsed.text)
        ..isChecked = savedChecked;
      currentStep = savedChecked.indexWhere((c) => !c);
      if (currentStep == -1) currentStep = parsed.text.length;
      displayStep = currentStep;
      _loading = false;
    });
  }

  stepItem _parseStepText(String input) {
    List<String> lines = input.trim().split('\n');
    String object = '';
    List<String> texts = [];

    for (var line in lines) {
      line = line.trim();
      if (line.startsWith('-')) {
        String content = line.substring(1).trim();
        if (RegExp(r'\d+단계\s*:').hasMatch(content)) {
          var split = content.split(':');
          if (split.length > 1) {
            texts.add(split[1].trim());
          }
        } else {
          object = content;
        }
      }
    }

    return stepItem(object: object, text: texts);
  }

  Future<void> _saveStepState(List<bool> isChecked) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, isChecked.map((e) => e ? '1' : '0').toList());
  }

  Future<List<bool>> _loadStepState(int length) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey);
    if (saved == null || saved.length != length) {
      return List.filled(length, false);
    }
    return saved.map((e) => e == '1').toList();
  }

  void _moveStep(int nextStep) async {
    if (nextStep < 0 || nextStep > stepData.text.length) return;
    setState(() {
      currentStep = nextStep;
      displayStep = nextStep;
      for (int i = 0; i < stepData.text.length; i++) {
        stepData.isChecked[i] = i < currentStep;
      }
    });
    await _saveStepState(stepData.isChecked);
  }

  void _showAllSteps() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('단계별 목표 전체보기'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < stepData.text.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: stepData.isChecked[i] ? Colors.green : Colors.blue,
                        ),
                        child: Center(
                          child: stepData.isChecked[i]
                              ? Icon(Icons.check, color: Colors.white, size: 16)
                              : Text(
                                  '${i + 1}',
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          stepData.text[i],
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('프로젝트 단계')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final int stepCount = stepData.text.length;
    final bool isFinished = currentStep >= stepCount;

    // 한 줄에 최대 7개
    int crossAxisCount = 7;
    if (MediaQuery.of(context).size.width < 400) {
      crossAxisCount = 5;
    }

    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.white, // 배경색 흰색으로 설정
          elevation: 0, // 그림자 제거
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Image.asset(
                  'assets/logo.jpg', // 로고 이미지 경로
                 fit: BoxFit.contain,
                ),
              ],
            ),
            ),
          title: Row(
            children: [
              Text(
                '멘톡',
                style: TextStyle(
                  color: Colors.black, // 텍스트 색상 검정으로
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 4),
              Text(
                '멘토 매칭 추천 서비스',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          centerTitle: false, // 타이틀 왼쪽 정렬
          actions: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: Colors.red),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.settings_outlined, color: Colors.grey),
              onPressed: () {},
            ),
          ],
        ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 최종 목표 위젯
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Text(
                stepData.object,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            
            // 단계별 목표 (큰 원)
            Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade300, Colors.purple.shade300],
                  ),
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '단계별 목표',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12),
                      isFinished
                          ? Text(
                              "🎉 모든 단계를 완료했습니다!",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            )
                          : Text(
                              stepData.text[displayStep],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ],
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // 단계별 목표 전체보기 버튼
            ElevatedButton(
              onPressed: _showAllSteps,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.black),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('단계별 목표 전체보기'),
            ),
            
            SizedBox(height: 20),
            
            // 스텝 인디케이터 (점선으로 연결된 원형)
            Expanded(
              flex: 0,
              child: Wrap(
                spacing: 10,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: List.generate(stepCount, (idx) {
                  final isDone = stepData.isChecked[idx];
                  final isCurrent = idx == currentStep;
                  final isDisplay = idx == displayStep;
                  
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            displayStep = idx;
                          });
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone ? Colors.blue : isCurrent ? Colors.blue : Colors.grey.shade300,
                            border: Border.all(
                              color: isDisplay ? Colors.black : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: isDone
                              ? Icon(Icons.check, color: Colors.white, size: 16)
                              : Text(
                                  '${idx + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isCurrent ? Colors.white : Colors.black,
                                  ),
                                ),
                        ),
                      ),
                      // 마지막 아이템이 아니고, 한 줄의 마지막이 아닌 경우 점선 추가
                      if (idx < stepCount - 1 && (idx + 1) % crossAxisCount != 0)
                        Container(
                          width: 10, // 원 사이 간격에 맞게 조정
                          padding: EdgeInsets.zero,
                          child: DottedBorder(
                            dashPattern: [3, 3],
                            color: Colors.blue.shade200,
                            strokeWidth: 1,
                            padding: EdgeInsets.zero, // 내부 패딩 제거
                            customPath: (size) {
                              return Path()
                                ..moveTo(0, size.height / 2)
                                ..lineTo(size.width, size.height / 2); // 컨테이너 너비 전체 사용
                            },
                            child: SizedBox(
                              width: 10, // 원 사이 간격에 맞게 조정
                              height: 1,
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
            
            SizedBox(height: 30),
            
            // 이전/다음 버튼
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: currentStep > 0
                        ? () => _moveStep(currentStep - 1)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade300,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text('이전', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: ElevatedButton(
                    onPressed: !isFinished
                        ? () {
                            if (currentStep < stepCount) {
                              _moveStep(currentStep + 1);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade300,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text('다음', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 진행률 바
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: LinearProgressIndicator(
                value: stepCount == 0
                    ? 0
                    : (currentStep > stepCount ? stepCount : currentStep) / stepCount,
                minHeight: 14,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.blue.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
