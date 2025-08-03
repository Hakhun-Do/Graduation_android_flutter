import 'package:flutter/material.dart';
import 'region_data.dart';  // regionMap을 선언한 파일 경로로 정확히 맞춰서

class SafeRegionSelector extends StatefulWidget {
  const SafeRegionSelector({super.key});

  @override
  State<SafeRegionSelector> createState() => _SafeRegionSelectorState();
}

class _SafeRegionSelectorState extends State<SafeRegionSelector> {
  String? selectedCity;
  String? selectedDistrict;
  String? selectedTown;

  @override
  Widget build(BuildContext context) {
    final cities = regionMap.keys.toList();

    final districts = (selectedCity != null && regionMap.containsKey(selectedCity))
        ? regionMap[selectedCity]!.keys.toList()
        : [];

    final towns = (selectedCity != null &&
        selectedDistrict != null &&
        regionMap.containsKey(selectedCity) &&
        regionMap[selectedCity]!.containsKey(selectedDistrict))
        ? regionMap[selectedCity]![selectedDistrict]!
        : [];

    if (selectedCity != null && !cities.contains(selectedCity)) {
      selectedCity = null;
      selectedDistrict = null;
      selectedTown = null;
    }
    if (selectedDistrict != null && !districts.contains(selectedDistrict)) {
      selectedDistrict = null;
      selectedTown = null;
    }
    if (selectedTown != null && !towns.contains(selectedTown)) {
      selectedTown = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          hint: Text('시/도 선택'),
          value: selectedCity,
          items: cities
              .map((city) => DropdownMenuItem(value: city, child: Text(city)))
              .toList(),
          onChanged: (value) {
            setState(() {
              selectedCity = value;
              selectedDistrict = null;
              selectedTown = null;
            });
          },
        ),
        SizedBox(height: 12),
        DropdownButton<String>(
          hint: Text('구/군 선택'),
          value: selectedDistrict,
          items: districts
              .map((district) => DropdownMenuItem<String>(
            value: district,
            child: Text(district),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              selectedDistrict = value;
              selectedTown = null;
            });
          },
        ),


        SizedBox(height: 12),
        DropdownButton<String>(
          hint: Text('동/읍/면 선택'),
          value: selectedTown,
          items: towns
              .map((town) => DropdownMenuItem<String>(
            value: town,
            child: Text(town),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              selectedTown = value;
            });
          },
        ),


        SizedBox(height: 20),
        if (selectedCity != null && selectedDistrict != null && selectedTown != null)
          Text(
            '선택한 지역: $selectedCity > $selectedDistrict > $selectedTown',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
      ],
    );
  }
}
