import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = "http://175.106.98.190:1040/auth"; // 실제 API URL로 변경
  //http://175.106.98.190:1040/auth

  final FlutterSecureStorage storage = FlutterSecureStorage();

  // 회원가입 요청 함수
  Future<Map<String, dynamic>> registerUser(
      String id, String password, String name, String phonenumber) async {
    final url = Uri.parse("$baseUrl/register"); // 실제 엔드포인트로 변경

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        //"Cache-Control": "no-cache",
        //"Postman-Token": "<calculated when request is sent>",
        //"Content-Length": "<calculated when request is sent>",
        //"Host": "<calculated when request is sent>",
        //"User-Agent": "PostmanRuntime/7.43.0",
        "Accept": "*/*",
        //"Accept-Encoding": "gzip, deflate, br",
        //"Connection": "keep-alive",
      },
      // 주석처리 - Postman 설정(JSON 파일 보낼때 필요없음)
      body: jsonEncode({
        "username": id,
        "password": password,
        "name": name,
        "num": phonenumber
      }),
    );

    if (response.statusCode == 200) {
      return {"success": true}; // 회원가입 성공
    } else if (response.statusCode == 409) {
      // 409 CONFLICT → 서버에서 예외 메시지를 보냄
      String errorMessage = utf8.decode(response.bodyBytes); // 한글 깨짐 방지
      return {
        "success": false,
        "error": errorMessage,
      };
    } else {
      // 기타 오류
      return {
        "success": false,
        "error": "회원가입 중 오류가 발생했습니다. 다시 시도해주세요.",
      };
    }
  }

  // 로그인 요청 함수(JWT 토큰 저장)
  Future<Map<String, dynamic>> loginUser(String id, String password) async {
    final url = Uri.parse("$baseUrl/login"); // 실제 엔드포인트로 변경

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Accept": "*/*",
      },
      body: jsonEncode({
        "username": id,
        "password": password,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      String responseBody = response.body.trim(); // 응답 문자열 정리
      if (responseBody.startsWith("Bearer ")) {
        String token = responseBody.substring(7); // "Bearer " 부분 제거

        // 토큰 저장
        await storage.write(key: "auth_token", value: token);
        return {"success": true, "token": token};
      } else {
        return {"success": false, "error": "토큰 형식이 올바르지 않습니다."};
      }
    } else if (response.statusCode == 401) {
      // 401 CONFLICT → 서버에서 예외 메시지를 보냄

      return {
        "success": false,
        "error": "로그인 실패: 아이디 또는 비밀번호가 올바르지 않습니다.",
      };
    } else {
      // 기타 오류
      return {
        "success": false,
        "error": "로그인 중 오류가 발생했습니다. 다시 시도해주세요.",
      };
    }
  }

  // 저장된 토큰 가져오기
  Future<String?> getToken() async {
    return await storage.read(key: "auth_token");
  }

  // 로그아웃 (토큰 삭제)
  Future<void> logout() async {
    await storage.delete(key: "auth_token");
  }

  // 회원 정보 조회
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    String? token = await storage.read(key: "auth_token"); // 저장된 JWT 토큰 가져오기
    if (token == null) {
      print("❌ JWT 토큰이 없습니다.");
      return null;
    }

    print("🔑 저장된 JWT 토큰: $token"); // 토큰 값 출력 (디버깅용)

    final url = Uri.parse("$baseUrl/getinfo"); // 프로필 조회 API 엔드포인트

    // ✅ 보낼 요청 정보 출력
    print("🔍 요청 URL: $url");
    print("🔍 Authorization 헤더: Bearer $token");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token", // JWT 토큰 인증
        "Content-Type": "application/json",
        "Accept": "*/*",
        "User-Agent": "PostmanRuntime/7.29.2", // ✅ Postman과 동일한 User-Agent 추가
      },
    );

    print("🔍 서버 응답 상태 코드: ${response.statusCode}");
    print("🔍 서버 응답 본문: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("✅ API 응답 데이터: $data"); // API 응답 확인
      return data;
    } else {
      print("❌ API 호출 실패: 상태 코드 ${response.statusCode}, 응답 ${response.body}");
      return null;
    }
  }

  // 비밀번호 변경
  Future<Map<String, dynamic>?> updatePassword(String currentPassword, String newPassword) async {
    String? token = await storage.read(key: "auth_token"); // 저장된 JWT 토큰 가져오기
    if (token == null) {
      print("❌ JWT 토큰이 없습니다.");
      return null;
    }

    print("🔑 저장된 JWT 토큰: $token"); // 토큰 값 출력 (디버깅용)

    final url = Uri.parse("$baseUrl/updatePassword"); // 프로필 조회 API 엔드포인트

    // ✅ 보낼 요청 정보 출력
    print("🔍 요청 URL: $url");
    print("🔍 Authorization 헤더: Bearer $token");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token", // JWT 토큰 인증
        "Content-Type": "application/json",
        "Accept": "*/*",
        "User-Agent": "PostmanRuntime/7.29.2", // ✅ Postman과 동일한 User-Agent 추가
      },
      body: jsonEncode({
        "password": currentPassword,
        "newPassword": newPassword,
      }),
    );

    print("🔍 서버 응답 상태 코드: ${response.statusCode}");
    print("🔍 서버 응답 본문: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("✅ API 응답 데이터: $data"); // API 응답 확인
      return data;
    } else {
      print("❌ API 호출 실패: 상태 코드 ${response.statusCode}, 응답 ${response.body}");
      return null;
    }
  }

  // 관할구역 변경
  Future<Map<String, dynamic>?> updatePos(String newpos) async {
    String? token = await storage.read(key: "auth_token"); // 저장된 JWT 토큰 가져오기
    if (token == null) {
      print("❌ JWT 토큰이 없습니다.");
      return null;
    }

    print("🔑 저장된 JWT 토큰: $token"); // 토큰 값 출력 (디버깅용)

    final url = Uri.parse("$baseUrl/updatePos"); // 프로필 조회 API 엔드포인트

    // ✅ 보낼 요청 정보 출력
    print("🔍 요청 URL: $url");
    print("🔍 Authorization 헤더: Bearer $token");

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token", // JWT 토큰 인증
        "Content-Type": "application/json",
        "Accept": "*/*",
        "User-Agent": "PostmanRuntime/7.29.2", // ✅ Postman과 동일한 User-Agent 추가
      },
      body: jsonEncode({
        "pos": newpos,
      }),
    );

    print("🔍 서버 응답 상태 코드: ${response.statusCode}");
    print("🔍 서버 응답 본문: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("✅ API 응답 데이터: $data"); // API 응답 확인
      return data;
    } else {
      print("❌ API 호출 실패: 상태 코드 ${response.statusCode}, 응답 ${response.body}");
      return null;
    }
  }
}

