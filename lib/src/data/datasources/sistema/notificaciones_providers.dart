import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:sistema_vacunacion/src/config/appconst_config.dart';
import 'dart:convert';
import 'package:sistema_vacunacion/src/core/debug/dev_log_service.dart';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

import 'package:sistema_vacunacion/src/domain/entities/sistema/notificacionesdosis_models.dart';

class _NotificacionesProviders {
  Future<List<NotificacionesDosis>> procesarRespuestaDos(Uri url) async {
    devLogService.log(
      DevLogTipo.apiRequest,
      'notificaciones',
      'GET ${url.path}',
      datos: {
        'dni': url.queryParameters['sysdesa10_dni'],
        'sexo': url.queryParameters['sysdesa10_sexo'],
        'embarazada': url.queryParameters['embarazada'],
        'puerpera': url.queryParameters['puerpera'],
        'personal_salud': url.queryParameters['personal_salud'],
        'sysdesa10_edad': url.queryParameters['sysdesa10_edad'],
        'rela_sysvacu16': url.queryParameters['rela_sysvacu16'],
      },
    );
    http.Response? resp;
    try {
      resp = await http.get(url);
      if (resp.statusCode == 200) {
        final decodedData = json.decode(decodificarRespuestaHTTP(resp.bodyBytes));
        final notificaciones = NotificacionesDosis.fromJsonList(
            decodedData['aplicaciones_beneficiario']);
        devLogService.log(
          DevLogTipo.apiResponse,
          'notificaciones',
          '${notificaciones.items.length} dosis recibidas',
          datos: {
            'dni': url.queryParameters['sysdesa10_dni'],
            'cantidad': notificaciones.items.length,
          },
        );
        return notificaciones.items;
      }
    } catch (e) {
      final cuerpo = resp?.bodyBytes;
      final crudo = cuerpo?.take(200).map((b) {
        final c = String.fromCharCode(b);
        return (b < 0x20 || b > 0x7e)
            ? '\\u${b.toRadixString(16).padLeft(4, '0')}'
            : c;
      }).join();
      devLogService.log(
        DevLogTipo.apiError,
        'notificaciones',
        '$e',
        datos: {
          'statusCode': resp?.statusCode,
          'bodyBytesLength': cuerpo?.length,
          'bodyPreview': crudo,
        },
      );
      // ignore: avoid_print
      print(
        '[notificaciones] error=$e statusCode=${resp?.statusCode} '
        'bodyPreview=$crudo',
      );
      throw 'Hubo un error $e';
    }

    throw 'Hubo un error mas jodido';
  }

  Future validarNotificaciones(
    String? dni,
    String? sexo, {
    required bool embarazada,
    required bool puerpera,
    required bool personalSalud,
    required String? edadDias,
  }) async {
    final url = Uri(
        scheme: scheme,
        host: host,
        path: urlListadoVacunas,
        queryParameters: {
          'sysdesa10_dni': dni,
          'sysdesa10_sexo': sexo,
          'embarazada': '$embarazada',
          'puerpera': '$puerpera',
          'personal_salud': '$personalSalud',
          'sysdesa10_edad': edadDias,
          // ponytail: valor fijo de prueba — el back de wserv_listados_vacunas.php
          // devuelve body vacío sin rela_sysvacu16. Sacar cuando el back deje
          // de requerirlo (o lo resuelva del lado del servidor).
          'rela_sysvacu16': '6',
        });

    final List<NotificacionesDosis> resp = await procesarRespuestaDos(url);
    return resp;
  }
}

final notificacionesProvider = _NotificacionesProviders();
