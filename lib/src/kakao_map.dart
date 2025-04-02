import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graduation_project/src/callbacks.dart';
import 'package:graduation_project/src/kakao_map_controller.dart';
import 'package:graduation_project/src/model/lat_lng.dart';
import 'package:webview_flutter/webview_flutter.dart';

class KakaoMap extends StatefulWidget {
  final MapCreateCallback? onMapCreated;
  final OnMapTap? onMapTap;
  final OnCameraIdle? onCameraIdle;
  final OnZoomChanged? onZoomChanged;

  KakaoMap({
    Key? key,
    this.onMapCreated,
    this.onMapTap,
    this.onCameraIdle,
    this.onZoomChanged,
  }) : super(key: key);

  @override
  State<KakaoMap> createState() => _KakaoMapState();
}

class _KakaoMapState extends State<KakaoMap> {
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) async {
            // ✅ WebViewController를 Future.value()로 감싸 전달
            final mapController = KakaoMapController(Future.value(_webViewController));

            // ✅ JS 초기화 기다리기 (1초 후 실행)
            await Future.delayed(Duration(seconds: 1));

            if (widget.onMapCreated != null) {
              widget.onMapCreated!(mapController);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse('http://localhost:8080/assets/web/kakaomap.html'));
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _webViewController);
  }
}
