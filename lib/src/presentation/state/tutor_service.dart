import 'package:sistema_vacunacion/src/domain/entities/models.dart';

import 'estado.dart';

class _TutorService {
  final tutorEstado = Estado<Tutor?>(null);

  Tutor? get tutor => tutorEstado.value;

  /// Solo cuenta si hay documento: un [Tutor] vacío no debe bloquear el alta de tutor.
  bool get existeTutor {
    final t = tutorEstado.value;
    if (t == null) return false;
    final dni = t.sysdesa10_dni_tutor?.trim() ?? '';
    return dni.isNotEmpty;
  }

  void cargarTutor(Tutor tutor) {
    tutorEstado.value = tutor;
  }

  void reiniciar() {
    tutorEstado.reiniciar();
  }
}

final tutorService = _TutorService();
