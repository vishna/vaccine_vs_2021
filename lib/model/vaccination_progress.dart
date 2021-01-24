import 'package:equatable/equatable.dart';

class VaccinationProgress extends Equatable {
  const VaccinationProgress(
      {this.name,
      this.isoCode,
      this.peopleVaccinated,
      this.peopleFullyVaccinated,
      this.date});

  factory VaccinationProgress.fromCsv(
      List<dynamic> row, Map<String, int> indexOf) {
    return VaccinationProgress(
        date: DateTime.parse(row[indexOf["date"]]),
        name: row[indexOf["location"]].toString().trim(),
        isoCode: row[indexOf["iso_code"]].toString().trim(),
        peopleFullyVaccinated: double.tryParse(
                row[indexOf["people_fully_vaccinated_per_hundred"]]
                    .toString()) ??
            0.0,
        peopleVaccinated: double.tryParse(
                row[indexOf["people_vaccinated_per_hundred"]].toString()) ??
            0.0);
  }

  final String name;
  final String isoCode;
  final num peopleVaccinated;
  final num peopleFullyVaccinated;
  final DateTime date;

  @override
  List<Object> get props =>
      [name, isoCode, peopleVaccinated, peopleFullyVaccinated];
}
