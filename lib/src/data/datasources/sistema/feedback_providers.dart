import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:sistema_vacunacion/src/config/config.dart';

class _FeedbackProvider {
  Future<void> enviarFeedback({
    required String tipo,
    required String mensaje,
    required String contacto,
  }) async {
    final url = Uri(scheme: 'https', host: hostFeedback, path: urlFeedback);

    http.Response resp;
    try {
      resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'},
            body: {'tipo': tipo, 'mensaje': mensaje, 'contacto': contacto},
          )
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw 'Sin conexión a internet. Verificá tu conexión e intentá de nuevo.';
    } on TimeoutException {
      throw 'El servidor tardó demasiado en responder. Intentá de nuevo.';
    } on http.ClientException {
      throw 'No se pudo conectar con el servidor. Intentá de nuevo.';
    }

    if (resp.statusCode == 429) {
      throw 'Demasiados envíos. Probá de nuevo más tarde.';
    }

    final Map<String, dynamic> data;
    try {
      data = json.decode(resp.body);
    } on FormatException {
      throw 'El servidor respondió de forma inesperada. Intentá más tarde.';
    }

    if (resp.statusCode != 200 || data['ok'] != true) {
      throw data['error']?.toString() ?? 'No se pudo enviar. Probá de nuevo.';
    }
  }
}

final feedbackProvider = _FeedbackProvider();
