import 'package:sistema_vacunacion/src/presentation/state/services.dart';
import 'package:sistema_vacunacion/src/utils/edad_beneficiario.dart';
import 'package:sistema_vacunacion/src/widgets/situacion_beneficiario_widget.dart';

/// Filas del Calendario Nacional de Vacunación 2026.
/// Fuente: `docs/calendario_nacional_vacunacion_2026.md:35-53` (orden del póster).
enum FilaCalendario {
  recienNacido('Recién nacido'),
  meses2('2 meses'),
  meses3('3 meses'),
  meses4('4 meses'),
  meses5('5 meses'),
  meses6('6 meses'),
  meses12('12 meses'),
  meses15('15 meses'),
  meses18('18 meses'),
  meses24('24 meses'),
  nacidos2021('Nacidos en 2021'),
  nacidos2015('Nacidos en 2015'),
  aPartir15Anios('A partir de los 15 años'),
  adultos('Adultos'),
  embarazadas('Embarazadas'),
  puerperas('Puérperas'),
  personalSalud('Personal de salud');

  const FilaCalendario(this.etiqueta);

  final String etiqueta;
}

/// Resultado de clasificar a una persona en las filas del calendario.
class ResultadoClasificacion {
  const ResultadoClasificacion({
    required this.filas,
    required this.edadIndeterminada,
  });

  /// Todas las filas que aplican. Puede estar vacía.
  final List<FilaCalendario> filas;

  /// `true` cuando no se pudo determinar la fila etaria por falta de datos
  /// o por ambigüedad (edad en años 0 o 1, sin fecha de nacimiento).
  /// Las filas de situación (embarazada/puérpera/personal de salud) igual
  /// se incluyen en [filas] aunque esto sea `true`.
  final bool edadIndeterminada;
}

/// Clasifica a una persona en las filas del Calendario Nacional 2026 que le
/// correspondan. Función pura: no lee estado, no hace I/O.
///
/// Reglas (ver plan): la pertenencia a una fila etaria de meses es por
/// **último hito alcanzado** (3 meses y medio → fila "3 meses"). "Adultos"
/// (desde los 16 años) y "A partir de los 15 años" (15 hasta el día antes
/// de cumplir 16) son **excluyentes entre sí**: nunca se devuelven juntas.
/// Las filas de situación (embarazada/puérpera/personal de salud) son
/// independientes de esto y se suman siempre que apliquen.
ResultadoClasificacion clasificarFilasCalendario({
  DateTime? fechaNacimiento,
  int? edadAnios,
  required CondicionGestacional? condicionGestacional,
  required bool esPersonalDeSalud,
  required DateTime hoy,
}) {
  final filas = <FilaCalendario>[];

  // A. Filas por situación — independientes de la edad.
  if (condicionGestacional == CondicionGestacional.embarazada) {
    filas.add(FilaCalendario.embarazadas);
  }
  if (condicionGestacional == CondicionGestacional.puerpera) {
    filas.add(FilaCalendario.puerperas);
  }
  if (esPersonalDeSalud) {
    filas.add(FilaCalendario.personalSalud);
  }

  // B+C+D. Filas etarias y cohortes, con fecha de nacimiento (precisión de meses).
  if (fechaNacimiento != null) {
    final meses = _mesesCumplidos(fechaNacimiento, hoy);
    _agregarFilasPorMeses(filas, meses);

    final anios = edadAniosDesde(fechaNacimiento, hoy);
    _agregarFilasPorAnios(filas, anios);

    if (fechaNacimiento.year == 2021) filas.add(FilaCalendario.nacidos2021);
    if (fechaNacimiento.year == 2015) filas.add(FilaCalendario.nacidos2015);

    return ResultadoClasificacion(filas: filas, edadIndeterminada: false);
  }

  // E. Fallback solo con edad en años (sin fecha de nacimiento: sin cohortes).
  if (edadAnios != null) {
    if (edadAnios >= 2) {
      _agregarFilasPorMeses(filas, edadAnios * 12);
      _agregarFilasPorAnios(filas, edadAnios);
      return ResultadoClasificacion(filas: filas, edadIndeterminada: false);
    }
    // 0 o 1 año: no distingue entre las filas de meses (recién nacido..18
    // meses). No clasificable con precisión.
    return ResultadoClasificacion(filas: filas, edadIndeterminada: true);
  }

  // F. Sin fecha ni edad.
  return ResultadoClasificacion(filas: filas, edadIndeterminada: true);
}

int _mesesCumplidos(DateTime nacimiento, DateTime hoy) {
  var meses = (hoy.year - nacimiento.year) * 12 + (hoy.month - nacimiento.month);
  if (hoy.day < nacimiento.day) meses--;
  return meses < 0 ? 0 : meses;
}

