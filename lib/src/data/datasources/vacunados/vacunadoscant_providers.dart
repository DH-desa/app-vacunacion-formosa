import 'dart:convert';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/core/debug/dev_log_service.dart';

import 'package:sistema_vacunacion/src/domain/entities/models.dart';
import 'package:sistema_vacunacion/src/presentation/state/services.dart';

class _CantidadVacunadosFecha {
  Future<List<CantidadVacunados>> procesarRespuestaDos(Uri url) async {
    try {
      final resp = await devHttpGet('cant_vacunados', url,
          timeout: const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        final decodedData = json.decode(decodificarRespuestaHTTP(resp.bodyBytes));
        final cantidadVacunas =
            CantidadVacunados.fromJsonList(decodedData['usuario']);
        return cantidadVacunas.items;
      }
    } catch (e) {
      throw 'Ocurrio un error $e';
    }

    throw 'Ocurrio un error mas jodido';
  }

  Future cantidadVacunas() async {
    final vacunador = vacunadorService.vacunador;
    final registrador = registradorService.registrador;
    if (vacunadorService.existeVacunador != false &&
        vacunador != null &&
        registrador != null) {
      final url =
          Uri(scheme: scheme, host: host, path: urlCantVacu, queryParameters: {
        'id_sysdesa12': vacunador.id_sysdesa12,
        'vacunador_registrador':
            registrador.flxcore03_dni == vacunador.id_sysdesa12 ? '1' : '0',
      });

      final List<CantidadVacunados> resp = await procesarRespuestaDos(url);
      return resp;
    }
  }
}

final cantidadVacunadosProvider = _CantidadVacunadosFecha();
