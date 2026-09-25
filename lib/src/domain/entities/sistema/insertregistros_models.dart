// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

String insertRegistrosToJson(List<InsertRegistros?> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x!.toJson())));

class InsertRegistros {
  List<InsertRegistros> items = [];
  InsertRegistros({
    this.id_flxcore03, //Cargador
    this.id_sysvacu04, //Vacuna
    this.id_sysofic01, //EFector
    this.id_sysdesa18,
    this.id_sysdesa12,
    this.id_sysvacu01,
    this.id_sysvacu02,
    this.id_sysvacu05,
    this.sysdesa10_nombre,
    this.sysdesa10_apellido,
    this.sysdesa10_dni,
    this.sysdesa10_sexo,
    this.sysdesa10_nro_tramite,
    this.sysdesa10_cadena_dni,
    this.sysdesa10_edad,
    this.sysdesa10_fecha_nacimiento,
    this.vacunador_registrador,
    this.vacunacion_en_terreno,
    this.codigo_mensaje,
    this.mensaje,
    this.sysdesa10_apellido_tutor,
    this.sysdesa10_nombre_tutor,
    this.sysdesa10_dni_tutor,
    this.sysdesa10_sexo_tutor,
    this.condicion_gestacional_beneficiario,
    this.es_personal_salud,
    this.nombreVacuna,
    this.nombreCondicion,
    this.nombreEsquema,
    this.nombreDosis,
    this.nombreLote,
    this.fecha_aplicacion,
  });

  String? id_flxcore03;
  String? id_sysvacu04;
  String? id_sysofic01;
  String? id_sysdesa12;
  String? id_sysdesa18;
  String? id_sysvacu01;
  String? id_sysvacu02;
  String? id_sysvacu05;
  String? sysdesa10_nombre;
  String? sysdesa10_apellido;
  String? sysdesa10_dni;
  String? sysdesa10_sexo;
  String? sysdesa10_nro_tramite;
  String? sysdesa10_cadena_dni;
  //String id_sysdesa06;
  String? sysdesa10_edad;
  String? sysdesa10_fecha_nacimiento;
  String? vacunador_registrador;
  /// [vacunacion_en_terreno] `1` = en terreno, `0` = en establecimiento (sesión equipo).
  /// La app ya lo envía en el JSON del campo insertvacunado; persistencia en BD depende del PHP.
  String? vacunacion_en_terreno;
  //DATOS TUTOR
  String? sysdesa10_apellido_tutor;
  String? sysdesa10_nombre_tutor;
  String? sysdesa10_dni_tutor;
  String? sysdesa10_sexo_tutor;
  // TODO backend: confirmar nombre de campo. Valores: 'embarazada' | 'puerpera' | null.
  String? condicion_gestacional_beneficiario;
  // TODO backend: confirmar nombre de campo. '1' | '0'.
  String? es_personal_salud;
  String? codigo_mensaje;
  String? mensaje;

  //Datos que no se envian
  String? nombreVacuna;
  String? nombreCondicion;
  String? nombreEsquema;
  String? nombreDosis;
  String? nombreLote;
  String? fecha_aplicacion;

  Map<String, dynamic> toJson() => {
        "id_flxcore03": id_flxcore03,
        "id_sysvacu04": id_sysvacu04,
        "id_sysofic01": id_sysofic01,
        "id_sysdesa18": id_sysdesa18,
        "id_sysdesa12": id_sysdesa12,
        "id_sysvacu01": id_sysvacu01, //condicion
        "id_sysvacu02": id_sysvacu02, //esquema
        "id_sysvacu05": id_sysvacu05, //dosis
        "sysdesa10_nombre": sysdesa10_nombre,
        "sysdesa10_apellido": sysdesa10_apellido,
        "sysdesa10_dni": sysdesa10_dni,
        "sysdesa10_sexo": sysdesa10_sexo,
        "sysdesa10_nro_tramite": sysdesa10_nro_tramite,
        "sysdesa10_cadena_dni": sysdesa10_cadena_dni,
        "sysdesa10_edad": sysdesa10_edad,
        "sysdesa10_fecha_nacimiento": sysdesa10_fecha_nacimiento,
        "vacunador_registrador": vacunador_registrador,
        "vacunacion_en_terreno": vacunacion_en_terreno,
        "codigo_mensaje": codigo_mensaje,
        "mensaje": mensaje,
        "sysdesa10_apellido_tutor": sysdesa10_apellido_tutor,
        "sysdesa10_nombre_tutor": sysdesa10_nombre_tutor,
        "sysdesa10_dni_tutor": sysdesa10_dni_tutor,
        "sysdesa10_sexo_tutor": sysdesa10_sexo_tutor,
        "condicion_gestacional_beneficiario": condicion_gestacional_beneficiario,
        "es_personal_salud": es_personal_salud,
        "fecha_aplicacion": fecha_aplicacion,
      };
}
