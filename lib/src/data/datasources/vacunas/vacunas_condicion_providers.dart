// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/core/debug/dev_log_service.dart';
import 'package:sistema_vacunacion/src/domain/entities/vacunas/vacunas_condicion_model.dart';
import 'dart:convert';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

class _VacunasCondicion {
  Future<List<VacunasCondicion>> procesarRespuestaDos(Uri url) async {
    try {
      final resp = await devHttpGet('condicion', url,
          timeout: const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        final decodedData = json.decode(decodificarRespuestaHTTP(resp.bodyBytes));
        final condicion =
            VacunasCondicion.fromJsonList(decodedData['condicion_vacunas']);
        return condicion.items;
      }
    } catch (e) {
      throw 'Ocurrio un error $e';
    }

    throw 'Ocurrio un error';
  }

  Future obtenerCondicionesProviders(
      String? sysvacu04, String? sysdesa10_edad) async {
    final url =
        Uri(scheme: scheme, host: host, path: urlCondicion, queryParameters: {
      'id_sysvacu04': sysvacu04,
      'sysdesa10_edad': sysdesa10_edad,
    });

    final List<VacunasCondicion> resp = await procesarRespuestaDos(url);
    if (resp[0].id_sysvacu01 != '') {
      return resp;
    } else {
      return resp;
    }
  }
}

final vacunasCondicion = _VacunasCondicion();
