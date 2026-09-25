import 'dart:convert';

import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

List<CantidadVacunados> cantidadVacunadosFromJson(String str) =>
    List<CantidadVacunados>.from(
      json.decode(str).map((x) => CantidadVacunados.fromJson(x)),
    );

String cantidadVacunadosToJson(List<CantidadVacunados> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CantidadVacunados {
  List<CantidadVacunados> items = [];
  CantidadVacunados({
    // ignore: non_constant_identifier_names
    this.id_sysdesa12,
    // ignore: non_constant_identifier_names
    this.cantidad_aplicaciones,
    // ignore: non_constant_identifier_names
    this.codigo_mensaje,
    // ignore: non_constant_identifier_names
    this.mensaje,
  });

  // ignore: non_constant_identifier_names
  String? id_sysdesa12;
  // ignore: non_constant_identifier_names
  String? cantidad_aplicaciones;
  // ignore: non_constant_identifier_names
  String? codigo_mensaje;
  // ignore: non_constant_identifier_names
  String? mensaje;
  // ignore: non_constant_identifier_names

  factory CantidadVacunados.fromJson(Map<String, dynamic> json) =>
      CantidadVacunados(
        id_sysdesa12: json["id_sysdesa12"],
        cantidad_aplicaciones: json["cantidad_aplicaciones"],
        codigo_mensaje: json["codigo_mensaje"],
        mensaje: fixEncoding(json["mensaje"]),
      );

  CantidadVacunados.fromJsonMap(Map<String, dynamic> json) {
    id_sysdesa12 = json["id_sysdesa12"];
    cantidad_aplicaciones = json["cantidad_aplicaciones"];
    codigo_mensaje = json["codigo_mensaje"];
    mensaje = fixEncoding(json["mensaje"]);
  }

  Map<String?, dynamic> toJson() => {
    id_sysdesa12: id_sysdesa12,
    cantidad_aplicaciones: cantidad_aplicaciones,
    codigo_mensaje: codigo_mensaje,
    mensaje: mensaje,
  };

  CantidadVacunados.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (final item in jsonList) {
      if (item is! Map) continue;
      final cantidad = CantidadVacunados.fromJsonMap(
        Map<String, dynamic>.from(item),
      );
      items.add(cantidad);
    }
  }
}
