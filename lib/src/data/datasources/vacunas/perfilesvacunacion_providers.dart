import 'dart:async';
import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/core/debug/dev_log_service.dart';
import 'package:sistema_vacunacion/src/domain/entities/models.dart';
import 'dart:convert';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

import 'package:sistema_vacunacion/src/presentation/state/services.dart';

class _PerfilesVacunacionProviders {
  Future<List<PerfilesVacunacion>> procesarRespuestaDos(Uri url) async {
    try {
      final resp = await devHttpGet('perfiles_vacunacion', url,
          timeout: const Duration(seconds: 30));
      if (resp.statusCode == 200) {
        final decodedData = json.decode(decodificarRespuestaHTTP(resp.bodyBytes));
        final perfiles =
            PerfilesVacunacion.fromJsonList(decodedData['perfiles_vacunacion']);
        return perfiles.items;
      }
    } catch (e) {
      throw 'Ocurrio un error $e';
    }

    throw 'Ocurrio un error';
  }

  /// Siempre actualiza el servicio para que la UI no quede en carga infinita.
  Future<void> obtenerDatosPerfilesVacunacion(String? rela) async {
    final url =
        Uri(scheme: scheme, host: host, path: urlPerfiVacu, queryParameters: {
      'rela_flxcore03': rela,
    });

    try {
      final List<PerfilesVacunacion> resp = await procesarRespuestaDos(url);
      if (resp.isEmpty) {
        perfilesVacunacionService.cargarlistaPerfilesVacunacion([]);
        return;
      }
      // Mismo criterio que en vacunas: codigo_mensaje "0" indica error del backend.
      if (resp.first.codigo_mensaje == '0') {
        final texto = resp.first.mensaje?.trim();
        perfilesVacunacionService.cargarlistaPerfilesVacunacion(
          [],
          mensajeSiListaVacia: (texto != null && texto.isNotEmpty)
              ? texto
              : 'No se pudieron obtener los perfiles de vacunación.',
        );
        return;
      }
      perfilesVacunacionService.cargarlistaPerfilesVacunacion(resp);
    } catch (_) {
      perfilesVacunacionService.cargarlistaPerfilesVacunacion(
        [],
        mensajeSiListaVacia:
            'No se pudo conectar con el servidor. Revise su conexión e intente de nuevo.',
      );
    }
  }
}

final perfilesProviders = _PerfilesVacunacionProviders();
