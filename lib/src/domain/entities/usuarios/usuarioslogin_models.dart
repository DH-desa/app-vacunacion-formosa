import 'dart:convert';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

List<Usuarios> usuariosFromJson(String str) =>
    List<Usuarios>.from(json.decode(str).map((x) => Usuarios.fromJson(x)));

String usuariosToJson(List<Usuarios> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Usuarios {
  List<Usuarios> items = [];

  // ignore: non_constant_identifier_names
  String? id_flxcore03;
  // ignore: non_constant_identifier_names
  String? flxcore03_dni;
  // ignore: non_constant_identifier_names
  String? flxcore03_nombre;
  // ignore: non_constant_identifier_names
  String? rela_sysofic01;
  // ignore: non_constant_identifier_names
  String? sysofic01_descripcion;
  // ignore: non_constant_identifier_names
  String? codigo_mensaje;
  String? mensaje;

  Usuarios({
    // ignore: non_constant_identifier_names
    this.id_flxcore03,
    // ignore: non_constant_identifier_names
    this.flxcore03_dni,
    // ignore: non_constant_identifier_names
    this.flxcore03_nombre,
    // ignore: non_constant_identifier_names
    this.rela_sysofic01,
    // ignore: non_constant_identifier_names
    this.sysofic01_descripcion,
    // ignore: non_constant_identifier_names
    this.codigo_mensaje,
    this.mensaje,
  });

  factory Usuarios.fromJson(Map<String, dynamic> json) => Usuarios(
    id_flxcore03: json["id_flxcore03"],
    flxcore03_dni: json["flxcore03_dni"],
    flxcore03_nombre: fixEncoding(json["flxcore03_nombre"]),
    rela_sysofic01: json["rela_sysofic01"],
    sysofic01_descripcion: fixEncoding(json["sysofic01_descripcion"]),
    codigo_mensaje: json["codigo_mensaje"],
    mensaje: fixEncoding(json["mensaje"]),
  );

  Usuarios.fromJsonMap(Map<String, dynamic> json) {
    id_flxcore03 = json["id_flxcore03"];
    flxcore03_dni = json["flxcore03_dni"];
    flxcore03_nombre = fixEncoding(json["flxcore03_nombre"]);
    rela_sysofic01 = json["rela_sysofic01"];
    sysofic01_descripcion = fixEncoding(json["sysofic01_descripcion"]);
    codigo_mensaje = json["codigo_mensaje"];
    mensaje = fixEncoding(json["mensaje"]);
  }

  Map<String?, dynamic> toJson() => {
    id_flxcore03: id_flxcore03,
    flxcore03_dni: flxcore03_dni,
    flxcore03_nombre: flxcore03_nombre,
    rela_sysofic01: rela_sysofic01,
    sysofic01_descripcion: sysofic01_descripcion,
    codigo_mensaje: codigo_mensaje,
    mensaje: mensaje,
  };

  Usuarios.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (final item in jsonList) {
      if (item is! Map) continue;
      final usuario = Usuarios.fromJsonMap(Map<String, dynamic>.from(item));
      items.add(usuario);
    }
  }
}
