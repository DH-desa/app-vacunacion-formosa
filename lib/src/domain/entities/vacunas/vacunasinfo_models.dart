import 'dart:convert';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

List<InfoVacunas> infoVacunasFromJson(String str) => List<InfoVacunas>.from(
  json.decode(str).map((x) => InfoVacunas.fromJson(x)),
);

String infoVacunasToJson(List<InfoVacunas> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class InfoVacunas {
  List<InfoVacunas> items = [];
  InfoVacunas({
    // ignore: non_constant_identifier_names
    this.id_sysvacu04,
    // ignore: non_constant_identifier_names
    this.sysvacu04_nombre,
    // ignore: non_constant_identifier_names
    this.codigo_mensaje,
    // ignore: non_constant_identifier_names
    this.mensaje,
  });

  // ignore: non_constant_identifier_names
  String? id_sysvacu04;
  // ignore: non_constant_identifier_names
  String? sysvacu04_nombre;
  // ignore: non_constant_identifier_names
  String? codigo_mensaje;
  // ignore: non_constant_identifier_names
  String? mensaje;

  factory InfoVacunas.fromJson(Map<String, dynamic> json) => InfoVacunas(
    id_sysvacu04: json["id_sysvacu04"],
    sysvacu04_nombre: fixEncoding(json["sysvacu04_nombre"]),
    codigo_mensaje: json["codigo_mensaje"],
    mensaje: fixEncoding(json["mensaje"]),
  );

  InfoVacunas.fromJsonMap(Map<String, dynamic> json) {
    id_sysvacu04 = json["id_sysvacu04"];
    sysvacu04_nombre = fixEncoding(json["sysvacu04_nombre"]);
    codigo_mensaje = json["codigo_mensaje"];
    mensaje = fixEncoding(json["mensaje"]);
  }

  Map<String?, dynamic> toJson() => {
    id_sysvacu04: id_sysvacu04,
    sysvacu04_nombre: sysvacu04_nombre,
    codigo_mensaje: codigo_mensaje,
    mensaje: mensaje,
  };

  InfoVacunas.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (final item in jsonList) {
      if (item is! Map) continue;
      final informacion = InfoVacunas.fromJsonMap(
        Map<String, dynamic>.from(item),
      );
      items.add(informacion);
    }
  }

  String userAsString() {
    return '$sysvacu04_nombre';
  }
}
