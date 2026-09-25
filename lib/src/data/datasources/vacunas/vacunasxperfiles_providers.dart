import 'dart:async';
import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/core/debug/dev_log_service.dart';
import 'package:sistema_vacunacion/src/domain/entities/models.dart';
import 'dart:convert';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

import 'package:sistema_vacunacion/src/presentation/state/services.dart';

class _VacunasxPerfiles {
  Future<List<VacunasxPerfil>> procesarRespuestaDos(Uri url) async {
    try {
      final resp = await devHttpGet('vacunas_x_perfil', url,
          timeout: const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        final decodedData = json.decode(decodificarRespuestaHTTP(resp.bodyBytes));
        final vacunas =
            VacunasxPerfil.fromJsonList(decodedData['vacunas_configuradas']);
        return vacunas.items;
      }
    } catch (e) {
      throw 'Ocurrio un error $e';
    }

    throw 'Ocurrio un error';
  }

  //URL PARA PRODUCCIÓN: https://dh.formosa.gob.ar/modulos/webservice/php/version_2_0/wserv_obtener_vacunas_configuradas.php
  Future obtenerVacunasxPerfilesProviders(
      String? id, String? dni, String? sexo) async {
    final url = Uri(
        scheme: scheme,
        host: host,
        path: urlVacuxPerfiles,
        queryParameters: {
          'id_sysvacu12': id,
          'sysdesa10_dni': dni,
          'sysdesa10_sexo': sexo,
        });

    final List<VacunasxPerfil> resp = await procesarRespuestaDos(url);
    if (resp[0].id_sysvacu04 != '') {
      return vacunasxPerfilService.cargarListaVacunasxPerfil(resp);
    } else {
      return 0;
    }
  }
}

final vacunasxPerfiles = _VacunasxPerfiles();
