import 'dart:convert';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

List<Vacunador> vacunadorFromJson(String str) =>
    List<Vacunador>.from(json.decode(str).map((x) => Vacunador.fromJson(x)));

String vacunadorToJson(List<Vacunador> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Vacunador {
  List<Vacunador> items = [];
  Vacunador({
    // ignore: non_constant_identifier_names
    this.id_sysdesa12,
    // ignore: non_constant_identifier_names
    this.sysdesa06_nro_documento,
    // ignore: non_constant_identifier_names
    this.sysdesa06_nombre,
    // ignore: non_constant_identifier_names
    this.codigo_mensaje,
    // ignore: non_constant_identifier_names
    this.mensaje,
  });

  // ignore: non_constant_identifier_names
  String? id_sysdesa12;
  // ignore: non_constant_identifier_names
  String? sysdesa06_nro_documento;
  // ignore: non_constant_identifier_names
  String? sysdesa06_nombre;

  // ignore: non_constant_identifier_names
  String? codigo_mensaje;
  String? mensaje;

  factory Vacunador.fromJson(Map<String, dynamic> json) => Vacunador(
    id_sysdesa12: json["id_sysdesa12"],
    sysdesa06_nro_documento: json["sysdesa06_nro_documento"],
    sysdesa06_nombre: fixEncoding(json["sysdesa06_nombre"]),
    codigo_mensaje: json["codigo_mensaje"],
    mensaje: fixEncoding(json["mensaje"]),
  );

  Vacunador.fromJsonMap(Map<String, dynamic> json) {
    id_sysdesa12 = json["id_sysdesa12"];
    sysdesa06_nro_documento = json["sysdesa06_nro_documento"];
    sysdesa06_nombre = fixEncoding(json["sysdesa06_nombre"]);
    codigo_mensaje = json["codigo_mensaje"];
    mensaje = fixEncoding(json["mensaje"]);
  }

  Map<String?, dynamic> toJson() => {
    id_sysdesa12: id_sysdesa12,
    sysdesa06_nro_documento: sysdesa06_nro_documento,
    sysdesa06_nombre: sysdesa06_nombre,
    codigo_mensaje: codigo_mensaje,
    mensaje: mensaje,
  };

  Vacunador.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (final item in jsonList) {
      if (item is! Map) continue;
      final vacunador = Vacunador.fromJsonMap(Map<String, dynamic>.from(item));
      items.add(vacunador);
    }
  }
}
