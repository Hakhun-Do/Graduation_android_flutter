import 'package:flutter/material.dart';
import 'package:graduation_project/api_service.dart'; // ApiService import 추가

class ChangePassword extends StatelessWidget {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final ApiService apiService = ApiService(); // ApiService 인스턴스 생성

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
              onPressed: () async {
                String currentPassword = _currentPasswordController.text.trim();
                String newPassword = _newPasswordController.text.trim();

                if (currentPassword.isEmpty || newPassword.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('모든 필드를 입력하세요!')));
                  }
                  return; // 비밀번호 변경 진행 안 함
                }

                // API 호출
                Map<String, dynamic>? result = await apiService.updatePassword(
                  currentPassword,
                  newPassword,
                );

                if (context.mounted) {
                  if (result != null && result["success"] == true) {
                    // 비밀번호 변경 성공 메시지 출력
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('비밀번호가 변경되었습니다!')));
                    Navigator.pop(context); // 이전 화면으로 돌아가기
                  } else {
                    // 비밀번호 변경 실패 메시지 출력
                    String errorMessage = result != null ? result["error"] ?? "비밀번호 변경에 실패했습니다." : "비밀번호 변경에 실패했습니다.";
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMessage)),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5A5EF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text('비밀번호 변경'),
            ),
          ],
        ),
      ),
    );
  }
}
