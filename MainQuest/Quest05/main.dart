import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

/// 전역: 스낵바 + 콘솔
late BuildContext globalContext;
void debugLog(String msg) {
  print(msg);
  if (globalContext != null) {
    ScaffoldMessenger.of(globalContext).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TimeZone 초기화
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  // 로컬 알림 초기화
  await _initLocalNotifications();

  runApp(const MyApp());
}

// 알림
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> _initLocalNotifications() async {
  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const InitializationSettings settings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings,
    onDidReceiveNotificationResponse: (resp) {
      debugLog("[Push Notification] 알림 탭: $resp");
    },
  );
}

/// 데이터 모델
class Memo {
  String content;
  String? summary;
  DateTime createdAt;

  Memo({required this.content, this.summary, required this.createdAt});

  Map<String, dynamic> toJson() => {
    'content': content,
    'summary': summary,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Memo.fromJson(Map<String, dynamic> json) {
    return Memo(
      content: json['content'],
      summary: json['summary'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class TodoItem {
  String content;
  bool done;
  DateTime createdAt;

  TodoItem({required this.content, this.done = false, required this.createdAt});

  Map<String, dynamic> toJson() => {
    'content': content,
    'done': done,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      content: json['content'],
      done: json['done'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peter App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
    );
  }
}

/// 스플래시 -> Main
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 2초 후 메인화면
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: const Center(
        child: Text(
          'Peter',
          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// MainScreen: PageView(0=Memo,1=Calendar,2=Todo)
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  List<Memo> memos = [];
  List<TodoItem> todos = [];
  // 날짜별 일정: key="yyyy-MM-dd", value=List<Map<String,dynamic>>
  Map<String, List<Map<String, dynamic>>> events = {};

  final PageController _pageController = PageController(initialPage: 1);
  final ScrollController _calendarScrollController = ScrollController();

  final int startYear = 2025;
  final int endYear = 2100;
  DateTime? selectedDay;

  static const String _openAIApiKey = 'Your key';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    globalContext = context; // 스낵바 위해 전역 context 저장

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) async {
          // (5) 페이지 이동 시 AI 멘트
          if (index == 0) {
            final ai = await _fetchAiResponse("메모 페이지로 이동했어. 간단히 환영해줘.");
            debugLog(ai);
          } else if (index == 1) {
            final ai = await _fetchAiResponse("캘린더 페이지로 이동했어. 간단히 환영해줘.");
            debugLog(ai);
            _jumpToTodayMonth(); // (2) 현재달 중앙
          } else if (index == 2) {
            final ai = await _fetchAiResponse("투두 페이지로 이동했어. 간단히 환영해줘.");
            debugLog(ai);
          }
        },
        children: [
          _buildMemoPage(),
          _buildCalendarPage(),
          _buildTodoPage(),
        ],
      ),
      // (5) 오류 해결 -> 정확히 '_buildPeterMouthFab' 메서드를 정의
      floatingActionButton: _buildPeterMouthFab(),
    );
  }

  // 메모 페이지
  Widget _buildMemoPage() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Memo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToNewMemoPage,
          ),
        ],
      ),
      body: memos.isEmpty
          ? const Center(child: Text('메모가 없습니다.'))
          : ListView.builder(
        itemCount: memos.length,
        itemBuilder: (context, index) {
          final m = memos[index];
          final dateStr = "${m.createdAt.year}-${m.createdAt.month}-${m.createdAt.day}";
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(height: 1, color: Colors.grey[300], margin: const EdgeInsets.symmetric(vertical: 4)),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                    const SizedBox(height: 4),
                    Text(m.summary ?? 'No summary', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(m.content),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToNewMemoPage() async {
    final text = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const NewMemoPage()),
    );
    if (text != null && text.isNotEmpty) {
      final summary = await _fetchAiResponse("이 메모를 1문장으로 요약:\n$text");
      final newMemo = Memo(content: text, summary: summary, createdAt: DateTime.now());
      setState(() {
        memos.add(newMemo);
      });
      _saveData();
      debugLog("새 메모 작성 완료");
    }
  }

  // 투두 페이지
  Widget _buildTodoPage() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('TodoList'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToNewTodoPage,
          ),
        ],
      ),
      body: todos.isEmpty
          ? const Center(child: Text('아직 ToDo가 없습니다.'))
          : ListView.builder(
        itemCount: todos.length,
        itemBuilder: (context, index) {
          final t = todos[index];
          final dateStr = "${t.createdAt.year}-${t.createdAt.month}-${t.createdAt.day}";
          return Column(
            children: [
              Container(height: 1, color: Colors.grey[300], margin: const EdgeInsets.symmetric(vertical: 4)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: Text(t.content),
                      value: t.done,
                      onChanged: (val) {
                        if (val == null) return;
                        _toggleTodoDone(index, val);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToNewTodoPage() async {
    final text = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const NewTodoPage()),
    );
    if (text != null && text.isNotEmpty) {
      final newTodo = TodoItem(content: text, createdAt: DateTime.now());
      setState(() {
        todos.add(newTodo);
      });
      _saveData();
      debugLog("새 투두 작성 완료");

      // 5초 후 미완료 시 재촉
      Timer(const Duration(seconds: 5), () async {
        if (!newTodo.done) {
          final remind = await _fetchAiResponse("아직 완료되지 않은 ToDo가 있습니다: ${newTodo.content}\n간단히 재촉해줘.");
          debugLog(remind);
        }
      });
    }
  }

  void _toggleTodoDone(int index, bool value) {
    setState(() {
      todos[index].done = value;
    });
    _saveData();
    debugLog("투두 완료상태 변경 -> $value");
  }

  // 캘린더 페이지
  Widget _buildCalendarPage() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Calendar'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              if (selectedDay == null) {
                debugLog("날짜를 먼저 탭해주세요!");
              } else {
                _goToScheduleDetailPage(selectedDay!);
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        controller: _calendarScrollController,
        itemCount: (endYear - startYear + 1) * 12,
        itemBuilder: (context, index) {
          final year = startYear + (index ~/ 12);
          final month = (index % 12) + 1;
          final firstDay = DateTime(year, month, 1);

          return _MonthView(
            year: year,
            month: month,
            firstDayOfMonth: firstDay,
            selectedDay: selectedDay,
            events: events,
            onDayTap: (day) {
              setState(() => selectedDay = day);
            },
            onDayDoubleTap: (day) {
              setState(() => selectedDay = day);
              _goToScheduleDetailPage(day);
            },
          );
        },
      ),
    );
  }

  // (2) 캘린더 돌아올 때 현재 날짜 달 화면 중앙
  void _jumpToTodayMonth() {
    final now = DateTime.now();
    final index = (now.year - startYear) * 12 + (now.month - 1);
    if (index < 0 || index >= (endYear - startYear + 1) * 12) return;

    const singleMonthHeight = 380.0;
    final offset = index * singleMonthHeight + singleMonthHeight / 2;
    _calendarScrollController.jumpTo(offset);
  }

  // 일정상세 페이지 이동
  void _goToScheduleDetailPage(DateTime day) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleDetailPage(
          day: day,
          parentEvents: events,
          onUpdateEvents: (updated) {
            setState(() {
              events = updated;
            });
            _saveData();
            debugLog("일정 업데이트 - 저장 완료");
          },
        ),
      ),
    );
  }

  /// (5) 피터의 입 FAB 메서드 (중요!)
  Widget _buildPeterMouthFab() {
    return SpeedDial(
      icon: Icons.add,
      backgroundColor: Colors.yellow,
      foregroundColor: Colors.black,
      childrenButtonSize: const Size(64, 64),
      spaceBetweenChildren: 16,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.notification_important, color: Colors.black),
          backgroundColor: Colors.yellow,
          label: '푸시알림 테스트',
          labelStyle: const TextStyle(color: Colors.black),
          onTap: _testNotification,
        ),
        SpeedDialChild(
          child: const Icon(Icons.note, color: Colors.black),
          backgroundColor: Colors.yellow,
          label: 'New Memo',
          labelStyle: const TextStyle(color: Colors.black),
          onTap: () async {
            final text = await Navigator.push<String>(
              context,
              MaterialPageRoute(builder: (_) => const NewMemoPage()),
            );
            if (text != null && text.isNotEmpty) {
              final summary = await _fetchAiResponse("이 메모를 1문장으로 요약:\n$text");
              final newMemo = Memo(content: text, summary: summary, createdAt: DateTime.now());
              setState(() {
                memos.add(newMemo);
              });
              await _saveData();
              debugLog("피터의 입 -> 새 메모 -> 메모 페이지 이동");

              // 메모 페이지(0)
              _pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.list, color: Colors.black),
          backgroundColor: Colors.yellow,
          label: 'New Todo',
          labelStyle: const TextStyle(color: Colors.black),
          onTap: () async {
            final text = await Navigator.push<String>(
              context,
              MaterialPageRoute(builder: (_) => const NewTodoPage()),
            );
            if (text != null && text.isNotEmpty) {
              final newTodo = TodoItem(content: text, createdAt: DateTime.now());
              setState(() {
                todos.add(newTodo);
              });
              await _saveData();
              debugLog("피터의 입 -> 새 투두 -> 투두 페이지 이동");

              // 5초 후 재촉
              Timer(const Duration(seconds: 5), () async {
                if (!newTodo.done) {
                  final remind = await _fetchAiResponse("아직 완료되지 않은 ToDo: ${newTodo.content}\n재촉해줘.");
                  debugLog(remind);
                }
              });

              // 투두 페이지(2)
              _pageController.animateToPage(
                2,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
        ),
      ],
    );
  }

  // 영구 저장 / 불러오기
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final memosJson = prefs.getString('memos') ?? '[]';
    final memosList = jsonDecode(memosJson) as List<dynamic>;
    memos = memosList.map((e) => Memo.fromJson(e)).toList();

    final todosJson = prefs.getString('todos') ?? '[]';
    final todosList = jsonDecode(todosJson) as List<dynamic>;
    todos = todosList.map((e) => TodoItem.fromJson(e)).toList();

    final eventsJson = prefs.getString('events') ?? '{}';
    final eventsMap = jsonDecode(eventsJson) as Map<String, dynamic>;
    events = eventsMap.map((k, v) {
      final listVal = v as List<dynamic>;
      final mapped = listVal.map((e) => e as Map<String, dynamic>).toList();
      return MapEntry(k, mapped);
    });

    setState(() {});
    debugLog("데이터 불러오기 완료");
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    final memosList = memos.map((e) => e.toJson()).toList();
    prefs.setString('memos', jsonEncode(memosList));

    final todosList = todos.map((e) => e.toJson()).toList();
    prefs.setString('todos', jsonEncode(todosList));

    final eventsMap = events.map((k, v) => MapEntry(k, v));
    prefs.setString('events', jsonEncode(eventsMap));

    debugLog("데이터 저장 완료");
  }

  // 푸시알림 테스트
  void _testNotification() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = now.add(const Duration(seconds: 5));

    const androidDetails = AndroidNotificationDetails(
      'peter_app_test_channel',
      'Test Notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final aiResp = await _fetchAiResponse("푸시알림 테스트를 요청했어. 간단히 인사 부탁해.");

    debugLog("[Push Debug] 알림 스케줄 - 5초 뒤\nOpenAI: $aiResp");

    await flutterLocalNotificationsPlugin.zonedSchedule(
      9999,
      "푸시 알림 테스트",
      aiResp,
      scheduledTime,
      platformDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  // 실제 알림 예약
  Future<void> _zonedScheduleNotification(DateTime dt, int minutesBefore, String title) async {
    final scheduleTime = dt.subtract(Duration(minutes: minutesBefore));
    if (scheduleTime.isBefore(DateTime.now())) return;

    final aiPrompt = "$title 일정 알림 응원 한마디 부탁해.";
    final aiMessage = await _fetchAiResponse(aiPrompt);

    debugLog("[Push Debug] 일정 알림 예약 - $scheduleTime\nOpenAI: $aiMessage");

    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const androidDetails = AndroidNotificationDetails(
      'peter_app_channel_id',
      'Calendar Notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final tzDateTime = tz.TZDateTime.from(scheduleTime, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      "다가오는 일정 알림",
      aiMessage,
      tzDateTime,
      platformDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  // OpenAI: gpt-4, max_tokens=200
  Future<String> _fetchAiResponse(String userMessage) async {
    final url = Uri.https('api.openai.com', '/v1/chat/completions');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIApiKey',
        },
        body: jsonEncode({
          "model": "gpt-4",
          "messages": [
            {
              "role": "system",
              "content": "너는 피터라는 AI assistant야. 비서 어플리케이션에 걸맞은 적절한 멘트와 응원을 해줘. 한국말 위주로."
            },
            {
              "role": "user",
              "content": userMessage,
            }
          ],
          "temperature": 0.8,
          "max_tokens": 200,
        }),
      );
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decoded) as Map<String, dynamic>;
        final choices = data['choices'] as List<dynamic>;
        if (choices.isNotEmpty) {
          final aiText = choices[0]['message']['content'] as String;
          return aiText.trim();
        } else {
          return "응답이 비어있어요.";
        }
      } else {
        final err = "오류: ${response.body}";
        debugLog(err);
        return err;
      }
    } catch (e) {
      debugLog("[Push Debug] Exception: $e");
      return "오류 발생: $e";
    }
  }
}

