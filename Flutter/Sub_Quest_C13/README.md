# AIFFEL Campus Online Code Peer Review Templete
- 코더 : 백승호, 이은솔
- 리뷰어 : 박종호, 최창윤

# PRT(Peer Review Template)
- [v]  **1. 주어진 문제를 해결하는 완성된 코드가 제출되었나요?**
![image](https://github.com/user-attachments/assets/f1daf31f-5df7-45e6-b1a5-42c9a2323d82)

잘 제출되었고 강아지가 귀여웠습니다.


- [v]  **2. 전체 코드에서 가장 핵심적이거나 가장 복잡하고 이해하기 어려운 부분에 작성된 
주석 또는 doc string을 보고 해당 코드가 잘 이해되었나요?**
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

  제가 어려워 했던 부분인데 내용이 쉬웠고 간결하게 코드가 작성되어있었습니다.
        
- [v]  **3. 에러가 난 부분을 디버깅하여 문제를 해결한 기록을 남겼거나
새로운 시도 또는 추가 실험을 수행해봤나요?**
두가지의 결과물을 제출했는데 설명으로 잘 들었고 승호님의 사진을 클릭했을때 Cat인지 아닌지를 알려주는 방식으로 만든것도
흥미로웠습니다.

        
- [v]  **4. 회고를 잘 작성했나요?**
네 잘 작성되었습니다
        
- [v]  **5. 코드가 간결하고 효율적인가요?**
매우 간결하고 보기에도 좋았습니다.
저도 이것을 바탕으로 다시 한번 시도를 해볼려고 합니다.
특히 은솔님껀 디자인적으로 매우 보기 좋았습니다.

# 회고(참고 링크 및 코드 개선)
```
이번엔 창윤님의 코드를 짜는것을 보는 네이게이션을 했습니다. 저는 챗GPT를 많이 활용하는데
그렇지않고 직접 짜는것을 보고 흥미로웠습니다.
```
