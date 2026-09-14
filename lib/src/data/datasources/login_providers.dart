import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:sistema_vacunacion/src/config/config.dart';
import 'dart:convert';
import 'package:sistema_vacunacion/src/core/debug/dev_log_service.dart';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

import 'package:sistema_vacunacion/src/domain/entities/models.dart';

class _UsuariosProviders {
  Future<List<Usuarios>> procesarRespuestaDos(Uri url) async {
    devLogService.log(
      DevLogTipo.apiRequest,
      'login',
      'GET ${url.path}',
      datos: {'dni': url.queryParameters['flxcore03_dni']},
    );
    try {
      final resp = await http.get(url).timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200) {
        final decodedData = json.decode(decodificarRespuestaHTTP(resp.bodyBytes));
        final usuarios = Usuarios.fromJsonList(decodedData['usuario']);
        if (usuarios.items.isNotEmpty) {
          final u = usuarios.items.first;
          devLogService.log(
            DevLogTipo.apiResponse,
            'login',
            'codigo_msg=${u.codigo_mensaje} | ${u.flxcore03_nombre ?? ''}',
            datos: {
              'id_flxcore03': u.id_flxcore03,
              'nombre': u.flxcore03_nombre,
              'codigo_mensaje': u.codigo_mensaje,
            },
          );
        }
        return usuarios.items;
      }
    } catch (e) {
      devLogService.log(DevLogTipo.apiError, 'login', '$e');
      throw "Hubo un error $e";
    }

    throw 'Hubo un error';
  }

  Future validarUsuarios(String dni) async {
    final url =
        Uri(scheme: scheme, host: host, path: urlLogin, queryParameters: {
      'flxcore03_dni': dni,
    });

    final List<Usuarios> resp = await procesarRespuestaDos(url);

    // Guard: la API siempre devuelve al menos 1 item.
    // flxcore03_dni vacio indica usuario no encontrado (manejado por el llamador).
    if (resp.isEmpty) throw 'No se encontraron datos del usuario.';

    return resp;
  }

  Future validarUsuariosNuevo(String? dni) async {
    final url = Uri(
        scheme: scheme,
        host: host,
        path: '/modulos/webservice/php/version_2_0/wserv_login.php',
        queryParameters: {
          'flxcore03_dni': dni,
        });

    final List<Usuarios> resp = await procesarRespuestaDos(url);

    // Guard: el llamador (escanerdni_widget) accede directamente a resp[0].
    if (resp.isEmpty) throw 'No se encontraron datos del usuario.';

    return resp;
  }
}

final usuariosProviers = _UsuariosProviders();
