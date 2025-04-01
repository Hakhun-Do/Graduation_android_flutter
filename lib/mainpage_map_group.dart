import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:graduation_project/src/kakao_map_controller.dart';
import 'package:graduation_project/src/kakao_map.dart';
import 'package:graduation_project/src/model/lat_lng.dart';

class MapGroup extends StatefulWidget {
  const MapGroup({super.key});

  @override
  _MapGroupState createState() => _MapGroupState();
}

class _MapGroupState extends State<MapGroup> {
  KakaoMapController? _kakaoMapController;
  LatLng? _lastLatLng; // 마지막 위치 저장
  int _lastZoomLevel = 0; // 마지막 줌 레벨 저장

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
                    /* 초기 위치로 카메라 이동 (첫 로딩 시 위치를 설정할 경우) - (삭제 해도 상관 없음)
                    if (_lastLatLng != null && _lastZoomLevel > 0) {
                      _kakaoMapController?.moveCamera(
                        _lastLatLng!, // `LatLng` 객체를 바로 사용
                        zoomLevel: _lastZoomLevel,
                      );
                    }
                     */
                  },
                  onMapTap: (LatLng latLng) {
                    print("맵 탭: ${jsonEncode(latLng)}");
                  },
                  onCameraIdle: (LatLng latLng, int zoomLevel) {
                    print("카메라 이동 완료: ${jsonEncode(latLng)}, 줌 레벨: $zoomLevel"); // 카메라가 이동을 완료했을 때 호출되는 이벤트
                    /* 마지막 위치와 줌 레벨을 저장 - (삭제 해도 상관 없음)
                    setState(() {
                      _lastLatLng = latLng;
                      _lastZoomLevel = zoomLevel;
                    });
                     */
                  },
                  onZoomChanged: (int zoomLevel) {
                    print("줌 변경: $zoomLevel");
                  },
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
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: '검색',
          suffixIcon: IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // 검색 기능 구현
              print("검색 버튼 눌림");
            },
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  // 아래 기능은 현재 사용하지 않는 부가적인 코드(샘플 코드에서 사용된 코드)
  /*
  _clear() {
    _kakaoMapController?.clear();
  }

  List<LatLng> createOuterBounds() {
    double delta = 0.01;

    List<LatLng> list = [];

    list.add(LatLng(90 - delta, -180 + delta));
    list.add(LatLng(0, -180 + delta));
    list.add(LatLng(-90 + delta, -180 + delta));
    list.add(LatLng(-90 + delta, 0));
    list.add(LatLng(-90 + delta, 180 - delta));
    list.add(LatLng(0, 180 - delta));
    list.add(LatLng(90 - delta, 180 - delta));
    list.add(LatLng(90 - delta, 0));
    list.add(LatLng(90 - delta, -180 + delta));

    return list;
  }

  fitBounds(List<LatLng> bounds) async {
    _kakaoMapController?.fitBounds(bounds);
  }
   */
}
