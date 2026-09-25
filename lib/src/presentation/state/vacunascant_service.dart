import 'package:sistema_vacunacion/src/domain/entities/models.dart';

import 'estado.dart';

class _CantidadVacunadosService {
  final cantidadVacunadosStateEstado = Estado<CantidadVacunados?>(null);

  CantidadVacunados? get getCantidadVacunadosState =>
      cantidadVacunadosStateEstado.value;

  void cargarEnviroment(CantidadVacunados enviroment) {
    cantidadVacunadosStateEstado.value = enviroment;
  }
}

final appStateService = _CantidadVacunadosService();
