import 'package:sistema_vacunacion/src/domain/entities/sistema/notificacionesdosis_models.dart';

import 'estado.dart';

class _NotificacionesDosisService {
  final notiDosisEstado = Estado<NotificacionesDosis?>(null);

  NotificacionesDosis? get dosis => notiDosisEstado.value;

  bool get existeDosis => notiDosisEstado.value != null;

  void cargarRegistro(NotificacionesDosis? dosis) {
    notiDosisEstado.value = dosis;
  }
  // ----------------------- Manejo de Listas de Notificaciones ---------------------- //

  final listaDosisAplicadasEstado = Estado<List<NotificacionesDosis>>([]);

  List<NotificacionesDosis> get listaDosisAplicadas =>
      listaDosisAplicadasEstado.value;

  void cargarListaDosis(List<NotificacionesDosis> dosisAplicadas) {
    listaDosisAplicadasEstado.value = dosisAplicadas;
  }

  void reiniciar() {
    notiDosisEstado.reiniciar();
    listaDosisAplicadasEstado.reiniciar();
  }
}

final notificacionesDosisService = _NotificacionesDosisService();
