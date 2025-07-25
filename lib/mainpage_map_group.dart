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
      '종로구': ['사직동', '삼청동', '부암동', '평창동', '무악동', '교남동', '가회동', '종로1·2·3·4가동', '종로5·6가동', '이화동', '혜화동', '창신제1동', '창신제2동', '창신제3동', '숭인제1동', '숭인제2동'],
      '중랑구': ['면목동', '상봉동', '중화동', '묵동', '망우동', '신내동'],
      '중구': ['소공동', '회현동', '명동', '필동', '장충동', '광희동', '을지로동', '신당동', '다산동', '약수동', '청구동'],
      '송파구': ['풍납동', '방이동', '오금동', '송파동', '석촌동', '삼전동', '가락동', '문정동', '장지동', '잠실동', '신천동'],
      '양천구': ['목동', '신월동', '신정동'],
      '영등포구': ['영등포동', '여의동', '신길동', '대림동', '영등포본동', '도림동', '문래동'],
      '용산구': ['후암동', '용산동', '남영동', '청파동', '원효로', '효창동', '이촌동', '이태원', '한남동', '서빙고동', '보광동'],
      '은평구': ['녹번동', '불광동', '갈현동', '구산동', '대조동', '응암동', '역촌동', '신사동', '증산동', '수색동', '진관동'],
      '도봉구': ['창동', '쌍문동', '방학동', '도봉동'],
      '동대문구': ['용신동', '제기동', '전농동', '답십리동', '장안동', '청량리동', '회기동', '휘경동', '이문동'],
      '동작구': ['노량진동', '상도동', '흑석동', '사당동', '대방동', '신대방동'],
      '마포구': ['아현동', '공덕동', '도화동', '용강동', '대흥동', '염리동', '신수동', '서강동', '합정동', '망원동', '연남동', '성산동', '상암동'],
      '서대문구': ['충현동', '천연동', '북아현동', '신촌동', '연희동', '홍제동', '홍은동', '남가좌동', '북가좌동'],
      '서초구': ['서초동', '잠원동', '반포동', '방배동', '양재동', '내곡동'],
      '성동구': ['왕십리·도선동', '행당동', '응봉동', '금호동', '옥수동', '성수동', '송정동', '용답동'],
      '성북구': ['성북동', '삼선동', '동선동', '돈암동', '안암동', '보문동', '정릉동', '길음동', '종암동', '월곡동', '장위동', '석관동'],
      '강남구': ['압구정동', '신사동', '논현동', '삼성동', '대치동', '역삼동', '개포동', '청담동', '세곡동'],
      '강동구': ['강일동', '고덕동', '명일동', '상일동', '길동', '둔촌동', '암사동', '성내동', '천호동'],
      '강북구': ['미아동', '번동', '수유동', '우이동'],
      '강서구': ['염창동', '등촌동', '화곡동', '가양동', '마곡동', '내발산동', '공항동', '방화동'],
      '관악구': ['보라매동', '청림동', '성현동', '행운동', '낙성대동', '중앙동', '인헌동', '남현동', '서원동', '신원동', '서림동', '신사동', '조원동', '미성동', '난곡동', '난향동'],
      '광진구': ['자양동', '구의동', '광장동', '능동', '화양동', '군자동', '중곡동'],
      '구로구': ['신도림동', '구로동', '가리봉동', '고척동', '개봉동', '오류동', '궁동', '수궁동'],
      '금천구': ['가산동', '독산동', '시흥동'],
      '노원구': ['월계동', '공릉동', '하계동', '중계동', '상계동']
    },
    '부산광역시': {
      '강서구': ['대저1동', '대저2동', '강동동', '명지1동', '명지2동', '가락동', '녹산동', '가덕도동'],
      '금정구': ['서1동', '서2동', '서3동', '금사회동동', '부곡1동', '부곡2동', '부곡3동', '부곡4동', '선두구동', '청룡노포동', '남산동', '구서1동', '구서2동', '금성동'],
      '남구': ['문현동', '대연동', '용호동', '용당동', '감만동', '우암동'],
      '동구': ['초량동', '수정동', '좌천동', '범일동'],
      '동래구': ['수민동', '복산동', '명륜동', '온천동', '사직동', '안락동'],
      '부산진구': ['부전동', '연지동', '초읍동', '양정동', '범전동', '범천동', '전포동', '가야동', '개금동', '당감동', '부암동'],
      '북구': ['구포동', '금곡동', '화명동', '만덕동'],
      '사상구': ['삼락동', '모라동', '덕포동', '괘법동', '감전동', '주례동', '학장동', '엄궁동'],
      '사하구': ['괴정동', '당리동', '하단동', '신평동', '장림동', '다대동', '구평동', '감천동'],
      '서구': ['동대신동', '서대신동', '부민동', '아미동', '초장동', '충무동', '남부민동', '암남동'],
      '수영구': ['남천동', '광안동', '민락동', '수영동', '망미동'],
      '연제구': ['거제동', '연산동'],
      '영도구': ['남항동', '영선동', '신선동', '봉래동', '청학동', '동삼동'],
      '중구': ['중앙동', '대청동', '보수동', '부평동', '광복동', '남포동', '영주동'],
      '해운대구': ['우동', '중동', '좌동', '송정동', '반여동', '반송동', '재송동']
    },
    '대구광역시': {
      '남구': ['대명동'],
      '달서구': ['성당동', '두류동', '본리동', '감삼동', '죽전동', '장기동', '용산동', '이곡동', '신당동', '본동', '상인동', '월성동', '진천동', '유천동'],
      '달성군': ['화원읍', '논공읍', '다사읍', '가창면', '하빈면', '옥포읍', '현풍읍', '유가읍', '구지면'],
      '동구': ['신암동', '신천동', '효목동', '도평동', '불로·봉무동', '지저동', '동촌동', '방촌동', '해안동', '안심동'],
      '북구': ['고성동', '침산동', '산격동', '대현동', '복현동', '검단동', '노원동', '무태조야동', '관문동', '태전동', '구암동', '관음동', '읍내동'],
      '서구': ['내당동', '비산동', '평리동', '상중이동', '원대동'],
      '수성구': ['범어동', '만촌동', '수성동', '황금동', '중동', '상동', '파동', '두산동', '지산동', '범물동', '고산동'],
      '중구': ['동인동', '삼덕동', '성내동', '대신동', '남산동', '대봉동']
    },
    '인천광역시': {
      '계양구': ['효성동', '계산동', '작전동', '서운동', '계양동', '귤현동', '동양동', '박촌동', '병방동', '장기동'],
      '미추홀구': ['숭의동', '용현동', '학익동', '도화동', '주안동', '관교동', '문학동', '옥련동'],
      '남동구': ['구월동', '간석동', '만수동', '장수서창동', '남촌도림동', '논현고잔동'],
      '동구': ['만석동', '화수동', '송현동', '송림동'],
      '부평구': ['부평동', '십정동', '산곡동', '청천동', '갈산동', '삼산동', '부개동', '일신동'],
      '서구': ['검암경서동', '연희동', '청라동', '가정동', '신현원창동', '석남동', '가좌동', '검단동'],
      '연수구': ['송도동', '연수동', '선학동', '청학동', '동춘동'],
      '중구': ['중앙동', '영종동', '용유동', '연안동', '신포동', '도원동'],
      '강화군': ['강화읍', '선원면', '불은면', '길상면', '화도면', '양도면', '내가면', '하점면', '양사면', '송해면', '교동면', '삼산면'],
      '옹진군': ['북도면', '연평면', '백령면', '대청면', '덕적면', '영흥면', '자월면']
    },
    '광주광역시': {
      '광산구': ['송정동', '도산동', '신흥동', '우산동', '월곡동', '운남동', '신가동', '하남동', '임곡동', '첨단동', '비아동', '신창동', '수완동', '동곡동', '평동'],
      '남구': ['봉선동', '월산동', '주월동', '양림동', '사직동', '백운동', '방림동', '송암동', '대촌동'],
      '동구': ['충장동', '동명동', '계림동', '산수동', '지산동', '서남동'],
      '북구': ['중흥동', '임동', '우산동', '문흥동', '두암동', '각화동', '매곡동', '오치동', '운암동', '동림동', '삼각동', '일곡동', '건국동', '양산동'],
      '서구': ['양동', '농성동', '광천동', '유촌동', '상무동', '화정동', '금호동', '풍암동', '쌍촌동']
    },
    '대전광역시': {
      '대덕구': ['오정동', '대화동', '회덕동', '신탄진동', '비래동', '송촌동', '중리동'],
      '동구': ['중앙동', '신인동', '효동', '판암동', '용운동', '대동', '자양동', '가양동', '용전동', '성남동', '홍도동', '삼성동'],
      '서구': ['복수동', '도마동', '가장동', '내동', '변동', '탄방동', '둔산동', '갈마동', '월평동', '만년동', '가수원동', '관저동', '기성동'],
      '유성구': ['진잠동', '온천동', '노은동', '신성동', '전민동', '구즉동', '관평동'],
      '중구': ['은행선화동', '목동', '중촌동', '대흥동', '문창동', '석교동', '대사동', '부사동', '용두동', '오류동', '태평동']
    },
    '울산광역시': {
      '남구': ['신정동', '달동', '삼산동', '옥동', '무거동', '야음장생포동', '대현동', '수암동'],
      '동구': ['방어동', '일산동', '화정동', '전하동', '남목동'],
      '북구': ['농소동', '송정동', '염포동', '강동동'],
      '울주군': ['온산읍', '언양읍', '온양읍', '범서읍', '서생면', '청량면', '웅촌면', '두동면', '두서면', '상북면', '삼남면', '삼동면'],
      '중구': ['학성동', '반구동', '복산동', '우정동', '태화동', '다운동', '성안동', '약사동']
    },
    '세종특별자치시': {
      '세종특별자치시': [
        '조치원읍', '연기면', '연동면', '부강면', '금남면', '장군면', '소정면', '전의면', '전동면',
        '한솔동', '새롬동', '나성동', '다정동', '보람동', '소담동', '반곡동', '아름동', '종촌동',
        '고운동', '도담동', '어진동'
      ]
    },
    '경기도': {
      '수원시': ['권선구', '영통구', '장안구', '팔달구'],
      '가평군': ['가평읍', '설악면', '청평면', '상면', '하면', '북면'],
      '고양시': ['덕양구', '일산동구', '일산서구'],
      '과천시': ['중앙동', '과천동', '갈현동', '별양동', '부림동', '문원동'],
      '광명시': ['광명동', '철산동', '하안동', '소하동', '학온동'],
      '광주시': ['경안동', '송정동', '광남동', '오포읍', '초월읍', '곤지암읍', '도척면', '퇴촌면', '남종면', '남한산성면'],
      '구리시': ['갈매동', '사노동', '인창동', '교문동', '수택동', '아천동'],
      '군포시': ['군포동', '산본동', '금정동', '궁내동', '광정동', '오금동', '수리동', '대야동', '송부동'],
      '김포시': ['김포본동', '장기본동', '사우동', '풍무동', '고촌읍', '사우읍', '장기읍', '월곶면', '하성면', '대곶면', '양촌읍', '구래읍', '운양동'],
      '남양주시': ['화도읍', '진접읍', '오남읍', '별내읍', '다산동', '진건읍', '퇴계원읍', '금곡동', '평내동', '호평동', '별내면', '수동면', '조안면', '와부읍'],
      '동두천시': ['생연동', '보산동', '불현동', '송내동', '중앙동', '지행동', '광암동', '걸산동', '상봉암동', '하봉암동', '탑동동', '송산동', '안흥동'],
      '부천시': ['원미구', '소사구', '오정구'],
      '성남시': ['수정구', '중원구', '분당구'],
      '시흥시': ['대야동', '신천동', '신현동', '은행동', '매화동', '목감동', '정왕동', '과림동', '무지내동', '조남동', '장곡동', '능곡동', '연성동'],
      '안산시': ['상록구', '단원구'],
      '안성시': ['안성동', '보개면', '금광면', '서운면', '미양면', '대덕면', '양성면', '원곡면', '일죽면', '죽산면', '삼죽면', '고삼면'],
      '안양시': ['만안구', '동안구'],
      '양주시': ['양주1동', '양주2동', '백석읍', '광적면', '남면', '은현면', '장흥면', '회천1동', '회천2동', '회천3동', '회천4동'],
      '여주시': ['여흥동', '중앙동', '오학동', '가남읍', '점동면', '능서면', '흥천면', '금사면', '산북면', '대신면', '북내면', '강천면'],
      '오산시': ['중앙동', '남촌동', '신장동', '세마동', '가장동', '대원동'],
      '용인시': ['처인구', '기흥구', '수지구'],
      '의왕시': ['고천동', '부곡동', '오전동', '내손동', '청계동', '학의동'],
      '의정부시': ['의정부동', '호원동', '장암동', '신곡동', '송산동', '자금동', '가능동', '녹양동'],
      '이천시': ['창전동', '증포동', '중리동', '관고동', '신둔면', '백사면', '호법면', '마장면', '대월면', '모가면', '설성면', '장호원읍', '율면'],
      '파주시': ['운정1동', '운정2동', '운정3동', '금촌1동', '금촌2동', '금촌3동', '조리읍', '월롱면', '탄현면', '파주읍', '문산읍', '법원읍', '적성면', '군내면', '장단면', '진동면', '파평면'],
      '평택시': ['진위면', '서탄면', '중앙동', '서정동', '송탄동', '지산동', '송북동', '신장1동', '신장2동', '신평동', '원평동', '통복동', '비전1동', '비전2동', '세교동', '가재동', '팽성읍', '안중읍', '포승읍', '청북읍', '고덕면', '오성면', '현덕면'],
      '포천시': ['가산면', '군내면', '내촌면', '신북면', '창수면', '영중면', '영북면', '이동면', '일동면', '화현면', '소흘읍', '포천동', '선단동'],
      '하남시': ['천현동', '신장동', '덕풍동', '풍산동', '미사동', '감북동', '감일동', '위례동', '춘궁동', '초이동'],
      '화성시': ['봉담읍', '우정읍', '향남읍', '남양읍', '매송면', '비봉면', '마도면', '송산면', '서신면', '팔탄면', '장안면', '양감면', '정남면', '병점1동', '병점2동', '진안동', '반월동', '기배동', '화산동', '동탄1동', '동탄2동', '동탄3동', '동탄4동', '동탄5동', '동탄6동', '동탄7동', '동탄8동'],
    },
    '강원특별자치도': {
      '춘천시': ['강남동', '강북', '남면', '남산면', '동내면', '동면', '북산면', '사북면', '서면', '신동면', '신북읍', '조운동', '중앙동', '근화동', '소양동', '교동', '효자동', '후평1동', '후평2동', '후평3동', '석사동', '퇴계동', '강남동'],
      '원주시': ['가곡동', '개운동', '단계동', '명륜동', '봉산동', '부론면', '소초면', '신림면', '우산동', '원동', '일산동', '지정면', '판부면', '평원동', '학성동', '행구동', '호저면', '흥업면', '문막읍', '귀래면', '중앙동', '태장1동', '태장2동', '무실동', '반곡관설동'],
      '강릉시': ['강동면', '강문동', '견소동', '교1동', '교2동', '구정면', '금학동', '남문동', '남항진동', '내곡동', '대신동', '명주동', '사천면', '성내동', '성산면', '성덕동', '송정동', '연곡면', '옥계면', '옥천동', '왕산면', '용강동', '운산동', '월호평동', '유천동', '임당동', '입암동', '저동', '주문진읍', '죽헌동', '중앙동', '지변동', '청량동', '초당동', '포남동', '홍제동'],
      '동해시': ['송정동', '북삼동', '부곡동', '비천동', '쇄운동', '신흥동', '어달동', '용정동', '이도동', '일출로', '지흥동', '천곡동', '추암동', '평릉동', '망상동', '묵호진동', '삼화동'],
      '태백시': ['문곡소도동', '상장동', '성황, , 건지동', '황지동', '황연동', '구문소동', '장성동', '철암동'],
      '속초시': ['교동', '금호동', '노학동', '대포동', '도문동', '동명동', '설악동', '영랑동', '장사동', '조양동', '중앙동', '청학동'],
      '삼척시': ['가곡면', '건지동', '근덕면', '남양동', '노곡면', '미로면', '사직동', '삼척동', '성내동', '소달동', '신기면', '신기동', '원덕읍', '읍상동', '장성동', '정라동', '조비동', '하장면', '도계읍']
    },
    "충청북도": {
      "청주시": ["상당구", "서원구", "흥덕구", "청원구"],
      "충주시": ["성내충인동", "지현동", "문화동", "호암직동", "달천동", "봉방동", "칠금금릉동", "연수동", "교현안림동", "용산동", "신니면", "노은면", "앙성면", "중앙탑면", "금가면", "동량면", "산척면", "엄정면", "소태면", "성내동", "충인동", "주덕읍", "살미면", "수안보면"],
      "제천시": ["중앙동", "영서동", "용두동", "신백동", "남현동", "강제동", "청전동", "송학면", "한수면", "남제천", "동현동", "화산동", "교동", "고암동", "백운면", "봉양읍", "금성면", "수산면", "덕산면"],
      "보은군": ["보은읍", "속리산면", "회남면", "마로면", "내북면", "삼승면", "탄부면", "장안면", "수한면"],
      "옥천군": ["옥천읍", "동이면", "이원면", "안내면", "청산면", "군서면", "안남면"],
      "영동군": ["영동읍", "용산면", "황간면", "추풍령면", "상촌면", "매곡면", "양강면", "학산면"],
      "진천군": ["진천읍", "덕산읍", "광혜원면", "이월면", "문백면", "백곡면", "초평면"],
      "괴산군": ["괴산읍", "청천면", "사리면", "소수면", "감물면", "칠성면", "연풍면", "불정면"],
      "음성군": ["음성읍", "감곡읍", "생극면", "금왕읍", "맹동면", "삼성면", "대소면"],
      "단양군": ["단양읍", "적성면", "가곡면", "영춘면", "단성면", "어상천면"],
      "증평군": ["증평읍", "도안면"],
    },
    '충청남도': {
      '천안시': ['목천읍', '풍세면', '광덕면', '성거읍', '직산읍', '입장면', '성환읍', '병천면', '동면', '가락', '신방동', '일봉동', '봉명동', '중앙동', '문성동', '원성1동', '원성2동', '유량동', '신안동', '성정1동', '성정2동', '쌍용1동', '쌍용2동', '쌍용3동', '불당동', '백석동', '차암동'],
      '공주시': ['웅진동', '금학동', '옥룡동', '중학동', '반죽동', '탄천면', '계룡면', '반포면', '이인면', '탄천면', '우성면', '사곡면', '정안면', '신관동', '월송동', '금흥동', '옥룡동', '웅진동', '산성동', '유구읍'],
      '보령시': ['대천동', '죽정동', '주포면', '웅천읍', '주교면', '오천면', '천북면', '청소면', '청라면', '미산면', '성주면', '남포면', '관창산업단지'],
      '아산시': ['염치읍', '둔포면', '영인면', '인주면', '선장면', '도고면', '신창면', '온양동', '배방읍', '탕정면', '음봉면'],
      '서산시': ['대산읍', '인지면', '부석면', '팔봉면', '지곡면', '성연면', '음암면', '운산면', '해미면', '고북면', '수석동', '동문동', '석남동'],
      '논산시': ['강경읍', '연무읍', '성동면', '광석면', '노성면', '상월면', '부적면', '연산면', '벌곡면', '양촌면', '가야곡면', '은진면', '취암동', '부창동', '반월동', '내동'],
      '계룡시': ['금암동', '두마면', '엄사면', '신도안면'],
      '당진시': ['당진동', '읍내동', '송악읍', '고대면', '석문면', '대호지면', '정미면', '면천면', '순성면', '우강면', '신평면', '송산면'],
    },
    '전라북도': {
      '전주시': ['완산구', '덕진구'],
      '군산시': ['옥구읍', '옥산면', '회현면', '임피면', '서수면', '대야면', '성산면', '나포면', '개정면', '개정동', '중앙동', '흥남동', '월명동', '해신동', '소룡동', '미룡동', '수송동', '나운1동', '나운2동', '신풍동', '조촌동', '경암동', '구암동'],
      '익산시': ['낭산면', '망성면', '삼기면', '성당면', '용안면', '용동면', '함열읍', '함라면', '황등면', '오산면', '왕궁면', '춘포면', '팔봉동', '모현동', '송학동', '인화동', '평화동', '동산동', '마동', '중앙동', '갈산동', '남중동', '신동', '영등1동', '영등2동'],
      '정읍시': ['소성면', '신태인읍', '옹동면', '칠보면', '태인면', '고부면', '덕천면', '이평면', '정우면', '감곡면', '입암면', '북면', '내장상동', '시기동', '초산동', '연지동', '교월동', '장명동', '수성동'],
      '남원시': ['운봉읍', '주생면', '수지면', '송동면', '주천면', '산동면', '이백면', '향교동', '도통동', '동충동', '금동', '어현동', '대강면', '대산면', '사매면'],
      '김제시': ['검산동', '교월동', '김제동', '만경읍', '백구면', '백산면', '봉남면', '부량면', '금구면', '금산면', '용지면', '월촌면', '죽산면', '진봉면', '청하면', '황산면'],
    },
    '전라남도': {
      '목포시': ['산정동', '연동', '대성동', '죽교동', '원산동', '용해동', '상동', '삼학동', '만호동', '유달동', '목원동', '동명동', '무안동', '온금동', '서산동', '북교동', '보광동', '산정동', '광동동', '달동'],
      '여수시': ['돌산읍', '소라면', '율촌면', '화양면', '화정면', '삼산면', '남면', '동문동', '한려동', '중앙동', '충무동', '광림동', '서강동', '대교동', '국동', '문수동', '미평동', '둔덕동', '만흥동', '쌍봉동', '시전동', '여천동', '주삼동', '삼일동', '묘도동'],
      '순천시': ['승주읍', '주암면', '황전면', '월등면', '향동', '매곡동', '삼산동', '조곡동', '덕연동', '풍덕동', '남제동', '저전동', '장천동', '중앙동', '가곡동', '용당동', '인월동', '해룡면', '서면', '별량면', '상사면', '낙안면'],
      '나주시': ['성북동', '금남동', '성내동', '영강동', '이창동', '삼영동', '다도면', '남평읍', '세지면', '왕곡면', '반남면', '공산면', '동강면', '봉황면', '문평면', '노안면', '금천면', '산포면', '다시면'],
      '광양시': ['광양읍', '봉강면', '옥룡면', '옥곡면', '진상면', '진월면', '다압면', '골약동', '중마동', '광영동'],
    },
    '경상북도': {
      '포항시': ['남구', '북구'],
      '경주시': ['성건동', '황오동', '중부동', '선도동', '용강동', '황성동', '동천동', '충효동', '보덕동', '감포읍', '외동읍', '양북면', '내남면', '산내면', '서면', '건천읍', '황남동', '월성동', '불국동'],
      '김천시': ['성내동', '평화동', '양금동', '자산동', '지좌동', '교동', '삼락동', '남산동', '율곡동', '아포읍', '어모면', '감문면', '조마면', '구성면', '개령면', '감천면', '대항면', '봉산면', '대곡동'],
      '안동시': ['안흥동', '운흥동', '명륜동', '태화동', '평화동', '안기동', '옥동', '송현동', '용상동', '강남동', '북후면', '서후면', '풍산읍', '와룡면', '남선면', '임하면', '길안면', '임동면', '예안면', '도산면'],
      '구미시': ['송정동', '원평동', '지산동', '도량동', '선산읍', '고아읍', '무을면', '옥성면', '도개면', '해평면', '산동면', '형곡1동', '형곡2동', '신평1동', '신평2동', '비산동', '공단1동', '공단2동', '광평동', '상모사곡동', '임오동', '양포동'],
      '영주시': ['휴천동', '가흥동', '영주동', '상망동', '하망동', '문정동', '조암동', '구성동', '아지동', '적서동', '가흥1동', '가흥2동', '이산면', '평은면', '문수면', '장수면', '안정면', '봉현면', '순흥면', '단산면', '부석면'],
      '영천시': ['완산동', '남부동', '동부동', '서부동', '중앙동', '망정동', '문외동', '화룡동', '청통면', '신녕면', '화산면', '화북면', '화남면', '자양면', '고경면', '대창면', '금호읍', '북안면'],
      '상주시': ['북문동', '동문동', '계림동', '냉림동', '남원동', '성주동', '무양동', '함창읍', '사벌국면', '중동면', '낙동면', '청리면', '공성면', '외남면', '내서면', '모동면', '화동면', '화서면', '은척면', '공검면'],
      '문경시': ['점촌동', '흥덕동', '모전동', '창동', '유곡동', '신기동', '영신동', '함창읍', '산양면', '산북면', '동로면', '가은읍', '마성면', '농암면', '문경읍'],
      '경산시': ['중앙동', '동부동', '서부1동', '서부2동', '남부동', '북부동', '중방동', '평산동', '옥산동', '사동동', '백천동', '하양읍', '진량읍', '와촌면', '자인면', '용성면', '남산면', '압량읍'],
    },
    '경상남도': {
      '창원시': ['의창구', '성산구', '마산합포구', '마산회원구', '진해구'],
      '진주시': ['문산읍', '내동면', '정촌면', '금곡면', '진성면', '일반성면', '이반성면', '사봉면', '지수면', '대곡면', '미천면', '명석면', '대평면', '수곡면', '집현면', '미천면', '초장동', '평거동', '신안동', '이현동', '판문동', '가호동', '충무공동'],
      '통영시': ['도천동', '명정동', '중앙동', '정량동', '북신동', '무전동', '미수동', '봉평동', '산양읍', '욕지면', '한산면', '사량면'],
      '사천시': ['벌리동', '사천읍', '정동면', '사남면', '용현면', '축동면', '곤양면', '곤명면', '서포면'],
      '김해시': ['삼안동', '불암동', '활천동', '대청동', '매화동', '삼성동', '동상동', '회현동', '부원동', '내외동', '칠산서부동', '장유1동', '장유2동', '장유3동', '진영읍', '주촌면', '한림면', '김해시'],
      '밀양시': ['삼문동', '교동', '내일동', '가곡동', '용평동', '활성동', '상남면', '부북면', '초동면', '무안면', '청도면', '가례면', '단장면', '산내면', '산외면'],
      '거제시': ['고현동', '장평동', '능포동', '아주동', '옥포동', '상문동', '수양동', '장승포동', '마전동', '일운면', '동부면', '남부면', '둔덕면', '사등면', '연초면', '하청면'],
      '양산시': ['삼성동', '강서동', '중앙동', '양주동', '웅상읍', '동면', '상북면', '하북면', '중앙동', '서창동', '소주동', '평산동', '덕계동'],
    },
    '제주특별자치도': {
      '제주시': ['일도1동', '일도2동', '이도1동', '이도2동', '삼도1동', '삼도2동', '건입동', '화북1동', '화북2동', '삼양동', '아라동', '오라동', '연동', '노형동', '외도동', '이호동', '도두동', '봉개동', '용담1동', '용담2동', '애월읍', '구좌읍', '조천읍', '한림읍', '한경면', '추자면', '우도면'],
      '서귀포시': ['송산동', '정방동', '중앙동', '천지동', '효돈동', '영천동', '동홍동', '서홍동', '대륜동', '대천동', '중문동', '예래동', '대정읍', '남원읍', '성산읍', '안덕면', '표선면'],
    }
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

  Future<void> _initLocationAndMoveCamera() async {
    try {
      Position position = await _determinePosition();

      if (_kakaoMapController != null) {
        // 1. 지도를 현재 위치로 이동
        _kakaoMapController!.moveCamera(
          LatLng(position.latitude, position.longitude),
          zoomLevel: 3,
        );

        // 2. 해당 위치에 마커 추가
        final jsAddMarker = '''
        addMarker(null, JSON.stringify({latitude: ${position.latitude}, longitude: ${position.longitude}}), null, 40, 44, 0, 0, "현재 위치");
        ''';
        await _kakaoMapController!.evalJavascript(jsAddMarker);

      }
      // (선택) 마커 추가 후 마커 데이터 새로 불러오고 싶으면 아래도 호출
      /*final addressInfo = await getAddressFromCoordinates(position.latitude, position.longitude);
      _selectedCity = addressInfo['city'];
      _selectedTown = addressInfo['town'];

      await updateMapMarkers(
        kakaoMapController: _kakaoMapController!,
        selectedCity: _selectedCity!,
        selectedTown: _selectedTown!,
      );*/
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
