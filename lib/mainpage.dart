import 'package:flutter/material.dart';
import 'mainpage_map_group.dart';
import 'mainpage_chat_group.dart';
import 'mainpage_profile_group.dart';
import 'package:graduation_project/api_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  Map<String, dynamic>? _userProfile; // 회원 정보 저장 변수
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // 회원 정보 불러오기
  }

  // 🔹 회원 정보 불러오는 함수
  Future<void> _loadUserProfile() async {
    final apiService = ApiService();
    final profile = await apiService.fetchUserProfile();
    if (profile != null) {
      setState(() {
        _userProfile = profile; // 받아온 데이터 저장
      });
    }
  }

  // 🔹 하단 네비게이션 바에서 화면을 변경하는 함수
  void _changeClass(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('소방와방')),
      body: _currentIndex == 0
          ? MapGroup() // 지도
          : _currentIndex == 1
          ? SingleChildScrollView( // ChatGroup을 ScrollView로 감쌈
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SafeRegionSelector(),
        ),
      ) // 채팅
          : SingleChildScrollView( // ProfileGroup을 ScrollView로 감쌈
        child: ProfileGroup(
          name: _userProfile?['userName'] ?? '이름 없음',
          phoneNumber: _userProfile?['userNum'] ?? '번호 없음',
          id: _userProfile?['userId'] ?? '아이디 없음',
          apiService: apiService, // 의존성 주입
        ),
      ), // 프로필
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.map), label: '지도'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: '채팅'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
        ],
        currentIndex: _currentIndex,
        onTap: _changeClass,
      ),
    );
  }
}