class MarkerDbService {

  Future<List<Map<String, dynamic>>> fetchMarkerData({
    required String ctprvnNm, // 시도명
    String? signguNm, // 시군구명
    //String? districtNm, //구읍면명
    //int numOfRows = 100, // 한 페이지에서 가져올 데이터 수
  }) async {
    final url = 'http://175.106.98.190:1040/pin/all';
    //int page = 1;
    List<Map<String, dynamic>> allMarkerDb = [];

    final uri = Uri.parse(
      '$url'
          '?ctprvnNm=${Uri.encodeComponent(ctprvnNm)}'
          '${signguNm != null ? '&signguNm=${Uri.encodeComponent(signguNm)}' : ''}',
    );

    try {
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0',
      });

      if (response.statusCode == 200) {
        try {
          final jsonBody = json.decode(response.body);
          if (jsonBody is List) {
            allMarkerDb.addAll(jsonBody.cast<Map<String, dynamic>>());
          } else {
            print('❌ 예상과 다른 응답 형태입니다: ${jsonBody.runtimeType}');
          }
        } catch (e) {
          print('❌ JSON 파싱 중 예외 발생: $e');
        }
      } else {
        print('❌ 서버 응답 오류: ${response.statusCode}');
        print('본문: ${response.body}');
      }
    } catch (e) {
      print('❌ 예외 발생: $e');
    }

    print('✅ DB마커 ${allMarkerDb.length}개 받아옴');
    return allMarkerDb;
  }
}
