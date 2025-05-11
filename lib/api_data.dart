import 'dart:convert';
import 'package:http/http.dart' as http;

class FireHydrantService {
  final String serviceKey = '28k6dj2VzcV4Bgng3CN931SanEKlVifOCPTFQ%2FaOF%2BLhVB3gH1YztmmiClWwCeFaviTXIRrZvGFGgkYRiIsipQ%3D%3D';

  Future<List<Map<String, dynamic>>> fetchHydrantData({
    required String ctprvnNm, // 시도명
    String? signguNm, // 시군구명
    int numOfRows = 1000, // 한 페이지에서 가져올 데이터 수
  }) async {
    final baseUrl = 'http://api.data.go.kr/openapi/tn_pubr_public_ffus_wtrcns_api';
    int page = 1;
    List<Map<String, dynamic>> allHydrants = [];

    while (true) {
      final uri = Uri.parse(
          '$baseUrl'
              '?serviceKey=$serviceKey'
              '&pageNo=$page'
              '&numOfRows=$numOfRows'
              '&type=json'
              '&CTPRVN_NM=${Uri.encodeComponent(ctprvnNm)}'
              '${signguNm != null ? '&SIGNGU_NM=${Uri.encodeComponent(signguNm)}' : ''}'
      );

      try {
        final response = await http.get(uri, headers: {
          'Content-Type': 'application/json',
        });

        if (response.statusCode == 200) {
          final jsonBody = json.decode(response.body);
          final body = jsonBody['response']?['body'];

          if (body == null || body['items'] == null) {
            print('❌ 응답에 body 또는 items 없음. 전체 응답: $jsonBody');
            break;
          }

          final items = body['items'] as List;
          allHydrants.addAll(items.cast<Map<String, dynamic>>());

          // 만약 받은 아이템의 수가 `numOfRows`보다 적다면 더 이상 페이지가 없다는 의미
          if (items.length < numOfRows) {
            break;
          }

          page++; // 다음 페이지로 이동
        } else {
          print('❌ 서버 응답 오류: ${response.statusCode}');
          print('본문: ${response.body}');
          break;
        }
      } catch (e) {
        print('❌ 예외 발생: $e');
        break;
      }
    }

    print('✅ 총 소화전 ${allHydrants.length}개 받아옴');
    return allHydrants;
  }
}