void _agregarFilasPorMeses(List<FilaCalendario> filas, int meses) {
  if (meses < 2) {
    filas.add(FilaCalendario.recienNacido);
  } else if (meses < 3) {
    filas.add(FilaCalendario.meses2);
  } else if (meses < 4) {
    filas.add(FilaCalendario.meses3);
  } else if (meses < 5) {
    filas.add(FilaCalendario.meses4);
  } else if (meses < 6) {
    filas.add(FilaCalendario.meses5);
  } else if (meses < 12) {
    filas.add(FilaCalendario.meses6);
  } else if (meses < 15) {
    filas.add(FilaCalendario.meses12);
  } else if (meses < 18) {
    filas.add(FilaCalendario.meses15);
  } else if (meses < 24) {
    filas.add(FilaCalendario.meses18);
  } else if (meses < 180) {
    filas.add(FilaCalendario.meses24);
  }
  // meses >= 180 (15 años): sin fila de meses, ver _agregarFilasPorAnios.
}

/// Excluyentes entre sí: de 15 años hasta el día antes de cumplir 16 cae en
/// `aPartir15Anios`; desde los 16 cae en `adultos`, no en ambas.
void _agregarFilasPorAnios(List<FilaCalendario> filas, int anios) {
  if (anios >= 16) {
    filas.add(FilaCalendario.adultos);
  } else if (anios >= 15) {
    filas.add(FilaCalendario.aPartir15Anios);
  }
}

/// Clasifica al beneficiario actualmente cargado en memoria
/// ([beneficiarioService] + [situacionBeneficiarioService]).
///
/// Precedencia de fuente de edad (fecha antes que edad en años, porque las
/// filas de meses y las cohortes requieren fecha de nacimiento):
/// 1. Fecha de nacimiento leída del PDF417 al escanear.
/// 2. `sysdesa10_fecha_nacimiento` devuelto por la API.
/// 3. Edad en años leída del PDF417 al escanear.
/// 4. `sysdesa10_edad` devuelto por la API.
///
/// No registra estado nuevo: es un cálculo derivado, se recalcula en cada
/// llamada.
ResultadoClasificacion clasificarBeneficiarioActual({DateTime? hoy}) {
  final ahora = hoy ?? DateTime.now();
  final beneficiario = beneficiarioService.beneficiario;

  if (beneficiario == null) {
    return ResultadoClasificacion(filas: const [], edadIndeterminada: true);
  }

  final fechaNacimiento =
      parseFechaNacimiento(beneficiarioService.fechaNacimientoDesdePdf417Escaneado) ??
          parseFechaNacimiento(beneficiario.sysdesa10_fecha_nacimiento);

  final edadAnios = fechaNacimiento != null
      ? null
      : parseEdadAnios(beneficiarioService.edadAniosDesdePdf417Escaneado) ??
          parseEdadAnios(beneficiario.sysdesa10_edad);

  return clasificarFilasCalendario(
    fechaNacimiento: fechaNacimiento,
    edadAnios: edadAnios,
    condicionGestacional: situacionBeneficiarioService.condicionGestacional,
    esPersonalDeSalud: situacionBeneficiarioService.esPersonalDeSalud,
    hoy: ahora,
  );
}

/// Una celda de la matriz vacuna×fila: nombre de la vacuna e indicación tal
/// cual figura en la celda del póster (incluye la referencia entre
/// paréntesis a la nota/aclaración cuando el póster la tiene).
class VacunaFilaCalendario {
  const VacunaFilaCalendario(this.vacuna, this.indicacion);

  final String vacuna;
  final String indicacion;
}

