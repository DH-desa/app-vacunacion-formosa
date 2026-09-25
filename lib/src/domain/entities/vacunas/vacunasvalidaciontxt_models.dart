import 'dart:convert';

import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

List<ValidaVacunacionTxt> valVacunasTXTFromJson(String str) =>
    List<ValidaVacunacionTxt>.from(
      json.decode(str).map((x) => ValidaVacunacionTxt.fromJson(x)),
    );

String valVacunasTXTToJson(List<ValidaVacunacionTxt> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ValidaVacunacionTxt {
  List<ValidaVacunacionTxt> items = [];
  ValidaVacunacionTxt({
    // ignore: non_constant_identifier_names
    this.sysdesa10_dni,
    // ignore: non_constant_identifier_names
    this.sysdesa10_nro_tramite,

    // ignore: non_constant_identifier_names
    this.sysdesa10_nombre,

    // ignore: non_constant_identifier_names
    this.sysdesa10_apellido,

    // ignore: non_constant_identifier_names
    this.sysdesa10_sexo,
    // ignore: non_constant_identifier_names
    this.codigo_mensaje,
    // ignore: non_constant_identifier_names
    this.mensaje,
  });

  // ignore: non_constant_identifier_names
  String? sysdesa10_dni;
  // ignore: non_constant_identifier_names
  String? sysdesa10_nro_tramite;
  // ignore: non_constant_identifier_names
  String? sysdesa10_nombre;
  // ignore: non_constant_identifier_names
  String? sysdesa10_apellido;
  // ignore: non_constant_identifier_names
  String? sysdesa10_sexo;
  // ignore: non_constant_identifier_names
  String? codigo_mensaje;
  String? mensaje;

  factory ValidaVacunacionTxt.fromJson(Map<String, dynamic> json) =>
      ValidaVacunacionTxt(
        sysdesa10_dni: json["sysdesa10_dni"],
        sysdesa10_nro_tramite: json["sysdesa10_nro_tramite"],
        sysdesa10_nombre: fixEncoding(json["sysdesa10_nombre"]),
        sysdesa10_apellido: fixEncoding(json["sysdesa10_apellido"]),
        sysdesa10_sexo: json["sysdesa10_sexo"],
        codigo_mensaje: json["codigo_mensaje"],
        mensaje: fixEncoding(json["mensaje"]),
      );

  ValidaVacunacionTxt.fromJsonMap(Map<String, dynamic> json) {
    sysdesa10_dni = json["sysdesa10_dni"];
    sysdesa10_nro_tramite = json["sysdesa10_nro_tramite"];
    sysdesa10_nombre = fixEncoding(json["sysdesa10_nombre"]);
    sysdesa10_apellido = fixEncoding(json["sysdesa10_apellido"]);
    sysdesa10_sexo = json["sysdesa10_sexo"];
    codigo_mensaje = json["codigo_mensaje"];
    mensaje = fixEncoding(json["mensaje"]);
  }

  Map<String?, dynamic> toJson() => {
    sysdesa10_dni: sysdesa10_dni,
    sysdesa10_nro_tramite: sysdesa10_nro_tramite,
    sysdesa10_nombre: sysdesa10_nombre,
    sysdesa10_apellido: sysdesa10_apellido,
    sysdesa10_sexo: sysdesa10_sexo,
    codigo_mensaje: codigo_mensaje,
    mensaje: mensaje,
  };

  ValidaVacunacionTxt.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (final item in jsonList) {
      if (item is! Map) continue;
      final valVacunasTXT = ValidaVacunacionTxt.fromJsonMap(
        Map<String, dynamic>.from(item),
      );
      items.add(valVacunasTXT);
    }
  }
}
