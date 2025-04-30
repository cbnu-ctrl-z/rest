import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProjectPage extends StatefulWidget {
  @override
  _ProjectPageState createState() => _ProjectPageState();
}

class stepItem {
  final String steptext;
  bool stepstate = false;
  stepItem({required this.steptext, this.stepstate = false});
}

class _ProjectPageState extends State<ProjectPage> {
  final url = '${dotenv.env['API_URL']}/project';
  final String step_in_DB = '''
  1.가
  2.나
  3.다
  ''';

  late List<stepItem> stepList;

  @override
  void initState() {
    super.initState();
    stepList =
        step_in_DB.trim().split('\n').map((line) {
          String sentence = line.replaceFirst(RegExp(r'^\d+\.'), '').trim();
          return stepItem(steptext: sentence);
        }).toList();
  }

  @override
  Widget build(BuildContext context) {
    int completedSteps = stepList.where((e) => e.stepstate).length;
    double progress = stepList.isEmpty ? 0.0 : completedSteps / stepList.length;

    return Scaffold(
      appBar: AppBar(title: Text('프로젝트 단계')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 진행률 텍스트
            Text(
              '진행도 ${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),

            const SizedBox(height: 8),

            /// 부드러운 프로그레스 바
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// 동적 단계 리스트
            Expanded(
              child: ListView.builder(
                itemCount: stepList.length,
                itemBuilder: (context, index) {
                  final step = stepList[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          step.stepstate = !step.stepstate;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              step.stepstate
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.1)
                                  : Theme.of(
                                    context,
                                  ).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(
                            step.stepstate
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color:
                                step.stepstate
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                          ),
                          title: Text(
                            step.steptext,
                            style: TextStyle(
                              fontWeight:
                                  step.stepstate
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                              color:
                                  step.stepstate
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                            ),
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
    );
  }
}
