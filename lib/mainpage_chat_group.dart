import 'package:flutter/material.dart';
import 'region_data.dart';
import 'api_service.dart';

class RegionSelector extends StatefulWidget {
  const RegionSelector({Key? key}) : super(key: key);

  @override
  State<RegionSelector> createState() => _RegionSelectorState();
}

class _RegionSelectorState extends State<RegionSelector> {
  String? _selectedCity;      // 시/도
  String? _selectedTown;      // 시/군/구
  String? _selectedDistrict;  // 읍/면/동

  List<Map<String, dynamic>> _comments = []; // 검색 결과

  InputDecoration dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF4F4F4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cityList = regionMap.keys.toList();
    final townList = _selectedCity != null
        ? regionMap[_selectedCity!]!.keys.toList()
        : <String>[];
    final districtList = (_selectedCity != null && _selectedTown != null)
        ? regionMap[_selectedCity!]![_selectedTown!] ?? <String>[]
        : <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: "코멘트를 입력하세요",
              filled: true,
              fillColor: const Color(0xFFF4F4F4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: (text) {
              // 필요시 처리
              print("코멘트 입력: $text");
            },
          ),
          const SizedBox(height: 30),

          // 1단계 시/도
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: dropdownDecoration('시/도'),
            value: _selectedCity,
            icon: const Icon(Icons.arrow_drop_down),
            items: cityList.map((city) =>
                DropdownMenuItem(value: city, child: Text(city))
            ).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCity = value;
                _selectedTown = null;
                _selectedDistrict = null;
              });
            },
          ),
          const SizedBox(height: 10),

          // 2단계 시/군/구
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: dropdownDecoration('시/군/구'),
            value: _selectedTown,
            icon: const Icon(Icons.arrow_drop_down),
            items: townList.map((town) =>
                DropdownMenuItem(value: town, child: Text(town))
            ).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTown = value;
                _selectedDistrict = null;
              });
            },
          ),
          const SizedBox(height: 10),

          // 3단계 읍/면/동
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: dropdownDecoration('읍/면/동'),
            value: _selectedDistrict,
            icon: const Icon(Icons.arrow_drop_down),
            items: districtList.map((district) =>
                DropdownMenuItem(value: district, child: Text(district))
            ).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDistrict = value;
              });
            },
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCity = null;
                      _selectedTown = null;
                      _selectedDistrict = null;
                      _comments.clear();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('초기화'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_selectedCity != null ||
                      _selectedTown != null ||
                      _selectedDistrict != null)
                      ? () async {
                    try {
                      final data = await ProblemMarkerService().fetchProblemData(
                        ctprvnNm: _selectedCity ?? '',
                        signguNm: _selectedTown,
                      );
                      print('API 응답 데이터: $data');  // 데이터 확인
                      setState(() {
                        _comments = data;
                      });
                      print("불러온 코멘트 수: ${data.length}");
                    } catch (e) {
                      print("데이터 불러오기 실패: $e");
                    }

                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('검색'),
                ),
              ),
            ],
          ),

          const Divider(color: Colors.black, thickness: 1, height: 20),

          // 검색 결과 표시 (스크롤뷰 안에서는 Expanded 대신 그냥 위젯! + shrinkWrap)
          _comments.isEmpty
              ? const Center(child: Text("검색 결과가 없습니다."))
              : ListView.builder(
            itemCount: _comments.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final comment = _comments[index]['comment'] ?? '코멘트 없음';
              final addr = _comments[index]['addr'] ?? '';
              final cat = _comments[index]['cat'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Row(
                    children: [
                      const Icon(Icons.comment, color: Colors.black87, size: 18), // 코멘트 아이콘
                      const SizedBox(width: 4),
                      Expanded( // 긴 코멘트일 때 줄바꿈 대응
                        child: Text(
                          comment,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (addr.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.grey, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              addr,
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      if (cat.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.category, color: Colors.black87, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              cat,
                              style: const TextStyle(color: Colors.black87, fontSize: 13),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