/// Matriz vacuna×fila del Calendario Nacional de Vacunación 2026.
/// Transcripción literal de `docs/calendario_nacional_vacunacion_2026.md:37-53`.
const Map<FilaCalendario, List<VacunaFilaCalendario>> matrizCalendario2026 = {
  FilaCalendario.recienNacido: [
    VacunaFilaCalendario('BCG', 'única dosis (A)'),
    VacunaFilaCalendario('Hepatitis B', 'dosis neonatal (B)'),
  ],
  FilaCalendario.meses2: [
    VacunaFilaCalendario('Neumococo Conjugada', '1º dosis'),
    VacunaFilaCalendario('Quíntuple o Pentavalente', '1º dosis'),
    VacunaFilaCalendario('IPV', '1º dosis'),
    VacunaFilaCalendario('Rotavirus', '1º dosis (D)'),
  ],
  FilaCalendario.meses3: [
    VacunaFilaCalendario('Meningococo ACYW', '1º dosis'),
  ],
  FilaCalendario.meses4: [
    VacunaFilaCalendario('Neumococo Conjugada', '2º dosis'),
    VacunaFilaCalendario('Quíntuple o Pentavalente', '2º dosis'),
    VacunaFilaCalendario('IPV', '2º dosis'),
    VacunaFilaCalendario('Rotavirus', '2º dosis (E)'),
  ],
  FilaCalendario.meses5: [
    VacunaFilaCalendario('Meningococo ACYW', '2º dosis'),
  ],
  FilaCalendario.meses6: [
    VacunaFilaCalendario('Neumococo Conjugada', '3º dosis'),
    VacunaFilaCalendario('Quíntuple o Pentavalente', '3º dosis'),
    VacunaFilaCalendario('Antigripal', 'dosis anual (F)'),
  ],
  FilaCalendario.meses12: [
    VacunaFilaCalendario('Neumococo Conjugada', 'refuerzo'),
    VacunaFilaCalendario('Antigripal', 'dosis anual (F)'),
    VacunaFilaCalendario('Hepatitis A', 'única dosis'),
    VacunaFilaCalendario('Triple Viral', '1º dosis'),
  ],
  FilaCalendario.meses15: [
    VacunaFilaCalendario('Quíntuple o Pentavalente', '1º refuerzo'),
    VacunaFilaCalendario('Meningococo ACYW', 'refuerzo'),
    VacunaFilaCalendario('Antigripal', 'dosis anual (F)'),
    VacunaFilaCalendario('Triple Viral', '2º dosis'),
    VacunaFilaCalendario('Varicela', '1º dosis'),
  ],
  FilaCalendario.meses18: [
    VacunaFilaCalendario('Quíntuple o Pentavalente', '1º refuerzo'),
    VacunaFilaCalendario('Antigripal', 'dosis anual (F)'),
    VacunaFilaCalendario('Triple Viral', '2º dosis'),
    VacunaFilaCalendario('Fiebre Amarilla', '1º dosis (P)'),
  ],
  FilaCalendario.meses24: [
    VacunaFilaCalendario('Antigripal', 'dosis anual (F)'),
  ],
  FilaCalendario.nacidos2021: [
    VacunaFilaCalendario('IPV', 'refuerzo'),
    VacunaFilaCalendario('Triple Viral', 'Nacidos 2021/22/23/24 (J)'),
    VacunaFilaCalendario('Varicela', '2º dosis'),
    VacunaFilaCalendario('Triple Bacteriana Celular', '2º refuerzo'),
  ],
  FilaCalendario.nacidos2015: [
    VacunaFilaCalendario('Meningococo ACYW', 'única dosis'),
    VacunaFilaCalendario('Triple Bacteriana Acelular', 'refuerzo'),
    VacunaFilaCalendario('Virus Papiloma Humano', 'única dosis (N)'),
    VacunaFilaCalendario('Fiebre Amarilla', 'refuerzo (Q)'),
  ],
  FilaCalendario.aPartir15Anios: [
    VacunaFilaCalendario('Triple Viral', 'iniciar o completar esquema (K)'),
    VacunaFilaCalendario('Fiebre Hemorrágica Argentina', 'única dosis (R)'),
  ],
  FilaCalendario.adultos: [
    VacunaFilaCalendario('Hepatitis B', 'iniciar o completar esquema (C)'),
    VacunaFilaCalendario('Neumococo Conjugada', 'única dosis (G)'),
    VacunaFilaCalendario('Antigripal', 'dosis anual (G)'),
    VacunaFilaCalendario('Triple Viral', 'iniciar o completar esquema (K)'),
    VacunaFilaCalendario('Doble Bacteriana', 'refuerzo cada 10 años'),
    VacunaFilaCalendario('Fiebre Hemorrágica Argentina', 'única dosis (R)'),
  ],
  FilaCalendario.embarazadas: [
    VacunaFilaCalendario('Antigripal', 'una dosis (H)'),
    VacunaFilaCalendario('Triple Bacteriana Acelular', 'una dosis (L)'),
    VacunaFilaCalendario('Virus Sincicial Respiratorio', 'única dosis (O)'),
  ],
  FilaCalendario.puerperas: [
    VacunaFilaCalendario('Antigripal', 'una dosis (I)'),
    VacunaFilaCalendario('Triple Viral', 'iniciar o completar esquema (K)'),
  ],
  FilaCalendario.personalSalud: [
    VacunaFilaCalendario('Antigripal', 'dosis anual'),
    VacunaFilaCalendario('Triple Viral', 'iniciar o completar esquema (K)'),
    VacunaFilaCalendario('Triple Bacteriana Acelular', 'una dosis (M)'),
  ],
};

/// Vacunas agrupadas por fila, para las filas de un [ResultadoClasificacion].
class VacunasPorFila {
  const VacunasPorFila(this.fila, this.vacunas);

  final FilaCalendario fila;
  final List<VacunaFilaCalendario> vacunas;
}

/// Agrupa por fila las vacunas de [filas] según [matrizCalendario2026].
/// Conserva el orden de [filas]; si la misma vacuna aparece en dos filas
/// aplicables, se lista una vez en cada bloque (no se deduplica entre filas).
List<VacunasPorFila> vacunasPorFilas(List<FilaCalendario> filas) {
  return filas
      .map((f) => VacunasPorFila(f, matrizCalendario2026[f] ?? const []))
      .toList();
}
