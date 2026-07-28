import 'package:sistema_vacunacion/src/domain/entities/models.dart';

import 'estado.dart';

class _InsertRegistroService {
  final registroEstado = Estado<InsertRegistros?>(null);

  InsertRegistros? get registro => registroEstado.value;

  bool get existeRegistro => registroEstado.value != null;

  void cargarRegistro(InsertRegistros registro) {
    registroEstado.value = registro;
  }

  void agregarFecha(DateTime fechaDeCarga) {
    // ponytail: mutación in-place, misma referencia; el setter de Estado
    // compara por identidad y no notifica solo. Forzar notifyListeners().
    registroEstado.value!.fecha_aplicacion = fechaDeCarga.toString();
    registroEstado.notificar();
  }

  /// Vacunas ya registradas con éxito en la visita en curso (ciclo persona):
  /// se acumula en cada registro exitoso y se muestra en VacunasPage para
  /// que el operador vea lo aplicado sin volver a buscar.
  final visitaRegistrosEstado = Estado<List<InsertRegistros>>([]);

  List<InsertRegistros> get visitaRegistros => visitaRegistrosEstado.value;

  void agregarRegistroVisita(InsertRegistros registro) {
    visitaRegistrosEstado.value = [...visitaRegistrosEstado.value, registro];
  }

  void reiniciar() {
    registroEstado.reiniciar();
  }
}

final insertRegistroService = _InsertRegistroService();
