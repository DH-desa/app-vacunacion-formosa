import 'dart:async';

import 'package:http/http.dart' as http;

enum DevLogTipo { apiRequest, apiResponse, apiError, estadoCambiado, info }

class DevLogEntry {
  final DateTime timestamp;
  final DevLogTipo tipo;
  final String tag;
  final String mensaje;
  final Map<String, dynamic>? datos;

  DevLogEntry({
    required this.timestamp,
    required this.tipo,
    required this.tag,
    required this.mensaje,
    this.datos,
  });
}

class _DevLogService {
  final List<DevLogEntry> _logs = [];
  // ignore: close_sinks
  final StreamController<List<DevLogEntry>> _ctrl =
      StreamController<List<DevLogEntry>>.broadcast();

  Stream<List<DevLogEntry>> get logsStream => _ctrl.stream;
  List<DevLogEntry> get logs => List.unmodifiable(_logs);

  void log(
    DevLogTipo tipo,
    String tag,
    String mensaje, {
    Map<String, dynamic>? datos,
  }) {
    _logs.insert(
      0,
      DevLogEntry(
        timestamp: DateTime.now(),
        tipo: tipo,
        tag: tag,
        mensaje: mensaje,
        datos: datos,
      ),
    );
    if (_logs.length > 200) _logs.removeLast();
    _ctrl.add(List.unmodifiable(_logs));
  }

  void limpiar() {
    _logs.clear();
    _ctrl.add(List.unmodifiable(_logs));
  }
}

final devLogService = _DevLogService();

/// GET instrumentado: registra request, response y error en el DEV Panel.
/// El timeout solo se aplica si se pasa, para no alterar el comportamiento
/// de los providers que no lo tenian.
Future<http.Response> devHttpGet(
  String tag,
  Uri url, {
  Duration? timeout,
}) async {
  devLogService.log(
    DevLogTipo.apiRequest,
    tag,
    'GET ${url.path}',
    datos: url.queryParameters.isEmpty ? null : url.queryParameters,
  );
  try {
    final futuro = http.get(url);
    final resp = await (timeout == null ? futuro : futuro.timeout(timeout));
    devLogService.log(
      resp.statusCode == 200 ? DevLogTipo.apiResponse : DevLogTipo.apiError,
      tag,
      'HTTP ${resp.statusCode} · ${resp.bodyBytes.length} bytes',
    );
    return resp;
  } catch (e) {
    devLogService.log(DevLogTipo.apiError, tag, '$e');
    rethrow;
  }
}
