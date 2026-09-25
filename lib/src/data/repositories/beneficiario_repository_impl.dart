import 'package:sistema_vacunacion/src/domain/repositories/beneficiario_repository.dart';
import 'package:sistema_vacunacion/src/data/datasources/beneficiario_providers.dart';

class BeneficiarioRepositoryImpl implements BeneficiarioRepository {
  @override
  Future obtenerDatosBeneficiario(
          String? barcodeDni, String? dni, String? sexo) =>
      beneficiarioProviders.obtenerDatosBeneficiario(barcodeDni, dni, sexo);
}

final beneficiarioRepository = BeneficiarioRepositoryImpl();
