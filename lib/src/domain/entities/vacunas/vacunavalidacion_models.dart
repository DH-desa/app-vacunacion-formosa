import 'dart:convert';

import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

List<ValidaVacunacion> validacionVacunaFromJson(String str) =>
    List<ValidaVacunacion>.from(
      json.decode(str).map((x) => ValidaVacunacion.fromJson(x)),
    );

String validacionVacunaToJson(List<ValidaVacunacion> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ValidaVacunacion {
  List<ValidaVacunacion> items = [];
  ValidaVacunacion({
    // ignore: non_constant_identifier_names
    this.id_sysdesa10,
    // ignore: non_constant_identifier_names
    this.sysdesa10_mensaje,
    // ignore: non_constant_identifier_names
    this.sysvacu04_nombre,
    // ignore: non_constant_identifier_names
    this.sysvacu05_nombre,
    // ignore: non_constant_identifier_names
    this.sysdesa10_fecha_aplicacion,
    // ignore: non_constant_identifier_names
    this.cumplen_veintiun_dias,
    // ignore: non_constant_identifier_names
    this.fecha_proxima_dosis,
    // ignore: non_constant_identifier_names
    this.dias_transcurridos,
    // ignore: non_constant_identifier_names
    this.faltan_dias_proxima_aplicacion,
    // ignore: non_constant_identifier_names
    this.codigo_mensaje,
    // ignore: non_constant_identifier_names
    this.mensaje,
  });

  // ignore: non_constant_identifier_names
  String? id_sysdesa10;
  // ignore: non_constant_identifier_names
  String? sysdesa10_mensaje;
  // ignore: non_constant_identifier_names
  String? sysvacu04_nombre;
  // ignore: non_constant_identifier_names
  String? sysvacu05_nombre;
  // ignore: non_constant_identifier_names
  String? sysdesa10_fecha_aplicacion;
  // ignore: non_constant_identifier_names
  String? cumplen_veintiun_dias;
  // ignore: non_constant_identifier_names
  String? fecha_proxima_dosis;
  // ignore: non_constant_identifier_names
  String? dias_transcurridos;
  // ignore: non_constant_identifier_names
  String? faltan_dias_proxima_aplicacion;
  // ignore: non_constant_identifier_names
  String? codigo_mensaje;
  String? mensaje;

  factory ValidaVacunacion.fromJson(Map<String, dynamic> json) =>
      ValidaVacunacion(
        id_sysdesa10: json["id_sysdesa10"],
        sysdesa10_mensaje: fixEncoding(json["sysdesa10_mensaje"]),
        sysvacu04_nombre: fixEncoding(json["sysvacu04_nombre"]),
        sysvacu05_nombre: fixEncoding(json["sysvacu05_nombre"]),
        sysdesa10_fecha_aplicacion: json["sysdesa10_fecha_aplicacion"],
        cumplen_veintiun_dias: json["cumplen_veintiun_dias"],
        fecha_proxima_dosis: json["fecha_proxima_dosis"],
        dias_transcurridos: json["dias_transcurridos"],
        faltan_dias_proxima_aplicacion: json["faltan_dias_proxima_aplicacion"],
        codigo_mensaje: json["codigo_mensaje"],
        mensaje: fixEncoding(json["mensaje"]),
      );

  ValidaVacunacion.fromJsonMap(Map<String, dynamic> json) {
    id_sysdesa10 = json["id_sysdesa10"];
    sysdesa10_mensaje = fixEncoding(json["sysdesa10_mensaje"]);
    sysvacu04_nombre = fixEncoding(json["sysvacu04_nombre"]);
    sysvacu05_nombre = fixEncoding(json["sysvacu05_nombre"]);
    sysdesa10_fecha_aplicacion = json["sysdesa10_fecha_aplicacion"];
    cumplen_veintiun_dias = json["cumplen_veintiun_dias"];
    fecha_proxima_dosis = json["fecha_proxima_dosis"];
    dias_transcurridos = json["dias_transcurridos"];
    faltan_dias_proxima_aplicacion = json["faltan_dias_proxima_aplicacion"];
    codigo_mensaje = json["codigo_mensaje"];
    mensaje = fixEncoding(json["mensaje"]);
  }

  Map<String?, dynamic> toJson() => {
    id_sysdesa10: id_sysdesa10,
    sysdesa10_mensaje: sysdesa10_mensaje,
    sysvacu04_nombre: sysvacu04_nombre,
    sysvacu05_nombre: sysvacu05_nombre,
    sysdesa10_fecha_aplicacion: sysdesa10_fecha_aplicacion,
    cumplen_veintiun_dias: cumplen_veintiun_dias,
    fecha_proxima_dosis: fecha_proxima_dosis,
    dias_transcurridos: dias_transcurridos,
    faltan_dias_proxima_aplicacion: faltan_dias_proxima_aplicacion,
    codigo_mensaje: codigo_mensaje,
    mensaje: mensaje,
  };

  ValidaVacunacion.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (final item in jsonList) {
      if (item is! Map) continue;
      final valVacunas = ValidaVacunacion.fromJsonMap(
        Map<String, dynamic>.from(item),
      );
      items.add(valVacunas);
    }
  }
}
