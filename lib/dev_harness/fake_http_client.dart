// Harness temporal para sacar capturas reales de cada pantalla sin pegarle
// a dh.formosa.gob.ar (producción, datos de salud reales). Intercepta TODO
// tráfico http.get/post de la app vía http.runWithClient y responde con JSON
// de mentira que respeta exactamente las claves que cada provider espera
// (verificadas leyendo lib/src/data/datasources/*.dart, no inventadas).
//
// NO se commitea: es solo para generar screenshots para la guía interactiva
// de web-admin-vacunacion.

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

typedef Responder = Map<String, dynamic> Function(Uri url);

/// DNI 11111111 devuelve un beneficiario menor de edad (para capturar la
/// pantalla de tutor); cualquier otro DNI devuelve la beneficiaria adulta.
Map<String, dynamic> _beneficiarioSegunDni(Uri uri) {
  final dni = uri.queryParameters['sysdesa10_dni'] ?? '';
  if (dni == '11111111') {
    return {
      'sysdesa10_apellido': 'Ramírez',
      'sysdesa10_nombre': 'Tomás',
      'sysdesa10_cuil': '',
      'sysdesa10_dni': dni,
      'sysdesa10_sexo': uri.queryParameters['sysdesa10_sexo'] ?? 'M',
      'sysdesa10_nro_tramite': '',
      'sysdesa10_fecha_nacimiento': '2018-02-10',
      'sysdesa10_edad': '8',
      'sysdesa10_cadena_dni': '',
      'codigo_mensaje': '1',
      'mensaje': 'OK',
      'foto_beneficiario': '',
    };
  }
  return {
    'sysdesa10_apellido': 'Fernández',
    'sysdesa10_nombre': 'Lucía',
    'sysdesa10_cuil': '27356789012',
    'sysdesa10_dni': dni.isNotEmpty ? dni : '35678901',
    'sysdesa10_sexo': uri.queryParameters['sysdesa10_sexo'] ?? 'F',
    'sysdesa10_nro_tramite': '',
    'sysdesa10_fecha_nacimiento': '1991-04-12',
    'sysdesa10_edad': '35',
    'sysdesa10_cadena_dni': '',
    'codigo_mensaje': '1',
    'mensaje': 'OK',
    'foto_beneficiario': '',
  };
}

