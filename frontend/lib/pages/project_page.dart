import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProjectPage extends StatefulWidget {
  final String id;
  const ProjectPage({required this.id});
  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class stepItem {
  //AI가 생성한 목표들을 저장하는 클래스
  final String mainObject; //최종목표
  final List<String> stepObject; //단계별 목표
  List<bool> isChecked; //단계별 목표 진행 완료여부 확인 부울변수

  stepItem({
    //생성자
    required this.mainObject,
    required this.stepObject,
  }) : isChecked = List<bool>.filled(stepObject.length, false);

  //int get completedStepCount => isChecked.where((v) => v).length;//완료된 계수의 개수 반환(isChecked 변수 상태 확인)
  //int get steptotal => stepObject.length;//단계별 목표 총 개수 반환
}

class _ProjectPageState extends State<ProjectPage> {
  bool isLoading = true;
  late String stepInDB;
  late stepItem stepData; //stepItem변수 생성, late을 통해 나중에 인스턴스 생성
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = widget.id;
    if (userId.isNotEmpty) {
    _fetchProject(userId);
    }
  }

  Future<void> _fetchProject(String userId) async {
    try {
      final url = '${dotenv.env['API_URL']}/projects/user/$userId';
      final useridresponse = await http.get(Uri.parse(url));
      final List<dynamic>dbdata = jsonDecode(useridresponse.body);
      final List<String> projectid = dbdata.map((item) => item['_id'] as String).toList();
      final String cleanprojectid = projectid[0];
      final projecturl  = '${dotenv.env['API_URL']}/projects/$cleanprojectid';
      final pidresponse = await http.get(Uri.parse(projecturl));
      final projectJson = json.decode(pidresponse.body);
      if (pidresponse.statusCode == 200) {
        stepInDB = projectJson['plan'] ?? '';
        await _initStepData(); // 데이터가 준비된 후에만 stepData 초기화
        setState(() {
          _loading = false; // 로딩 종료
        });
      } else {
        _showErrorDialog("프로젝트 정보를 불러오지 못했습니다.");
      }
    } catch (e) {
      _showErrorDialog("오류 발생: $e");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("오류"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("확인"),
              ),
            ],
          ),
    );
  }

  int currentStep = 0; // 현재 진행중인 단계 표시
  int displayStep = 0; // 인디케이터 클릭 시 보여줄 단계 표시
  bool _loading =
      true; //데이터 로딩 상태, 처음에는 데이터 체크 등 필요한 정보를 가져와야 하므로 loading - true
  static const String _prefsKey = 'step_isChecked';

  @override
  void initState() {
    //위젯트리 생성
    super.initState();
  }

  Future<void> _initStepData() async {
    //비동기 함수 _initStepData 선언 / step_in_DB의 내용들을 stepItem 멤버함수에 넣음
    final parsed = _parseStepText(
      stepInDB,
    ); //DB에 있는 목표텍스트를 파싱해서 변수에 저장 / 자료형 : stepItem
    
    final savedChecked = await _loadStepState(
      parsed.stepObject.length,
    ); //부울값 저장 List<String> / 현재의 단계 진행상태를 가져옴
    
    setState(() {
      //현재 진행상태에 따라 UI업데이트
      stepData = stepItem(
        mainObject: parsed.mainObject,
        stepObject: parsed.stepObject,
      ) //파싱한 데이터들을 저장하며 인스턴스 생성
      ..isChecked = savedChecked;
      currentStep = savedChecked.indexWhere((c) => !c,); //완료되지 않은 단계 중 가장 먼저 오는 단계의 인덱스를 가짐 / 모두 완료된(ture)상태면 -1을 가짐
      if (currentStep == -1)
        currentStep = parsed.stepObject.length; //모두 완료된 상태면 현재 진행중인 단계를 마지막 단계로 표시
      displayStep = currentStep; //인디케이터를 클릭 전 기본값은 currentStep과 동일
    });
  }

  stepItem _parseStepText(String input) {
    //목표텍스트 파싱함수
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

    return stepItem(mainObject: object, stepObject: texts);
  }

  Future<List<bool>> _loadStepState(int totalStepCount) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey);
    if (saved == null) {
      return List.filled(totalStepCount, false);
    }
    final loaded = saved.map((e) => e == '1').toList();
    if (loaded.length < totalStepCount) {
      return List<bool>.from(loaded)..addAll(List.filled(totalStepCount - loaded.length, false));
    } else if (loaded.length > totalStepCount) {
      return loaded.sublist(0, totalStepCount);
    }
    return loaded;
  }

  Future<void> _saveStepState(List<bool> isChecked) async {
    //현재 진행상태 저장 함수
    final prefs =
        await SharedPreferences.getInstance(); //앱 내 영구 저장파일에 접근하기 위한 변수
    await prefs.setStringList(
      _prefsKey,
      isChecked.map((e) => e ? '1' : '0').toList(),
    ); //SharedPreferences는 오직 List<String>만 지원하기에 부울 값을 1,0으로 변환하여 저장
  }

  void _moveStep(int targetStep) async {
    //단계이동 함수
    if (targetStep < 0 || targetStep > stepData.stepObject.length)
      return; //nextStep이 유효범위 밖이면 함수 중단(잘못된 인덱스 요청 무시)
    setState(() {
      currentStep = targetStep; //현재 진행중인 단계 변경
      displayStep = targetStep; //화면에 표시할 단계변경
      for (int i = 0; i < stepData.stepObject.length; i++) {
        //전체단계수만큼 반복하며 targetStep 인덱스의 전 인덱스들은 모두 true(완료)상태로 변환,  targetStep이후 부턴 false로 변환
        stepData.isChecked[i] = i < currentStep;
      }
    });
    await _saveStepState(stepData.isChecked); //현재 진행상태 저장
  }

  void _showAllSteps() {
    //단계별 목표 전체보기 박스 제시
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('단계별 목표 전체보기'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < stepData.stepObject.length; i++)
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
                              color:
                                  stepData.isChecked[i]
                                      ? Colors.green
                                      : Colors.blue,
                            ),
                            child: Center(
                              child:
                                  stepData.isChecked[i]
                                      ? Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                      : Text(
                                        '${i + 1}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              stepData.stepObject[i],
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

  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      //로딩중일 경우
      return Scaffold(
        body: Text('현재 진행중인 프로젝트가 없습니다.'),
      );
    }

    final int stepCount = stepData.stepObject.length; //단계개수
    final bool isFinished = currentStep == stepCount; //모든 단계완료 여부 확인 부울변수

    // 한줄에 최대 몇개의 인디케이터를 넣을지 정함
    int maxcrossAxisCount = 7;
    if (MediaQuery.of(context).size.width < 400) {
      maxcrossAxisCount = 5;
    }

    return Scaffold(
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
                stepData.mainObject,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                            stepData.stepObject[displayStep >= stepCount ? stepCount - 1 : displayStep],
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
                            color:
                                isDone
                                    ? Colors.blue
                                    : isCurrent
                                    ? Colors.blue
                                    : Colors.grey.shade300,
                            border: Border.all(
                              color:
                                  isDisplay ? Colors.black : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child:
                              isDone
                                  ? Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                  : Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color:
                                          isCurrent
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                        ),
                      ),
                      // 마지막 아이템이 아니고, 한 줄의 마지막이 아닌 경우 점선 추가
                      if (idx < stepCount - 1 &&
                          (idx + 1) % maxcrossAxisCount != 0)
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
                                ..lineTo(
                                  size.width,
                                  size.height / 2,
                                ); // 컨테이너 너비 전체 사용
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
                    onPressed:
                        currentStep > 0
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
                    child: const Text(
                      '이전',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        !isFinished
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
                    child: const Text(
                      '다음',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
