import 'dart:convert';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

List<ConfiVacuna> confiVacunasFromJson(String str) => List<ConfiVacuna>.from(
  json.decode(str).map((x) => ConfiVacuna.fromJson(x)),
);

String confiVacunasToJson(List<ConfiVacuna> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ConfiVacuna {
  List<ConfiVacuna> items = [];
  ConfiVacuna({
    // ignore: non_constant_identifier_names
    this.id_sysvacu03,
    // ignore: non_constant_identifier_names
    this.sysvacu01_descripcion,
    // ignore: non_constant_identifier_names
    this.sysvacu02_descripcion,
    // ignore: non_constant_identifier_names
    this.sysvacu05_nombre,
    // ignore: non_constant_identifier_names
    this.sysvacu06_denominacion,
    // ignore: non_constant_identifier_names
    this.sysvacu05_orden,
    // ignore: non_constant_identifier_names
    this.codigo_mensaje,
    // ignore: non_constant_identifier_names
    this.mensaje,
  });

  // ignore: non_constant_identifier_names
  String? id_sysvacu03;
  // ignore: non_constant_identifier_names
  String? sysvacu01_descripcion;
  // ignore: non_constant_identifier_names
  String? sysvacu02_descripcion;
  // ignore: non_constant_identifier_names
  String? sysvacu05_nombre;
  // ignore: non_constant_identifier_names
  String? sysvacu06_denominacion;
  // ignore: non_constant_identifier_names
  String? sysvacu05_orden;
  // ignore: non_constant_identifier_names
  String? codigo_mensaje;
  // ignore: non_constant_identifier_names
  String? mensaje;

  factory ConfiVacuna.fromJson(Map<String, dynamic> json) => ConfiVacuna(
    id_sysvacu03: json["id_sysvacu03"],
    sysvacu01_descripcion: fixEncoding(json["sysvacu01_descripcion"]),
    sysvacu02_descripcion: fixEncoding(json["sysvacu02_descripcion"]),
    sysvacu05_nombre: fixEncoding(json["sysvacu05_nombre"]),
    sysvacu06_denominacion: fixEncoding(json["sysvacu06_denominacion"]),
    sysvacu05_orden: json["sysvacu05_orden"],
    codigo_mensaje: json["codigo_mensaje"],
    mensaje: fixEncoding(json["mensaje"]),
  );

  ConfiVacuna.fromJsonMap(Map<String, dynamic> json) {
    id_sysvacu03 = json["id_sysvacu03"];
    sysvacu01_descripcion = fixEncoding(json["sysvacu01_descripcion"]);
    sysvacu02_descripcion = fixEncoding(json["sysvacu02_descripcion"]);
    sysvacu05_nombre = fixEncoding(json["sysvacu05_nombre"]);
    sysvacu06_denominacion = fixEncoding(json["sysvacu06_denominacion"]);
    sysvacu05_orden = json["sysvacu05_orden"];
    codigo_mensaje = json["codigo_mensaje"];
    mensaje = fixEncoding(json["mensaje"]);
  }

  Map<String?, dynamic> toJson() => {
    id_sysvacu03: id_sysvacu03,
    sysvacu01_descripcion: sysvacu01_descripcion,
    sysvacu02_descripcion: sysvacu02_descripcion,
    sysvacu05_nombre: sysvacu05_nombre,
    sysvacu06_denominacion: sysvacu06_denominacion,
    sysvacu05_orden: sysvacu05_orden,
    codigo_mensaje: codigo_mensaje,
    mensaje: mensaje,
  };

  ConfiVacuna.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (final item in jsonList) {
      if (item is! Map) continue;
      final configuracion = ConfiVacuna.fromJsonMap(
        Map<String, dynamic>.from(item),
      );
      items.add(configuracion);
    }
  }

  String userAsString() {
    return '$sysvacu01_descripcion - $sysvacu02_descripcion - $sysvacu05_nombre - $sysvacu06_denominacion';
  }
}
