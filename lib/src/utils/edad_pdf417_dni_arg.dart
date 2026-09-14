/// Fecha de nacimiento y edad a partir del PDF417 del DNI argentino (no del API).

bool pareceFechaNacimientoArg(String s) {
  final t = s.trim();
  if (t.length < 8) return false;
  if (RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$').hasMatch(t)) return true;
  if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(t)) return true;
  return false;
}

DateTime? _parseFechaArg(String raw) {
  final s = raw.trim();
  if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
    return DateTime.tryParse(s.length >= 10 ? s.substring(0, 10) : s);
  }
  final m = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(s);
  if (m == null) return null;
  final d = int.tryParse(m.group(1)!);
  final mo = int.tryParse(m.group(2)!);
  final y = int.tryParse(m.group(3)!);
  if (d == null || mo == null || y == null) return null;
  return DateTime(y, mo, d);
}

/// Intenta leer la fecha de nacimiento en las posiciones habituales del PDF417.
/// DNI nuevo (>=7 campos) y DNI viejo (16/17 campos) suelen traer la fecha de
/// nacimiento y la de trámite/emisión, ambas DD/MM/AAAA — indistinguibles por
/// forma. Cuando aparece una sola fecha en los campos, se usa esa. Cuando
/// aparece más de una (el caso típico), se elige la más antigua: el trámite
/// de un DNI nunca puede emitirse antes de que la persona nazca, así que la
/// fecha más antigua siempre es la de nacimiento — no es una suposición, es
/// un invariante real, y evita depender de en qué índice cayó cada campo
/// (que es justamente lo que falla cuando el layout se corre una posición).
String? fechaNacimientoDesdePartesPdf417(List<String> partes) {
  final p = partes.map((e) => e.trim()).toList();
  if (p.length < 7 && p.length != 16 && p.length != 17) return null;

  final candidatas = p.where(pareceFechaNacimientoArg).toList();
  if (candidatas.isEmpty) return null;
  if (candidatas.length == 1) return candidatas.first;

  String? masAntigua;
  DateTime? fechaMasAntigua;
  for (final c in candidatas) {
    final dt = _parseFechaArg(c);
    if (dt == null) continue;
    if (fechaMasAntigua == null || dt.isBefore(fechaMasAntigua)) {
      fechaMasAntigua = dt;
      masAntigua = c;
    }
  }
  return masAntigua;
}

/// Años cumplidos desde el texto de fecha del DNI (DD/MM/AAAA o ISO).
int? aniosCumplidosDesdeFechaNacimientoTexto(String? raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  final dt = _parseFechaArg(s);
  if (dt == null) return null;
  final ahora = DateTime.now();
  var anios = ahora.year - dt.year;
  if (ahora.month < dt.month ||
      (ahora.month == dt.month && ahora.day < dt.day)) {
    anios--;
  }
  if (anios < 0 || anios > 120) return null;
  return anios;
}

/// Días de vida desde el texto de fecha del DNI (DD/MM/AAAA o ISO).
int? diasDeVidaDesdeFechaNacimientoTexto(String? raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  final dt = _parseFechaArg(s);
  if (dt == null) return null;
  final dias = DateTime.now().difference(dt).inDays;
  if (dias < 0) return null;
  return dias;
}
