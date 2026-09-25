import 'package:sistema_vacunacion/src/domain/repositories/vacunador_repository.dart';
import 'package:sistema_vacunacion/src/data/datasources/vacunador_providers.dart';

class VacunadorRepositoryImpl implements VacunadorRepository {
  @override
  Future validarVacunador(String? dni) =>
      vacunadorProviders.validarVacunador(dni);
}

final vacunadorRepository = VacunadorRepositoryImpl();
