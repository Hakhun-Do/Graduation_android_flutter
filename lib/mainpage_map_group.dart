import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:graduation_project/src/kakao_map_controller.dart';
import 'package:graduation_project/src/kakao_map.dart';
import 'package:graduation_project/src/model/lat_lng.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:graduation_project/api_data.dart';
import 'region_data.dart';
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
        'flutterClickMarker',
        onMessageReceived: (JavaScriptMessage message) async {
          final data = jsonDecode(message.message);
          final lat = data['latitude'];
          final lng = data['longitude'];

          final add = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('이 위치에 마커를 추가하시겠습니까?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text('취소')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: Text('추가')),
              ],
            ),
          );

          if (add != true) return;

          // 입력 받기 (카테고리 + 코멘트)
          String? category;
          String comment = '';
          await showDialog(
            context: context,
            builder: (context) {
              final commentController = TextEditingController();
              return AlertDialog(
                title: Text('마커 정보 입력'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: '카테고리'),
                      items: [
                        DropdownMenuItem(value: '소방용수시설추가', child: Text('소방용수시설추가')),
                        DropdownMenuItem(value: '소방차전용구역추가', child: Text('소방차전용구역추가')),
                        DropdownMenuItem(value: '통행불가', child: Text('통행불가')),
                      ],
                      onChanged: (val) => category = val,
                    ),
                    TextField(
                      controller: commentController,
                      decoration: InputDecoration(labelText: '코멘트'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('취소')),
                  ElevatedButton(
                    onPressed: () {
                      comment = commentController.text;
                      Navigator.pop(context);
                    },
                    child: Text('저장'),
                  ),
                ],
              );
            },
          );

          if (category == null || comment.isEmpty) return;

          // 주소 변환
          final addressInfo = await getFullAddressFromLatLng(lat, lng);
          final ctp = addressInfo['city'] ?? '';
          final sig = addressInfo['town'] ?? '';
          final adr = addressInfo['address'] ?? '';

          // DB 저장
          final result = await ApiService().pinAdd(
            lat.toString(),
            lng.toString(),
            comment,
            ctp,
            sig,
            category!,
            adr,
          );

          if (result != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ 마커가 추가되었습니다(마커 최신화 중)")));

            final js = '''
        addMarker(null, JSON.stringify({latitude: $lat, longitude: $lng}), null, 40, 44, 0, 0, "$comment");
      ''';
            //새롭게 추가되는 마커 크기 24, 30 -> 40, 44으로 지정
            await _kakaoMapController?.evalJavascript(js);
          }

          await updateMapMarkers( // 마커 생성 함수 호출
            kakaoMapController: _kakaoMapController!,
            selectedCity: ctp,
            selectedTown: sig,
          );
        },
      )

      ..addJavaScriptChannel(
        'flutterClickMarkerFromMap',
        onMessageReceived: (JavaScriptMessage message) async {
          final data = jsonDecode(message.message);
          final lat = data['latitude'];
          final lng = data['longitude'];

          final commentController = TextEditingController();

          final addressInfo = await getFullAddressFromLatLng(lat, lng);
          final ctp = addressInfo['city'] ?? '';
          final sig = addressInfo['town'] ?? '';
          final adr = addressInfo['address'] ?? '';

          final com = await ApiService().pinAll(lat.toString(), lng.toString());
          String comment = '';

          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setState) {
                  return Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Stack(
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 10),
                              Text('코멘트', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Text(
                                '코멘트 : $com',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: commentController,
                                decoration: InputDecoration(labelText: '코멘트'),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 3,
                                children: [
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 내부 여백 줄이기
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 터치 영역 최소화
                                      minimumSize: Size(0, 32), // 버튼 높이 최소화
                                    ),
                                    onPressed: () async {
                                      // TODO: 추가 로직
                                      comment = commentController.text;
                                      final result1 = await ApiService().pinAdd(
                                        lat.toString(),
                                        lng.toString(),
                                        comment,
                                        ctp,
                                        sig,
                                        '코멘트',
                                        adr,
                                      );
                                      if (result1 != null) {ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ 마커가 추가되었습니다")));}
                                      Navigator.pop(context);
                                    },
                                    child: Text('추가'),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 내부 여백 줄이기
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 터치 영역 최소화
                                      minimumSize: Size(0, 32), // 버튼 높이 최소화
                                    ),
                                    onPressed: () async {
                                      // TODO: 수정 로직
                                      comment = commentController.text;
                                      final result2 = await ApiService().pinMod(
                                        lat.toString(),
                                        lng.toString(),
                                        comment,
                                        '코멘트',
                                      );
                                      if (result2 != null) {ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ 마커가 수정되었습니다")));}
                                      Navigator.pop(context);
                                    },
                                    child: Text('수정'),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 내부 여백 줄이기
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 터치 영역 최소화
                                      minimumSize: Size(0, 32), // 버튼 높이 최소화
                                    ),
                                    onPressed: () async {
                                      // TODO: 삭제 로직
                                      comment = commentController.text;
                                      final result3 = await ApiService().pinDel(
                                        lat.toString(),
                                        lng.toString(),
                                      );
                                      if (result3) {ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ 마커가 삭제되었습니다(마커 최신화 중)")));}
                                      Navigator.pop(context);
                                      await updateMapMarkers( // 마커 생성 함수 호출
                                        kakaoMapController: _kakaoMapController!,
                                        selectedCity: ctp,
                                        selectedTown: sig,
                                      );
                                    },
                                    child: Text('삭제'),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 내부 여백 줄이기
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 터치 영역 최소화
                                      minimumSize: Size(0, 32), // 버튼 높이 최소화
                                    ),
                                    onPressed: () async {
                                      // TODO: 신고 로직
                                      comment = commentController.text;
                                      final result4 = await ApiService().pinAdd(
                                        lat.toString(),
                                        lng.toString(),
                                        comment,
                                        ctp,
                                        sig,
                                        '이상',
                                        adr,
                                      );
                                      if (result4 != null) {ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ 마커가 신고되었습니다(마커 최신화 중)")));}
                                      Navigator.pop(context);
                                      await updateMapMarkers( // 마커 생성 함수 호출
                                        kakaoMapController: _kakaoMapController!,
                                        selectedCity: ctp,
                                        selectedTown: sig,
                                      );
                                    },
                                    child: Text('신고'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(Icons.close),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
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

  Future<void> _initLocationAndMoveCamera() async {
    try {
      Position position = await _determinePosition();

      if (_kakaoMapController != null) {
        // 1. 지도를 현재 위치로 이동
        _kakaoMapController!.moveCamera(
          LatLng(position.latitude, position.longitude),
          zoomLevel: 3,
        );
      }
      // 2. 현재 위치 기반의 행정구역 정보 가져오기
      final addressInfo = await getAddressFromCoordinates(position.latitude, position.longitude);
      _selectedCity = addressInfo['city'];
      _selectedTown = addressInfo['town'];

      // 3. 해당 지역의 마커들 불러와 지도에 표시
      await updateMapMarkers(
        kakaoMapController: _kakaoMapController!,
        selectedCity: _selectedCity!,
        selectedTown: _selectedTown!,
      );
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

      // 좌표로 변환 받은
      final addressInfo = await getAddressFromCoordinates(position.latitude, position.longitude);

      _selectedCity = addressInfo['city'];
      _selectedTown = addressInfo['town'];

      await updateMapMarkers( // 마커 생성 함수 호출
        kakaoMapController: _kakaoMapController!,
        selectedCity: _selectedCity!,
        selectedTown: _selectedTown!,
      );

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

  Future<Map<String, String>> getFullAddressFromLatLng(double lat, double lng) async {
    const String kakaoApiKey = '206075c96a586adaec930981a17a3668';

    final coordToRegion = Uri.parse(
        'https://dapi.kakao.com/v2/local/geo/coord2regioncode.json?x=$lng&y=$lat');
    final coordToAddress = Uri.parse(
        'https://dapi.kakao.com/v2/local/geo/coord2address.json?x=$lng&y=$lat');

    final regionRes = await http.get(
      coordToRegion,
      headers: {
        'Authorization': 'KakaoAK $kakaoApiKey',
        'KA': 'sdk/1.0.0 os/android lang/ko-KR device/myApp',
      },
    );

    final addressRes = await http.get(
      coordToAddress,
      headers: {
        'Authorization': 'KakaoAK $kakaoApiKey',
        'KA': 'sdk/1.0.0 os/android lang/ko-KR device/myApp',
      },
    );

    if (regionRes.statusCode == 200 && addressRes.statusCode == 200) {
      final regionData = jsonDecode(regionRes.body)['documents'][0];
      final addressData = jsonDecode(addressRes.body)['documents'][0]['address'];

      final city = regionData['region_1depth_name'];
      final town = regionData['region_2depth_name'];
      final address = addressData['address_name'];

      print("✅ 좌표 주소 변환 결과: city=$city, town=$town, address=$address");

      return {
        'city': city,
        'town': town,
        'address': address,
      };
    } else {
      throw Exception(
          '주소 변환 실패\nregion: ${regionRes.body}\naddress: ${addressRes.body}');
    }
  }

  Widget _buildDropdowns() {
    final cityList = regionMap.keys.toSet().toList();
    final townList = _selectedCity != null ? regionMap[_selectedCity!]!.keys.toList() : [];
    final districtList = (_selectedCity != null && _selectedTown != null)
        ? regionMap[_selectedCity!]![_selectedTown!] ?? []
        : [];

    if (!cityList.contains(_selectedCity)) _selectedCity = null;
    if (!townList.contains(_selectedTown)) _selectedTown = null;
    if (!districtList.contains(_selectedDistrict)) _selectedDistrict = null;

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

                  await updateMapMarkers( // 마커 생성 함수 호출
                    kakaoMapController: _kakaoMapController!,
                    selectedCity: _selectedCity!,
                    selectedTown: _selectedTown!,
                  );
                }
              },

            ),
        ],
      ),
    );
  }

  // 마커 생성 함수
  Future<void> updateMapMarkers({
    required KakaoMapController kakaoMapController,
    required String selectedCity,
    required String selectedTown,
  }) async {
    try {
      // 2. ✅ 기존 마커 제거 (JS 함수 호출)
      await kakaoMapController!.evalJavascript('clear();');

      // Future 객체들을 변수로 준비
      final Future<List<Map<String, dynamic>>> hydrantFuture =
      FireHydrantService().fetchHydrantData(
        ctprvnNm: selectedCity!,
        signguNm: selectedTown,
      ); // 소방용수시설

      final Future<List<Map<String, dynamic>>> truckFuture =
      FireTruckZoneService().fetchFireTruckZones(
        ctprvnNm: selectedCity!,
        signguNm: selectedTown,
      ); // 소방차전용구역

      final Future<List<Map<String, dynamic>>> problemFuture =
      ProblemMarkerService().fetchProblemData(
        ctprvnNm: selectedCity!,
        signguNm: selectedTown,
      ); // 통행불가

      final Future<List<Map<String, dynamic>>> breakdownFuture =
      BreakdownMarkerService().fetchBreakdownData(
        ctprvnNm: selectedCity!,
        signguNm: selectedTown,
      ); // 고장, 이상

      final Future<List<Map<String, dynamic>>> hydrantAddFuture =
      HydrantAddMarkerService().fetchHydrantAddData(
        ctprvnNm: selectedCity!,
        signguNm: selectedTown,
      ); // 소방용수시설 추가

      final Future<List<Map<String, dynamic>>> truckAddFuture =
      TruckAddMarkerService().fetchTruckAddData(
        ctprvnNm: selectedCity!,
        signguNm: selectedTown,
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
        final lnmadr = hydrant['lnmadr'] ?? '-';
        final descLc = hydrant['descLc'] ?? '-';
        final prtcYn = hydrant['prtcYn'] ?? '미확인';
        final institutionNm = hydrant['institutionNm'] ?? '-';
        final institutionPhoneNumber = hydrant['institutionPhoneNumber'] ?? '-';
        final referenceDate = hydrant['referenceDate'] ?? '미등록';
        if (lat != null && lng != null) {
          return {
            'latitude': lat,
            'longitude': lng,
            'address': address,
            'type': 'hydrant',
            'lnmadr': lnmadr,
            'descLc': descLc,
            'prtcYn': prtcYn,
            'institutionNm': institutionNm,
            'institutionPhoneNumber': institutionPhoneNumber,
            'referenceDate': referenceDate,
          };
        }
        return null;
      }).whereType<Map<String, dynamic>>().toList();

      final truckMarkers = truckData.map((zone) {
        final lat = double.tryParse(zone['latitude']?.toString() ?? '');
        final lng = double.tryParse(zone['longitude']?.toString() ?? '');
        final address = zone['lnmadr'] ?? '위치 정보 없음';

        // 각 상세 필드 추출 (null이면 기본값 대입)
        final prkcmprt = zone['prkcmprt'] ?? '-';
        final copertnHouseNm = zone['copertnHouseNm'] ?? '-';
        final dongNo = zone['dongNo'] ?? '-';
        final aphusPhoneNumber = zone['aphusPhoneNumber'] ?? '-';
        final institutionNm = zone['institutionNm'] ?? '-';
        final institutionPhoneNumber = zone['institutionPhoneNumber'] ?? '-';
        final referenceDate = zone['referenceDate'] ?? '-';

        if (lat != null && lng != null) {
          return {
            'latitude': lat,
            'longitude': lng,
            'address': address,
            'type': 'firetruck',

            // 상세 필드 추가
            'lnmadr': address,
            'prkcmprt': prkcmprt,
            'copertnHouseNm': copertnHouseNm,
            'dongNo': dongNo,
            'aphusPhoneNumber': aphusPhoneNumber,
            'institutionNm': institutionNm,
            'institutionPhoneNumber': institutionPhoneNumber,
            'referenceDate': referenceDate,
          };
        }
        return null;
      }).whereType<Map<String, dynamic>>().toList();

      final problemMarkers = problemData.map((zone) {
        final lat = double.tryParse(zone['id']?['lat']?.toString() ?? '');
        final lng = double.tryParse(zone['id']?['lon']?.toString() ?? '');
        final address = zone['addr'] ?? '-';
        final category = zone['cat'] ?? '-';
        final date = zone['date'] ?? '-';
        if (lat != null && lng != null) {
          return {
            'latitude': lat,
            'longitude': lng,
            'address': address,
            'category': category,
            'date': date,
            'type': 'problem',
          };
        }
        return null;
      }).whereType<Map<String, dynamic>>().toList();

      final breakdownMarkers = breakdownData.map((zone) {
        final lat = double.tryParse(zone['id']?['lat']?.toString() ?? '');
        final lng = double.tryParse(zone['id']?['lon']?.toString() ?? '');
        final address = zone['addr'] ?? '-';
        final category = zone['cat'] ?? '-';
        final date = zone['date'] ?? '-';
        if (lat != null && lng != null) {
          return {
            'latitude': lat,
            'longitude': lng,
            'address': address,
            'category': category,
            'date': date,
            'type': 'breakdown',
          };
        }
        return null;
      }).whereType<Map<String, dynamic>>().toList();

      final hydrantAddMarkers = hydrantAddData.map((zone) {
        final lat = double.tryParse(zone['id']?['lat']?.toString() ?? '');
        final lng = double.tryParse(zone['id']?['lon']?.toString() ?? '');
        final address = zone['addr'] ?? '-';
        final category = zone['cat'] ?? '-';
        final date = zone['date'] ?? '-';
        if (lat != null && lng != null) {
          return {
            'latitude': lat,
            'longitude': lng,
            'address': address,
            'category': category,
            'date': date,
            'type': 'hydrantAdd',
          };
        }
        return null;
      }).whereType<Map<String, dynamic>>().toList();

      final truckAddMarkers = truckAddData.map((zone) {
        final lat = double.tryParse(zone['id']?['lat']?.toString() ?? '');
        final lng = double.tryParse(zone['id']?['lon']?.toString() ?? '');
        final address = zone['addr'] ?? '-';
        final category = zone['cat'] ?? '-';
        final date = zone['date'] ?? '-';
        if (lat != null && lng != null) {
          return {
            'latitude': lat,
            'longitude': lng,
            'address': address,
            'category': category,
            'date': date,
            'type': 'truckAdd',
          };
        }
        return null;
      }).whereType<Map<String, dynamic>>().toList();

      final allMarkers = [...hydrantMarkers, ...truckMarkers, ...problemMarkers, ...hydrantAddMarkers, ...truckAddMarkers, ...breakdownMarkers,];

      final js = '''
                    addMarkersFromList(${jsonEncode(allMarkers)});
                  ''';
      //addMarkersFromList : 해당 위치 마커 표시하기 위한

      try {
        print("🧪 마커 JS 전송: ${js.substring(0, 300)}...");
        await kakaoMapController!.evalJavascript(js);
      } catch (e) {
        print("❌ JS 실행 오류: $e");
      }
    } catch (e) {
      print('❌ 마커 업데이트 중 오류: $e');
    }
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
