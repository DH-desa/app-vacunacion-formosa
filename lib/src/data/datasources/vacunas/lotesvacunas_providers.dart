import 'dart:async';
import 'package:sistema_vacunacion/src/config/appconst_config.dart';
import 'package:sistema_vacunacion/src/core/debug/dev_log_service.dart';
import 'dart:convert';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

import 'package:sistema_vacunacion/src/domain/entities/models.dart';

class _LotesVacunaProviders {
  // ignore: missing_return
  Future<List<Lotes>> procesarRespuestaDos(Uri url) async {
    try {
      final resp = await devHttpGet('lotes', url,
          timeout: const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        final decodedData = json.decode(decodificarRespuestaHTTP(resp.bodyBytes));
        final lotes = Lotes.fromJsonList(decodedData['lotes_vacunas']);
        return lotes.items;
      }
    } catch (e) {
      throw 'Ocurrio un error $e';
    }

    throw 'Ocurrio un error';
  }

  Future validarLotes(String? idVacu) async {
    final url =
        Uri(scheme: scheme, host: host, path: urlLoteVacu, queryParameters: {
      'id_sysvacu04': idVacu,
    });

    final List<Lotes> resp = await procesarRespuestaDos(url);
    return resp;
  }
}

final lotesVacunaProvider = _LotesVacunaProviders();
