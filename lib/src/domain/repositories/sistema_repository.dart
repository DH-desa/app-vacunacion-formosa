import 'package:sistema_vacunacion/src/domain/entities/entities.dart';

abstract class SistemaRepository {
  Future<List<MensajeServidor>> insertRegistroProd();
  Future validarNotificaciones(
    String? dni,
    String? sexo, {
    required bool embarazada,
    required bool puerpera,
    required bool personalSalud,
    required String? edadDias,
  });
  Future validarVersionNuevaVersion(String nombreapp, String versionApp);
}
