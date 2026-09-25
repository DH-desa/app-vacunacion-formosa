/// Fecha de nacimiento y edad desde el código del DNI (no del API). El QR 2026
/// trae el año con dos dígitos, y eso abre una ambigüedad de siglo.

/// Fija el borde inferior de la ventana ambigua: más que esto, `19YY` no es creíble.
const int kEdadMaximaPlausible = 110;

final _kRegexFechaCuatro = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
final _kRegexFechaDos = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2})$');
final _kRegexFechaIso = RegExp(r'^\d{4}-\d{2}-\d{2}');

bool pareceFechaNacimientoArg(String s) {
  final t = s.trim();
  if (_kRegexFechaCuatro.hasMatch(t)) return true;
  if (_kRegexFechaDos.hasMatch(t)) return true;
  if (_kRegexFechaIso.hasMatch(t)) return true;
  return false;
}

/// Siglos posibles para un año de dos dígitos, sin los imposibles: `20YY`
/// futuro, `19YY` demasiado viejo.
List<int> aniosPlausiblesParaDosDigitos(int yy, {DateTime? hoy}) {
  final ahora = hoy ?? DateTime.now();
  final candidatos = <int>[];
  final siglo20 = 2000 + yy;
  final siglo19 = 1900 + yy;
  if (siglo20 <= ahora.year) candidatos.add(siglo20);
  if (ahora.year - siglo19 <= kEdadMaximaPlausible) candidatos.add(siglo19);
  return candidatos;
}

/// True si el año admite más de un siglo. Con 2026, la ventana es `16..26`.
bool anioDosDigitosEsAmbiguo(int yy, {DateTime? hoy}) =>
    aniosPlausiblesParaDosDigitos(yy, hoy: hoy).length > 1;

/// True si el siglo de [raw] no puede determinarse. El caller prefiere entonces
/// la fecha del API, y si no la hay, deja la edad indeterminada.
bool fechaTieneSigloAmbiguo(String? raw, {DateTime? hoy}) {
  if (raw == null) return false;
  final m = _kRegexFechaDos.firstMatch(raw.trim());
  if (m == null) return false;
  final yy = int.tryParse(m.group(3)!);
  if (yy == null) return false;
  return anioDosDigitosEsAmbiguo(yy, hoy: hoy);
}

DateTime? _parseFechaArg(String raw, {DateTime? hoy}) {
  final s = raw.trim();
  if (_kRegexFechaIso.hasMatch(s)) {
    return DateTime.tryParse(s.length >= 10 ? s.substring(0, 10) : s);
  }
  final m4 = _kRegexFechaCuatro.firstMatch(s);
  if (m4 != null) {
    final d = int.tryParse(m4.group(1)!);
    final mo = int.tryParse(m4.group(2)!);
    final y = int.tryParse(m4.group(3)!);
    if (d == null || mo == null || y == null) return null;
    return DateTime(y, mo, d);
  }
  final m2 = _kRegexFechaDos.firstMatch(s);
  if (m2 == null) return null;
  final d = int.tryParse(m2.group(1)!);
  final mo = int.tryParse(m2.group(2)!);
  final yy = int.tryParse(m2.group(3)!);
  if (d == null || mo == null || yy == null) return null;
  final candidatos = aniosPlausiblesParaDosDigitos(yy, hoy: hoy);
  // Ambiguo o sin candidato: no se elige. Decide el caller.
  if (candidatos.length != 1) return null;
  return DateTime(candidatos.first, mo, d);
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

/// Años cumplidos desde el texto del DNI. `null` si el siglo es ambiguo: de la
/// edad depende qué vacunas se ofrecen, así que mejor indeterminada que inventada.
int? aniosCumplidosDesdeFechaNacimientoTexto(String? raw, {DateTime? hoy}) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;
  final dt = _parseFechaArg(s, hoy: hoy);
  if (dt == null) return null;
  final ahora = hoy ?? DateTime.now();
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
