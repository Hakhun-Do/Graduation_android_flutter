import 'package:flutter/material.dart';

class ProfileGroup extends StatelessWidget {
  final String name;
  final String phoneNumber;
  final String id;

  const ProfileGroup(
      {super.key,
      required this.name,
      required this.phoneNumber,
      required this.id});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft, // 왼쪽 정렬
      padding: EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey,
          ),
          SizedBox(height: 20),
          Text(
            '소방공무원',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text('이름: $name'),
          SizedBox(height: 10),
          Text('전화번호: $phoneNumber'),
          SizedBox(height: 20),
          Text('계정', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text('아이디: $id'),
          SizedBox(height: 10),
          Column(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/c');
                },
                child: Text('비밀번호 변경'),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/i');
                },
                child: Text('관할 구역 지정'),
              ),
              SizedBox(height: 20),
            ],
          ),
          Text('설정', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Column(
            children: [
              TextButton(
                onPressed: () {},
                child: Text('로그아웃'),
              ),
              SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }
}
