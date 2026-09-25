import 'package:sistema_vacunacion/src/utils/edad_pdf417_dni_arg.dart';

/// Formato del código leído. Los dos conviven, no hay migración.
enum FormatoCodigoDni { pdf417, qr }

/// Resultado del parseo del código del DNI argentino.
class DatosDniPdf417 {
  const DatosDniPdf417({
    required this.apellido,
    required this.nombre,
    required this.dni,
    required this.sexo,
    required this.tramite,
    required this.formato,
    this.fechaNacimientoPdf417,
  });

  final String apellido;
  final String nombre;
  final String dni;

  /// `null` en el QR, que no trae el campo. No es fallo de parseo: Registrador
  /// y Vacunador consultan solo por DNI.
  final String? sexo;
  final String tramite;

  /// Formato del que se extrajeron estos datos.
  final FormatoCodigoDni formato;

  /// Fecha de nacimiento tal como viene en el código (DD/MM/AAAA, DD/MM/AA o ISO).
  final String? fechaNacimientoPdf417;
}

// Compiladas una sola vez — se usan en cada evento de scan.
final kRegexDniPdf417 = RegExp(r'^\d{7,8}$');
final kRegexSexoPdf417 = RegExp(r'^[MFX]$', caseSensitive: false);
final kRegexSoloNumsPdf417 = RegExp(r'^\d+$');

/// JWT: tres segmentos base64url. Marca del QR 2026 — contar campos no sirve,
/// colisiona con el PDF417 de 8.
final kRegexJwtQrDni = RegExp(r'^eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$');

// Bytes de control o U+FFFD: señal de lectura PDF417 corrupta.
final kRegexBytesCorruptosPdf417 = RegExp('[\x00-\x1F�]');

/// True si [p] son los campos de un QR 2026, reconocido por el JWT final.
bool esLecturaQrDniArgentino(List<String> p) =>
    p.length == 8 && kRegexJwtQrDni.hasMatch(p[7].trim());

/// Layout QR: `tramite@apellido@nombre@dni@ejemplar@fNac@fEmision@jwt`.
/// Sin sexo y sin dejar el hueco, así que desde [3] va corrido contra el PDF417.
DatosDniPdf417? _parsearQrDniArgentino(List<String> p) {
  final dni = p[3].replaceAll(RegExp(r'\s'), '');
  if (!kRegexDniPdf417.hasMatch(dni)) return null;
  return DatosDniPdf417(
    apellido: p[1],
    nombre: p[2],
    dni: dni,
    sexo: null, // el QR no lo trae; lo aporta el operador
    tramite: p[0],
    formato: FormatoCodigoDni.qr,
    fechaNacimientoPdf417: fechaNacimientoDesdePartesPdf417(p),
  );
}

/// QR 2026 primero (se identifica por el JWT); después DNI viejo (16/17 campos),
/// luego layout “nuevo” por posiciones (cualquier N≥5), y si nada aplica,
/// heurística por dígitos y texto.
DatosDniPdf417? parsearPdf417DniArgentino(List<String> p) {
  if (esLecturaQrDniArgentino(p)) return _parsearQrDniArgentino(p);

  final n = p.length;
  final fn = fechaNacimientoDesdePartesPdf417(p);

  // Formato anterior: PDF417 del reverso (16 o 17 campos con @).
  if (n == 17 || n == 16) {
    final dni = p[1].replaceAll(RegExp(r'\s'), '');
    final sx = normalizarSexoPdf417(p[8]);
    if (kRegexDniPdf417.hasMatch(dni) && sx != null) {
      return DatosDniPdf417(
        apellido: p[4],
        nombre: p[5],
        dni: dni,
        sexo: sx,
        tramite: p[10],
        formato: FormatoCodigoDni.pdf417,
        fechaNacimientoPdf417: fn,
      );
    }
    final h = parseoHeuristicoPdf417(p);
    if (h == null) return null;
    return DatosDniPdf417(
      apellido: h.apellido,
      nombre: h.nombre,
      dni: h.dni,
      sexo: h.sexo,
      tramite: h.tramite,
      formato: FormatoCodigoDni.pdf417,
      fechaNacimientoPdf417: fn ?? h.fechaNacimientoPdf417,
    );
  }

  if (n >= 5) {
    final dni = p[4].replaceAll(RegExp(r'\s'), '');
    final sx = normalizarSexoPdf417(p[3]);
    if (kRegexDniPdf417.hasMatch(dni) && sx != null) {
      return DatosDniPdf417(
        apellido: p[1],
        nombre: p[2],
        dni: dni,
        sexo: sx,
        tramite: p[0],
        formato: FormatoCodigoDni.pdf417,
        fechaNacimientoPdf417: fn,
      );
    }
  }

  final h = parseoHeuristicoPdf417(p);
  if (h == null) return null;
  return DatosDniPdf417(
    apellido: h.apellido,
    nombre: h.nombre,
    dni: h.dni,
    sexo: h.sexo,
    tramite: h.tramite,
    formato: FormatoCodigoDni.pdf417,
    fechaNacimientoPdf417: fn ?? h.fechaNacimientoPdf417,
  );
}

