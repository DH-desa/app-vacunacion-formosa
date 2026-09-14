import 'dart:convert';

Efectores efectoresFromJson(String str) => Efectores.fromJson(json.decode(str));

String efectoresToJson(Efectores data) => json.encode(data.toJson());

class Efectores {
  List<Efectores> items = [];
  Efectores({
    this.idFlxcore03,
    this.flxcore03Dni,
    this.flxcore03Nombre,
    this.relaSysofic01,
    this.sysofic01Descripcion,
  });

  String? idFlxcore03;
  String? flxcore03Dni;
  String? flxcore03Nombre;
  String? relaSysofic01;
  String? sysofic01Descripcion;

  factory Efectores.fromJson(Map<String, dynamic> json) => Efectores(
    idFlxcore03: json["id_flxcore03"],
    flxcore03Dni: json["flxcore03_dni"],
    flxcore03Nombre: json["flxcore03_nombre"],
    relaSysofic01: json["rela_sysofic01"],
    sysofic01Descripcion: json["sysofic01_descripcion"],
  );

  Efectores.fromJsonMap(Map<String, dynamic> json) {
    idFlxcore03 = json["id_flxcore03"];
    flxcore03Dni = json["flxcore03_dni"];
    flxcore03Nombre = json["flxcore03_nombre"];
    relaSysofic01 = json["rela_sysofic01"];
    sysofic01Descripcion = json["sysofic01_descripcion"];
  }

  Map<String, dynamic> toJson() => {
    "id_flxcore03": idFlxcore03,
    "flxcore03_dni": flxcore03Dni,
    "flxcore03_nombre": flxcore03Nombre,
    "rela_sysofic01": relaSysofic01,
    "sysofic01_descripcion": sysofic01Descripcion,
  };

  Efectores.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (final item in jsonList) {
      if (item is! Map) continue;
      final informacion = Efectores.fromJsonMap(
        Map<String, dynamic>.from(item),
      );
      items.add(informacion);
    }
  }
}
