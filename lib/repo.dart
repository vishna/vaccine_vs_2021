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

  static Map<String, VaccinationProgress> vaccineData;
  static Future<Map<String, VaccinationProgress>> fetchVaccineData() async {
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

    final output = <String, VaccinationProgress>{};
    for (var index = 1; index < vaccinations.length; index++) {
      final row = vaccinations[index];

      final vp = VaccinationProgress.fromCsv(row, indexOf);
      final previousVp = output[vp.name];
      if (previousVp == null ||
          vp.peopleVaccinated > previousVp.peopleVaccinated) {
        output[vp.name] = vp;
      }
    }

    vaccineData = output;

    if (_locationIsoCode != null) {
      final preselectedEntry = output.values.firstWhere(
        (element) => element.isoCode == _locationIsoCode,
        orElse: () => null,
      );

      if (preselectedEntry != null && Vaxx2021App.stack == initialStack) {
        Vaxx2021App.selectCountry(preselectedEntry.name);
      }
    }

    return output;
  }
}
