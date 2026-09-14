import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_vacunacion/src/utils/edad_pdf417_dni_arg.dart';
import 'package:sistema_vacunacion/src/utils/pdf417_dni_arg_parser.dart';

/// Casos reales conocidos del PDF417 del DNI argentino (campos separados por
/// `@`) para validar el parser SIN depender de reproducir un escaneo físico.
void main() {
  group('DNI nuevo (tarjeta plástica, campos >= 5)', () {
    // Layout: trámite@apellido@nombre@sexo@dni@ejemplar@fechaNacimiento@fechaEmision
    const partes = [
      '00012345678',
      'GARCIA',
      'MARIA JOSE',
      'F',
      '30123456',
      'A',
      '15/03/1990',
      '10/05/2015',
    ];

    test('asigna cada campo a la posición correcta', () {
      final d = parsearPdf417DniArgentino(partes);
      expect(d, isNotNull);
      expect(d!.dni, '30123456');
      expect(d.apellido, 'GARCIA');
      expect(d.nombre, 'MARIA JOSE');
      expect(d.sexo, 'F');
      expect(d.tramite, '00012345678');
      expect(d.fechaNacimientoPdf417, '15/03/1990');
    });

    test('la edad calculada corresponde a la fecha de nacimiento real', () {
      final d = parsearPdf417DniArgentino(partes);
      final anios = aniosCumplidosDesdeFechaNacimientoTexto(
        d!.fechaNacimientoPdf417,
      );
      // Referencia fija: no depender de DateTime.now() para que el test sea estable.
      final nacimiento = DateTime(1990, 3, 15);
      final hoy = DateTime.now();
      var esperada = hoy.year - nacimiento.year;
      if (hoy.month < nacimiento.month ||
          (hoy.month == nacimiento.month && hoy.day < nacimiento.day)) {
        esperada--;
      }
      expect(anios, esperada);
    });

    test('con CUIL agregado como noveno campo, sigue leyendo bien (n>=5, no exige n exacto)', () {
      final conCuil = [...partes, '27301234563'];
      final d = parsearPdf417DniArgentino(conCuil);
      expect(d!.dni, '30123456');
      expect(d.fechaNacimientoPdf417, '15/03/1990');
    });
  });

  group('DNI viejo (cartón/libreta, 17 campos)', () {
    // Layout documentado en el código: dni=[1], apellido=[4], nombre=[5],
    // sexo=[8], tramite=[10]; fecha de nacimiento heurística en [6,7,5,8,9].
    List<String> partesViejo({String fechaNac = '20/11/1965'}) {
      final p = List<String>.filled(17, '');
      p[1] = '12345678';
      p[4] = 'PEREZ';
      p[5] = 'JUAN CARLOS';
      p[6] = fechaNac;
      p[8] = 'M';
      p[10] = '00098765432';
      return p;
    }

    test('asigna cada campo a la posición correcta', () {
      final d = parsearPdf417DniArgentino(partesViejo());
      expect(d, isNotNull);
      expect(d!.dni, '12345678');
      expect(d.apellido, 'PEREZ');
      expect(d.nombre, 'JUAN CARLOS');
      expect(d.sexo, 'M');
      expect(d.tramite, '00098765432');
      expect(d.fechaNacimientoPdf417, '20/11/1965');
    });

    test(
      'FIX del síntoma reportado: un campo de más antes de [6] corre la '
      'fecha de nacimiento, pero como el trámite nunca puede ser anterior '
      'al nacimiento, se elige la fecha más antigua de las dos candidatas '
      '(mecanismo que antes daba "56 años")',
      () {
        // Documento real con un campo extra (p.ej. una fecha de emisión que
        // en este layout cae en [6] en vez de estar donde se esperaba):
        // la fecha de nacimiento real (20/11/1965) queda en [7], pero el
        // índice [6] también tiene forma de fecha (trámite/emisión).
        final p = partesViejo();
        p[6] = '05/06/2010'; // fecha de emisión, NO de nacimiento
        p[7] = '20/11/1965'; // la fecha de nacimiento real quedó corrida acá

        final d = parsearPdf417DniArgentino(p);

        // La más antigua entre ambas candidatas es la de nacimiento real.
        expect(d!.fechaNacimientoPdf417, '20/11/1965');
      },
    );
  });

  group('Heurística de respaldo (formato desconocido, N variable)', () {
    test('sin marcador de sexo reconocible, no asume nada (retorna null)', () {
      final p = ['0001', 'GOMEZ', 'ANA', '99999999999', '30999999'];
      final d = parsearPdf417DniArgentino(p);
      expect(d, isNull);
    });

    test('con sexo X (no binario) reconocido en cualquier posición', () {
      final p = ['0001', 'GOMEZ', 'ANA', 'X', '30999999'];
      final d = parsearPdf417DniArgentino(p);
      expect(d!.sexo, 'X');
      expect(d.dni, '30999999');
    });
  });

  group('fechaNacimientoDesdePartesPdf417 — desambiguación por fecha más antigua', () {
    test('layout con una sola fecha: la usa', () {
      final p = ['0001', 'GOMEZ', 'ANA', 'F', '30999999', 'A', '15/03/1990'];
      expect(fechaNacimientoDesdePartesPdf417(p), '15/03/1990');
    });

    test(
      'layout con dos fechas candidatas (nacimiento y trámite), en cualquier '
      'orden: elige la más antigua, sin importar el índice',
      () {
        final pOrdenNormal = [
          '0001',
          'GOMEZ',
          'ANA',
          'F',
          '30999999',
          '15/03/1990',
          '10/05/2015',
        ];
        expect(fechaNacimientoDesdePartesPdf417(pOrdenNormal), '15/03/1990');

        final pOrdenInvertido = [
          '0001',
          'GOMEZ',
          'ANA',
          'F',
          '30999999',
          '10/05/2015',
          '15/03/1990',
        ];
        expect(fechaNacimientoDesdePartesPdf417(pOrdenInvertido), '15/03/1990');
      },
    );

    test('sin ninguna fecha reconocible: devuelve null', () {
      final p = ['0001', 'GOMEZ', 'ANA', 'F', '30999999'];
      expect(fechaNacimientoDesdePartesPdf417(p), isNull);
    });
  });

  group('cadenaEsLecturaPlausibleDniArgentino', () {
    test('acepta una cadena real con @ y DNI de 8 dígitos', () {
      const cruda =
          '00012345678@GARCIA@MARIA JOSE@F@30123456@A@15/03/1990@10/05/2015';
      expect(cadenaEsLecturaPlausibleDniArgentino(cruda), isTrue);
    });

    test('rechaza una cadena sin @ (otro tipo de código, ej. QR/EAN)', () {
      expect(cadenaEsLecturaPlausibleDniArgentino('7791234567890'), isFalse);
    });

    test('rechaza cadena vacía', () {
      expect(cadenaEsLecturaPlausibleDniArgentino(''), isFalse);
    });
  });
}
