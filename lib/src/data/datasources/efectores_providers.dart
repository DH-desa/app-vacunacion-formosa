import 'dart:async';
import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/core/debug/dev_log_service.dart';
import 'package:sistema_vacunacion/src/domain/entities/models.dart';
import 'dart:convert';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

import 'package:sistema_vacunacion/src/presentation/state/efectores_service.dart';

class _EfectorsProviders {
  Future<List<Efectores>> procesarRespuestaDos(Uri url) async {
    try {
      final resp = await devHttpGet('efectores', url,
          timeout: const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        final decodedData = json.decode(decodificarRespuestaHTTP(resp.bodyBytes));
        final efectores = Efectores.fromJsonList(decodedData['usuario']);
        return efectores.items;
      }
    } catch (e) {
      throw 'Ocurrio un error $e';
    }

    throw 'Ocurrio un error';
  }

  Future obtenerDatosEfectores(String? dni) async {
    final url =
        Uri(scheme: scheme, host: host, path: urlEfect, queryParameters: {
      'flxcore03_dni': dni,
    });

    final List<Efectores> resp = await procesarRespuestaDos(url);

    // Guard: respuesta vacia es inesperada — la API retorna al menos 1 item.
    if (resp.isEmpty) throw 'No se encontraron efectores para el usuario.';

    // Si el DNI tiene valor: carga la lista en el servicio y retorna.
    // Si el DNI es vacio: la API indico que no hay efectores — retorna la lista
    // con el item de error para que el llamador lo maneje.
    if (resp[0].flxcore03Dni != '') {
      return efectoresService.cargarListaEfectores(resp);
    } else {
      return resp;
    }
  }
}

final efectoresProviders = _EfectorsProviders();
