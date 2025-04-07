import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graduation_project/src/kakao_map_controller.dart';
import 'package:graduation_project/src/kakao_map.dart';
import 'package:graduation_project/src/model/lat_lng.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart'; // WebViewController 관련

class MapGroup extends StatefulWidget {
  const MapGroup({super.key});

  @override
  _MapGroupState createState() => _MapGroupState();
}

class _MapGroupState extends State<MapGroup> {
  final TextEditingController _searchController = TextEditingController();
  KakaoMapController? _kakaoMapController;
  LatLng? _lastLatLng;
  int _lastZoomLevel = 0;

  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();

    // ✅ WebView에서 'flutterWebViewReady' 채널을 통해 JS 초기화 완료 신호를 받을 때 처리
    _webViewController = WebViewController()
      ..addJavaScriptChannel(
        'flutterWebViewReady',
        onMessageReceived: (JavaScriptMessage message) {
          print('웹뷰 로딩 완료 메시지 수신: ${message.message}');
          _kakaoMapController?.evalJavascript(
            'searchKeywordFlutterBridge.postMessage("암사역");',
          );
        },
      );

  }

  Future<void> _initLocationAndMoveCamera() async {
    try {
      Position position = await _determinePosition();
      print("현재 위치: ${position.latitude}, ${position.longitude}");

      if (_kakaoMapController != null) {
        _kakaoMapController!.moveCamera(
          LatLng(position.latitude, position.longitude),
          zoomLevel: 3,
        );
      }
    } catch (e) {
      print("위치 정보를 가져오는 중 오류 발생: $e");
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                child: KakaoMap(
                  onMapCreated: (KakaoMapController controller) {
                    _kakaoMapController = controller;
                    _initLocationAndMoveCamera();
                  },
                  onMapTap: (LatLng latLng) {
                    print("맵 탭: ${jsonEncode(latLng)}");
                  },
                  onCameraIdle: (LatLng latLng, int zoomLevel) {
                    print("카메라 이동 완료: ${jsonEncode(latLng)}, 줌 레벨: $zoomLevel");
                  },
                  onZoomChanged: (int zoomLevel) {
                    print("줌 변경: $zoomLevel");
                  },
                  webViewController: _webViewController, // ✅ WebViewController 전달
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: '검색어를 입력하세요',
          suffixIcon: IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              final keyword = _searchController.text.trim();
              if (keyword.isNotEmpty && _kakaoMapController != null) {
                print("검색 실행: $keyword");
                _kakaoMapController!.evalJavascript(
                  'searchKeywordFlutterBridge.postMessage("$keyword");',
                );
              }
            },
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
