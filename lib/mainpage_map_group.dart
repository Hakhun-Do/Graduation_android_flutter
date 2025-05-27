import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graduation_project/src/kakao_map_controller.dart';
import 'package:graduation_project/src/kakao_map.dart';
import 'package:graduation_project/src/model/lat_lng.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:graduation_project/api_data.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';


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

  bool _mapReady = true;
  bool _isPanelExpanded = true;

  final Map<String, Map<String, List<String>>> regionMap = {
    '서울특별시': {
      '종로구': ['사직동'],
    },
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
      )
      ..addJavaScriptChannel(
        'searchResultBridge',
        onMessageReceived: (JavaScriptMessage message) {
          final data = jsonDecode(message.message);
          if (data['success'] == true) {
            print('🔍 검색 성공: ${data['count']}개 결과');
          } else {
            print('❌ 검색 실패');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('검색 결과가 없습니다.')),
            );
          }
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
      }
    } catch (e) {
      print("❌ 위치 정보를 가져오는 중 오류 발생: $e");
    }
  }

  Future<void> _moveToMyLocation() async {
    try {
      Position position = await _determinePosition();
      if (_kakaoMapController != null) {
        _kakaoMapController!.moveCamera(
          LatLng(position.latitude, position.longitude),
          zoomLevel: 3,
        );
      }
      await _webViewController.runJavaScript(
        'panTo(${position.latitude}, ${position.longitude});',
      );

      // 카카오 맵 api의 좌표를 주소로 변환해 주는 기능 요청하는 함수
      Future<Map<String, String>> getAddressFromCoordinates(double lat, double lng) async {
        const String kakaoApiKey = '206075c96a586adaec930981a17a3668';
        final url = Uri.parse('https://dapi.kakao.com/v2/local/geo/coord2regioncode.json?x=$lng&y=$lat');

        final response = await http.get(
          url,
          headers: {
            'Authorization': 'KakaoAK $kakaoApiKey',
            'KA': 'sdk/1.0.0 os/android lang/ko-KR device/myApp', // 최소한 이 형식 유지
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final regionInfo = data['documents'][0];
          final city = regionInfo['region_1depth_name'];
          final town = regionInfo['region_2depth_name'];
          print('✅ GPS 좌표 주소 변환 결과 값 : $regionInfo');
          return {
            'city': city,
            'town': town,
          };
        } else {
          throw Exception('주소 변환 실패: ${response.body}');
        }
      }

      // gps 이동후 해당 지역 마커 표시
      // 좌표로 변환 받은
      final addressInfo = await getAddressFromCoordinates(position.latitude, position.longitude);

      _selectedCity = addressInfo['city'];
      _selectedTown = addressInfo['town'];

      // 2. ✅ 기존 마커 제거 (JS 함수 호출)
      await _kakaoMapController!.evalJavascript('clear();');

      // Future 객체들을 변수로 준비
      final Future<List<Map<String, dynamic>>> hydrantFuture =
      FireHydrantService().fetchHydrantData(
        ctprvnNm: _selectedCity!,
        signguNm: _selectedTown,
      ); // 소방용수시설

      final Future<List<Map<String, dynamic>>> truckFuture =
      FireTruckZoneService().fetchFireTruckZones(
        ctprvnNm: _selectedCity!,
        signguNm: _selectedTown,
      ); // 소방차전용구역

      final Future<List<Map<String, dynamic>>> problemFuture =
      ProblemMarkerService().fetchProblemData(
        ctprvnNm: _selectedCity!,
        signguNm: _selectedTown,
      ); // 통행불가

      final Future<List<Map<String, dynamic>>> breakdownFuture =
      BreakdownMarkerService().fetchBreakdownData(
        ctprvnNm: _selectedCity!,
        signguNm: _selectedTown,
      ); // 고장, 이상

      final Future<List<Map<String, dynamic>>> hydrantAddFuture =
      HydrantAddMarkerService().fetchHydrantAddData(
        ctprvnNm: _selectedCity!,
        signguNm: _selectedTown,
      ); // 소방용수시설 추가

      final Future<List<Map<String, dynamic>>> truckAddFuture =
      TruckAddMarkerService().fetchTruckAddData(
        ctprvnNm: _selectedCity!,
        signguNm: _selectedTown,
      ); // 소방차전용구역 추가

      // 여기서 Future 객체들을 동시에 실행
      final results = await Future.wait([
        hydrantFuture,
        truckFuture,
        problemFuture,
        breakdownFuture,
        hydrantAddFuture,
        truckAddFuture,
      ]);

      // 결과 꺼내기
      final hydrantData = results[0];
      final truckData = results[1];
      final problemData = results[2];
      final breakdownData = results[3];
      final hydrantAddData = results[4];
      final truckAddData = results[5];

      // 필터링은 UI thread에서 너무 오래 걸리지 않게 간단 처리
      final hydrantMarkers = hydrantData.map((hydrant) {
        final lat = double.tryParse(hydrant['latitude']?.toString() ?? '');
        final lng = double.tryParse(hydrant['longitude']?.toString() ?? '');
        final address = hydrant['rdnmadr'] ?? '위치 정보 없음';
        if (lat != null && lng != null) {
          return {
            'latitude': lat,
            'longitude': lng,
            'address': address,
            'type': 'hydrant',
          };
        }
        return null;
      }).whereType<Map<String, dynamic>>().toList();

      final truckMarkers = truckData.map((zone) {
        final lat = double.tryParse(zone['latitude']?.toString() ?? '');
        final lng = double.tryParse(zone['longitude']?.toString() ?? '');
        final address = zone['lnmadr'] ?? '위치 정보 없음';
        if (lat != null && lng != null) {
          return {
            'latitude': lat,
            'longitude': lng,
            'address': address,
            'type': 'firetruck',
          };
        }
        return null;
      }).whereType<Map<String, dynamic>>().toList();

      final problemMarkers = problemData.map((zone) {
        final lat = double.tryParse(zone['id']?['lat']?.toString() ?? '');
        final lng = double.tryParse(zone['id']?['lon']?.toString() ?? '');
        //final address = zone['lnmadr'] ?? '위치 정보 없음';
        if (lat != null && lng != null) {
          return {
            'latitude': lat,
            'longitude': lng,
            //'address': address,
            'type': 'problem',
          };
        }
        return null;
      }).whereType<Map<String, dynamic>>().toList();

      final breakdownMarkers = breakdownData.map((zone) {
        final lat = double.tryParse(zone['id']?['lat']?.toString() ?? '');
        final lng = double.tryParse(zone['id']?['lon']?.toString() ?? '');
        //final address = zone['lnmadr'] ?? '위치 정보 없음';
        if (lat != null && lng != null) {
          return {
            'latitude': lat,
            'longitude': lng,
            //'address': address,
            'type': 'breakdown',
          };
        }
        return null;
      }).whereType<Map<String, dynamic>>().toList();

      final hydrantAddMarkers = hydrantAddData.map((zone) {
        final lat = double.tryParse(zone['id']?['lat']?.toString() ?? '');
        final lng = double.tryParse(zone['id']?['lon']?.toString() ?? '');
        //final address = zone['lnmadr'] ?? '위치 정보 없음';
        if (lat != null && lng != null) {
          return {
            'latitude': lat,
            'longitude': lng,
            //'address': address,
            'type': 'hydrantAdd',
          };
        }
        return null;
      }).whereType<Map<String, dynamic>>().toList();

      final truckAddMarkers = truckAddData.map((zone) {
        final lat = double.tryParse(zone['id']?['lat']?.toString() ?? '');
        final lng = double.tryParse(zone['id']?['lon']?.toString() ?? '');
        //final address = zone['lnmadr'] ?? '위치 정보 없음';
        if (lat != null && lng != null) {
          return {
            'latitude': lat,
            'longitude': lng,
            //'address': address,
            'type': 'truckAdd',
          };
        }
        return null;
      }).whereType<Map<String, dynamic>>().toList();

      final allMarkers = [...hydrantMarkers, ...truckMarkers, ...problemMarkers, ...breakdownMarkers, ...hydrantAddMarkers, ...truckAddMarkers,];

      final js = '''
                    addMarkersFromList(${jsonEncode(allMarkers)});
                  ''';

      try {
        print("🧪 마커 JS 전송: ${js.substring(0, 300)}...");
        await _kakaoMapController!.evalJavascript(js);
      } catch (e) {
        print("❌ JS 실행 오류: $e");
      }

    } catch (e) {
      print("❌ 내 위치로 이동 중 오류 발생: $e");
    }
  }

  Future<void> showHydrantOverlay({
    required double lat,
    required double lng,
    required String htmlContent,
  }) async {
    final js = '''
      hydrantOverlay(${lat}, ${lng}, "${htmlContent.replaceAll('"', '\\"')}");
    ''';
    await _webViewController.runJavaScript(js);
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
            isExpanded: true,
            decoration: InputDecoration(
              labelText: '시/도 선택',
              border: OutlineInputBorder(),
              helperText: _mapReady ? null : '지도가 로딩될 때까지 기다려 주세요',
            ),
            value: _selectedCity,
            items: cityList.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
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
              isExpanded: true,
              decoration: const InputDecoration(labelText: '시/군 선택', border: OutlineInputBorder()),
              value: _selectedTown,
              items: townList.map<DropdownMenuItem<String>>((town) => DropdownMenuItem<String>(
                value: town,
                child: Text(town),
              )).toList(),
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
              isExpanded: true,
              decoration: const InputDecoration(labelText: '구/읍/면 선택', border: OutlineInputBorder()),
              value: _selectedDistrict,
              items: districtList.map<DropdownMenuItem<String>>((district) => DropdownMenuItem<String>(
                value: district,
                child: Text(district),
              )).toList(),
              onChanged: (value) async {
                setState(() {
                  _selectedDistrict = value;
                });

                if (_mapReady && _kakaoMapController != null && _selectedCity != null && _selectedTown != null) {
                  final keyword = "$_selectedCity $_selectedTown $_selectedDistrict";
                  print("🔍 검색 실행: $keyword");

                  // 1. Flutter → JS 검색 (기존)
                  _kakaoMapController!.evalJavascript(
                    'searchKeywordFlutterBridge.postMessage("$keyword");',
                  );

                  // 2. ✅ 기존 마커 제거 (JS 함수 호출)
                  await _kakaoMapController!.evalJavascript('clear();');

                  // Future 객체들을 변수로 준비
                  final Future<List<Map<String, dynamic>>> hydrantFuture =
                  FireHydrantService().fetchHydrantData(
                    ctprvnNm: _selectedCity!,
                    signguNm: _selectedTown,
                  ); // 소방용수시설

                  final Future<List<Map<String, dynamic>>> truckFuture =
                  FireTruckZoneService().fetchFireTruckZones(
                    ctprvnNm: _selectedCity!,
                    signguNm: _selectedTown,
                  ); // 소방차전용구역

                  final Future<List<Map<String, dynamic>>> problemFuture =
                  ProblemMarkerService().fetchProblemData(
                    ctprvnNm: _selectedCity!,
                    signguNm: _selectedTown,
                  ); // 통행불가

                  final Future<List<Map<String, dynamic>>> breakdownFuture =
                  BreakdownMarkerService().fetchBreakdownData(
                    ctprvnNm: _selectedCity!,
                    signguNm: _selectedTown,
                  ); // 고장, 이상

                  final Future<List<Map<String, dynamic>>> hydrantAddFuture =
                  HydrantAddMarkerService().fetchHydrantAddData(
                    ctprvnNm: _selectedCity!,
                    signguNm: _selectedTown,
                  ); // 소방용수시설 추가

                  final Future<List<Map<String, dynamic>>> truckAddFuture =
                  TruckAddMarkerService().fetchTruckAddData(
                    ctprvnNm: _selectedCity!,
                    signguNm: _selectedTown,
                  ); // 소방차전용구역 추가

                  // 여기서 Future 객체들을 동시에 실행
                  final results = await Future.wait([
                    hydrantFuture,
                    truckFuture,
                    problemFuture,
                    breakdownFuture,
                    hydrantAddFuture,
                    truckAddFuture,
                  ]);

                  // 결과 꺼내기
                  final hydrantData = results[0];
                  final truckData = results[1];
                  final problemData = results[2];
                  final breakdownData = results[3];
                  final hydrantAddData = results[4];
                  final truckAddData = results[5];

                  // 필터링은 UI thread에서 너무 오래 걸리지 않게 간단 처리
                  final hydrantMarkers = hydrantData.map((hydrant) {
                    final lat = double.tryParse(hydrant['latitude']?.toString() ?? '');
                    final lng = double.tryParse(hydrant['longitude']?.toString() ?? '');
                    final address = hydrant['rdnmadr'] ?? '위치 정보 없음';
                    if (lat != null && lng != null) {
                      return {
                        'latitude': lat,
                        'longitude': lng,
                        'address': address,
                        'type': 'hydrant',
                      };
                    }
                    return null;
                  }).whereType<Map<String, dynamic>>().toList();

                  final truckMarkers = truckData.map((zone) {
                    final lat = double.tryParse(zone['latitude']?.toString() ?? '');
                    final lng = double.tryParse(zone['longitude']?.toString() ?? '');
                    final address = zone['lnmadr'] ?? '위치 정보 없음';
                    if (lat != null && lng != null) {
                      return {
                        'latitude': lat,
                        'longitude': lng,
                        'address': address,
                        'type': 'firetruck',
                      };
                    }
                    return null;
                  }).whereType<Map<String, dynamic>>().toList();

                  final problemMarkers = problemData.map((zone) {
                    final lat = double.tryParse(zone['id']?['lat']?.toString() ?? '');
                    final lng = double.tryParse(zone['id']?['lon']?.toString() ?? '');
                    //final address = zone['lnmadr'] ?? '위치 정보 없음';
                    if (lat != null && lng != null) {
                      return {
                        'latitude': lat,
                        'longitude': lng,
                        //'address': address,
                        'type': 'problem',
                      };
                    }
                    return null;
                  }).whereType<Map<String, dynamic>>().toList();

                  final breakdownMarkers = breakdownData.map((zone) {
                    final lat = double.tryParse(zone['id']?['lat']?.toString() ?? '');
                    final lng = double.tryParse(zone['id']?['lon']?.toString() ?? '');
                    //final address = zone['lnmadr'] ?? '위치 정보 없음';
                    if (lat != null && lng != null) {
                      return {
                        'latitude': lat,
                        'longitude': lng,
                        //'address': address,
                        'type': 'breakdown',
                      };
                    }
                    return null;
                  }).whereType<Map<String, dynamic>>().toList();

                  final hydrantAddMarkers = hydrantAddData.map((zone) {
                    final lat = double.tryParse(zone['id']?['lat']?.toString() ?? '');
                    final lng = double.tryParse(zone['id']?['lon']?.toString() ?? '');
                    //final address = zone['lnmadr'] ?? '위치 정보 없음';
                    if (lat != null && lng != null) {
                      return {
                        'latitude': lat,
                        'longitude': lng,
                        //'address': address,
                        'type': 'hydrantAdd',
                      };
                    }
                    return null;
                  }).whereType<Map<String, dynamic>>().toList();

                  final truckAddMarkers = truckAddData.map((zone) {
                    final lat = double.tryParse(zone['id']?['lat']?.toString() ?? '');
                    final lng = double.tryParse(zone['id']?['lon']?.toString() ?? '');
                    //final address = zone['lnmadr'] ?? '위치 정보 없음';
                    if (lat != null && lng != null) {
                      return {
                        'latitude': lat,
                        'longitude': lng,
                        //'address': address,
                        'type': 'truckAdd',
                      };
                    }
                    return null;
                  }).whereType<Map<String, dynamic>>().toList();

                  final allMarkers = [...hydrantMarkers, ...truckMarkers, ...problemMarkers, ...breakdownMarkers, ...hydrantAddMarkers, ...truckAddMarkers,];

                  final js = '''
                    addMarkersFromList(${jsonEncode(allMarkers)});
                  ''';

                  try {
                    print("🧪 마커 JS 전송: ${js.substring(0, 300)}...");
                    await _kakaoMapController!.evalJavascript(js);
                  } catch (e) {
                    print("❌ JS 실행 오류: $e");
                  }
                }
              },

            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: KakaoMap(
            onMapCreated: (controller) {
              _kakaoMapController = controller;
              _initLocationAndMoveCamera();
            },
            onMapTap: (latLng) => print("📍 맵 탭: ${jsonEncode(latLng)}"),
            onCameraIdle: (latLng, zoomLevel) => print("📸 카메라 이동 완료: ${jsonEncode(latLng)}, 줌 레벨: $zoomLevel"),
            onZoomChanged: (zoomLevel) => print("🔍 줌 변경: $zoomLevel"),
            webViewController: _webViewController,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: SafeArea(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: _isPanelExpanded ? 270 : 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black26)],
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  IconButton(
                    icon: Icon(_isPanelExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                    onPressed: () => setState(() => _isPanelExpanded = !_isPanelExpanded),
                  ),
                  if (_isPanelExpanded)
                    Expanded(child: SingleChildScrollView(child: _buildDropdowns())),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 30,
          right: 20,
          child: FloatingActionButton(
            heroTag: 'moveToMyLocation',
            onPressed: _moveToMyLocation,
            child: Icon(Icons.my_location),
            tooltip: '내 위치로 이동',
          ),
        ),
      ],
    );
  }
}
