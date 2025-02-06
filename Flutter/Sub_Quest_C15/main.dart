import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jellyfish Classifier',
      debugShowCheckedModeBanner: false,
      home: JellyfishClassifierScreen(),
    );
  }
}

class JellyfishClassifierScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jellyfish Classifier'),
        // 앱바 좌측에 해파리 아이콘 이미지 추가
        // 만약 지정된 에셋('assets/jellyfish.jpg')이 없다면 대체 아이콘(Icons.bubble_chart)을 표시
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/jellyfish1.jpg',
            fit: BoxFit.contain,
            errorBuilder:
                (BuildContext context, Object exception, StackTrace? stackTrace) {
              return Icon(Icons.bubble_chart, size: 40);
            },
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 화면 중앙에 에셋 이미지를 배치 (assets 폴더 내 이미지 경로)
            Image.asset(
              'assets/jellyfish.jpg',
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 20),
            // 중앙 이미지 밑에 좌측과 우측에 각각 버튼 배치
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // 왼쪽 버튼 동작 추가
                    },
                    child: Text('L Button'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // 오른쪽 버튼 동작 추가
                    },
                    child: Text('R Button'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
