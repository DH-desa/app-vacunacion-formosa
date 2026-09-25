import 'package:sistema_vacunacion/src/widgets/situacion_beneficiario_widget.dart';

import 'estado.dart';

class _SituacionBeneficiarioService {
  final condicionGestacionalEstado = Estado<CondicionGestacional?>(null);
  final esPersonalDeSaludEstado = Estado<bool>(false);

  CondicionGestacional? get condicionGestacional =>
      condicionGestacionalEstado.value;

  bool get esPersonalDeSalud => esPersonalDeSaludEstado.value;

  void cargarSituacion({
    CondicionGestacional? condicionGestacional,
    required bool esPersonalDeSalud,
  }) {
    condicionGestacionalEstado.value = condicionGestacional;
    esPersonalDeSaludEstado.value = esPersonalDeSalud;
  }

  void reiniciar() {
    condicionGestacionalEstado.reiniciar();
    esPersonalDeSaludEstado.reiniciar();
  }
}

final situacionBeneficiarioService = _SituacionBeneficiarioService();
