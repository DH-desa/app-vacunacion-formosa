import 'package:sistema_vacunacion/src/domain/repositories/sistema_repository.dart';
import 'package:sistema_vacunacion/src/domain/entities/entities.dart';
import 'package:sistema_vacunacion/src/data/datasources/sistema/insertregistro_providers.dart';
import 'package:sistema_vacunacion/src/data/datasources/sistema/notificaciones_providers.dart';
import 'package:sistema_vacunacion/src/data/datasources/sistema/validarversion_providers.dart';

class SistemaRepositoryImpl implements SistemaRepository {
  @override
  Future<List<MensajeServidor>> insertRegistroProd() =>
      insertRegistroProvider.insertRegistroProd();

  @override
  Future validarNotificaciones(
    String? dni,
    String? sexo, {
    required bool embarazada,
    required bool puerpera,
    required bool personalSalud,
    required String? edadDias,
  }) =>
      notificacionesProvider.validarNotificaciones(
        dni,
        sexo,
        embarazada: embarazada,
        puerpera: puerpera,
        personalSalud: personalSalud,
        edadDias: edadDias,
      );

  @override
  Future validarVersionNuevaVersion(String nombreapp, String versionApp) =>
      validacionVersionProvider.validarVersionNuevaVersion(
          nombreapp, versionApp);
}

final sistemaRepository = SistemaRepositoryImpl();
