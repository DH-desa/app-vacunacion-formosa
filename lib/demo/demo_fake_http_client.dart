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
// Las vacunas pendientes se generan como lo hace el backend real
// (docs/backend_wserv_listados_vacunas.php) con las filas del Calendario
// Nacional de Vacunación 2026 (docs/calendario_nacional_vacunacion_2026.md):
// todas las dosis de los rangos etarios alcanzados según la edad en días que
// manda la app, más las de cada condición (embarazada/puérpera/personal de
// salud), menos las aplicadas. Escaneo e ingreso manual se resuelven igual.
//
// DNI de muestra (todos ficticios):
//   Registrador: 36355149 OK · 30000000 sin permiso · 30000001 sin efector
//   Vacunador:   cualquier DNI OK · 30000002 inválido
//   Beneficiario: 11111111 adulta · 11111112 recién nacido (3 días)
//                 11111113 6 meses · 11111114 12 meses · 11111115 15 meses
//                 11111116 18 meses · 11111117 nacida 2021 · 11111118 nacido 2015
//                 11111119 15 años · 11111120 adulto sin Hepatitis B
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
// Los lactantes y la adolescente de 15 años se fechan relativo a hoy: su fila
// del calendario depende del mes exacto y una fecha fija los corre de fila
// con el paso del tiempo. Las cohortes 2021/2015 conservan el año porque el
// calendario de la app las clasifica por año de nacimiento. El DNI 11111111
// pasa a adulta para mantener compatibilidad con el flujo de tutor del
// primer mensaje.

class _DniBeneficiario {
  final String apellido;
  final String nombre;
  final String sexo;
  final DateTime fechaNacimiento;
  const _DniBeneficiario(
      this.apellido, this.nombre, this.sexo, this.fechaNacimiento);
}

DateTime _hoy() {
  final ahora = DateTime.now();
  return DateTime(ahora.year, ahora.month, ahora.day);
}

String _fechaIso(DateTime f) =>
    '${f.year}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';

int _edadAnios(DateTime nacimiento, DateTime hoy) {
  var anios = hoy.year - nacimiento.year;
  if (hoy.month < nacimiento.month ||
      (hoy.month == nacimiento.month && hoy.day < nacimiento.day)) {
    anios--;
  }
  return anios;
}

