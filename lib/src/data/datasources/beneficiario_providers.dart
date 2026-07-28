import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/core/debug/dev_log_service.dart';
import 'package:sistema_vacunacion/src/domain/entities/models.dart';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

class _BeneficiarioProviders {
  // ignore: missing_return
  Future<List<Beneficiario>> procesarRespuestaDos(Uri url) async {
    devLogService.log(
      DevLogTipo.apiRequest,
      'beneficiario',
      'GET ${url.path}',
      datos: {
        'dni': url.queryParameters['sysdesa10_dni'],
        'sexo': url.queryParameters['sysdesa10_sexo'],
        if (url.queryParameters.containsKey('embarazada'))
          'embarazada': url.queryParameters['embarazada'],
        if (url.queryParameters.containsKey('puerpera'))
          'puerpera': url.queryParameters['puerpera'],
        if (url.queryParameters.containsKey('personal_salud'))
          'personal_salud': url.queryParameters['personal_salud'],
      },
    );
    http.Response? resp;
    try {
      // Timeout de 30 segundos: evita que la app quede colgada indefinidamente
      // si el servidor no responde. TimeoutException es capturada por el catch.
      resp = await http.get(url).timeout(const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        final decodedData = json.decode(decodificarRespuestaHTTP(resp.bodyBytes));
        final listaRaw =
            normalizarListaBeneficiarioDesdeJson(decodedData['beneficiario']);
        if (listaRaw == null) {
          throw 'El servidor respondió sin lista "beneficiario" válida.';
        }
        final contenedor = Beneficiario.fromJsonList(listaRaw);
        final items = contenedor.items;
        if (items.isNotEmpty) {
          final b0 = items.first;
          final f = b0.foto_beneficiario;
          developer.log(
            'codigo_mensaje=${b0.codigo_mensaje}, foto_beneficiario: '
            '${f == null ? "null" : f.isEmpty ? "cadena vacía — sin imagen en esta respuesta" : "${f.length} caracteres"}',
            name: 'wserv_obtener_datos_beneficiario',
          );
          devLogService.log(
            DevLogTipo.apiResponse,
            'beneficiario',
            'codigo_msg=${b0.codigo_mensaje} | ${b0.sysdesa10_apellido ?? ''}, ${b0.sysdesa10_nombre ?? ''}',
            datos: {
              'dni': b0.sysdesa10_dni,
              'nombre': b0.sysdesa10_nombre,
              'apellido': b0.sysdesa10_apellido,
              'sexo': b0.sysdesa10_sexo,
              'edad': b0.sysdesa10_edad,
              'fecha_nacimiento': b0.sysdesa10_fecha_nacimiento,
              'codigo_mensaje': b0.codigo_mensaje,
              'foto': f == null ? null : '${f.length} chars',
            },
          );
        }
        return items;
      }
    } catch (e) {
      final cuerpo = resp?.bodyBytes;
      // Muestra bytes no imprimibles como \uXXXX para ver BOM u otra basura
      // que un servidor pueda anteponer al JSON.
      final crudo = cuerpo?.take(200).map((b) {
        final c = String.fromCharCode(b);
        return (b < 0x20 || b > 0x7e)
            ? '\\u${b.toRadixString(16).padLeft(4, '0')}'
            : c;
      }).join();
      devLogService.log(
        DevLogTipo.apiError,
        'beneficiario',
        '$e',
        datos: {
          'statusCode': resp?.statusCode,
          'bodyBytesLength': cuerpo?.length,
          'bodyPreview': crudo,
        },
      );
      // ignore: avoid_print
      print(
        '[beneficiario] error=$e statusCode=${resp?.statusCode} '
        'bodyPreview=$crudo',
      );
      throw 'Ocurrio un error $e';
    }

    throw 'Ocurrio un error';
  }

  Future obtenerDatosBeneficiario(
      String? barcodeDni, String? dni, String? sexo) async {
    final url = Uri(
        scheme: scheme,
        host: host,
        path: urlBenef,
        queryParameters: {
          'sysdesa10_cadena_dni': barcodeDni,
          'sysdesa10_dni': dni,
          'sysdesa10_sexo': sexo
        });

    final List<Beneficiario> resp = await procesarRespuestaDos(url);

    // Guard: la API siempre devuelve al menos 1 item (con campos vacios si no
    // encuentra datos). Si llega vacio es una respuesta inesperada del servidor.
    if (resp.isEmpty) throw 'No se encontraron datos para el beneficiario.';

    return resp;
  }

  /// Igual que [obtenerDatosBeneficiario] pero contra
  /// `wserv_obtener_datos_persona.php` (version_5_0), que además recibe la
  /// situación del beneficiario: `embarazada` y `puerpera` son excluyentes
  /// entre sí (igual que en el formulario).
  Future obtenerDatosPersona(
    String? barcodeDni,
    String? dni,
    String? sexo, {
    required bool embarazada,
    required bool puerpera,
    required bool personalSalud,
  }) async {
    final url = Uri(
        scheme: scheme,
        host: host,
        path: urlObtenerDatosPersona,
        queryParameters: {
          'sysdesa10_cadena_dni': barcodeDni,
          'sysdesa10_dni': dni,
          'sysdesa10_sexo': sexo,
          'embarazada': '$embarazada',
          'puerpera': '$puerpera',
          'personal_salud': '$personalSalud',
        });

    final List<Beneficiario> resp = await procesarRespuestaDos(url);

    if (resp.isEmpty) throw 'No se encontraron datos para el beneficiario.';

    return resp;
  }
}

final beneficiarioProviders = _BeneficiarioProviders();
