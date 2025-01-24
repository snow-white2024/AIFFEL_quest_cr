import 'package:flutter/material.dart';

/// 두 번째 페이지 (강아지 페이지)
class SecondPage extends StatefulWidget {
  final bool isCat;

  SecondPage({required this.isCat});

  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  late bool isCatHere;

  @override
  void initState() {
    super.initState();
    isCatHere = widget.isCat;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.pets),  // 강아지 모양 아이콘을 원한다면 교체
        title: Text('Second Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // "Back" 버튼
            ElevatedButton(
              onPressed: () {
                // pop으로 돌아가면서 true 값을 넘겨줌
                Navigator.pop(context, true);
              },
              child: Text('Back'),
            ),
            SizedBox(height: 20),
            // 강아지 이미지 (예시로 NetworkImage 사용)
            GestureDetector(
              onTap: () {
                print('isCat in SecondPage: $isCatHere');
              },
              child: Container(
                width: 300,
                height: 300,
                child: Image.asset(
                  'assets/dog.png',
                  fit:BoxFit.cover,
                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}
