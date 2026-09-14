import 'dart:async';
import 'dart:convert';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

import 'package:sistema_vacunacion/src/config/appconst_config.dart';
import 'package:sistema_vacunacion/src/core/debug/dev_log_service.dart';
import 'package:sistema_vacunacion/src/domain/entities/models.dart';

class _ValidacionVersion {
  List<Version> vacia = [];
  Future<List<Version>> procesarRespuesta(Uri url) async {
    try {
      final resp = await devHttpGet('version', url,
          timeout: const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        final decodedData = json.decode(decodificarRespuestaHTTP(resp.bodyBytes));
        final version = Version.fromJsonList(decodedData['versiones']);

        return version.items;
      }
    } catch (e) {
      return vacia;
    }

    throw 'Hubo un error mas jodido';
  }

  Future validarVersionNuevaVersion(String nombreapp, String versionApp) async {
    final url = Uri(
        scheme: scheme,
        host: host,
        path: urlValVersion,
        queryParameters: {
          'sysappl01_nombre': nombreapp,
          'sysappl01_version': versionApp,
        });

    final List<Version> resp = await procesarRespuesta(url);
    if (resp.isNotEmpty) {
      return resp[0].sysappl01_version;
    } else {
      return 0;
    }
  }
}

final validacionVersionProvider = _ValidacionVersion();
