/// Fecha de nacimiento y edad a partir del PDF417 del DNI argentino (no del API).

bool pareceFechaNacimientoArg(String s) {
  final t = s.trim();
  if (t.length < 8) return false;
  if (RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$').hasMatch(t)) return true;
  if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(t)) return true;
  return false;
}

/// Intenta leer la fecha de nacimiento en las posiciones habituales del PDF417.
/// DNI nuevo: tras DNI suelen ir ejemplar y fecha (índice ~6). DNI viejo (16/17): varios índices.
String? fechaNacimientoDesdePartesPdf417(List<String> partes) {
  final p = partes.map((e) => e.trim()).toList();
  final n = p.length;
  if (n == 17 || n == 16) {
    for (final i in [6, 7, 5, 8, 9]) {
      if (i < p.length && pareceFechaNacimientoArg(p[i])) return p[i].trim();
    }
    for (final s in p) {
      if (pareceFechaNacimientoArg(s)) return s.trim();
    }
    return null;
  }
  if (n >= 7) {
    for (final i in [6, 5, 7, 8]) {
      if (i < p.length && pareceFechaNacimientoArg(p[i])) return p[i].trim();
    }
    for (final s in p) {
      if (pareceFechaNacimientoArg(s)) return s.trim();
    }
  }
  return null;
}

/// Años cumplidos desde el texto de fecha del DNI (DD/MM/AAAA o ISO).
int? aniosCumplidosDesdeFechaNacimientoTexto(String? raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  DateTime? dt;
  if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
    dt = DateTime.tryParse(s.length >= 10 ? s.substring(0, 10) : s);
  }
  if (dt == null) {
    final m = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(s);
    if (m != null) {
      final d = int.tryParse(m.group(1)!);
      final mo = int.tryParse(m.group(2)!);
      final y = int.tryParse(m.group(3)!);
      if (d != null && mo != null && y != null) {
        dt = DateTime(y, mo, d);
      }
    }
  }
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
  DateTime? dt;
  if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(s)) {
    dt = DateTime.tryParse(s.length >= 10 ? s.substring(0, 10) : s);
  }
  if (dt == null) {
    final m = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(s);
    if (m != null) {
      final d = int.tryParse(m.group(1)!);
      final mo = int.tryParse(m.group(2)!);
      final y = int.tryParse(m.group(3)!);
      if (d != null && mo != null && y != null) {
        dt = DateTime(y, mo, d);
      }
    }
  }
  if (dt == null) return null;
  final dias = DateTime.now().difference(dt).inDays;
  if (dias < 0) return null;
  return dias;
}
