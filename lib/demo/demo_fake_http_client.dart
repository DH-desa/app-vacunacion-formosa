// Backend falso para la DEMO educativa. Intercepta TODO el tráfico http de la
// app (vía http.runWithClient, instalado desde lib/demo/main_demo.dart) y
// responde JSON que respeta EXACTAMENTE las claves que cada provider/modelo
// espera (verificado leyendo datasources/*.dart y models/*.dart, no
// inventado).
//
// Objetivo: la app corre completa (login, equipo, beneficiario, 8 pasos,
// registro) sin tocar dh.formosa.gob.ar. Cero impacto en BD: las rutas no
// mapeadas devuelven 404, nunca pasan al servidor real.
//
// El escáner (flutter_zxing) es real en Android físico; el fake responde
// según el DNI escaneado/ingresado para que cada validación de la app sea
// alcanzable con un DNI conocido (ver docs/demo_guia.md).
//
// Las vacunas pendientes se generan dinámicamente según el Calendario
// Nacional de Vacunación 2026 (docs/calendario_nacional_vacunacion_2026.md):
// la edad, sexo y condición (embarazada/puérpera/personal de salud)
// determinan qué vacunas corresponden, igual que haría el backend real.
//
// DNI de muestra (todos ficticios):
//   Registrador: 36355149 OK · 30000000 sin permiso · 30000001 sin efector
//   Vacunador:   cualquier DNI OK · 30000002 inválido
//   Beneficiario: 11111111 adulta · 11111112 recién nacido · 11111113 6 meses
//                 11111114 12 meses · 11111115 15 meses · 11111116 18 meses
//                 11111117 5 años (nacido 2021) · 11111118 11 años (nacido 2015)
//                 11111119 15 años · 11111120 35 años
//                 22222222 embarazada · 33333333 puérpera · 44444444 personal salud
//                 99999999 no encontrado

// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

typedef Responder = Map<String, dynamic> Function(Uri url);

const String _ok = '1';

// true: las validaciones de error se disparan con los DNIs y vacunas
// designados (matriz en docs/demo_guia.md). Útil para mostrar el manejo de
// errores de la app en vivo.
// false: happy path completo. Todo DNI funciona como OK, toda vacuna tiene
// lotes y se registra sin error. Útil para grabar demos sin trabarse.
const bool kDemoValidations = true;

