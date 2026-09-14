import 'package:sistema_vacunacion/src/utils/edad_pdf417_dni_arg.dart';

/// Resultado del parseo del PDF417 del DNI argentino.
class DatosDniPdf417 {
  const DatosDniPdf417({
    required this.apellido,
    required this.nombre,
    required this.dni,
    required this.sexo,
    required this.tramite,
    this.fechaNacimientoPdf417,
  });

  final String apellido;
  final String nombre;
  final String dni;
  final String sexo;
  final String tramite;

  /// Fecha de nacimiento tal como viene en el PDF417 (DD/MM/AAAA o ISO).
  final String? fechaNacimientoPdf417;
}

// Compiladas una sola vez — se usan en cada evento de scan.
final kRegexDniPdf417 = RegExp(r'^\d{7,8}$');
final kRegexSexoPdf417 = RegExp(r'^[MFX]$', caseSensitive: false);
final kRegexSoloNumsPdf417 = RegExp(r'^\d+$');

// Bytes de control o U+FFFD: señal de lectura PDF417 corrupta.
final kRegexBytesCorruptosPdf417 = RegExp('[\x00-\x1F�]');

/// DNI viejo (17 campos) primero; luego layout “nuevo” por posiciones (cualquier N≥5);
/// si no aplica, heurística por dígitos y texto.
DatosDniPdf417? parsearPdf417DniArgentino(List<String> p) {
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
    fechaNacimientoPdf417: fn ?? h.fechaNacimientoPdf417,
  );
}

/// M / F / X (género no binario, habilitado por Renaper desde 2021).
/// Devuelve `null` si [raw] no es un valor de sexo reconocible — el caller
/// debe tratarlo como fallo de parseo, nunca asumir un sexo por default.
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
  // Ningún campo tiene un valor de sexo reconocible: parseo no confiable,
  // no asumir "F" por default.
  if (sexo == null) return null;

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
    fechaNacimientoPdf417:
        null, // el caller ya calculó fn y hace fn ?? h.fechaNacimientoPdf417
  );
}

/// True si [crudo] tiene forma de DNI válida y sin bytes corruptos.
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
