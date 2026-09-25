// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

VacunasCondicion vacunasCondicionFromJson(String str) =>
    VacunasCondicion.fromJson(json.decode(str));

String vacunasCondicionToJson(VacunasCondicion data) =>
    json.encode(data.toJson());

class VacunasCondicion {
  List<VacunasCondicion> items = [];
  VacunasCondicion({
    this.id_sysvacu01,
    this.sysvacu01_codigo,
    this.sysvacu01_descripcion,
    this.sysvacu01_orden,
    this.sysvacu01_abreviatura,
    this.codigo_mensaje,
    this.mensaje,
  });

  String? id_sysvacu01;
  String? sysvacu01_codigo;
  String? sysvacu01_descripcion;
  String? sysvacu01_orden;
  String? sysvacu01_abreviatura;
  String? codigo_mensaje;
  String? mensaje;

  factory VacunasCondicion.fromJson(Map<String, dynamic> json) =>
      VacunasCondicion(
        id_sysvacu01: json["id_sysvacu01"],
        sysvacu01_codigo: json["sysvacu01_codigo"],
        sysvacu01_descripcion: fixEncoding(json["sysvacu01_descripcion"]),
        sysvacu01_orden: json["sysvacu01_orden"],
        sysvacu01_abreviatura: fixEncoding(json["sysvacu01_abreviatura"]),
        codigo_mensaje: json["codigo_mensaje"],
        mensaje: fixEncoding(json["mensaje"]),
      );

  VacunasCondicion.fromJsonMap(Map<String, dynamic> json) {
    id_sysvacu01 = json["id_sysvacu01"];
    sysvacu01_codigo = json["sysvacu01_codigo"];
    sysvacu01_descripcion = fixEncoding(json["sysvacu01_descripcion"]);
    sysvacu01_orden = json["sysvacu01_orden"];
    sysvacu01_abreviatura = fixEncoding(json["sysvacu01_abreviatura"]);
    codigo_mensaje = json["codigo_mensaje"];
    mensaje = fixEncoding(json["mensaje"]);
  }

  Map<String, dynamic> toJson() => {
    "id_sysvacu01": id_sysvacu01,
    "sysvacu01_codigo": sysvacu01_codigo,
    "sysvacu01_descripcion": sysvacu01_descripcion,
    "sysvacu01_orden": sysvacu01_orden,
    "sysvacu01_abreviatura": sysvacu01_abreviatura,
    "codigo_mensaje": codigo_mensaje,
    "mensaje": mensaje,
  };

  VacunasCondicion.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (final item in jsonList) {
      if (item is! Map) continue;
      final vacunasCondiciones = VacunasCondicion.fromJsonMap(
        Map<String, dynamic>.from(item),
      );
      items.add(vacunasCondiciones);
    }
  }
}
