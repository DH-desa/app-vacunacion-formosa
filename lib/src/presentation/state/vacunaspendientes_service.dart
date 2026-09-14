import 'package:sistema_vacunacion/src/domain/entities/vacunas/vacunas_pendientes_model.dart';

import 'estado.dart';

class _VacunasPendientesService {
  final listaPendientesEstado = Estado<List<VacunaPendiente>>([]);

  /// Mensaje cuando la última descarga de pendientes falló (red/servidor):
  /// distingue "sin pendientes" (lista vacía, sin mensaje) de "no se pudo
  /// consultar" (lista vacía o desactualizada, con mensaje), para que la UI
  /// no muestre un falso "está al día" y pueda ofrecer reintentar.
  final mensajeErrorEstado = Estado<String?>(null);

  List<VacunaPendiente> get listaPendientes => listaPendientesEstado.value;

  String? get mensajeError => mensajeErrorEstado.value;

  void cargarListaPendientes(List<VacunaPendiente> pendientes) {
    mensajeErrorEstado.value = null;
    listaPendientesEstado.value = pendientes;
  }

  void marcarError(String mensaje) {
    mensajeErrorEstado.value = mensaje;
  }

  void reiniciar() {
    listaPendientesEstado.reiniciar();
    mensajeErrorEstado.reiniciar();
  }
}

final vacunasPendientesService = _VacunasPendientesService();
