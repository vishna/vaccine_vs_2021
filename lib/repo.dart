import 'dart:convert';

import 'package:country_code/country_code.dart';
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;
import 'package:vaccine_vs_2021/main.dart';
import 'package:vaccine_vs_2021/model/vaccination_progress.dart';

class Repo {
  static String _locationIsoCode;
  static Future<void> _resolveLocation() async {
    try {
      final response = await http.get('https://api.ipregistry.co?key=tryout');
      final value = jsonDecode(response.body);
      String code2 = value["location"]["country"]["code"];
      final cc = CountryCode.tryParse(code2);
      _locationIsoCode = cc.alpha3;
    } catch (_) {}
  }

  static Map<String, List<VaccinationProgress>> vaccineData;
  static Future<Map<String, List<VaccinationProgress>>>
      fetchVaccineData() async {
    if (vaccineData != null) {
      return vaccineData;
    }

    await _resolveLocation();

    final response = await http.get(
        'https://raw.githubusercontent.com/owid/covid-19-data/master/public/data/vaccinations/vaccinations.csv');

    List<List<dynamic>> vaccinations = const CsvToListConverter()
        .convert(response.body, fieldDelimiter: ",", eol: "\n");

    final indexOf = Map<String, int>.fromIterable(vaccinations.first,
        key: (v) => v, value: (v) => vaccinations.first.indexOf(v));

    final output = <String, List<VaccinationProgress>>{};
    for (var index = 1; index < vaccinations.length; index++) {
      final row = vaccinations[index];

      final vp = VaccinationProgress.fromCsv(row, indexOf);
      if (vp == null) {
        continue;
      }
      final vpArray = output[vp.name] ?? [];
      vpArray.add(vp);
      vpArray.sort((a, b) => a.date.compareTo(b.date));
      output[vp.name] = vpArray;
    }

    vaccineData = output;

    if (_locationIsoCode != null) {
      final preselectedEntry = output.values.firstWhere(
        (element) => element.first.isoCode == _locationIsoCode,
        orElse: () => null,
      );

      if (preselectedEntry != null && Vaxx2021App.stack == initialStack) {
        Vaxx2021App.selectCountry(preselectedEntry.first.name);
      }
    }

    return output;
  }

  static List<String> lookupCountry(String query) {
    final allCountries = List<String>.from(vaccineData.keys)
      ..sort((a, b) => a.compareTo(b));
    if (query == null || query.isEmpty) {
      return allCountries;
    }

    return allCountries
        .where((element) => element.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
