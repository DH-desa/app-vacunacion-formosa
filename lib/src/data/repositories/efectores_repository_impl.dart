import 'package:sistema_vacunacion/src/domain/repositories/efectores_repository.dart';
import 'package:sistema_vacunacion/src/data/datasources/efectores_providers.dart';

class EfectoresRepositoryImpl implements EfectoresRepository {
  @override
  Future obtenerDatosEfectores(String? dni) =>
      efectoresProviders.obtenerDatosEfectores(dni);
}

final efectoresRepository = EfectoresRepositoryImpl();
