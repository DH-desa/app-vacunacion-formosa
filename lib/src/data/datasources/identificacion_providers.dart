import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/core/debug/dev_log_service.dart';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

/// Identificación de la persona por D.N.I. contra las fuentes oficiales.
/// El QR del DNI 2026 no trae el sexo y trae el año con dos dígitos: en vez de
/// pedirle esos datos al operador, se consulta y el servicio los resuelve.
class IdentificacionBeneficiario {
  const IdentificacionBeneficiario({
    required this.estado,
    required this.origen,
    required this.dni,
    required this.sexo,
    required this.apellido,
    required this.nombre,
    required this.fechaNacimiento,
    required this.edadAnios,
    required this.nroTramite,
    required this.mensaje,
  });

  /// `ok` · `sexo_no_coincide` · `no_encontrado` · `fuentes_caidas` · `error_interno`
  final String estado;

  /// Qué fuente resolvió la identidad: `local` o `renaper`.
  final String origen;

  final String dni;
  final String sexo;
  final String apellido;
  final String nombre;

  /// `AAAA-MM-DD`, siempre con año de cuatro dígitos.
  final String fechaNacimiento;
  final String edadAnios;
  final String nroTramite;
  final String mensaje;

  bool get identificada => estado == 'ok' || estado == 'sexo_no_coincide';

  factory IdentificacionBeneficiario.fromJson(Map<String, dynamic> json) {
    String txt(String k) => json[k]?.toString().trim() ?? '';
    return IdentificacionBeneficiario(
      estado: txt('estado'),
      origen: txt('origen'),
      dni: txt('sysdesa10_dni'),
      sexo: txt('sysdesa10_sexo'),
      apellido: txt('sysdesa10_apellido'),
      nombre: txt('sysdesa10_nombre'),
      fechaNacimiento: txt('sysdesa10_fecha_nacimiento'),
      edadAnios: txt('sysdesa10_edad'),
      nroTramite: txt('sysdesa10_nro_tramite'),
      mensaje: txt('mensaje'),
    );
  }
}

class _IdentificacionProviders {
  /// [sexo] va vacío cuando el código no lo trae (QR): entonces el servicio lo
  /// deduce. Si viene, el servicio lo valida y avisa cuando no coincide.
  Future<IdentificacionBeneficiario> identificar(String dni, String? sexo) async {
    final url = Uri(
      scheme: scheme,
      host: host,
      path: urlIdentificarBeneficiario,
      queryParameters: {'sysdesa10_dni': dni, 'sysdesa10_sexo': sexo ?? ''},
    );

    devLogService.log(
      DevLogTipo.apiRequest,
      'identificacion',
      'GET ${url.path}',
      datos: {'dni': dni, 'sexo': sexo ?? '(sin sexo)'},
    );

    final resp = await http.get(url).timeout(const Duration(seconds: 20));
    if (resp.statusCode != 200) {
      throw 'El servicio de identificación respondió ${resp.statusCode}.';
    }
    final cuerpo = decodificarRespuestaHTTP(resp.bodyBytes);
    if (cuerpo.trim().isEmpty) {
      throw 'El servicio de identificación respondió vacío.';
    }
    final lista = json.decode(cuerpo)['beneficiario'];
    if (lista is! List || lista.isEmpty) {
      throw 'El servicio de identificación respondió sin datos.';
    }
    final ident = IdentificacionBeneficiario.fromJson(
      Map<String, dynamic>.from(lista.first as Map),
    );

    devLogService.log(
      DevLogTipo.apiResponse,
      'identificacion',
      'estado=${ident.estado} origen=${ident.origen}',
      datos: {
        'sexo': ident.sexo,
        'fecha_nacimiento': ident.fechaNacimiento,
        'edad': ident.edadAnios,
        'mensaje': ident.mensaje,
      },
    );
    return ident;
  }
}

final identificacionProviders = _IdentificacionProviders();
