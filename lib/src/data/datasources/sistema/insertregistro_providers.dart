import 'dart:convert';
import 'package:sistema_vacunacion/src/core/debug/dev_log_service.dart';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

import 'package:http/http.dart' as http;
import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/domain/entities/models.dart';
import 'package:sistema_vacunacion/src/presentation/state/services.dart';

class _InsertRegistro {
  Future<List<MensajeServidor>> insertRegistroProd() async {
    List<InsertRegistros> listaRegistros = [];
    listaRegistros.add(insertRegistroService.registro!);
    String registro = insertRegistrosToJson(listaRegistros);

    final url = Uri(
        scheme: scheme,
        host: host,
        path: urlPruebaInsert,
        queryParameters: {'insertvacunado': registro});

    devLogService.log(
      DevLogTipo.apiRequest,
      'insertRegistro',
      'POST ${url.path}',
      datos: {'payload': json.decode(registro)},
    );

    final cargarRegistro = await procesarRespuestaUri(url);

    devLogService.log(
      DevLogTipo.apiResponse,
      'insertRegistro',
      'Respuesta: ${cargarRegistro.isNotEmpty ? cargarRegistro.first.mensaje ?? 'ok' : 'vacío'}',
    );

    return cargarRegistro;
  }

  // ignore: missing_return
  Future<List<MensajeServidor>> procesarRespuestaUri(Uri uri) async {
    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'},
      );
      if (resp.statusCode == 200) {
        final decodedData = json.decode(decodificarRespuestaHTTP(resp.bodyBytes));
        // PRUEBA EN CURSO: la copia de prueba seca devuelve acá lo que habría
        // escrito y lo que le habría mandado a NOMIVAC, sin ejecutarlo.
        if (decodedData is Map && decodedData['prueba_seca'] != null) {
          for (final captura in (decodedData['prueba_seca'] as List)) {
            devLogService.log(
              DevLogTipo.info,
              'prueba_seca',
              '${(captura as Map)['tipo']}',
              datos: {'detalle': captura['sql'] ?? captura['payload']},
            );
          }
        }
        final mensaje = MensajeServidor.fromJsonList(decodedData['mensajes']);
        return mensaje.items;
      }
    } catch (e) {
      throw 'Ocurrio un error $e';
    }

    throw 'Ocurrio un error mas jodido';
  }

  Future<List<MensajeServidor>?> procesarRespuestaConExepciones(Uri uri) async {
    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'},
      );
      if (resp.statusCode == 200) {
        final decodedData = json.decode(decodificarRespuestaHTTP(resp.bodyBytes));
        final mensaje = MensajeServidor.fromJsonList(decodedData['mensajes']);
        return mensaje.items;
      }
    } catch (e) {
      throw 'Ocurrio un error $e';
    }

    throw ('Tiempo de espera agotado');
  }
}

final insertRegistroProvider = _InsertRegistro();
