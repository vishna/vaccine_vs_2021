import 'package:equatable/equatable.dart';

class VaccinationProgress extends Equatable {
  const VaccinationProgress({
    this.name,
    this.isoCode,
    this.peopleVaccinated,
    this.peopleFullyVaccinated,
  });
  final String name;
  final String isoCode;
  final num peopleVaccinated;
  final num peopleFullyVaccinated;

  @override
  List<Object> get props =>
      [name, isoCode, peopleVaccinated, peopleFullyVaccinated];
}
