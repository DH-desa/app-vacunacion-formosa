import 'package:sistema_vacunacion/src/domain/entities/usuarios/usuariovacunador_models.dart';

import 'estado.dart';

class _VacunadorService {
  final vacunadorEstado = Estado<Vacunador?>(null);

  Vacunador? get vacunador => vacunadorEstado.value;

  bool get existeVacunador => vacunadorEstado.value != null;

  void cargarVacunador(Vacunador? vacunador) {
    vacunadorEstado.value = vacunador;
  }

  void reiniciar() {
    vacunadorEstado.reiniciar();
  }
}

final vacunadorService = _VacunadorService();
