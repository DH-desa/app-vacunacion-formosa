import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_vacunacion/src/domain/calendario/calendario_2026.dart';
import 'package:sistema_vacunacion/src/utils/edad_beneficiario.dart';
import 'package:sistema_vacunacion/src/widgets/situacion_beneficiario_widget.dart';

void main() {
  final hoy = DateTime(2026, 7, 3);

  ResultadoClasificacion clasificar({
    DateTime? fechaNacimiento,
    int? edadAnios,
    CondicionGestacional? condicionGestacional,
    bool esPersonalDeSalud = false,
  }) {
    return clasificarFilasCalendario(
      fechaNacimiento: fechaNacimiento,
      edadAnios: edadAnios,
      condicionGestacional: condicionGestacional,
      esPersonalDeSalud: esPersonalDeSalud,
      hoy: hoy,
    );
  }

  DateTime nacidoHaceMeses(int meses) {
    return DateTime(hoy.year, hoy.month - meses, hoy.day);
  }

  DateTime nacidoHaceAnios(int anios) {
    return DateTime(hoy.year - anios, hoy.month, hoy.day);
  }

  group('Filas etarias por hito (último hito alcanzado)', () {
    test('menos de 2 meses -> recienNacido', () {
      final r = clasificar(fechaNacimiento: nacidoHaceMeses(1));
      expect(r.filas, [FilaCalendario.recienNacido]);
      expect(r.edadIndeterminada, false);
    });

    test('exactamente 2 meses -> meses2', () {
      final r = clasificar(fechaNacimiento: nacidoHaceMeses(2));
      expect(r.filas, [FilaCalendario.meses2]);
    });

    test('3 meses y 15 días -> meses3 (no meses4)', () {
      final nacimiento = DateTime(hoy.year, hoy.month - 3, hoy.day - 15);
      final r = clasificar(fechaNacimiento: nacimiento);
      expect(r.filas, [FilaCalendario.meses3]);
    });

    test('4 meses -> meses4', () {
      final r = clasificar(fechaNacimiento: nacidoHaceMeses(4));
      expect(r.filas, [FilaCalendario.meses4]);
    });

    test('5 meses -> meses5', () {
      final r = clasificar(fechaNacimiento: nacidoHaceMeses(5));
      expect(r.filas, [FilaCalendario.meses5]);
    });

    test('6 meses -> meses6', () {
      final r = clasificar(fechaNacimiento: nacidoHaceMeses(6));
      expect(r.filas, [FilaCalendario.meses6]);
    });

    test('12 meses -> meses12', () {
      final r = clasificar(fechaNacimiento: nacidoHaceMeses(12));
      expect(r.filas, [FilaCalendario.meses12]);
    });

    test('15 meses -> meses15', () {
      final r = clasificar(fechaNacimiento: nacidoHaceMeses(15));
      expect(r.filas, [FilaCalendario.meses15]);
    });

    test('18 meses -> meses18', () {
      final r = clasificar(fechaNacimiento: nacidoHaceMeses(18));
      expect(r.filas, [FilaCalendario.meses18]);
    });

    test('23 meses -> meses18 (no meses24)', () {
      final r = clasificar(fechaNacimiento: nacidoHaceMeses(23));
      expect(r.filas, [FilaCalendario.meses18]);
    });

    test('24 meses -> meses24', () {
      final r = clasificar(fechaNacimiento: nacidoHaceMeses(24));
      expect(r.filas, [FilaCalendario.meses24]);
    });

    test('14 años -> solo meses24', () {
      final r = clasificar(fechaNacimiento: nacidoHaceAnios(14));
      expect(r.filas, [FilaCalendario.meses24]);
    });
  });

  group('Rangos de años (D4/D5)', () {
    test('15 años exactos -> aPartir15Anios sin adultos', () {
      final r = clasificar(fechaNacimiento: nacidoHaceAnios(15));
      expect(r.filas, [FilaCalendario.aPartir15Anios]);
    });

    test('16 años -> solo adultos (excluyente con aPartir15Anios)', () {
      final r = clasificar(fechaNacimiento: nacidoHaceAnios(16));
      expect(r.filas, [FilaCalendario.adultos]);
    });
  });

  group('Cohortes', () {
    test('nacido 15/06/2021 -> nacidos2021 además de su fila etaria', () {
      final nacimiento = DateTime(2021, 6, 15);
      final r = clasificar(fechaNacimiento: nacimiento);
      expect(r.filas, contains(FilaCalendario.nacidos2021));
      expect(r.filas, contains(FilaCalendario.meses24));
    });

    test('nacido en 2015 -> nacidos2015 además de su fila etaria', () {
      final nacimiento = DateTime(2015, 3, 10);
      final r = clasificar(fechaNacimiento: nacimiento);
      expect(r.filas, contains(FilaCalendario.nacidos2015));
      expect(r.filas, contains(FilaCalendario.meses24));
    });
  });

  group('Situación', () {
    test('embarazada de 25 años -> embarazadas + adultos (sin aPartir15Anios)', () {
      final r = clasificar(
        fechaNacimiento: nacidoHaceAnios(25),
        condicionGestacional: CondicionGestacional.embarazada,
      );
      expect(r.filas, [FilaCalendario.embarazadas, FilaCalendario.adultos]);
    });

    test('puérpera y personal de salud simultáneos, ambas conviven con adultos', () {
      final r = clasificar(
        fechaNacimiento: nacidoHaceAnios(30),
        condicionGestacional: CondicionGestacional.puerpera,
        esPersonalDeSalud: true,
      );
      expect(r.filas, contains(FilaCalendario.puerperas));
      expect(r.filas, contains(FilaCalendario.personalSalud));
      expect(r.filas, contains(FilaCalendario.adultos));
      expect(r.filas, isNot(contains(FilaCalendario.aPartir15Anios)));
    });

    test('embarazada de 34 años + personal de salud -> las 3 filas conviven', () {
      final r = clasificar(
        fechaNacimiento: nacidoHaceAnios(34),
        condicionGestacional: CondicionGestacional.embarazada,
        esPersonalDeSalud: true,
      );
      expect(r.filas, [
        FilaCalendario.embarazadas,
        FilaCalendario.personalSalud,
        FilaCalendario.adultos,
      ]);
    });
  });

  group('Fallback sin fecha de nacimiento', () {
    test('edadAnios = 8 -> meses24, sin cohortes', () {
      final r = clasificar(edadAnios: 8);
      expect(r.filas, [FilaCalendario.meses24]);
      expect(r.edadIndeterminada, false);
    });

    test('edadAnios = 1 -> indeterminada', () {
      final r = clasificar(edadAnios: 1);
      expect(r.edadIndeterminada, true);
    });

    test('edadAnios = 0 -> indeterminada', () {
      final r = clasificar(edadAnios: 0);
      expect(r.edadIndeterminada, true);
    });
  });

  test('sin datos + personal de salud -> [personalSalud], indeterminada', () {
    final r = clasificar(esPersonalDeSalud: true);
    expect(r.filas, [FilaCalendario.personalSalud]);
    expect(r.edadIndeterminada, true);
  });

  group('parseEdadAnios', () {
    test('"8 años" -> 8', () => expect(parseEdadAnios('8 años'), 8));
    test('"130" -> null (fuera de rango)', () => expect(parseEdadAnios('130'), null));
    test('null -> null', () => expect(parseEdadAnios(null), null));
  });

  group('parseFechaNacimiento', () {
    test('"2021-06-15" -> DateTime(2021,6,15)', () {
      expect(parseFechaNacimiento('2021-06-15'), DateTime(2021, 6, 15));
    });
    test('"2021-06-15 00:00:00" -> DateTime(2021,6,15)', () {
      expect(parseFechaNacimiento('2021-06-15 00:00:00'), DateTime(2021, 6, 15));
    });
    test('"15/6/2021" -> DateTime(2021,6,15)', () {
      expect(parseFechaNacimiento('15/6/2021'), DateTime(2021, 6, 15));
    });
    test('basura -> null', () => expect(parseFechaNacimiento('no es fecha'), null));
  });

  group('matrizCalendario2026', () {
    test('tiene una entrada por cada una de las 17 filas', () {
      expect(matrizCalendario2026.length, FilaCalendario.values.length);
      for (final f in FilaCalendario.values) {
        expect(matrizCalendario2026.containsKey(f), true, reason: f.name);
      }
    });

    test('ninguna fila queda con lista vacía', () {
      for (final entry in matrizCalendario2026.entries) {
        expect(entry.value, isNotEmpty, reason: entry.key.name);
      }
    });

    test('recienNacido tiene BCG y Hepatitis B (doc:37)', () {
      final vacunas = matrizCalendario2026[FilaCalendario.recienNacido]!;
      expect(vacunas.map((v) => v.vacuna), ['BCG', 'Hepatitis B']);
      expect(vacunas[0].indicacion, 'única dosis (A)');
      expect(vacunas[1].indicacion, 'dosis neonatal (B)');
    });

    test('adultos tiene las 6 vacunas del doc:50', () {
      final vacunas = matrizCalendario2026[FilaCalendario.adultos]!;
      expect(vacunas.map((v) => v.vacuna), [
        'Hepatitis B',
        'Neumococo Conjugada',
        'Antigripal',
        'Triple Viral',
        'Doble Bacteriana',
        'Fiebre Hemorrágica Argentina',
      ]);
    });

    test('embarazadas tiene VSR (doc:51)', () {
      final vacunas = matrizCalendario2026[FilaCalendario.embarazadas]!;
      expect(
        vacunas.map((v) => v.vacuna),
        contains('Virus Sincicial Respiratorio'),
      );
    });
  });

  group('vacunasPorFilas', () {
    test('agrupa preservando el orden de las filas de entrada', () {
      final grupos = vacunasPorFilas([
        FilaCalendario.adultos,
        FilaCalendario.embarazadas,
      ]);
      expect(grupos.length, 2);
      expect(grupos[0].fila, FilaCalendario.adultos);
      expect(grupos[1].fila, FilaCalendario.embarazadas);
      expect(grupos[0].vacunas, matrizCalendario2026[FilaCalendario.adultos]);
    });

    test('lista vacía de filas -> lista vacía de grupos', () {
      expect(vacunasPorFilas(const []), isEmpty);
    });
  });
}
