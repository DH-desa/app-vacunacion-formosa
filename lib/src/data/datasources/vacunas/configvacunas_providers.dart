import 'dart:async';
import 'package:sistema_vacunacion/src/config/appconst_config.dart';
import 'package:sistema_vacunacion/src/core/debug/dev_log_service.dart';

import 'dart:convert';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

import 'package:sistema_vacunacion/src/domain/entities/models.dart';
import 'package:sistema_vacunacion/src/presentation/state/services.dart';

class _ConfiguracionVacunaProviders {
  Future<List<ConfiVacuna>> procesarRespuestaDos(Uri url) async {
    try {
      final resp = await devHttpGet('config_vacunas', url,
          timeout: const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        final decodedData = json.decode(decodificarRespuestaHTTP(resp.bodyBytes));
        final configuracionVacunas =
            ConfiVacuna.fromJsonList(decodedData['configuraciones']);
        return configuracionVacunas.items;
      }
    } catch (e) {
      throw 'Ocurrio un error $e';
    }

    throw Error();
  }

  Future validarConfiguraciones(String? idVacu) async {
    final beneficiario = beneficiarioService.beneficiario;
    if (beneficiario == null) {
      throw 'No hay beneficiario cargado para validar configuraciones de vacuna';
    }
    final url =
        Uri(scheme: scheme, host: host, path: urlConfigVacu, queryParameters: {
      'id_sysvacu04': idVacu,
      'sysdesa10_edad': beneficiario.sysdesa10_edad,
      'sysdesa10_dni': beneficiario.sysdesa10_dni,
      'sysdesa10_sexo': beneficiario.sysdesa10_sexo,
    });

    final List<ConfiVacuna> resp = await procesarRespuestaDos(url);
    if (resp.isNotEmpty) {
      return resp;
    } else {
      return resp;
    }
  }
}

final configuracionVacunaProvider = _ConfiguracionVacunaProviders();
