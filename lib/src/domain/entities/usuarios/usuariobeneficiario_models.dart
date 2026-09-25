import 'dart:convert';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

/// Convierte el valor JSON del campo foto a [String] (base64, data-URI o URL).
String? valorJsonAFotoBeneficiario(dynamic v) {
  if (v == null) return null;
  if (v is bool) return null;
  if (v is String) {
    var s = v.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('\uFEFF')) s = s.substring(1);
    return s;
  }
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

/// Prueba varias claves por si el backend renombra el campo.
String? fotoBeneficiarioDesdeJson(Map<String, dynamic> json) {
  const claves = [
    'foto_beneficiario',
    'fotoBeneficiario',
    'FotoBeneficiario',
    'foto',
  ];
  for (final k in claves) {
    if (!json.containsKey(k)) continue;
    final s = valorJsonAFotoBeneficiario(json[k]);
    if (s != null) return s;
  }
  return null;
}

/// El servicio devuelve `beneficiario` como lista; si mandan un solo objeto, lo envolvemos.
List<dynamic>? normalizarListaBeneficiarioDesdeJson(dynamic raw) {
  if (raw == null) return null;
  if (raw is List<dynamic>) return raw;
  if (raw is Map<String, dynamic>) return [raw];
  if (raw is Map) return [Map<String, dynamic>.from(raw)];
  return null;
}

List<Beneficiario> infoBeneficiarioFromJson(String str) =>
    List<Beneficiario>.from(
        json.decode(str).map((x) => Beneficiario.fromJson(x)));

String infoBeneficiarioToJson(List<Beneficiario> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Beneficiario {
  List<Beneficiario> items = [];
  Beneficiario({
    // ignore: non_constant_identifier_names
    this.sysdesa10_apellido,
    // ignore: non_constant_identifier_names
    this.sysdesa10_nombre,
    // ignore: non_constant_identifier_names
    this.sysdesa10_cuil,
    // ignore: non_constant_identifier_names
    this.sysdesa10_dni,
    // ignore: non_constant_identifier_names
    this.sysdesa10_sexo,
    // ignore: non_constant_identifier_names
    this.sysdesa10_nro_tramite,
    // ignore: non_constant_identifier_names
    this.sysdesa10_fecha_nacimiento,
    // ignore: non_constant_identifier_names
    this.sysdesa10_edad,
    // ignore: non_constant_identifier_names
    this.sysdesa10_cadena_dni,
    // ignore: non_constant_identifier_names
    this.codigo_mensaje,
    // ignore: non_constant_identifier_names
    this.mensaje,
    // ignore: non_constant_identifier_names
    this.foto_beneficiario,
  });
  // ignore: non_constant_identifier_names
  String? sysdesa10_apellido;
  // ignore: non_constant_identifier_names
  String? sysdesa10_nombre;
  // ignore: non_constant_identifier_names
  String? sysdesa10_cuil;
  // ignore: non_constant_identifier_names
  String? sysdesa10_dni;
  // ignore: non_constant_identifier_names
  String? sysdesa10_sexo;
  // ignore: non_constant_identifier_names
  String? sysdesa10_nro_tramite;
  // ignore: non_constant_identifier_names
  String? sysdesa10_fecha_nacimiento;
  // ignore: non_constant_identifier_names
  String? sysdesa10_edad;
  // ignore: non_constant_identifier_names
  String? sysdesa10_cadena_dni;
  // ignore: non_constant_identifier_names
  String? codigo_mensaje;

  dynamic mensaje;
  // ignore: non_constant_identifier_names
  String? foto_beneficiario;

  // ignore: non_constant_identifier_names

  factory Beneficiario.fromJson(Map<String, dynamic> json) => Beneficiario(
        sysdesa10_apellido: fixEncoding(json["sysdesa10_apellido"]),
        sysdesa10_nombre: fixEncoding(json["sysdesa10_nombre"]),
        sysdesa10_cuil: json["sysdesa10_cuil"],
        sysdesa10_dni: json["sysdesa10_dni"],
        sysdesa10_sexo: json["sysdesa10_sexo"],
        sysdesa10_nro_tramite: json["sysdesa10_nro_tramite"],
        sysdesa10_fecha_nacimiento: json["sysdesa10_fecha_nacimiento"]?.toString(),
        sysdesa10_edad: json["sysdesa10_edad"]?.toString(),
        sysdesa10_cadena_dni: json["sysdesa10_cadena_dni"],
        codigo_mensaje: json["codigo_mensaje"],
        mensaje: fixEncoding(json["mensaje"]),
        foto_beneficiario: fotoBeneficiarioDesdeJson(json),
      );
  Beneficiario.fromJsonMap(Map<String, dynamic> json) {
    sysdesa10_apellido = fixEncoding(json["sysdesa10_apellido"]);
    sysdesa10_nombre = fixEncoding(json["sysdesa10_nombre"]);
    sysdesa10_cuil = json["sysdesa10_cuil"];
    sysdesa10_dni = json["sysdesa10_dni"];
    sysdesa10_sexo = json["sysdesa10_sexo"];
    sysdesa10_nro_tramite = json["sysdesa10_nro_tramite"];
    sysdesa10_fecha_nacimiento = json["sysdesa10_fecha_nacimiento"]?.toString();
    sysdesa10_edad = json["sysdesa10_edad"]?.toString();
    sysdesa10_cadena_dni = json["sysdesa10_cadena_dni"];
    codigo_mensaje = json["codigo_mensaje"];
    mensaje = fixEncoding(json["mensaje"]);
    foto_beneficiario = fotoBeneficiarioDesdeJson(json);
  }
  Map<dynamic, dynamic> toJson() => {
        sysdesa10_apellido: sysdesa10_apellido,
        sysdesa10_nombre: sysdesa10_nombre,
        sysdesa10_cuil: sysdesa10_cuil,
        sysdesa10_dni: sysdesa10_dni,
        sysdesa10_sexo: sysdesa10_sexo,
        sysdesa10_nro_tramite: sysdesa10_nro_tramite,
        sysdesa10_fecha_nacimiento: sysdesa10_fecha_nacimiento,
        sysdesa10_edad: sysdesa10_edad,
        sysdesa10_cadena_dni: sysdesa10_cadena_dni,
        codigo_mensaje: codigo_mensaje,
        mensaje: mensaje,
        foto_beneficiario: foto_beneficiario,
      };
  Beneficiario.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;

    for (final item in jsonList) {
      if (item is! Map) continue;
      final informacion =
          Beneficiario.fromJsonMap(Map<String, dynamic>.from(item));
      items.add(informacion);
    }
  }
}
