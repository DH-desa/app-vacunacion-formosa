import 'package:sistema_vacunacion/src/domain/entities/models.dart';

import 'estado.dart';

class _CantidadVacunasService {
  final cantidadVacunadosEstado = Estado<CantidadVacunados?>(null);

  CantidadVacunados? get cantidadvacunados => cantidadVacunadosEstado.value;

  bool get existeCantidadvacunados => cantidadVacunadosEstado.value != null;

  void cargarCantidadVacunados(CantidadVacunados? cantidadVacunados) {
    cantidadVacunadosEstado.value = cantidadVacunados;
  }

  void reiniciar() {
    cantidadVacunadosEstado.reiniciar();
  }
}

final cantidadVacunasService = _CantidadVacunasService();
