import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('플러터 앱 만들기'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.settings), // 플러터 아이콘
          onPressed: () {
            // 아이콘 클릭 시의 동작
            debugPrint('플러터 아이콘 클릭됨');
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                debugPrint('"TEXT"버튼이 눌렸습니다');
              },
              child: const Text('TEXT'),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.topLeft,
              children: [
                Container(
                  width: 300,
                  height: 300,
                  color: Colors.grey[300],
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 240,
                    height: 240,
                    color: Colors.red[300],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 180,
                    height: 180,
                    color: Colors.green[300],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 120,
                    height: 120,
                    color: Colors.blue[300],
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 60,
                    height: 60,
                    color: Colors.yellow[300],
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

//백승호 : 일상생활에서 우리가 많이 사용하는 핸드폰 화면에 구성을 꾸며본다는게 무척 흥미로웠습니다. 문제를 하나하나 책과 함께 비교하여 직접코딩 후 ai를 이용해 수정 도움을 받아 작성하였습니다.
