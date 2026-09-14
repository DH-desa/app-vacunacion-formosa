// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

PerfilesVacunacion perfilesVacunacionFromJson(String str) =>
    PerfilesVacunacion.fromJson(json.decode(str));

String perfilesVacunacionToJson(PerfilesVacunacion data) =>
    json.encode(data.toJson());

class PerfilesVacunacion {
  List<PerfilesVacunacion> items = [];
  PerfilesVacunacion({
    this.id_sysvacu12,
    this.sysvacu12_descripcion,
    this.codigo_mensaje,
    this.mensaje,
  });

  String? id_sysvacu12;
  String? sysvacu12_descripcion;
  String? codigo_mensaje;
  String? mensaje;

  factory PerfilesVacunacion.fromJson(Map<String, dynamic> json) =>
      PerfilesVacunacion(
        id_sysvacu12: json["id_sysvacu12"],
        sysvacu12_descripcion: fixEncoding(json["sysvacu12_descripcion"]),
        codigo_mensaje: json["codigo_mensaje"],
        mensaje: fixEncoding(json["mensaje"]),
      );

  PerfilesVacunacion.fromJsonMap(Map<String, dynamic> json) {
    id_sysvacu12 = json["id_sysvacu12"];
    sysvacu12_descripcion = fixEncoding(json["sysvacu12_descripcion"]);
    codigo_mensaje = json["codigo_mensaje"];
    mensaje = fixEncoding(json["mensaje"]);
  }

  Map<String, dynamic> toJson() => {
    "id_sysvacu12": id_sysvacu12,
    "sysvacu12_descripcion": sysvacu12_descripcion,
    "codigo_mensaje": codigo_mensaje,
    "mensaje": mensaje,
  };

  PerfilesVacunacion.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (final item in jsonList) {
      if (item is! Map) continue;
      final informacion = PerfilesVacunacion.fromJsonMap(
        Map<String, dynamic>.from(item),
      );
      items.add(informacion);
    }
  }
}
