import 'dart:convert';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

List<Lotes> lotesVacunasFromJson(String str) =>
    List<Lotes>.from(json.decode(str).map((x) => Lotes.fromJson(x)));

String lotesVacunasToJson(List<Lotes> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Lotes {
  List<Lotes> items = [];
  Lotes({
    // ignore: non_constant_identifier_names
    this.id_sysdesa18,
    // ignore: non_constant_identifier_names
    this.sysdesa18_lote,
    // ignore: non_constant_identifier_names
    this.sysdesa18_cantidad_actual,
    // ignore: non_constant_identifier_names
    this.sysdesa18_fecha_vencimiento,
    // ignore: non_constant_identifier_names
    this.sysvacu02_descripcion,
    // ignore: non_constant_identifier_names
    this.codigo_mensaje,
    // ignore: non_constant_identifier_names
    this.mensaje,
  });

  // ignore: non_constant_identifier_names
  String? id_sysdesa18;
  // ignore: non_constant_identifier_names
  String? sysdesa18_lote;
  // ignore: non_constant_identifier_names
  String? sysdesa18_cantidad_actual;
  // ignore: non_constant_identifier_names
  String? sysdesa18_fecha_vencimiento;
  // ignore: non_constant_identifier_names
  String? sysvacu02_descripcion;
  // ignore: non_constant_identifier_names
  String? codigo_mensaje;
  // ignore: non_constant_identifier_names
  String? mensaje;

  factory Lotes.fromJson(Map<String, dynamic> json) => Lotes(
    id_sysdesa18: json["id_sysdesa18"],
    sysdesa18_lote: fixEncoding(json["sysdesa18_lote"]),
    sysdesa18_cantidad_actual: json["sysdesa18_cantidad_actual"],
    sysdesa18_fecha_vencimiento: json["sysdesa18_fecha_vencimiento"],
    sysvacu02_descripcion: fixEncoding(json["sysvacu02_descripcion"]),
    codigo_mensaje: json["codigo_mensaje"],
    mensaje: fixEncoding(json["mensaje"]),
  );

  Lotes.fromJsonMap(Map<String, dynamic> json) {
    id_sysdesa18 = json["id_sysdesa18"];
    sysdesa18_lote = fixEncoding(json["sysdesa18_lote"]);
    sysdesa18_cantidad_actual = json["sysdesa18_cantidad_actual"];
    sysdesa18_fecha_vencimiento = json["sysdesa18_fecha_vencimiento"];
    sysvacu02_descripcion = fixEncoding(json["sysvacu02_descripcion"]);
    codigo_mensaje = json["codigo_mensaje"];
    mensaje = fixEncoding(json["mensaje"]);
  }

  Map<String?, dynamic> toJson() => {
    id_sysdesa18: id_sysdesa18,
    sysdesa18_lote: sysdesa18_lote,
    sysdesa18_cantidad_actual: sysdesa18_cantidad_actual,
    sysdesa18_fecha_vencimiento: sysdesa18_fecha_vencimiento,
    sysvacu02_descripcion: sysvacu02_descripcion,
    codigo_mensaje: codigo_mensaje,
    mensaje: mensaje,
  };

  Lotes.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (final item in jsonList) {
      if (item is! Map) continue;
      final lotes = Lotes.fromJsonMap(Map<String, dynamic>.from(item));
      items.add(lotes);
    }
  }

  String userAsString() {
    return '$sysdesa18_lote';
  }
}
