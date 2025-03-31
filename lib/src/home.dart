import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:graduation_project/src/kakao_map_controller.dart';
import 'package:graduation_project/src/kakao_map.dart';
import 'package:graduation_project/src/model/lat_lng.dart';

import 'package:webview_flutter/webview_flutter.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  KakaoMapController? _kakaoMapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          KakaoMap(
            onMapCreated: (KakaoMapController controller) {
              _kakaoMapController = controller;
            },
            onMapTap: (LatLng latLng) {
              print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
              print("${jsonEncode(latLng)}");
              print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
            },
            onCameraIdle: (LatLng latLng, int zoomLevel) {
              print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
              print("${jsonEncode(latLng)}");
              print("zoomLevel : $zoomLevel");
              print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
            },
            onZoomChanged: (int zoomLevel) {
              print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
              print("zoomLevel : $zoomLevel");
              print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
            },
          ),
        ],
      ),
    );
  }

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

}
