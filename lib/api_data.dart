import 'dart:convert';
import 'package:http/http.dart' as http;

class FireHydrantService {
  final String serviceKey = 'YkMXpzQvOLzoDr/jU/BxsEQiP7tB7RhprJlYxd2Q3+8jLcGlXSIUhXJkLOzu7/2iOoB6+7pFJ34b2Bx2mOodVw==';

  Future<List<Map<String, dynamic>>> fetchHydrantData({
    int page = 1,
    int numOfRows = 100,
  }) async {
    final baseUrl = 'http://api.data.go.kr/openapi/tn_pubr_public_ffus_wtrcns_api';

    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      'serviceKey': serviceKey,
      'pageNo': '$page',
      'numOfRows': '$numOfRows',
      'type': 'json', // JSON 형식 요청
    });

    try {
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        final items = jsonBody['response']['body']['items'] as List;
        return items.cast<Map<String, dynamic>>();
      } else {
        print('❌ 서버 응답 오류: ${response.statusCode}');
        print('본문: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ 예외 발생: $e');
      return [];
    }
  }
}