class FakeHttpClient extends http.BaseClient {
  final List<MapEntry<String, Responder>> _rutas = [
    MapEntry('wserv_login.php', (_) => {
          'usuario': [
            {
              'id_flxcore03': '1001',
              'flxcore03_dni': '36355149',
              'flxcore03_nombre': 'Ana Gómez',
              'rela_sysofic01': '55',
              'sysofic01_descripcion': 'CAPS Barrio Guadalupe',
              'codigo_mensaje': '1',
              'mensaje': 'OK',
            }
          ]
        }),
    MapEntry('wserv_efector_registrador.php', (_) => {
          'usuario': [
            {
              'id_flxcore03': '1001',
              'flxcore03_dni': '36355149',
              'flxcore03_nombre': 'Ana Gómez',
              'rela_sysofic01': '55',
              'sysofic01_descripcion': 'CAPS Barrio Guadalupe',
            },
            {
              'id_flxcore03': '1001',
              'flxcore03_dni': '36355149',
              'flxcore03_nombre': 'Ana Gómez',
              'rela_sysofic01': '77',
              'sysofic01_descripcion': 'Hospital Central',
            },
          ]
        }),
    MapEntry('wserv_vacunador.php', (_) => {
          'vacunador': [
            {
              'id_sysdesa12': '501',
              'sysdesa06_nro_documento': '30123456',
              'sysdesa06_nombre': 'Carlos Pérez',
              'codigo_mensaje': '1',
              'mensaje': 'OK',
            }
          ]
        }),
    MapEntry('wserv_cantidad_vacunas_registradas.php', (_) => {
          'usuario': [
            {'cantidad_aplicaciones': '5'}
          ]
        }),
    MapEntry('wserv_obtener_datos_beneficiario.php', (uri) => {'beneficiario': [_beneficiarioSegunDni(uri)]}),
    MapEntry('wserv_obtener_datos_persona.php', (uri) => {'beneficiario': [_beneficiarioSegunDni(uri)]}),
    MapEntry('wserv_listados_vacunas.php', (_) => {
          'vacunas_aplicadas': [
            {
              'sysvacu04_nombre': 'Hepatitis B',
              'sysvacu05_nombre': '1ra Dosis',
              'sysdesa10_fecha_aplicacion': '2025-03-10',
              'fecha_proxima_dosis': '',
              'dias_transcurridos': '150',
              'sysdesa18_lote': 'HB2201',
              'sysvacu03_tiempo_interdosis': '',
            }
          ],
          'vacunas_pendientes': [
            {
              'rela_sysvacu01': '3',
              'sysvacu01_descripcion': 'Sin condición',
              'rela_sysvacu02': '7',
              'sysvacu02_descripcion': 'Esquema habitual',
              'rela_sysvacu04': '12',
              'sysvacu04_nombre': 'COVID-19',
              'rela_sysvacu05': '9',
              'sysvacu05_nombre': '1ra Dosis',
              'aplicacion_dentro_limite': 1,
            },
            {
              'rela_sysvacu01': '3',
              'sysvacu01_descripcion': 'Sin condición',
              'rela_sysvacu02': '7',
              'sysvacu02_descripcion': 'Esquema habitual',
              'rela_sysvacu04': '15',
              'sysvacu04_nombre': 'Antigripal',
              'rela_sysvacu05': '20',
              'sysvacu05_nombre': 'Única Dosis',
              'aplicacion_dentro_limite': 1,
            },
          ],
        }),
    MapEntry('wserv_obtener_perfil_vacunacion.php', (_) => {
          'perfiles_vacunacion': [
            {'id_sysvacu12': '1', 'sysvacu12_descripcion': 'Campaña Antigripal'},
            {'id_sysvacu12': '2', 'sysvacu12_descripcion': 'Calendario habitual'},
          ]
        }),
    MapEntry('wserv_obtener_vacunas_configuradas.php', (_) => {
          'vacunas_configuradas': [
            {'id_sysvacu04': '12', 'sysvacu04_nombre': 'COVID-19'},
            {'id_sysvacu04': '15', 'sysvacu04_nombre': 'Antigripal'},
            {'id_sysvacu04': '20', 'sysvacu04_nombre': 'Hepatitis B'},
          ]
        }),
    MapEntry('wserv_obtener_condicion_vacunas.php', (_) => {
          'condicion_vacunas': [
            {
              'id_sysvacu04': '12',
              'id_sysvacu01': '3',
              'sysvacu01_descripcion': 'Sin condición',
            },
            {
              'id_sysvacu04': '12',
              'id_sysvacu01': '4',
              'sysvacu01_descripcion': 'Personal de salud',
            },
          ]
        }),
    MapEntry('wserv_obtener_esquema_vacunas.php', (_) => {
          'esquema_vacunas': [
            {
              'id_sysvacu04': '12',
              'id_sysvacu01': '3',
              'id_sysvacu02': '7',
              'sysvacu02_descripcion': 'Esquema habitual',
            }
          ]
        }),
    MapEntry('wserv_obtener_dosis_vacunas.php', (_) => {
          'dosis_vacunas': [
            {
              'id_sysvacu04': '12',
              'id_sysvacu01': '3',
              'id_sysvacu02': '7',
              'id_sysvacu05': '9',
              'sysvacu05_nombre': '1ra Dosis',
            },
            {
              'id_sysvacu04': '12',
              'id_sysvacu01': '3',
              'id_sysvacu02': '7',
              'id_sysvacu05': '10',
              'sysvacu05_nombre': '2da Dosis',
            },
          ]
        }),
    MapEntry('wserv_obtener_lotes_vacunas.php', (_) => {
          'lotes_vacunas': [
            {
              'id_sysdesa18': '88',
              'sysdesa18_lote': 'AB1234',
              'sysdesa18_cantidad_actual': '40',
              'sysdesa18_fecha_vencimiento': '2026-12-31',
              'sysvacu02_descripcion': 'Esquema habitual',
            }
          ]
        }),
    MapEntry('wserv_registrar_vacuna.php', (_) => {
          'mensajes': [
            {'codigo_mensaje': '1', 'mensaje': 'Vacuna registrada correctamente.'}
          ]
        }),
    MapEntry('wserv_versiones_app.php', (_) => {
          'versiones': [
            {'id_sysappl01': '1', 'sysappl01_nombre': 'vacunacion', 'sysappl01_version': '4.0.0'}
          ]
        }),
  ];

  final http.Client _pasoDirecto = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Solo interceptamos el backend de producción (datos de salud reales).
    // Todo lo demás (fonts.gstatic.com, etc.) pasa directo: no hay riesgo.
    if (request.url.host != 'dh.formosa.gob.ar') {
      return _pasoDirecto.send(request);
    }

    for (final ruta in _rutas) {
      if (request.url.path.contains(ruta.key)) {
        final body = utf8.encode(json.encode(ruta.value(request.url)));
        return http.StreamedResponse(
          Stream.value(Uint8List.fromList(body)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
    }
    // Ruta de producción no mapeada: 404 en vez de pegarle al servidor real.
    return http.StreamedResponse(Stream.value(Uint8List(0)), 404);
  }
}
