import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graduation_project/src/kakao_map_controller.dart';
import 'package:graduation_project/src/kakao_map.dart';
import 'package:graduation_project/src/model/lat_lng.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapGroup extends StatefulWidget {
  const MapGroup({super.key});

  @override
  _MapGroupState createState() => _MapGroupState();
}

class _MapGroupState extends State<MapGroup> {
  KakaoMapController? _kakaoMapController;
  LatLng? _lastLatLng;
  int _lastZoomLevel = 0;

  late final WebViewController _webViewController;

  String? _selectedCity;
  String? _selectedTown;
  String? _selectedDistrict;

  bool _mapReady = false;

  final Map<String, Map<String, List<String>>> regionMap = {
    '강원특별자치도': {
      '춘천시': ['신북읍', '남산면', '동내면'],
      '원주시': ['단구동', '무실동', '태장동'],
    },
    // 필요한 다른 지역 추가 가능
  };

  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController()
      ..addJavaScriptChannel(
        'flutterWebViewReady',
        onMessageReceived: (JavaScriptMessage message) {
          print('✅ JS → Flutter 메시지 수신됨: ${message.message}');
          setState(() {
            _mapReady = true;
          });
        },
      )
      ..addJavaScriptChannel(
        'cameraIdle',
        onMessageReceived: (JavaScriptMessage message) {
          print('📸 JS → Flutter: cameraIdle → ${message.message}');
          final data = jsonDecode(message.message);
          _lastLatLng = LatLng(data['latitude'], data['longitude']);
          _lastZoomLevel = data['zoomLevel'];
        },
      )
      ..addJavaScriptChannel(
        'onMapTap',
        onMessageReceived: (JavaScriptMessage message) {
          print('📍 JS → Flutter: onMapTap → ${message.message}');
        },
      );
  }

  Future<void> _initLocationAndMoveCamera() async {
    try {
      Position position = await _determinePosition();
      if (_kakaoMapController != null) {
        _kakaoMapController!.moveCamera(
          LatLng(position.latitude, position.longitude),
          zoomLevel: 3,
        );
        print('✅ 현재 위치로 카메라 이동');
      }
    } catch (e) {
      print("❌ 위치 정보를 가져오는 중 오류 발생: $e");
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
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
        _buildDropdowns(),
        Expanded(
          child: KakaoMap(
            onMapCreated: (KakaoMapController controller) {
              _kakaoMapController = controller;
              print('✅ 지도 컨트롤러 할당 완료');
              _initLocationAndMoveCamera();
            },
            onMapTap: (LatLng latLng) {
              print("📍 맵 탭: ${jsonEncode(latLng)}");
            },
            onCameraIdle: (LatLng latLng, int zoomLevel) {
              print("📸 카메라 이동 완료: ${jsonEncode(latLng)}, 줌 레벨: $zoomLevel");
            },
            onZoomChanged: (int zoomLevel) {
              print("🔍 줌 변경: $zoomLevel");
            },
            webViewController: _webViewController,
          ),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _mapReady = true;
            });
            print("🔧 강제 지도 로딩 완료 처리");
          },
          child: Text("지도 로딩 완료 버튼"),
        ),
      ],
    );
  }

  Widget _buildDropdowns() {
    final cityList = regionMap.keys.toList();
    final townList = _selectedCity != null ? regionMap[_selectedCity!]!.keys.toList() : [];
    final districtList = (_selectedCity != null && _selectedTown != null)
        ? regionMap[_selectedCity!]![_selectedTown!] ?? []
        : [];

    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: '시/도 선택',
              border: OutlineInputBorder(),
              helperText: _mapReady ? null : '지도가 로딩될 때까지 기다려 주세요',
            ),
            value: _selectedCity,
            items: cityList
                .map((city) => DropdownMenuItem<String>(
              value: city,
              child: Text(city),
            ))
                .toList(),
            onChanged: _mapReady
                ? (value) {
              setState(() {
                _selectedCity = value;
                _selectedTown = null;
                _selectedDistrict = null;
              });
            }
                : null,
          ),
          const SizedBox(height: 10),
          if (_selectedCity != null)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: '시/군 선택', border: OutlineInputBorder()),
              value: _selectedTown,
              items: townList
                  .map((town) => DropdownMenuItem<String>(
                value: town,
                child: Text(town),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTown = value;
                  _selectedDistrict = null;
                });
              },
            ),
          const SizedBox(height: 10),
          if (_selectedTown != null)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: '구/읍/면 선택', border: OutlineInputBorder()),
              value: _selectedDistrict,
              items: districtList
                  .map((district) => DropdownMenuItem<String>(
                value: district,
                child: Text(district),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDistrict = value;
                  if (!_mapReady) {
                    print("⏳ 지도가 아직 준비되지 않았습니다");
                  } else if (_kakaoMapController == null) {
                    print("⏳ 지도 컨트롤러가 아직 준비되지 않았습니다");
                  } else if (_selectedDistrict == null) {
                    print("⛔️ 행정동(구/읍/면)이 아직 선택되지 않았습니다");
                  } else {
                    final keyword = "$_selectedCity $_selectedTown $_selectedDistrict";
                    print("🔍 검색 실행: $keyword");
                    _kakaoMapController!.evalJavascript(
                      'searchKeywordFlutterBridge.postMessage("$keyword");',
                    );
                  }
                });
              },
            ),
        ],
      ),
    );
  }
}
