import 'package:flutter/material.dart';

class ChatGroup extends StatelessWidget {
  final String importantGroup;
  final String frequentGroup;
  final String popularGroup;

  const ChatGroup({
    super.key,
    required this.importantGroup,
    required this.frequentGroup,
    required this.popularGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroupCard(
            icon: Icons.pin,
            title: '내가 고정한 게시글 & 게시판',
            content: importantGroup),
        SizedBox(height: 10),
        _buildGroupCard(
            icon: Icons.star, title: '내가 자주가는 게시판', content: frequentGroup),
        SizedBox(height: 10),
        _buildGroupCard(
            icon: Icons.fireplace, title: '인기 게시판', content: popularGroup),
      ],
    );
  }

  Widget _buildGroupCard(
      {required IconData icon,
      required String title,
      required String content}) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(content),
          SizedBox(height: 10),
          Text('• ~~~~~~~~~~'),
          Text('• ***********'),
          Text('• %%%%%%%%%%'),
          Text('• @@@@@@'),
        ],
      ),
    );
  }
}