/// 달력 한 달 (MonthView)
class _MonthView extends StatelessWidget {
  final int year;
  final int month;
  final DateTime firstDayOfMonth;
  final DateTime? selectedDay;
  final Map<String, List<Map<String, dynamic>>> events;
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<DateTime> onDayDoubleTap;

  const _MonthView({
    Key? key,
    required this.year,
    required this.month,
    required this.firstDayOfMonth,
    required this.selectedDay,
    required this.events,
    required this.onDayTap,
    required this.onDayDoubleTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final monthName = _monthName(month);
    final title = "$monthName $year";
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Text('Sun'), Text('Mon'), Text('Tue'),
            Text('Wed'), Text('Thu'), Text('Fri'), Text('Sat'),
          ],
        ),
        _buildMonthGrid(daysInMonth, startWeekday),
        Container(
          height: 1,
          color: Colors.grey.shade300,
          margin: const EdgeInsets.symmetric(vertical: 12),
        ),
      ],
    );
  }

  Widget _buildMonthGrid(int daysInMonth, int startWeekday) {
    final adjustedStart = startWeekday % 7;
    const totalCells = 42;

    return SizedBox(
      height: 300,
      child: GridView.count(
        crossAxisCount: 7,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(totalCells, (index) {
          final dayNum = index - adjustedStart + 1;
          if (dayNum < 1 || dayNum > daysInMonth) {
            return const SizedBox.shrink();
          }
          final dayDate = DateTime(year, month, dayNum);

          final now = DateTime.now();
          final isToday = (now.year == dayDate.year && now.month == dayDate.month && now.day == dayDate.day);
          final isSelected = (selectedDay != null &&
              selectedDay!.year == dayDate.year &&
              selectedDay!.month == dayDate.month &&
              selectedDay!.day == dayDate.day);

          final dateKey = "${dayDate.year}-${dayDate.month}-${dayDate.day}";
          final hasEvent = events[dateKey]?.isNotEmpty == true;

          Color bgColor = Colors.transparent;
          Color textColor = Colors.black;
          if (isToday) {
            bgColor = Colors.red;
            textColor = Colors.white;
          } else if (isSelected) {
            bgColor = Colors.blue;
            textColor = Colors.white;
          }

          return GestureDetector(
            onTap: () => onDayTap(dayDate),
            onDoubleTap: () => onDayDoubleTap(dayDate),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$dayNum', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    if (hasEvent)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: (isToday || isSelected) ? Colors.white : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _monthName(int m) {
    const monthNames = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return monthNames[m - 1];
  }
}

/// 새 메모 작성
class NewMemoPage extends StatefulWidget {
  const NewMemoPage({Key? key}) : super(key: key);

  @override
  State<NewMemoPage> createState() => _NewMemoPageState();
}

class _NewMemoPageState extends State<NewMemoPage> {
  final TextEditingController _memoCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Memo'),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: () {
              final text = _memoCtrl.text.trim();
              Navigator.pop(context, text);
            },
            child: const Text('저장', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _memoCtrl,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '메모 내용을 자유롭게 작성하세요',
            ),
            maxLines: null,
            expands: true,
          ),
        ),
      ),
    );
  }
}