Map<String, _DniBeneficiario> _beneficiariosDemo() {
  final hoy = _hoy();
  final dia = hoy.day > 28 ? 28 : hoy.day;
  DateTime haceMeses(int meses) => DateTime(hoy.year, hoy.month - meses, dia);
  return {
    '11111111': _DniBeneficiario('Fernández', 'Lucía', 'F', DateTime(1991, 4, 12)),
    '11111112': _DniBeneficiario(
        'Gómez', 'Mateo', 'M', hoy.subtract(const Duration(days: 3))),
    '11111113': _DniBeneficiario('Ruiz', 'Sofía', 'F', haceMeses(6)),
    '11111114': _DniBeneficiario('López', 'Diego', 'M', haceMeses(12)),
    '11111115': _DniBeneficiario('Martínez', 'Valentina', 'F', haceMeses(15)),
    '11111116': _DniBeneficiario('Pérez', 'Bruno', 'M', haceMeses(18)),
    '11111117': _DniBeneficiario('Sánchez', 'Emma', 'F', DateTime(2021, 3, 15)),
    '11111118': _DniBeneficiario('Torres', 'Tomás', 'M', DateTime(2015, 9, 20)),
    '11111119': _DniBeneficiario('Acosta', 'Camila', 'F', haceMeses(15 * 12 + 1)),
    '11111120': _DniBeneficiario('Díaz', 'Juan', 'M', DateTime(1990, 1, 15)),
    '22222222': _DniBeneficiario('Romero', 'Carla', 'F', DateTime(1995, 6, 20)),
    '33333333': _DniBeneficiario('Vega', 'Laura', 'F', DateTime(1992, 12, 5)),
    '44444444': _DniBeneficiario('Castro', 'Roberto', 'M', DateTime(1988, 4, 10)),
    '35678901': _DniBeneficiario('Fernández', 'Lucía', 'F', DateTime(1991, 4, 12)),
  };
}

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

  final demo = _beneficiariosDemo()[dni];
  if (demo != null) {
    return {
      'sysdesa10_apellido': demo.apellido,
      'sysdesa10_nombre': demo.nombre,
      'sysdesa10_cuil': '',
      'sysdesa10_dni': dni,
      'sysdesa10_sexo': sexo.isNotEmpty ? sexo : demo.sexo,
      'sysdesa10_nro_tramite': '',
      'sysdesa10_fecha_nacimiento': _fechaIso(demo.fechaNacimiento),
      'sysdesa10_edad': '${_edadAnios(demo.fechaNacimiento, _hoy())}',
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
// lotes coherentes. Las pendientes se generan dinámicamente según edad y
// condición de la persona (ver _listadosSegunCalendario).

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

// Condiciones: Sin condición = 3 (id propio de la demo); las especiales usan
// los ids del backend real (wserv_listados_vacunas.php): embarazada = 2,
// personal de salud = 4, puérpera = 5.
const String _cSin = '3', _cEmb = '2', _cSalud = '4', _cPuer = '5';
const Map<String, String> _descCondicion = {
  _cSin: 'Sin condición',
  _cEmb: 'Embarazada',
  _cSalud: 'Personal de salud',
  _cPuer: 'Puérpera',
};

// Condiciones especiales por vacuna (filas Embarazadas/Puérperas/Personal de
// salud del calendario, más COVID-19 personal de salud). Todas las vacunas
// además tienen Sin condición.
const Map<String, List<String>> _condEspecialesPorVacuna = {
  '12': [_cSalud],
  '15': [_cEmb, _cSalud, _cPuer],
  '28': [_cSalud, _cPuer],
  '31': [_cEmb, _cSalud],
  '34': [_cEmb],
};

// ponytail: for-in en const no compila, por eso final.
final Map<String, List<Map<String, String>>> _condicionesPorVacuna = {
  for (final v in _vacunas.keys)
    v: [
      for (final c in [_cSin, ...?_condEspecialesPorVacuna[v]])
        {'id_sysvacu01': c, 'sysvacu01_descripcion': _descCondicion[c]!},
    ],
};

final Map<String, List<Map<String, String>>> _esquemasPorVacunaCond = {
  for (final v in _vacunas.keys)
    for (final c in [_cSin, ...?_condEspecialesPorVacuna[v]])
      '$v|$c': [{'id_sysvacu02': '7', 'sysvacu02_descripcion': 'Esquema habitual'}],
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
    {'id_sysvacu05': '51', 'sysvacu05_nombre': 'Única Dosis'},
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
  '15|2|7': [{'id_sysvacu05': '20', 'sysvacu05_nombre': 'Dosis Anual'}],
  '15|4|7': [{'id_sysvacu05': '20', 'sysvacu05_nombre': 'Dosis Anual'}],
  '15|5|7': [{'id_sysvacu05': '20', 'sysvacu05_nombre': 'Dosis Anual'}],
  '28|4|7': [
    {'id_sysvacu05': '39', 'sysvacu05_nombre': '1ra Dosis'},
    {'id_sysvacu05': '40', 'sysvacu05_nombre': '2da Dosis'},
  ],
  '28|5|7': [
    {'id_sysvacu05': '39', 'sysvacu05_nombre': '1ra Dosis'},
    {'id_sysvacu05': '40', 'sysvacu05_nombre': '2da Dosis'},
  ],
  '31|2|7': [{'id_sysvacu05': '44', 'sysvacu05_nombre': 'Refuerzo'}],
  '31|4|7': [{'id_sysvacu05': '44', 'sysvacu05_nombre': 'Refuerzo'}],
  '34|2|7': [{'id_sysvacu05': '47', 'sysvacu05_nombre': 'Única Dosis'}],
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

// ── Vacunas esperadas (réplica de wserv_listados_vacunas.php) ──────────────
//
// El backend real arma las esperadas con TODAS las filas de los rangos
// etarios cuyo mínimo ya alcanzó la persona (acumulativo: un adulto también
// recibe las filas de lactante) y marca aplicacion_dentro_limite = 1 solo si
// la edad cae dentro de la ventana de la dosis. La app oculta las que traen
// 0, así que cada persona ve todas las dosis de su edad y las de etapas
// anteriores que todavía están en ventana. Edades en días, como las manda
// la app. Las ventanas que el calendario no fija son valores de la demo.

class _FilaEsperada {
  final String idVac;
  final String idDosis;
  final String nombreDosis;
  final int edadMin; // días: desde cuándo la fila entra en el rango etario
  final int limiteMin; // días: ventana de aplicación de la dosis
  final int limiteMax;
  const _FilaEsperada(this.idVac, this.idDosis, this.nombreDosis, this.edadMin,
      this.limiteMin, this.limiteMax);
}

const int _anio = 365;
const int _sinTope = 120 * _anio;

// Ordenadas por edadMin, como el ORDER BY del backend: ante la misma
// vacuna+dosis gana la última (la del rango etario mayor).
const List<_FilaEsperada> _filasPorRangoEtario = [
  // Recién nacido
  _FilaEsperada('21', '21', 'Única Dosis', 0, 0, 6 * _anio),
  _FilaEsperada('20', '9', '1ra Dosis', 0, 0, 7),
  // 2 meses (Rotavirus: nota D, antes de las 14 semanas y 6 días)
  _FilaEsperada('22', '22', '1ra Dosis', 60, 60, 5 * _anio),
  _FilaEsperada('23', '26', '1ra Dosis', 60, 60, 7 * _anio),
  _FilaEsperada('24', '30', '1ra Dosis', 60, 60, 7 * _anio),
  _FilaEsperada('25', '33', '1ra Dosis', 60, 60, 104),
  // 3 meses
  _FilaEsperada('26', '35', '1ra Dosis', 90, 90, 2 * _anio),
  // 4 meses (Rotavirus: nota E, antes de las 24 semanas)
  _FilaEsperada('22', '23', '2da Dosis', 120, 120, 5 * _anio),
  _FilaEsperada('23', '27', '2da Dosis', 120, 120, 7 * _anio),
  _FilaEsperada('24', '31', '2da Dosis', 120, 120, 7 * _anio),
  _FilaEsperada('25', '34', '2da Dosis', 120, 120, 168),
  // 5 meses
  _FilaEsperada('26', '36', '2da Dosis', 150, 150, 2 * _anio),
  // 6 meses (Antigripal infantil: nota F, de 6 a 24 meses)
  _FilaEsperada('22', '24', '3ra Dosis', 180, 180, 5 * _anio),
  _FilaEsperada('23', '28', '3ra Dosis', 180, 180, 7 * _anio),
  _FilaEsperada('15', '20', 'Dosis Anual', 180, 180, 2 * _anio),
  // 12 meses
  _FilaEsperada('22', '25', 'Refuerzo', 365, 365, 5 * _anio),
  _FilaEsperada('27', '38', 'Única Dosis', 365, 365, 5 * _anio),
  _FilaEsperada('28', '39', '1ra Dosis', 365, 365, _sinTope),
  // 15 meses
  _FilaEsperada('23', '29', '1er Refuerzo', 450, 450, 7 * _anio),
  _FilaEsperada('26', '37', 'Refuerzo', 450, 450, 2 * _anio),
  _FilaEsperada('28', '40', '2da Dosis', 450, 450, _sinTope),
  _FilaEsperada('29', '41', '1ra Dosis', 450, 450, 13 * _anio),
  // 18 meses (Fiebre Amarilla: nota *, de 2 a 59 años en zona de riesgo)
  _FilaEsperada('35', '48', '1ra Dosis', 540, 540, 59 * _anio),
  // Nacidos en 2021: el backend solo conoce la edad, se toma desde los 4 años
  _FilaEsperada('24', '32', 'Refuerzo', 4 * _anio, 4 * _anio, 7 * _anio),
  _FilaEsperada('28', '40', '2da Dosis', 4 * _anio, 4 * _anio, _sinTope),
  _FilaEsperada('29', '42', '2da Dosis', 4 * _anio, 4 * _anio, 13 * _anio),
  _FilaEsperada('30', '43', '2do Refuerzo', 4 * _anio, 4 * _anio, 7 * _anio),
  // Nacidos en 2015: ídem, desde los 10 años
  _FilaEsperada('26', '21', 'Única Dosis', 10 * _anio, 10 * _anio, 13 * _anio),
  _FilaEsperada('31', '44', 'Refuerzo', 10 * _anio, 10 * _anio, 13 * _anio),
  _FilaEsperada('32', '45', 'Única Dosis', 10 * _anio, 10 * _anio, 13 * _anio),
  _FilaEsperada('35', '49', 'Refuerzo', 10 * _anio, 10 * _anio, 13 * _anio),
  // A partir de los 15 años (Triple Viral: nota K, iniciar o completar)
  _FilaEsperada('28', '39', '1ra Dosis', 15 * _anio, 15 * _anio, _sinTope),
  _FilaEsperada('28', '40', '2da Dosis', 15 * _anio, 15 * _anio, _sinTope),
  _FilaEsperada('36', '50', 'Única Dosis', 15 * _anio, 15 * _anio, 64 * _anio),
  // Adultos (Hepatitis B: nota C; Neumococo y Antigripal: nota G, 65 años o más)
  _FilaEsperada('20', '9', '1ra Dosis', 16 * _anio, 16 * _anio, _sinTope),
  _FilaEsperada('20', '10', '2da Dosis', 16 * _anio, 16 * _anio, _sinTope),
  _FilaEsperada('20', '11', '3ra Dosis', 16 * _anio, 16 * _anio, _sinTope),
  _FilaEsperada('22', '51', 'Única Dosis', 16 * _anio, 65 * _anio, _sinTope),
  _FilaEsperada('15', '20', 'Dosis Anual', 16 * _anio, 65 * _anio, _sinTope),
  _FilaEsperada('28', '39', '1ra Dosis', 16 * _anio, 16 * _anio, _sinTope),
  _FilaEsperada('28', '40', '2da Dosis', 16 * _anio, 16 * _anio, _sinTope),
  _FilaEsperada('33', '46', 'Refuerzo', 16 * _anio, 16 * _anio, _sinTope),
  _FilaEsperada('36', '50', 'Única Dosis', 16 * _anio, 16 * _anio, 64 * _anio),
];

// Filas por condición: el backend no les aplica rango etario ni límite
// (aplicacion_dentro_limite = null). Orden del backend: 2, 4, 5.
const Map<String, List<List<String>>> _filasPorCondicion = {
  _cEmb: [
    ['15', '20', 'Dosis Anual'],
    ['31', '44', 'Refuerzo'],
    ['34', '47', 'Única Dosis'],
  ],
  _cSalud: [
    ['15', '20', 'Dosis Anual'],
    ['28', '39', '1ra Dosis'],
    ['28', '40', '2da Dosis'],
    ['31', '44', 'Refuerzo'],
  ],
  _cPuer: [
    ['15', '20', 'Dosis Anual'],
    ['28', '39', '1ra Dosis'],
    ['28', '40', '2da Dosis'],
  ],
};

/// Historial (vacunas_aplicadas) y pendientes (vacunas_pendientes): una
/// dosis está en uno u otro, NUNCA en ambos.
///
/// Historial fijo de la demo: BCG y Hepatitis B neonatal pasada la primera
/// semana (11111120 sin Hepatitis B, para mostrar el esquema de adulto
/// completo). Todo lo demás que corresponde queda pendiente, así cada vacuna
/// muestra su serie de dosis y el switch "Controlar orden de dosis" tiene
/// qué bloquear.
MapEntry<List<Map<String, dynamic>>, List<Map<String, dynamic>>>
    _listadosSegunCalendario(Uri uri) {
  final dni = uri.queryParameters['sysdesa10_dni'] ?? '';
  final embarazada = uri.queryParameters['embarazada'] == 'true';
  final puerpera = uri.queryParameters['puerpera'] == 'true';
  final personalSalud = uri.queryParameters['personal_salud'] == 'true';
  final hoy = _hoy();

  // Como el backend: la edad es la que manda la app. Si no llega, se toma la
  // del DNI de muestra; si tampoco hay, solo aplican las filas de condición.
  var edadDias = int.tryParse(uri.queryParameters['sysdesa10_edad'] ?? '');
  final demo = _beneficiariosDemo()[dni];
  if (edadDias == null && demo != null) {
    edadDias = hoy.difference(demo.fechaNacimiento).inDays;
  }

  final aplicadas = <Map<String, dynamic>>[];
  final clavesAplicadas = <String>{};
  void apl(String idVac, String idDosis, String nombreDosis) {
    clavesAplicadas.add('${idVac}_$idDosis');
    aplicadas.add({
      'sysvacu04_nombre': _vacunas[idVac],
      'sysvacu05_nombre': nombreDosis,
      'sysdesa10_fecha_aplicacion':
          _fechaIso(hoy.subtract(Duration(days: edadDias!))),
      'fecha_proxima_dosis': '',
      'dias_transcurridos': '$edadDias',
      'sysdesa18_lote': 'LOTE-$idVac',
      'sysvacu03_tiempo_interdosis': '',
      'codigo_mensaje': _ok,
      'mensaje': 'OK',
    });
  }

  if (edadDias != null && edadDias > 7) {
    apl('21', '21', 'Única Dosis');
    if (dni != '11111120') apl('20', '9', '1ra Dosis');
  }

  Map<String, dynamic> pend(String idVac, String idDosis, String nombreDosis,
          String idCond, int? dentroLimite) =>
      {
        'rela_sysvacu01': idCond,
        'sysvacu01_descripcion': _descCondicion[idCond],
        'rela_sysvacu02': '7',
        'sysvacu02_descripcion': 'Esquema habitual',
        'rela_sysvacu04': idVac,
        'sysvacu04_nombre': _vacunas[idVac],
        'rela_sysvacu05': idDosis,
        'sysvacu05_nombre': nombreDosis,
        'aplicacion_dentro_limite': dentroLimite,
      };

  // Clave vacuna_dosis: la última fila con esa clave pisa a las anteriores,
  // igual que el deduplicado del backend.
  final esperadas = <String, Map<String, dynamic>>{};
  if (edadDias != null) {
    for (final f in _filasPorRangoEtario) {
      if (f.edadMin > edadDias) continue;
      final dentro = edadDias >= f.limiteMin && edadDias <= f.limiteMax;
      esperadas['${f.idVac}_${f.idDosis}'] =
          pend(f.idVac, f.idDosis, f.nombreDosis, _cSin, dentro ? 1 : 0);
    }
  }
  for (final cond in [
    if (embarazada) _cEmb,
    if (personalSalud) _cSalud,
    if (puerpera) _cPuer,
  ]) {
    for (final f in _filasPorCondicion[cond]!) {
      esperadas['${f[0]}_${f[1]}'] = pend(f[0], f[1], f[2], cond, null);
    }
  }

  final pendientes = [
    for (final e in esperadas.entries)
      if (!clavesAplicadas.contains(e.key)) e.value,
  ];
  return MapEntry(aplicadas, pendientes);
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