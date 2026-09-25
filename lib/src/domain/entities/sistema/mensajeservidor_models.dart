import 'dart:convert';

import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

List<MensajeServidor> mensajeServidorFromJson(String str) =>
    List<MensajeServidor>.from(
      json.decode(str).map((x) => MensajeServidor.fromJson(x)),
    );

String mensajeServidorToJson(List<MensajeServidor> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class MensajeServidor {
  List<MensajeServidor> items = [];
  MensajeServidor({
    // ignore: non_constant_identifier_names
    this.codigo_mensaje,
    // ignore: non_constant_identifier_names
    this.mensaje,
    // ignore: non_constant_identifier_names
  });
  // ignore: non_constant_identifier_names
  String? codigo_mensaje;
  // ignore: non_constant_identifier_names
  String? mensaje;
  // ignore: non_constant_identifier_names

  factory MensajeServidor.fromJson(Map<String, dynamic> json) =>
      MensajeServidor(
        codigo_mensaje: json["codigo_mensaje"],
        mensaje: fixEncoding(json["mensaje"]),
      );

  MensajeServidor.fromJsonMap(Map<String, dynamic> json) {
    codigo_mensaje = json["codigo_mensaje"];
    mensaje = fixEncoding(json["mensaje"]);
  }

  Map<String?, dynamic> toJson() => {
    codigo_mensaje: codigo_mensaje,
    mensaje: mensaje,
  };

  MensajeServidor.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;
    for (final item in jsonList) {
      if (item is! Map) continue;
      final menServidor = MensajeServidor.fromJsonMap(
        Map<String, dynamic>.from(item),
      );
      items.add(menServidor);
    }
  }
}