http.StreamedResponse _json(Map<String, dynamic> body) {
  final bytes = utf8.encode(json.encode(body));
  return http.StreamedResponse(
    Stream.value(Uint8List.fromList(bytes)),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

http.StreamedResponse _noContent(int status) =>
    http.StreamedResponse(Stream.value(Uint8List(0)), status);

// ── Beneficiarios de muestra ────────────────────────────────────────────────
//
// Cada DNI tiene fecha de nacimiento coherente con hoy (2026-08-13) para que
// el clasificador del calendario 2026 ubique a la persona en la fila etaria
// correcta. El DNI 11111111 pasa a adulta para mantener compatibilidad con
// el flujo de tutor del primer mensaje.

class _DniBeneficiario {
  final String dni;
  final String apellido;
  final String nombre;
  final String sexo;
  final String fechaNacimiento;
  final String edadAnios;
  const _DniBeneficiario(this.dni, this.apellido, this.nombre, this.sexo,
      this.fechaNacimiento, this.edadAnios);
}

// Edades calculadas respecto al 2026-08-13.
final Map<String, _DniBeneficiario> _beneficiariosDemo = {
  '11111111': const _DniBeneficiario(
      '11111111', 'Fernández', 'Lucía', 'F', '1991-04-12', '35'),
  '11111112': const _DniBeneficiario(
      '11111112', 'Gómez', 'Mateo', 'M', '2026-07-01', '0'),
  '11111113': const _DniBeneficiario(
      '11111113', 'Ruiz', 'Sofía', 'F', '2026-02-01', '0'),
  '11111114': const _DniBeneficiario(
      '11111114', 'López', 'Diego', 'M', '2025-08-01', '0'),
  '11111115': const _DniBeneficiario(
      '11111115', 'Martínez', 'Valentina', 'F', '2025-05-01', '1'),
  '11111116': const _DniBeneficiario(
      '11111116', 'Pérez', 'Bruno', 'M', '2025-02-01', '1'),
  '11111117': const _DniBeneficiario(
      '11111117', 'Sánchez', 'Emma', 'F', '2021-03-15', '5'),
  '11111118': const _DniBeneficiario(
      '11111118', 'Torres', 'Tomás', 'M', '2015-09-20', '10'),
  '11111119': const _DniBeneficiario(
      '11111119', 'Acosta', 'Camila', 'F', '2010-08-13', '15'),
  '11111120': const _DniBeneficiario(
      '11111120', 'Díaz', 'Juan', 'M', '1990-01-15', '36'),
  '22222222': const _DniBeneficiario(
      '22222222', 'Romero', 'Carla', 'F', '1995-06-20', '31'),
  '33333333': const _DniBeneficiario(
      '33333333', 'Vega', 'Laura', 'F', '1992-12-05', '33'),
  '44444444': const _DniBeneficiario(
      '44444444', 'Castro', 'Roberto', 'M', '1988-04-10', '38'),
  '35678901': const _DniBeneficiario(
      '35678901', 'Fernández', 'Lucía', 'F', '1991-04-12', '35'),
};

Map<String, dynamic> _beneficiarioSegunDni(Uri uri) {
  final dni = uri.queryParameters['sysdesa10_dni'] ?? '';
  final sexo = uri.queryParameters['sysdesa10_sexo'] ?? 'F';

  if (kDemoValidations && dni == '99999999') {
    return {
      'sysdesa10_apellido': '',
      'sysdesa10_nombre': '',
      'sysdesa10_cuil': '',
      'sysdesa10_dni': dni,
      'sysdesa10_sexo': sexo,
      'sysdesa10_nro_tramite': '',
      'sysdesa10_fecha_nacimiento': '',
      'sysdesa10_edad': '',
      'sysdesa10_cadena_dni': uri.queryParameters['sysdesa10_cadena_dni'] ?? '',
      'foto_beneficiario': '',
      'codigo_mensaje': '0',
      'mensaje': 'No se encontró el beneficiario con ese DNI y sexo.',
    };
  }

  final demo = _beneficiariosDemo[dni];
  if (demo != null) {
    return {
      'sysdesa10_apellido': demo.apellido,
      'sysdesa10_nombre': demo.nombre,
      'sysdesa10_cuil': '',
      'sysdesa10_dni': dni,
      'sysdesa10_sexo': sexo.isNotEmpty ? sexo : demo.sexo,
      'sysdesa10_nro_tramite': '',
      'sysdesa10_fecha_nacimiento': demo.fechaNacimiento,
      'sysdesa10_edad': demo.edadAnios,
      'sysdesa10_cadena_dni': uri.queryParameters['sysdesa10_cadena_dni'] ?? '',
      'foto_beneficiario': '',
      'codigo_mensaje': _ok,
      'mensaje': 'OK',
    };
  }

  // DNI no listado: adulta genérica (compatibilidad con escaneo libre).
  return {
    'sysdesa10_apellido': 'Fernández',
    'sysdesa10_nombre': 'Lucía',
    'sysdesa10_cuil': '27356789012',
    'sysdesa10_dni': dni.isNotEmpty ? dni : '35678901',
    'sysdesa10_sexo': sexo,
    'sysdesa10_nro_tramite': '',
    'sysdesa10_fecha_nacimiento': '1991-04-12',
    'sysdesa10_edad': '35',
    'sysdesa10_cadena_dni': uri.queryParameters['sysdesa10_cadena_dni'] ?? '',
    'foto_beneficiario': '',
    'codigo_mensaje': _ok,
    'mensaje': 'OK',
  };
}

// ── Catálogo de vacunas (Calendario Nacional 2026) ───────────────────────────
//
// 18 vacunas del calendario, cada una con ID, condiciones, esquemas, dosis y
// lotes coherentes. Las pendientes se generan dinámicamente según edad/sexo/
// condición de la persona (ver _pendientesSegunCalendario).

// Vacuna: id_sysvacu04 → nombre
const Map<String, String> _vacunas = {
  '12': 'COVID-19',
  '15': 'Antigripal',
  '20': 'Hepatitis B',
  '21': 'BCG',
  '22': 'Neumococo Conjugada',
  '23': 'Quíntuple o Pentavalente',
  '24': 'IPV',
  '25': 'Rotavirus',
  '26': 'Meningococo ACYW',
  '27': 'Hepatitis A',
  '28': 'Triple Viral',
  '29': 'Varicela',
  '30': 'Triple Bacteriana Celular',
  '31': 'Triple Bacteriana Acelular',
  '32': 'Virus Papiloma Humano',
  '33': 'Doble Bacteriana',
  '34': 'Virus Sincicial Respiratorio',
  '35': 'Fiebre Amarilla',
  '36': 'Fiebre Hemorrágica Argentina',
};

// Perfiles (id_sysvacu12 → descripción) — ver handler wserv_obtener_perfil_vacunacion.

// Perfil → vacunas
const Map<String, List<String>> _vacunasPorPerfil = {
  '1': ['15'],
  '2': ['12', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29',
        '30', '31', '32', '33', '34', '35', '36'],
};

// Condiciones por vacuna (todas: Sin condición = 3; algunas: Personal salud = 4)
const Map<String, List<Map<String, String>>> _condicionesPorVacuna = {
  '12': [
    {'id_sysvacu01': '3', 'sysvacu01_descripcion': 'Sin condición'},
    {'id_sysvacu01': '4', 'sysvacu01_descripcion': 'Personal de salud'},
  ],
  '15': [{'id_sysvacu01': '3', 'sysvacu01_descripcion': 'Sin condición'}],
  '20': [{'id_sysvacu01': '3', 'sysvacu01_descripcion': 'Sin condición'}],
  '21': [{'id_sysvacu01': '3', 'sysvacu01_descripcion': 'Sin condición'}],
  '22': [{'id_sysvacu01': '3', 'sysvacu01_descripcion': 'Sin condición'}],
  '23': [{'id_sysvacu01': '3', 'sysvacu01_descripcion': 'Sin condición'}],
  '24': [{'id_sysvacu01': '3', 'sysvacu01_descripcion': 'Sin condición'}],
  '25': [{'id_sysvacu01': '3', 'sysvacu01_descripcion': 'Sin condición'}],
  '26': [{'id_sysvacu01': '3', 'sysvacu01_descripcion': 'Sin condición'}],
  '27': [{'id_sysvacu01': '3', 'sysvacu01_descripcion': 'Sin condición'}],
  '28': [{'id_sysvacu01': '3', 'sysvacu01_descripcion': 'Sin condición'}],
  '29': [{'id_sysvacu01': '3', 'sysvacu01_descripcion': 'Sin condición'}],
  '30': [{'id_sysvacu01': '3', 'sysvacu01_descripcion': 'Sin condición'}],
  '31': [{'id_sysvacu01': '3', 'sysvacu01_descripcion': 'Sin condición'}],
  '32': [{'id_sysvacu01': '3', 'sysvacu01_descripcion': 'Sin condición'}],
  '33': [{'id_sysvacu01': '3', 'sysvacu01_descripcion': 'Sin condición'}],
  '34': [{'id_sysvacu01': '3', 'sysvacu01_descripcion': 'Sin condición'}],
  '35': [{'id_sysvacu01': '3', 'sysvacu01_descripcion': 'Sin condición'}],
  '36': [{'id_sysvacu01': '3', 'sysvacu01_descripcion': 'Sin condición'}],
};

// ponytail: for-in en const no compila, por eso final.
final Map<String, List<Map<String, String>>> _esquemasPorVacunaCond = {
  for (final v in _vacunas.keys)
    '$v|3': [{'id_sysvacu02': '7', 'sysvacu02_descripcion': 'Esquema habitual'}],
  '12|4': [{'id_sysvacu02': '7', 'sysvacu02_descripcion': 'Esquema habitual'}],
};

// Dosis por (vacuna|cond|esquema): mapea indicaciones del calendario a dosis.
// ponytail: un lote genérico por vacuna para no inflar el catálogo.
const Map<String, List<Map<String, String>>> _dosisPorVacunaCondEsq = {
  '12|3|7': [
    {'id_sysvacu05': '9', 'sysvacu05_nombre': '1ra Dosis'},
    {'id_sysvacu05': '10', 'sysvacu05_nombre': '2da Dosis'},
  ],
  '12|4|7': [
    {'id_sysvacu05': '9', 'sysvacu05_nombre': '1ra Dosis'},
    {'id_sysvacu05': '10', 'sysvacu05_nombre': '2da Dosis'},
  ],
  '15|3|7': [{'id_sysvacu05': '20', 'sysvacu05_nombre': 'Dosis Anual'}],
  '20|3|7': [
    {'id_sysvacu05': '9', 'sysvacu05_nombre': '1ra Dosis'},
    {'id_sysvacu05': '10', 'sysvacu05_nombre': '2da Dosis'},
    {'id_sysvacu05': '11', 'sysvacu05_nombre': '3ra Dosis'},
  ],
  '21|3|7': [{'id_sysvacu05': '21', 'sysvacu05_nombre': 'Única Dosis'}],
  '22|3|7': [
    {'id_sysvacu05': '22', 'sysvacu05_nombre': '1ra Dosis'},
    {'id_sysvacu05': '23', 'sysvacu05_nombre': '2da Dosis'},
    {'id_sysvacu05': '24', 'sysvacu05_nombre': '3ra Dosis'},
    {'id_sysvacu05': '25', 'sysvacu05_nombre': 'Refuerzo'},
  ],
  '23|3|7': [
    {'id_sysvacu05': '26', 'sysvacu05_nombre': '1ra Dosis'},
    {'id_sysvacu05': '27', 'sysvacu05_nombre': '2da Dosis'},
    {'id_sysvacu05': '28', 'sysvacu05_nombre': '3ra Dosis'},
    {'id_sysvacu05': '29', 'sysvacu05_nombre': '1er Refuerzo'},
  ],
  '24|3|7': [
    {'id_sysvacu05': '30', 'sysvacu05_nombre': '1ra Dosis'},
    {'id_sysvacu05': '31', 'sysvacu05_nombre': '2da Dosis'},
    {'id_sysvacu05': '32', 'sysvacu05_nombre': 'Refuerzo'},
  ],
  '25|3|7': [
    {'id_sysvacu05': '33', 'sysvacu05_nombre': '1ra Dosis'},
    {'id_sysvacu05': '34', 'sysvacu05_nombre': '2da Dosis'},
  ],
  '26|3|7': [
    {'id_sysvacu05': '35', 'sysvacu05_nombre': '1ra Dosis'},
    {'id_sysvacu05': '36', 'sysvacu05_nombre': '2da Dosis'},
    {'id_sysvacu05': '37', 'sysvacu05_nombre': 'Refuerzo'},
  ],
  '27|3|7': [{'id_sysvacu05': '38', 'sysvacu05_nombre': 'Única Dosis'}],
  '28|3|7': [
    {'id_sysvacu05': '39', 'sysvacu05_nombre': '1ra Dosis'},
    {'id_sysvacu05': '40', 'sysvacu05_nombre': '2da Dosis'},
  ],
  '29|3|7': [
    {'id_sysvacu05': '41', 'sysvacu05_nombre': '1ra Dosis'},
    {'id_sysvacu05': '42', 'sysvacu05_nombre': '2da Dosis'},
  ],
  '30|3|7': [
    {'id_sysvacu05': '43', 'sysvacu05_nombre': '2do Refuerzo'},
  ],
  '31|3|7': [{'id_sysvacu05': '44', 'sysvacu05_nombre': 'Refuerzo'}],
  '32|3|7': [{'id_sysvacu05': '45', 'sysvacu05_nombre': 'Única Dosis'}],
  '33|3|7': [{'id_sysvacu05': '46', 'sysvacu05_nombre': 'Refuerzo'}],
  '34|3|7': [{'id_sysvacu05': '47', 'sysvacu05_nombre': 'Única Dosis'}],
  '35|3|7': [
    {'id_sysvacu05': '48', 'sysvacu05_nombre': '1ra Dosis'},
    {'id_sysvacu05': '49', 'sysvacu05_nombre': 'Refuerzo'},
  ],
  '36|3|7': [{'id_sysvacu05': '50', 'sysvacu05_nombre': 'Única Dosis'}],
};

// Lotes: uno genérico por vacuna.
Map<String, List<Map<String, String>>> get _lotesPorVacuna => {
  for (final entry in _vacunas.entries)
    entry.key: [{
      'id_sysdesa18': '${80 + int.parse(entry.key)}',
      'sysdesa18_lote': 'LOTE-${entry.key}',
      'sysdesa18_cantidad_actual': '50',
      'sysdesa18_fecha_vencimiento': '2027-12-31',
      'sysvacu02_descripcion': 'Esquema habitual',
    }],
};

// ── Clasificador Calendario 2026 (función pura) ────────────────────────────
//
// Replica la lógica de clasificarFilasCalendario (calendario_2026.dart) sin
// importar el package de la app: el fake vive en lib/demo/ y no debe tener
// dependencias internas. El fake es autónomo.

/// Genera el historial (vacunas_aplicadas) y las pendientes
/// (vacunas_pendientes) de forma coherente: una dosis dada está en el
/// historial (ya se aplicó) O en pendientes (falta aplicar), NUNCA en ambas.
///
/// Regla: una dosis del hito X está APLICADA si la persona ya superó ese
/// hito (mesesCumplidos > X), y PENDIENTE si está justo en ese hito
/// (mesesCumplidos == X). Antigripal "Dosis Anual" es excepción: siempre
/// pendiente (es la del año en curso, renovvable).
MapEntry<List<Map<String, dynamic>>, List<Map<String, dynamic>>>
    _listadosSegunCalendario(Uri uri) {
  final dni = uri.queryParameters['sysdesa10_dni'] ?? '';
  final edadDiasStr = uri.queryParameters['sysdesa10_edad'] ?? '';
  final embarazada = uri.queryParameters['embarazada'] == 'true';
  final puerpera = uri.queryParameters['puerpera'] == 'true';
  final personalSalud = uri.queryParameters['personal_salud'] == 'true';

  final demo = _beneficiariosDemo[dni];
  DateTime? fechaNac;
  if (demo != null) fechaNac = DateTime.tryParse(demo.fechaNacimiento);
  final hoy = DateTime(2026, 8, 13);

  int mesesCumplidos;
  int aniosCumplidos;
  if (fechaNac != null) {
    mesesCumplidos = (hoy.year - fechaNac.year) * 12 +
        (hoy.month - fechaNac.month);
    if (hoy.day < fechaNac.day) mesesCumplidos--;
    if (mesesCumplidos < 0) mesesCumplidos = 0;
    aniosCumplidos = hoy.year - fechaNac.year;
    if (hoy.month < fechaNac.month ||
        (hoy.month == fechaNac.month && hoy.day < fechaNac.day)) {
      aniosCumplidos--;
    }
  } else {
    mesesCumplidos = (int.tryParse(edadDiasStr) ?? 0) ~/ 30;
    aniosCumplidos = (int.tryParse(edadDiasStr) ?? 0) ~/ 365;
  }

  final aplicadas = <Map<String, dynamic>>[];
  final pendientes = <Map<String, dynamic>>[];

  const cSin = '3', cSalud = '4', cEmb = '5', cPuer = '6';
  const dSin = 'Sin condición', dSalud = 'Personal de salud';
  const dEmb = 'Embarazada', dPuer = 'Puérpera';

  String fechaAplicacion(int mesHito) {
    if (fechaNac == null) return '2025-01-01';
    final f = DateTime(fechaNac.year, fechaNac.month + mesHito,
        fechaNac.day > 28 ? 28 : fechaNac.day);
    return '${f.year}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';
  }

  String diasDesde(int mesHito) {
    if (fechaNac == null) return '500';
    final f = DateTime(fechaNac.year, fechaNac.month + mesHito,
        fechaNac.day > 28 ? 28 : fechaNac.day);
    return hoy.difference(f).inDays.toString();
  }

  void apl(String idVac, String nombreVac, String idDosis, String nombreDosis,
      int mesHito) {
    aplicadas.add({
      'sysvacu04_nombre': nombreVac,
      'sysvacu05_nombre': nombreDosis,
      'sysdesa10_fecha_aplicacion': fechaAplicacion(mesHito),
      'fecha_proxima_dosis': '',
      'dias_transcurridos': diasDesde(mesHito),
      'sysdesa18_lote': 'LOTE-$idVac',
      'sysvacu03_tiempo_interdosis': '',
      'codigo_mensaje': _ok,
      'mensaje': 'OK',
    });
  }

  void pend(String idVac, String nombreVac, String idDosis, String nombreDosis,
      {String idCond = cSin, String descCond = dSin, int dentroLimite = 1}) {
    pendientes.add({
      'rela_sysvacu01': idCond,
      'sysvacu01_descripcion': descCond,
      'rela_sysvacu02': '7',
      'sysvacu02_descripcion': 'Esquema habitual',
      'rela_sysvacu04': idVac,
      'sysvacu04_nombre': nombreVac,
      'rela_sysvacu05': idDosis,
      'sysvacu05_nombre': nombreDosis,
      'aplicacion_dentro_limite': dentroLimite,
    });
  }

  // 11111120: adulto que NO recibió Hepatitis B al nacer → las 3 dosis
  // del esquema de adulto están pendientes (permite probar el switch
  // "Controlar orden de dosis": 2da bloqueada mientras 1ra esté pendiente).
  final sinHepatitisB = dni == '11111120';

  // ── Hitos del calendario infantil (0-24 meses) ──
  if (mesesCumplidos > 0) {
    apl('21', 'BCG', '21', 'Única Dosis', 0);
    if (!sinHepatitisB) apl('20', 'Hepatitis B', '9', '1ra Dosis', 0);
  } else if (mesesCumplidos == 0) {
    pend('21', 'BCG', '21', 'Única Dosis');
    if (!sinHepatitisB) pend('20', 'Hepatitis B', '9', '1ra Dosis');
  }

  if (mesesCumplidos > 2) {
    apl('22', 'Neumococo Conjugada', '22', '1ra Dosis', 2);
    apl('23', 'Quíntuple o Pentavalente', '26', '1ra Dosis', 2);
    apl('24', 'IPV', '30', '1ra Dosis', 2);
    apl('25', 'Rotavirus', '33', '1ra Dosis', 2);
  } else if (mesesCumplidos == 2) {
    pend('22', 'Neumococo Conjugada', '22', '1ra Dosis');
    pend('23', 'Quíntuple o Pentavalente', '26', '1ra Dosis');
    pend('24', 'IPV', '30', '1ra Dosis');
    pend('25', 'Rotavirus', '33', '1ra Dosis');
  }

  if (mesesCumplidos > 3)
    apl('26', 'Meningococo ACYW', '35', '1ra Dosis', 3);
  else if (mesesCumplidos == 3)
    pend('26', 'Meningococo ACYW', '35', '1ra Dosis');

  if (mesesCumplidos > 4) {
    apl('22', 'Neumococo Conjugada', '23', '2da Dosis', 4);
    apl('23', 'Quíntuple o Pentavalente', '27', '2da Dosis', 4);
    apl('24', 'IPV', '31', '2da Dosis', 4);
    apl('25', 'Rotavirus', '34', '2da Dosis', 4);
  } else if (mesesCumplidos == 4) {
    pend('22', 'Neumococo Conjugada', '23', '2da Dosis');
    pend('23', 'Quíntuple o Pentavalente', '27', '2da Dosis');
    pend('24', 'IPV', '31', '2da Dosis');
    pend('25', 'Rotavirus', '34', '2da Dosis');
  }

  if (mesesCumplidos > 5)
    apl('26', 'Meningococo ACYW', '36', '2da Dosis', 5);
  else if (mesesCumplidos == 5)
    pend('26', 'Meningococo ACYW', '36', '2da Dosis');

  if (mesesCumplidos > 6) {
    apl('22', 'Neumococo Conjugada', '24', '3ra Dosis', 6);
    apl('23', 'Quíntuple o Pentavalente', '28', '3ra Dosis', 6);
  } else if (mesesCumplidos == 6) {
    pend('22', 'Neumococo Conjugada', '24', '3ra Dosis');
    pend('23', 'Quíntuple o Pentavalente', '28', '3ra Dosis');
  }
  if (mesesCumplidos >= 6)
    pend('15', 'Antigripal', '20', 'Dosis Anual');

  if (mesesCumplidos > 12) {
    apl('22', 'Neumococo Conjugada', '25', 'Refuerzo', 12);
    apl('27', 'Hepatitis A', '38', 'Única Dosis', 12);
    apl('28', 'Triple Viral', '39', '1ra Dosis', 12);
  } else if (mesesCumplidos == 12) {
    pend('22', 'Neumococo Conjugada', '25', 'Refuerzo');
    pend('27', 'Hepatitis A', '38', 'Única Dosis');
    pend('28', 'Triple Viral', '39', '1ra Dosis');
  }

  if (mesesCumplidos > 15) {
    apl('23', 'Quíntuple o Pentavalente', '29', '1er Refuerzo', 15);
    apl('26', 'Meningococo ACYW', '37', 'Refuerzo', 15);
    apl('28', 'Triple Viral', '40', '2da Dosis', 15);
    apl('29', 'Varicela', '41', '1ra Dosis', 15);
  } else if (mesesCumplidos == 15) {
    pend('23', 'Quíntuple o Pentavalente', '29', '1er Refuerzo');
    pend('26', 'Meningococo ACYW', '37', 'Refuerzo');
    pend('28', 'Triple Viral', '40', '2da Dosis');
    pend('29', 'Varicela', '41', '1ra Dosis');
  }

  // ── Cohortes por año de nacimiento ──
  if (fechaNac != null) {
    final cohorte2021 = fechaNac.year >= 2021 && fechaNac.year <= 2024;
    if (cohorte2021 && aniosCumplidos >= 5) {
      if (aniosCumplidos > 5) {
        apl('24', 'IPV', '32', 'Refuerzo', 60);
        apl('28', 'Triple Viral', '40', '2da Dosis', 60);
        apl('29', 'Varicela', '42', '2da Dosis', 60);
        apl('30', 'Triple Bacteriana Celular', '43', '2do Refuerzo', 60);
      } else {
        pend('24', 'IPV', '32', 'Refuerzo');
        pend('28', 'Triple Viral', '40', '2da Dosis');
        pend('29', 'Varicela', '42', '2da Dosis');
        pend('30', 'Triple Bacteriana Celular', '43', '2do Refuerzo');
      }
    }
    if (fechaNac.year == 2015 && aniosCumplidos >= 11) {
      if (aniosCumplidos > 11) {
        apl('26', 'Meningococo ACYW', '21', 'Única Dosis', 132);
        apl('31', 'Triple Bacteriana Acelular', '44', 'Refuerzo', 132);
        apl('32', 'Virus Papiloma Humano', '45', 'Única Dosis', 132);
        apl('35', 'Fiebre Amarilla', '49', 'Refuerzo', 132);
      } else {
        pend('26', 'Meningococo ACYW', '21', 'Única Dosis');
        pend('31', 'Triple Bacteriana Acelular', '44', 'Refuerzo');
        pend('32', 'Virus Papiloma Humano', '45', 'Única Dosis');
        pend('35', 'Fiebre Amarilla', '49', 'Refuerzo');
      }
    }
  }

  if (aniosCumplidos == 15) {
    pend('28', 'Triple Viral', '39', '1ra Dosis');
    pend('36', 'Fiebre Hemorrágica Argentina', '50', 'Única Dosis');
  }

  if (aniosCumplidos >= 16) {
    pend('15', 'Antigripal', '20', 'Dosis Anual');
    pend('28', 'Triple Viral', '39', '1ra Dosis');
    pend('28', 'Triple Viral', '40', '2da Dosis');
    pend('33', 'Doble Bacteriana', '46', 'Refuerzo');
    pend('36', 'Fiebre Hemorrágica Argentina', '50', 'Única Dosis');
    if (sinHepatitisB) {
      pend('20', 'Hepatitis B', '9', '1ra Dosis');
      pend('20', 'Hepatitis B', '10', '2da Dosis');
      pend('20', 'Hepatitis B', '11', '3ra Dosis');
    }
  }

  // ── Filas de situación (independientes de la edad) ──
  if (embarazada) {
    pend('15', 'Antigripal', '20', 'Dosis Anual', idCond: cEmb, descCond: dEmb);
    pend('31', 'Triple Bacteriana Acelular', '44', 'Refuerzo',
        idCond: cEmb, descCond: dEmb);
    pend('34', 'Virus Sincicial Respiratorio', '47', 'Única Dosis',
        idCond: cEmb, descCond: dEmb);
  }
  if (puerpera) {
    pend('15', 'Antigripal', '20', 'Dosis Anual', idCond: cPuer, descCond: dPuer);
    pend('28', 'Triple Viral', '39', '1ra Dosis', idCond: cPuer, descCond: dPuer);
  }
  if (personalSalud) {
    pend('15', 'Antigripal', '20', 'Dosis Anual', idCond: cSalud, descCond: dSalud);
    pend('28', 'Triple Viral', '39', '1ra Dosis', idCond: cSalud, descCond: dSalud);
    pend('31', 'Triple Bacteriana Acelular', '44', 'Refuerzo',
        idCond: cSalud, descCond: dSalud);
  }

  // Deduplicar pendientes por (vacuna+dosis).
  final unicas = <String, Map<String, dynamic>>{};
  for (final p in pendientes) {
    final clave = '${p['rela_sysvacu04']}|${p['rela_sysvacu05']}';
    final existente = unicas[clave];
    if (existente == null) {
      unicas[clave] = p;
      continue;
    }
    final condExistente = existente['rela_sysvacu01']?.toString() ?? cSin;
    final condNueva = p['rela_sysvacu01']?.toString() ?? cSin;
    if (condExistente == cSin && condNueva != cSin) unicas[clave] = p;
  }

  return MapEntry(aplicadas, unicas.values.toList());
}

// ── Cliente HTTP falso ─────────────────────────────────────────────────────

class DemoFakeHttpClient extends http.BaseClient {
  final http.Client _pasoDirecto = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.host != 'dh.formosa.gob.ar') {
      return _pasoDirecto.send(request);
    }
    return _responder(request);
  }

  Future<http.StreamedResponse> _responder(http.BaseRequest request) async {
    final uri = request.url;
    final path = uri.path;

    // ── Login ──
    if (path.contains('wserv_login.php')) {
      final dni = uri.queryParameters['flxcore03_dni'] ?? '';
      if (kDemoValidations && dni == '30000000') {
        return _json({
          'usuario': [
            {'id_flxcore03': '', 'flxcore03_dni': '', 'flxcore03_nombre': '',
             'rela_sysofic01': '', 'sysofic01_descripcion': '',
             'codigo_mensaje': '0',
             'mensaje': 'El usuario no tiene permisos para acceder al sistema.'}
          ]
        });
      }
      if (kDemoValidations && dni == '30000001') {
        return _json({
          'usuario': [
            {'id_flxcore03': '1002', 'flxcore03_dni': '30000001',
             'flxcore03_nombre': 'Pedro Ruiz', 'rela_sysofic01': '',
             'sysofic01_descripcion': null, 'codigo_mensaje': _ok,
             'mensaje': 'OK'}
          ]
        });
      }
      return _json({
        'usuario': [
          {'id_flxcore03': '1001', 'flxcore03_dni': '36355149',
           'flxcore03_nombre': 'Ana Gómez', 'rela_sysofic01': '55',
           'sysofic01_descripcion': 'CAPS Barrio Guadalupe',
           'codigo_mensaje': _ok, 'mensaje': 'OK'}
        ]
      });
    }

    // ── Efectores ──
    if (path.contains('wserv_efector_registrador.php')) {
      return _json({
        'usuario': [
          {'id_flxcore03': '1001', 'flxcore03_dni': '36355149',
           'flxcore03_nombre': 'Ana Gómez', 'rela_sysofic01': '55',
           'sysofic01_descripcion': 'CAPS Barrio Guadalupe'},
          {'id_flxcore03': '1001', 'flxcore03_dni': '36355149',
           'flxcore03_nombre': 'Ana Gómez', 'rela_sysofic01': '77',
           'sysofic01_descripcion': 'Hospital Central'},
        ]
      });
    }

    // ── Vacunador ──
    if (path.contains('wserv_vacunador.php')) {
      final dni = uri.queryParameters['sysdesa06_nro_documento'] ?? '';
      if (kDemoValidations && dni == '30000002') {
        return _json({
          'vacunador': [
            {'id_sysdesa12': '', 'sysdesa06_nro_documento': dni,
             'sysdesa06_nombre': '', 'codigo_mensaje': '0',
             'mensaje': 'El DNI no corresponde a un vacunador habilitado.'}
          ]
        });
      }
      return _json({
        'vacunador': [
          {'id_sysdesa12': '501',
           'sysdesa06_nro_documento': dni.isNotEmpty ? dni : '30123456',
           'sysdesa06_nombre': 'Carlos Pérez',
           'codigo_mensaje': _ok, 'mensaje': 'OK'}
        ]
      });
    }

    // ── Contador de vacunas ──
    if (path.contains('wserv_cantidad_vacunas_registradas.php')) {
      return _json({
        'usuario': [{'id_sysdesa12': '501', 'cantidad_aplicaciones': '5'}]
      });
    }

    // ── Beneficiario / tutor ──
    if (path.contains('wserv_obtener_datos_beneficiario.php')) {
      return _json({'beneficiario': [_beneficiarioSegunDni(uri)]});
    }

    // ── Historial (aplicadas) + pendientes dinámicas ──
    // Una dosis está en aplicadas O en pendientes, NUNCA en ambas.
    if (path.contains('wserv_listados_vacunas.php')) {
      final listados = _listadosSegunCalendario(uri);
      return _json({
        'vacunas_aplicadas': listados.key,
        'vacunas_pendientes': listados.value,
      });
    }

    // ── Perfiles de vacunación ──
    if (path.contains('wserv_obtener_perfil_vacunacion.php')) {
      return _json({
        'perfiles_vacunacion': [
          {'id_sysvacu12': '1', 'sysvacu12_descripcion': 'Campaña Antigripal'},
          {'id_sysvacu12': '2', 'sysvacu12_descripcion': 'Calendario habitual'},
        ]
      });
    }

    // ── Vacunas por perfil ──
    if (path.contains('wserv_obtener_vacunas_configuradas.php')) {
      final perfil = uri.queryParameters['id_sysvacu12'] ?? '2';
      final ids = _vacunasPorPerfil[perfil] ?? _vacunasPorPerfil['2']!;
      final lista = ids.map((id) =>
          {'id_sysvacu04': id, 'sysvacu04_nombre': _vacunas[id]}).toList();
      return _json({'vacunas_configuradas': lista});
    }

    // ── Condiciones ──
    if (path.contains('wserv_obtener_condicion_vacunas.php')) {
      final vac = uri.queryParameters['id_sysvacu04'] ?? '';
      return _json({'condicion_vacunas':
        _condicionesPorVacuna[vac] ?? []});
    }

    // ── Esquemas ──
    if (path.contains('wserv_obtener_esquema_vacunas.php')) {
      final vac = uri.queryParameters['id_sysvacu04'] ?? '';
      final cond = uri.queryParameters['id_sysvacu01'] ?? '';
      return _json({'esquema_vacunas':
        _esquemasPorVacunaCond['$vac|$cond'] ?? []});
    }

    // ── Dosis ──
    if (path.contains('wserv_obtener_dosis_vacunas.php')) {
      final vac = uri.queryParameters['id_sysvacu04'] ?? '';
      final cond = uri.queryParameters['id_sysvacu01'] ?? '';
      final esq = uri.queryParameters['id_sysvacu02'] ?? '';
      return _json({'dosis_vacunas':
        _dosisPorVacunaCondEsq['$vac|$cond|$esq'] ?? []});
    }

    // ── Lotes ──
    // Hornear errores en datos (sin toggles):
    //   Fiebre Hemorrágica Argentina (36) → lista vacía → "Sin lotes".
    //   Fiebre Amarilla (35) → codigo_mensaje '0' → "No se pudieron cargar".
    if (path.contains('wserv_obtener_lotes_vacunas.php')) {
      final vac = uri.queryParameters['id_sysvacu04'] ?? '';
      if (kDemoValidations && vac == '36') return _json({'lotes_vacunas': []});
      if (kDemoValidations && vac == '35') {
        return _json({
          'lotes_vacunas': [
            {'id_sysdesa18': '', 'sysdesa18_lote': '',
             'sysdesa18_cantidad_actual': '', 'sysdesa18_fecha_vencimiento': '',
             'sysvacu02_descripcion': '', 'codigo_mensaje': '0',
             'mensaje': 'Error interno al consultar los lotes disponibles.'}
          ]
        });
      }
      return _json({'lotes_vacunas': _lotesPorVacuna[vac] ?? []});
    }

    // ── Registro (POST) ──
    // Fiebre Amarilla (35) falla al registrar.
    if (path.contains('wserv_registrar_vacuna.php')) {
      final payload = uri.queryParameters['insertvacunado'] ?? '';
      if (kDemoValidations && payload.contains('"id_sysvacu04":"35"')) {
        return _json({
          'mensajes': [
            {'codigo_mensaje': '0',
             'mensaje': 'No se pudo registrar la vacunación. Intente nuevamente.'}
          ]
        });
      }
      return _json({
        'mensajes': [
          {'codigo_mensaje': _ok, 'mensaje': 'Vacuna registrada correctamente.'}
        ]
      });
    }

    // ── Versión de la app ──
    if (path.contains('wserv_versiones_app.php')) {
      return _json({
        'versiones': [
          {'id_sysappl01': '1', 'sysappl01_nombre': 'vacunacion',
           'sysappl01_version': '4.0.0'}
        ]
      });
    }

    if (path.contains('wserv_obtener_configuraciones_vacuna.php')) {
      return _json({'configuraciones': []});
    }

    return _noContent(404);
  }
}