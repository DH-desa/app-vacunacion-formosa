// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

VacunasDosis vacunasDosisFromJson(String str) =>
    VacunasDosis.fromJson(json.decode(str));

String vacunasDosisToJson(VacunasDosis data) => json.encode(data.toJson());

class VacunasDosis {
  List<VacunasDosis> items = [];
  VacunasDosis({
    this.id_sysvacu05,
    this.sysvacu05_nombre,
    this.sysvacu05_orden,
    this.sysvacu05_cod_sisa,
    this.sysvacu05_esquema,
    this.sysvacu05_orden_numerico,
    this.codigo_mensaje,
    this.mensaje,
  });

  String? id_sysvacu05;
  String? sysvacu05_nombre;
  String? sysvacu05_orden;
  String? sysvacu05_cod_sisa;
  String? sysvacu05_esquema;
  String? sysvacu05_orden_numerico;
  String? codigo_mensaje;
  String? mensaje;

  factory VacunasDosis.fromJson(Map<String, dynamic> json) => VacunasDosis(
    id_sysvacu05: json["id_sysvacu05"],
    sysvacu05_nombre: fixEncoding(json["sysvacu05_nombre"]),
    sysvacu05_orden: fixEncoding(json["sysvacu05_orden"]),
    sysvacu05_cod_sisa: json["sysvacu05_cod_sisa"],
    sysvacu05_esquema: json["sysvacu05_esquema"],
    sysvacu05_orden_numerico: json["sysvacu05_orden_numerico"],
    codigo_mensaje: json["codigo_mensaje"],
    mensaje: fixEncoding(json["mensaje"]),
  );

  VacunasDosis.fromJsonMap(Map<String, dynamic> json) {
    id_sysvacu05 = json["id_sysvacu05"];
    sysvacu05_nombre = fixEncoding(json["sysvacu05_nombre"]);
    sysvacu05_orden = fixEncoding(json["sysvacu05_orden"]);
    sysvacu05_cod_sisa = json["sysvacu05_cod_sisa"];
    sysvacu05_esquema = json["sysvacu05_esquema"];
    sysvacu05_orden_numerico = json["sysvacu05_orden_numerico"];
    codigo_mensaje = json["codigo_mensaje"];
    mensaje = fixEncoding(json["mensaje"]);
  }

  Map<String, dynamic> toJson() => {
    "id_sysvacu05": id_sysvacu05,
    "sysvacu05_nombre": sysvacu05_nombre,
    "sysvacu05_orden": sysvacu05_orden,
    "sysvacu05_cod_sisa": sysvacu05_cod_sisa,
    "sysvacu05_esquema": sysvacu05_esquema,
    "sysvacu05_orden_numerico": sysvacu05_orden_numerico,
    "codigo_mensaje": codigo_mensaje,
    "mensaje": mensaje,
  };

  VacunasDosis.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (final item in jsonList) {
      if (item is! Map) continue;
      final vacunasDosis = VacunasDosis.fromJsonMap(
        Map<String, dynamic>.from(item),
      );
      items.add(vacunasDosis);
    }
  }
}
