// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/core/debug/dev_log_service.dart';
import 'package:sistema_vacunacion/src/domain/entities/vacunas/vacunas_dosis_model.dart';
import 'dart:convert';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

class _VacunasDosisProvider {
  Future<List<VacunasDosis>> procesarRespuestaDos(Uri url) async {
    try {
      final resp = await devHttpGet('dosis', url,
          timeout: const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        final decodedData = json.decode(decodificarRespuestaHTTP(resp.bodyBytes));
        final dosis = VacunasDosis.fromJsonList(decodedData['dosis_vacunas']);
        return dosis.items;
      }
    } catch (e) {
      throw 'Ocurrio un error $e';
    }

    throw 'Ocurrio un error';
  }

  Future obtenerDosisProviders(
      String id_sysvacu04, String id_sysvacu01, String id_sysvacu02) async {
    final url =
        Uri(scheme: scheme, host: host, path: urlDosis, queryParameters: {
      'id_sysvacu04': id_sysvacu04,
      'id_sysvacu01': id_sysvacu01,
      'id_sysvacu02': id_sysvacu02,
    });

    final List<VacunasDosis> resp = await procesarRespuestaDos(url);
    if (resp[0].id_sysvacu05 != '') {
      return resp;
    } else {
      return resp;
    }
  }
}

final vacunasDosisProvider = _VacunasDosisProvider();
