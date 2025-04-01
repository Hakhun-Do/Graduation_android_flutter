import 'package:flutter/material.dart';

class InputArea extends StatelessWidget {
  final TextEditingController _areaController = TextEditingController();

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
              onPressed: () {
                // 관할 구역 지정 로직 추가
                print('지정된 관할 구역: ${_areaController.text}');
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
