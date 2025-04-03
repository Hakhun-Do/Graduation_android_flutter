import 'package:flutter/material.dart';
import 'package:graduation_project/api_service.dart';

class ProfileGroup extends StatelessWidget {
  final String name;
  final String phoneNumber;
  final String id;
  final ApiService apiService;

  const ProfileGroup({
    super.key,
    required this.name,
    required this.phoneNumber,
    required this.id,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '소방공무원',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text('이름: $name'),
          const SizedBox(height: 10),
          Text('전화번호: $phoneNumber'),
          const SizedBox(height: 20),
          const Text('계정', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text('아이디: $id'),
          const SizedBox(height: 10),
          _buildActionButtons(context),
          const SizedBox(height: 20),
          const Text('설정', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/c'),
          child: const Text('비밀번호 변경'),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/i'),
          child: const Text('관할 구역 지정'),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return TextButton(
      onPressed: () async {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
        await apiService.logout();
      },
      child: const Text('로그아웃'),
    );
  }
}
