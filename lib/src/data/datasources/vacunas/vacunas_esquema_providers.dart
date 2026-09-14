// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/core/debug/dev_log_service.dart';
import 'dart:convert';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

import 'package:sistema_vacunacion/src/domain/entities/vacunas/vacunas_esquema_model.dart';

class _VacunasEsquemaProvider {
  Future<List<VacunasEsquema>> procesarRespuestaDos(Uri url) async {
    try {
      final resp = await devHttpGet('esquema', url,
          timeout: const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        final decodedData = json.decode(decodificarRespuestaHTTP(resp.bodyBytes));
        final esquemas =
            VacunasEsquema.fromJsonList(decodedData['esquema_vacunas']);
        return esquemas.items;
      }
    } catch (e) {
      throw 'Ocurrio un error $e';
    }

    throw 'Ocurrio un error';
  }

  Future obtenerEsquemasProviders(
      String? id_sysvacu04, String? id_sysvacu01) async {
    final url =
        Uri(scheme: scheme, host: host, path: urlEsquema, queryParameters: {
      'id_sysvacu04': id_sysvacu04,
      'id_sysvacu01': id_sysvacu01,
    });

    final List<VacunasEsquema> resp = await procesarRespuestaDos(url);
    if (resp[0].id_sysvacu02 != '') {
      return resp;
    } else {
      return resp;
    }
  }
}

final vacunasEsquemaProvider = _VacunasEsquemaProvider();
