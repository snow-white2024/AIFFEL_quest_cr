import 'package:flutter/material.dart';
import 'second_page.dart'; // SecondPage를 사용하기 위해 import

/// 첫 번째 페이지 (고양이 페이지)
class FirstPage extends StatefulWidget {
  @override
  _FirstPageState createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  bool isCat = true; // 기본값 true로 설정

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.pets), // 고양이 모양 아이콘을 원하시면 교체 가능
        title: Text('First Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // "Next" 버튼
            ElevatedButton(
              onPressed: () async {
                setState(() {  //문제 해결과정 : 해당 코드가 누락되어 있어, 강아지 사진이 출력되었을때
                  isCat = false; // isCat이 true로 출력되는 문제 해결.
                });
                // 페이지 이동 시, 현재 isCat 값을 SecondPage로 전달
                // push의 결과값을 result로 받음(SecondPage에서 pop 할 때 넘겨준 값)
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SecondPage(isCat: isCat),
                  ),
                );

                // 돌아온 값이 있다면, 화면에 반영
                if (result != null) {
                  setState(() {
                    isCat = result;
                  });
                }
              },
              child: Text('Next'),
            ),
            SizedBox(height: 20),
            // 고양이 이미지 (예시로 NetworkImage 사용)
            GestureDetector(
              onTap: () {
                print('isCat in FirstPage: $isCat');
              },
              child: Container(
                width: 300,
                height: 300,
                child: Image.asset(
                  'assets/cat.png',
                  fit: BoxFit.cover,
                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}
