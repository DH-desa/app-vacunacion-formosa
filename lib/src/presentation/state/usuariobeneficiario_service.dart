import 'package:sistema_vacunacion/src/domain/entities/models.dart';
import 'package:sistema_vacunacion/src/presentation/state/tutor_service.dart';
import 'package:sistema_vacunacion/src/utils/edad_beneficiario.dart';
import 'package:sistema_vacunacion/src/utils/edad_pdf417_dni_arg.dart';

import 'estado.dart';

class _BeneficiariorService {
  final beneficiarioEstado = Estado<Beneficiario?>(null);

  /// Edad en años leída del PDF417 del DNI al escanear (texto para UI y APIs).
  final edadEstado = Estado<String?>(null);
  final fechaNacEstado = Estado<String?>(null);

  Beneficiario? get beneficiario => beneficiarioEstado.value;

  String? get edadAniosDesdePdf417Escaneado => edadEstado.value;

  String? get fechaNacimientoDesdePdf417Escaneado => fechaNacEstado.value;

  bool get existeBeneficiario => beneficiarioEstado.value != null;

  /// Edad y fecha que se guardan al registrar la vacuna y se informan a NOMIVAC.
  /// Primero las validadas al escanear: `wserv_obtener_datos_beneficiario.php`
  /// devuelve edad fija y fecha vacía cuando la consulta lleva la cadena del DNI.
  String? get edadParaRegistro {
    final validada = edadAniosDesdePdf417Escaneado?.trim();
    if (validada != null && validada.isNotEmpty) return validada;
    return beneficiario?.sysdesa10_edad;
  }

  String? get fechaNacimientoParaRegistro {
    final validada = fechaNacimientoDesdePdf417Escaneado?.trim();
    if (validada != null && validada.isNotEmpty) return validada;
    return beneficiario?.sysdesa10_fecha_nacimiento;
  }

  /// Edad en días de vida (`wserv_listados_vacunas.php` la espera así, a
  /// diferencia del resto de la app que usa años). Prioridad PDF417 sobre
  /// dato del API, igual criterio que [edadAniosDesdePdf417Escaneado].
  String? get diasDeVidaBeneficiario {
    final dias =
        diasDeVidaDesdeFechaNacimientoTexto(fechaNacimientoDesdePdf417Escaneado) ??
        (() {
          final nacimiento =
              parseFechaNacimiento(beneficiario?.sysdesa10_fecha_nacimiento);
          return nacimiento == null
              ? null
              : diasDeVidaDesde(nacimiento, DateTime.now());
        })();
    return dias?.toString();
  }

  void cargarBeneficiario(
    Beneficiario? beneficiario, {
    String? edadAniosDesdePdf417Escaneado,
    String? fechaNacimientoDesdePdf417Escaneado,
  }) {
    // Un beneficiario nuevo no debe arrastrar tutor de otro registro en memoria.
    tutorService.reiniciar();
    edadEstado.value = edadAniosDesdePdf417Escaneado;
    fechaNacEstado.value = fechaNacimientoDesdePdf417Escaneado;
    beneficiarioEstado.value = beneficiario;
  }

  void reiniciar() {
    beneficiarioEstado.reiniciar();
    edadEstado.reiniciar();
    fechaNacEstado.reiniciar();
  }
}

final beneficiarioService = _BeneficiariorService();