/// M / F / X (género no binario, habilitado por Renaper desde 2021).
/// Devuelve `null` si [raw] no es un valor de sexo reconocible. El caller nunca
/// debe asumir un sexo por default: o lo pide, o no consulta.
String? normalizarSexoPdf417(String raw) {
  final u = raw.trim().toUpperCase();
  if (u == 'M' || u == 'MASCULINO') return 'M';
  if (u == 'X') return 'X';
  if (u == 'F' || u == 'FEMENINO') return 'F';
  return null;
}

DatosDniPdf417? parseoHeuristicoPdf417(List<String> p) {
  String? dni;
  int? idxDni;

  // Posición habitual del DNI en layout nuevo (evita confundir con otros números de 7–8 dígitos).
  if (p.length > 4) {
    final t4 = p[4].replaceAll(RegExp(r'\s'), '');
    if (kRegexDniPdf417.hasMatch(t4)) {
      dni = t4;
      idxDni = 4;
    }
  }
  if (dni == null) {
    for (var i = 0; i < p.length; i++) {
      final t = p[i].replaceAll(RegExp(r'\s'), '');
      if (kRegexDniPdf417.hasMatch(t)) {
        dni = t;
        idxDni = i;
        break;
      }
    }
  }
  if (dni == null) return null;

  String? sexo;
  for (final s in p) {
    sexo = normalizarSexoPdf417(s.trim());
    if (sexo != null) break;
  }
  // Sin sexo reconocible el parseo sigue valiendo: el DNI ya se encontró.
  // Nunca se asume un valor por default.

  final textos = <String>[];
  for (var i = 0; i < p.length; i++) {
    final s = p[i].trim();
    if (s.isEmpty) continue;
    if (i == idxDni) continue;
    final soloDigitos = s.replaceAll(RegExp(r'\s'), '');
    if (kRegexSoloNumsPdf417.hasMatch(soloDigitos)) continue;
    if (kRegexSexoPdf417.hasMatch(s)) continue;
    if (s.length < 2) continue;
    textos.add(s);
  }
  textos.sort((a, b) => b.length.compareTo(a.length));
  final apellido = textos.isNotEmpty ? textos[0] : '';
  final nombre = textos.length > 1 ? textos[1] : '';
  final tramite = p.isNotEmpty ? p[0] : '';

  return DatosDniPdf417(
    apellido: apellido,
    nombre: nombre,
    dni: dni,
    sexo: sexo,
    tramite: tramite,
    // Solo se llega acá desde la rama PDF417: el QR se despacha antes.
    formato: FormatoCodigoDni.pdf417,
    fechaNacimientoPdf417:
        null, // el caller ya calculó fn y hace fn ?? h.fechaNacimientoPdf417
  );
}

/// True si [crudo] tiene forma de DNI válida y sin bytes corruptos. Vale para
/// los dos formatos; exige DNI reconocible, no sexo.
bool cadenaEsLecturaPlausibleDniArgentino(String crudo) {
  final s = crudo.trim();
  if (s.isEmpty || !s.contains('@')) return false;
  final partes = s.split('@').map((e) => e.trim()).toList();
  final datos = parsearPdf417DniArgentino(partes);
  if (datos == null || !kRegexDniPdf417.hasMatch(datos.dni)) return false;
  if (kRegexBytesCorruptosPdf417.hasMatch(datos.apellido) ||
      kRegexBytesCorruptosPdf417.hasMatch(datos.nombre)) {
    return false;
  }
  return true;
}
