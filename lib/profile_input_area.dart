import 'package:flutter/material.dart';
import 'package:graduation_project/api_service.dart'; // ApiService import 추가

class InputArea extends StatelessWidget {
  final TextEditingController _areaController = TextEditingController();
  final ApiService apiService = ApiService(); // ApiService 인스턴스 생성

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('관할 구역 지정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_back,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              '관할 구역을 입력하세요',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity, // 입력 칸의 너비를 화면에 맞춥니다.
              child: TextField(
                controller: _areaController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '관할 구역',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // 관할 구역 지정 로직 추가
                String newPos = _areaController.text.trim();

                if (newPos.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('관할 구역을 입력하세요!')));
                  }
                  return; // 관할 구역 지정 진행 안 함
                }

                // API 호출
                Map<String, dynamic>? result = await apiService.updatePos(
                  newPos,
                );

                if (context.mounted) {
                  if (result != null && result["success"] == true) {
                    // 관할 구역 변경 성공 메시지 출력
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('관할 구역이 변경되었습니다!')));
                    Navigator.pop(context); // 이전 화면으로 돌아가기
                  } else {
                    // 관할 구역 변경 실패 메시지 출력
                    String errorMessage = result != null ? result["error"] ?? "관할 구역 변경에 실패했습니다." : "관할 구역 변경에 실패했습니다.";
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMessage)),
                    );
                  }
                }
              },
              child: Text('관할 구역 지정'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE5A5EF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
