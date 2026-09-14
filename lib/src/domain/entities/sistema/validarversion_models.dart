import 'dart:convert';

import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

List<Version> versionFromJson(String str) =>
    List<Version>.from(json.decode(str).map((x) => Version.fromJson(x)));

String versionToJson(List<Version> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Version {
  List<Version> items = [];
  Version({
    // ignore: non_constant_identifier_names
    this.id_sysappl01,
    // ignore: non_constant_identifier_names
    this.sysappl01_nombre,
    // ignore: non_constant_identifier_names
    this.sysappl01_version,
    // ignore: non_constant_identifier_names
    this.sysappl01_fecha_actualizacion,
    // ignore: non_constant_identifier_names
    this.codigo_mensaje,
    // ignore: non_constant_identifier_names
    this.mensaje,
  });

  // ignore: non_constant_identifier_names
  String? id_sysappl01;
  // ignore: non_constant_identifier_names
  String? sysappl01_nombre;
  // ignore: non_constant_identifier_names
  String? sysappl01_version;
  // ignore: non_constant_identifier_names
  String? sysappl01_fecha_actualizacion;
  // ignore: non_constant_identifier_names
  String? codigo_mensaje;
  String? mensaje;

  factory Version.fromJson(Map<String, dynamic> json) => Version(
    id_sysappl01: json["id_sysappl01"],
    sysappl01_nombre: fixEncoding(json["sysappl01_nombre"]),
    sysappl01_version: json["sysappl01_version"],
    sysappl01_fecha_actualizacion: json["sysappl01_fecha_actualizacion"],
    codigo_mensaje: json["codigo_mensaje"],
    mensaje: fixEncoding(json["mensaje"]),
  );

  Version.fromJsonMap(Map<String, dynamic> json) {
    id_sysappl01 = json["id_sysappl01"];
    sysappl01_nombre = fixEncoding(json["sysappl01_nombre"]);
    sysappl01_version = json["sysappl01_version"];
    sysappl01_fecha_actualizacion = json["sysappl01_fecha_actualizacion"];
    codigo_mensaje = json["codigo_mensaje"];
    mensaje = fixEncoding(json["mensaje"]);
  }

  Map<String?, dynamic> toJson() => {
    id_sysappl01: id_sysappl01,
    sysappl01_nombre: sysappl01_nombre,
    sysappl01_version: sysappl01_version,
    sysappl01_fecha_actualizacion: sysappl01_fecha_actualizacion,
    codigo_mensaje: codigo_mensaje,
    mensaje: mensaje,
  };

  Version.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (final item in jsonList) {
      if (item is! Map) continue;
      final version = Version.fromJsonMap(Map<String, dynamic>.from(item));
      items.add(version);
    }
  }
}
