/// Parseo de edad y fecha de nacimiento del beneficiario tal como los
/// devuelve `wserv_obtener_datos_beneficiario.php` (campos `sysdesa10_edad`
/// y `sysdesa10_fecha_nacimiento`).
///
/// Extraído de `vacunas_page.dart` (`_edadNumericaBeneficiario` y
/// `_edadAniosDesdeFechaNacimiento`) para reutilizarlo en el clasificador
/// del calendario de vacunación sin duplicar la lógica de parseo.
library;

import 'package:sistema_vacunacion/src/utils/edad_pdf417_dni_arg.dart';

/// Edad numérica desde el WS (`8`, `"12"`, `"8 años"`, etc.).
/// Valores > 120 se ignoran (a veces mandan año de nacimiento en el campo edad).
int? parseEdadAnios(String? raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  int? v = int.tryParse(s);
  if (v == null) {
    final m = RegExp(r'(\d+)').firstMatch(s);
    if (m != null) v = int.tryParse(m.group(1)!);
  }
  if (v == null || v > 120) return null;
  return v;
}

/// Fecha de nacimiento desde el WS, formatos `yyyy-MM-dd` (con o sin hora),
/// `d/M/yyyy`, `d-M-yyyy` o `d/M/yy` (QR 2026). No calcula edad, solo parsea
/// el `DateTime`. Con año de 2 dígitos y siglo ambiguo devuelve `null`.
DateTime? parseFechaNacimiento(String? raw, {DateTime? hoy}) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  DateTime? dt;
  if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
    dt = DateTime.tryParse(s.substring(0, s.length >= 10 ? 10 : s.length));
  }
  if (dt == null) {
    final m = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})').firstMatch(s);
    if (m != null) {
      final d = int.tryParse(m.group(1)!);
      final mo = int.tryParse(m.group(2)!);
      final y = int.tryParse(m.group(3)!);
      if (d != null && mo != null && y != null) {
        dt = DateTime(y, mo, d);
      }
    }
  }
  if (dt == null) {
    final m = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2})$').firstMatch(s);
    if (m != null) {
      final d = int.tryParse(m.group(1)!);
      final mo = int.tryParse(m.group(2)!);
      final yy = int.tryParse(m.group(3)!);
      if (d != null && mo != null && yy != null) {
        final anios = aniosPlausiblesParaDosDigitos(yy, hoy: hoy);
        if (anios.length == 1) dt = DateTime(anios.first, mo, d);
      }
    }
  }
  return dt;
}

/// Años cumplidos entre [nacimiento] y [hoy].
int edadAniosDesde(DateTime nacimiento, DateTime hoy) {
  var anios = hoy.year - nacimiento.year;
  if (hoy.month < nacimiento.month ||
      (hoy.month == nacimiento.month && hoy.day < nacimiento.day)) {
    anios--;
  }
  return anios;
}

/// Días de vida entre [nacimiento] y [hoy] (`wserv_listados_vacunas.php`
/// espera la edad en días, no en años).
int diasDeVidaDesde(DateTime nacimiento, DateTime hoy) =>
    hoy.difference(nacimiento).inDays;
