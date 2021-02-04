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
    final date = DateTime.parse(row[indexOf["date"]]);
    final name = row[indexOf["location"]].toString().trim();
    final isoCode = row[indexOf["iso_code"]].toString().trim();
    final peopleFullyVaccinated = double.tryParse(
        row[indexOf["people_fully_vaccinated_per_hundred"]].toString());
    final peopleVaccinated = double.tryParse(
        row[indexOf["people_vaccinated_per_hundred"]].toString());
    if (peopleVaccinated == null || peopleFullyVaccinated == null) {
      return null;
    }
    return VaccinationProgress(
        date: date,
        name: name,
        isoCode: isoCode,
        peopleFullyVaccinated: peopleFullyVaccinated,
        peopleVaccinated: peopleVaccinated);
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