/// 새 투두 작성
class NewTodoPage extends StatefulWidget {
  const NewTodoPage({Key? key}) : super(key: key);

  @override
  State<NewTodoPage> createState() => _NewTodoPageState();
}

class _NewTodoPageState extends State<NewTodoPage> {
  final TextEditingController _todoCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 ToDo 작성'),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: () {
              final text = _todoCtrl.text.trim();
              Navigator.pop(context, text);
            },
            child: const Text('등록', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _todoCtrl,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '할 일을 자유롭게 작성하세요',
            ),
            maxLines: null,
            expands: true,
          ),
        ),
      ),
    );
  }
}

/// (3) 일정상세 페이지(반복기능, 하단 목록)
class ScheduleDetailPage extends StatefulWidget {
  final DateTime day;
  final Map<String, List<Map<String, dynamic>>> parentEvents;
  final Function(Map<String, List<Map<String, dynamic>>>) onUpdateEvents;

  const ScheduleDetailPage({
    Key? key,
    required this.day,
    required this.parentEvents,
    required this.onUpdateEvents,
  }) : super(key: key);

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  final TextEditingController _titleCtrl = TextEditingController();
  TimeOfDay? _timeOfDay;
  int _notifyBefore = 10;
  String _repeat = 'No Repeat';

  List<Map<String, dynamic>> _currentDayEvents = [];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  /// 부모 events에서 해당 day 일정들 불러오기
  void _loadSchedules() {
    final dateKey = "${widget.day.year}-${widget.day.month}-${widget.day.day}";
    _currentDayEvents = widget.parentEvents[dateKey] ?? [];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = "${widget.day.year}-${widget.day.month}-${widget.day.day}";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('일정상세'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text("선택 날짜: $dateStr", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: '일정 제목',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black),
                      onPressed: _pickTime,
                      child: Text(
                        _timeOfDay == null
                            ? '시간 설정'
                            : '${_timeOfDay!.hour}시 ${_timeOfDay!.minute}분',
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text("알림: "),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '분 전'),
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null) {
                            _notifyBefore = parsed;
                          }
                        },
                      ),
                    ),
                    const Text("분 전"),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text("반복: "),
                    DropdownButton<String>(
                      value: _repeat,
                      items: ['No Repeat','Daily','Weekly','Monthly']
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _repeat = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black),
                  onPressed: _addSchedule,
                  child: const Text('추가'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _currentDayEvents.isEmpty
                ? const Center(child: Text('등록된 일정이 없습니다.'))
                : ListView.builder(
              itemCount: _currentDayEvents.length,
              itemBuilder: (context, idx) {
                final ev = _currentDayEvents[idx];
                final title = ev['title'] ?? '';
                final dt = ev['dateTime'] as DateTime?;
                final nb = ev['notifyBefore'] as int?;
                final rep = ev['repeat'] as String?;

                String info = '제목: $title';
                if (dt != null) info += '\n시간: ${dt.hour}시 ${dt.minute}분';
                if (nb != null) info += '\n알림: ${nb}분 전';
                if (rep != null && rep != 'No Repeat') {
                  info += '\n반복: $rep';
                }
                return ListTile(
                  title: Text(info),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _timeOfDay = picked);
  }

  void _addSchedule() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    DateTime? dt;
    if (_timeOfDay != null) {
      dt = DateTime(widget.day.year, widget.day.month, widget.day.day, _timeOfDay!.hour, _timeOfDay!.minute);
    }

    final schedule = {
      'title': title,
      'dateTime': dt,
      'notifyBefore': dt == null ? null : _notifyBefore,
      'repeat': _repeat,
    };

    // 부모 반영
    _insertSchedule(widget.day, schedule);

    // 반복 기능 (3회 예시)
    if (_repeat != 'No Repeat' && dt != null) {
      final repeats = _generateRepeatSchedules(dt, _repeat, title);
      for (final r in repeats) {
        _insertSchedule(r['day'] as DateTime, r);
      }
    }

    // 로컬 목록
    setState(() {
      _currentDayEvents.add(schedule);
    });
    // 폼 초기화
    _titleCtrl.clear();
    _timeOfDay = null;
    _notifyBefore = 10;
    _repeat = 'No Repeat';
  }

  // 부모 Events에 일정 삽입 -> onUpdateEvents
  void _insertSchedule(DateTime day, Map<String, dynamic> sched) {
    final newMap = Map<String, List<Map<String, dynamic>>>.from(widget.parentEvents);

    final dateKey = "${day.year}-${day.month}-${day.day}";
    newMap.putIfAbsent(dateKey, () => []);
    newMap[dateKey]!.add(sched);

    // 부모 업데이트
    widget.onUpdateEvents(newMap);
  }

  // 반복 로직 (Daily/Weekly/Monthly) -> 3회
  List<Map<String, dynamic>> _generateRepeatSchedules(DateTime startDt, String mode, String title) {
    final results = <Map<String, dynamic>>[];
    var current = startDt;

    for (int i = 1; i <= 3; i++) {
      if (mode == 'Daily') {
        current = current.add(const Duration(days: 1));
      } else if (mode == 'Weekly') {
        current = current.add(const Duration(days: 7));
      } else if (mode == 'Monthly') {
        var nextM = current.month + 1;
        var nextY = current.year;
        if (nextM > 12) {
          nextM -= 12;
          nextY += 1;
        }
        current = DateTime(nextY, nextM, current.day, current.hour, current.minute);
      }

      results.add({
        'title': "(반복)$title",
        'dateTime': current,
        'notifyBefore': _notifyBefore,
        'repeat': mode,
        'day': current, // day param for _insertSchedule
      });
    }

    return results;
  }
}
