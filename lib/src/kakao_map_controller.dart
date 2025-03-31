import 'dart:convert';
import 'package:graduation_project/src/model/lat_lng.dart';
import 'package:webview_flutter/webview_flutter.dart';

class KakaoMapController {
  final Future<WebViewController> _webViewControllerFuture;

  KakaoMapController(this._webViewControllerFuture);

  Future<void> clear() async {
    final webViewController = await _webViewControllerFuture;
    await webViewController.runJavaScript('clear();');
  }

  Future<void> fitBounds(List<LatLng> points) async {
    final webViewController = await _webViewControllerFuture;
    await webViewController.runJavaScript("fitBounds('${jsonEncode(points)}');");
  }

  /* 카메라 이동 기능을 추가 - (삭제 해도 상관 없음)
  Future<void> moveCamera(LatLng latLng, {int zoomLevel = 0}) async {
    final webViewController = await _webViewControllerFuture;
    await webViewController.runJavaScript('moveCamera(${latLng.latitude}, ${latLng.longitude}, $zoomLevel);');
  }
   */
}
