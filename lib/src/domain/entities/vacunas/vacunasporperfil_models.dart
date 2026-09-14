// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

VacunasxPerfil vacunasxPerfilFromJson(String str) =>
    VacunasxPerfil.fromJson(json.decode(str));

String vacunasxPerfilToJson(VacunasxPerfil data) => json.encode(data.toJson());

class VacunasxPerfil {
  List<VacunasxPerfil> items = [];
  VacunasxPerfil({
    this.id_sysvacu04,
    this.sysvacu04_nombre,
    this.codigo_mensaje,
    this.mensaje,
  });

  String? id_sysvacu04;
  String? sysvacu04_nombre;
  String? codigo_mensaje;
  String? mensaje;

  factory VacunasxPerfil.fromJson(Map<String, dynamic> json) => VacunasxPerfil(
    id_sysvacu04: json["id_sysvacu04"],
    sysvacu04_nombre: fixEncoding(json["sysvacu04_nombre"]),
    codigo_mensaje: json["codigo_mensaje"],
    mensaje: fixEncoding(json["mensaje"]),
  );

  VacunasxPerfil.fromJsonMap(Map<String, dynamic> json) {
    id_sysvacu04 = json["id_sysvacu04"];
    sysvacu04_nombre = fixEncoding(json["sysvacu04_nombre"]);
    codigo_mensaje = json["codigo_mensaje"];
    mensaje = fixEncoding(json["mensaje"]);
  }

  Map<String, dynamic> toJson() => {
    "id_sysvacu04": id_sysvacu04,
    "sysvacu04_nombre": sysvacu04_nombre,
    "codigo_mensaje": codigo_mensaje,
    "mensaje": mensaje,
  };

  VacunasxPerfil.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (final item in jsonList) {
      if (item is! Map) continue;
      final vacunasxperfiles = VacunasxPerfil.fromJsonMap(
        Map<String, dynamic>.from(item),
      );
      items.add(vacunasxperfiles);
    }
  }
}
