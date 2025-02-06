//회고 백승호 : 어떻게 접근해야할지 생각하다가 시간을 오래사용하였다. 서버에 가중치를 업로드 하는 것과 해파리임을 맞추는것은 확인하였고 어플의 기본 틀은 만들 수 있었으나 버튼으로 서버의 응답을 연결하는 중요한 과정은 아직 완수 하지 못하였다. 너무 아쉽다.

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

