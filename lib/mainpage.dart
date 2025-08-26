import 'package:flutter/material.dart';
import 'mainpage_map_group.dart';
import 'mainpage_chat_group.dart';
import 'mainpage_profile_group.dart';
import 'package:graduation_project/api_service.dart';

// mainpage.dart
class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {

  final GlobalKey<MapGroupState> _mapKey = GlobalKey<MapGroupState>();

  int _currentIndex = 0;
  Map? _userProfile;
  double? _moveLat;
  double? _moveLon;
  final ApiService apiService = ApiService();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();

    _pages = [
      MapGroup(
        key: _mapKey,
        initialLat: _moveLat,
        initialLon: _moveLon,
      ), // 지도
      RegionSelector(
        onMoveToMap: () => _changeClass(0),
        onMapMove: (lat, lon) {
          print('Before setState: _moveLat=$_moveLat, _moveLon=$_moveLon');
          print('onMapMove called with lat=$lat, lon=$lon');
          setState(() {
            _moveLat = lat;
            _moveLon = lon;
            _currentIndex = 0; // 지도 탭으로 전환
          });
          print('After setState: _moveLat=$_moveLat, _moveLon=$_moveLon');
          _mapKey.currentState?.moveMap(lat, lon);
        },
      ),

      ProfileGroup(
        name: _userProfile?['userName'] ?? '이름 없음',
        phoneNumber: _userProfile?['userNum'] ?? '번호 없음',
        id: _userProfile?['userId'] ?? '아이디 없음',
        apiService: apiService,
      ),
    ];
  }

  Future _loadUserProfile() async {
    final profile = await apiService.fetchUserProfile();
    if (profile != null) {
      setState(() {
        _userProfile = profile;
        _pages[2] = ProfileGroup(
          name: _userProfile?['userName'] ?? '이름 없음',
          phoneNumber: _userProfile?['userNum'] ?? '번호 없음',
          id: _userProfile?['userId'] ?? '아이디 없음',
          apiService: apiService,
        );
      });
    }
  }

  void _changeClass(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('소방와방')),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
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
