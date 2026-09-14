import 'dart:async';
import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/core/debug/dev_log_service.dart';

import 'dart:convert';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

import 'package:sistema_vacunacion/src/domain/entities/models.dart';
import 'package:sistema_vacunacion/src/presentation/state/services.dart';

class _InfoVacunasProviders {
  Future<List<InfoVacunas>> procesarRespuestaDos(Uri url) async {
    try {
      final resp = await devHttpGet('info_vacunas', url,
          timeout: const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        final decodedData = json.decode(decodificarRespuestaHTTP(resp.bodyBytes));
        final informacion =
            InfoVacunas.fromJsonList(decodedData['vacunas_configuradas']);
        return informacion.items;
      }
    } catch (e) {
      throw 'Ocurrio un error $e';
    }

    throw 'Ocurrio un error';
  }

  // ignore: missing_return
  Future<List<InfoVacunas>> obtenerRespuestaVacunas(Uri url) async {
    final resp = await devHttpGet('info_vacunas', url,
        timeout: const Duration(seconds: 30));
    if (resp.statusCode == 200) {
      final decodedData = json.decode(decodificarRespuestaHTTP(resp.bodyBytes));
      final vacunas =
          InfoVacunas.fromJsonList(decodedData['vacunas_configuradas']);
      return vacunas.items;
    }
    throw '';
  }

  Future validarVacunas() async {
    final beneficiario = beneficiarioService.beneficiario;
    if (beneficiario == null) {
      throw 'No hay beneficiario cargado para validar vacunas';
    }
    final url =
        Uri(scheme: scheme, host: host, path: urlInfoVacu, queryParameters: {
      'sysdesa10_dni': beneficiario.sysdesa10_dni,
      'sysdesa10_sexo': beneficiario.sysdesa10_sexo,
    });

    final List<InfoVacunas> resp = await obtenerRespuestaVacunas(url);
    if (resp.isEmpty) return resp;
    if (resp[0].id_sysvacu04 != '') {
      return resp;
    } else {
      return resp;
    }
  }
}

final infoVacunasProviers = _InfoVacunasProviders();
