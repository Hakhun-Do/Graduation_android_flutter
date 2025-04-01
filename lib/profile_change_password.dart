import 'package:flutter/material.dart';

class ChangePassword extends StatelessWidget {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  ChangePassword({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('비밀번호 변경')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64, color: Colors.grey),
            SizedBox(height: 20),
            Text('변경할 비밀번호를 입력하세요', style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),

            // 현재 비밀번호 입력
            SizedBox(
              width: double.infinity,
              child: TextField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '현재 비밀번호',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                ),
                obscureText: true, // 비밀번호 입력값 숨기는 기능
              ),
            ),
            SizedBox(height: 20),

            // 변경할 비밀번호 입력
            SizedBox(
              width: double.infinity,
              child: TextField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '변경할 비밀번호',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                ),
                obscureText: true,
              ),
            ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                print('현재 비밀번호: ${_currentPasswordController.text}');
                print('변경할 비밀번호: ${_newPasswordController.text}');
                // 여기에 비밀번호 검증 및 변경 로직 추가
              },
              child: Text('비밀번호 변경'),
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

