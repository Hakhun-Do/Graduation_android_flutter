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
  final WebViewController? webViewController;

  KakaoMap({
    Key? key,
    this.onMapCreated,
    this.onMapTap,
    this.onCameraIdle,
    this.onZoomChanged,
    this.webViewController,
  }) : super(key: key);

  @override
  State<KakaoMap> createState() => _KakaoMapState();
}

class _KakaoMapState extends State<KakaoMap> {
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();

    _webViewController = widget.webViewController ??
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..addJavaScriptChannel(
            'flutterWebViewReady',
            onMessageReceived: (JavaScriptMessage message) {
              print('✅ JS 로딩 완료 수신: ${message.message}');
            },
          )
          ..setBackgroundColor(Colors.transparent)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (String url) async {
                final mapController =
                KakaoMapController(Future.value(_webViewController));
                await Future.delayed(Duration(seconds: 1));
                if (widget.onMapCreated != null) {
                  widget.onMapCreated!(mapController);
                }
              },
            ),
          )
          ..loadRequest(
            Uri.parse('http://localhost:8080/assets/web/kakaomap.html'),
          );

  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(
      controller: _webViewController,
    );
  }
}
