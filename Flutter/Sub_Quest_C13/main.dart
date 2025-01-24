import 'package:flutter/material.dart';
import 'pages/first_page.dart';  // 우리가 따로 만든 페이지 파일을 import

void main() {
  runApp(MyApp());
}

/// 전체 앱을 감싸는 MyApp
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, //디버그 배너 제거
      title: 'Cat or Dog',
      home: FirstPage(),
      // 혹은 named route를 사용하려면 initialRoute와 routes 등을 설정해줄 수도 있음
    );
  }
}

//- 은솔
//
//     push 함수를 통해 bool 값도 전달할 수 있다는 점을 알았습니다. 스택이 쌓이고 제거되는 과정을 시각적으로 확인할 수 있으면 더 이해가 잘될 것 같습니다.
//
// - 승호
//
//     고양이와 강아지가 귀여워서 힐링할 수 있었습니다. 그러나 스택이 쌓이고 제거되는 과정을 보지 못해서 스트레스를 받았습니다.