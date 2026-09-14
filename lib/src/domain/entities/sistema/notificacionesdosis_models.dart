// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

List<NotificacionesDosis> notificacionDosisFromJson(String str) =>
    List<NotificacionesDosis>.from(
      json.decode(str).map((x) => NotificacionesDosis.fromJson(x)),
    );

String notificacionDosisToJson(List<NotificacionesDosis> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class NotificacionesDosis {
  List<NotificacionesDosis> items = [];
  NotificacionesDosis({
    this.sysvacu04_nombre,
    this.sysvacu05_nombre,
    this.sysdesa10_fecha_aplicacion,
    this.fecha_proxima_dosis,
    this.dias_transcurridos,
    this.sysdesa18_lote,
    this.sysvacu03_tiempo_interdosis,
    this.codigo_mensaje,
    this.mensaje,
  });

  String? sysvacu04_nombre;
  String? sysvacu05_nombre;
  String? sysdesa10_fecha_aplicacion;
  String? fecha_proxima_dosis;
  String? dias_transcurridos;

  String? sysdesa18_lote;
  String? sysvacu03_tiempo_interdosis;
  String? codigo_mensaje;
  String? mensaje;

  factory NotificacionesDosis.fromJson(Map<String, dynamic> json) =>
      NotificacionesDosis(
        sysvacu04_nombre: fixEncoding(json["sysvacu04_nombre"]),
        sysvacu05_nombre: fixEncoding(json["sysvacu05_nombre"]),
        sysdesa10_fecha_aplicacion: json["sysdesa10_fecha_aplicacion"],
        fecha_proxima_dosis: json["fecha_proxima_dosis"],
        dias_transcurridos: json["dias_transcurridos"],
        sysdesa18_lote: fixEncoding(json["sysdesa18_lote"]),
        sysvacu03_tiempo_interdosis: json["sysvacu03_tiempo_interdosis"],
        codigo_mensaje: json["codigo_mensaje"],
        mensaje: fixEncoding(json["mensaje"]),
      );

  NotificacionesDosis.fromJsonMap(Map<String, dynamic> json) {
    sysvacu04_nombre = fixEncoding(json["sysvacu04_nombre"]);
    sysvacu05_nombre = fixEncoding(json["sysvacu05_nombre"]);
    sysdesa10_fecha_aplicacion = json["sysdesa10_fecha_aplicacion"];
    fecha_proxima_dosis = json["fecha_proxima_dosis"];
    dias_transcurridos = json["dias_transcurridos"];
    sysdesa18_lote = fixEncoding(json["sysdesa18_lote"]);
    sysvacu03_tiempo_interdosis = json["sysvacu03_tiempo_interdosis"];
    codigo_mensaje = json["codigo_mensaje"];
    mensaje = fixEncoding(json["mensaje"]);
  }

  Map<String?, dynamic> toJson() => {
    sysvacu04_nombre: sysvacu04_nombre,
    sysvacu05_nombre: sysvacu05_nombre,
    sysdesa10_fecha_aplicacion: sysdesa10_fecha_aplicacion,
    sysdesa10_fecha_aplicacion: sysdesa10_fecha_aplicacion,
    fecha_proxima_dosis: fecha_proxima_dosis,
    dias_transcurridos: dias_transcurridos,
    sysdesa18_lote: sysdesa18_lote,
    sysvacu03_tiempo_interdosis: sysvacu03_tiempo_interdosis,
    codigo_mensaje: codigo_mensaje,
    mensaje: mensaje,
  };

  NotificacionesDosis.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (final item in jsonList) {
      if (item is! Map) continue;
      final notificacionesDosis = NotificacionesDosis.fromJsonMap(
        Map<String, dynamic>.from(item),
      );
      items.add(notificacionesDosis);
    }
  }
}
