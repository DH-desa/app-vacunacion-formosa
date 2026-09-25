import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_vacunacion/src/utils/edad_beneficiario.dart';
import 'package:sistema_vacunacion/src/utils/edad_pdf417_dni_arg.dart';

/// El QR 2026 trae el año con dos dígitos. Un `26` puede ser 1926 o 2026, y
/// esta app vacuna a recién nacidos y a centenarios, así que ninguno de los dos
/// es descartable. Estas pruebas fijan el criterio: resolver donde se puede y
/// abstenerse donde no.
void main() {
  // Fecha fija para que la ventana no dependa del día en que corran los tests.
  final hoy = DateTime(2026, 9, 15);

  group('ventana de siglo', () {
    test('27 a 99 solo pueden ser 1900: 20YY sería futuro', () {
      for (final yy in [27, 50, 80, 99]) {
        expect(anioDosDigitosEsAmbiguo(yy, hoy: hoy), isFalse, reason: 'yy=$yy');
        expect(aniosPlausiblesParaDosDigitos(yy, hoy: hoy), [1900 + yy]);
      }
    });

    test('00 a 15 solo pueden ser 2000: 19YY superaría los 110 años', () {
      for (final yy in [0, 10, 15]) {
        expect(anioDosDigitosEsAmbiguo(yy, hoy: hoy), isFalse, reason: 'yy=$yy');
        expect(aniosPlausiblesParaDosDigitos(yy, hoy: hoy), [2000 + yy]);
      }
    });

    test('16 a 26 son ambiguos: los dos siglos son plausibles', () {
      for (final yy in [16, 20, 26]) {
        expect(anioDosDigitosEsAmbiguo(yy, hoy: hoy), isTrue, reason: 'yy=$yy');
        expect(aniosPlausiblesParaDosDigitos(yy, hoy: hoy).length, 2);
      }
    });
  });

  group('parseo y edad', () {
    test('año de 2 dígitos no ambiguo: resuelve el siglo y calcula la edad', () {
      expect(pareceFechaNacimientoArg('07/02/80'), isTrue);
      expect(aniosCumplidosDesdeFechaNacimientoTexto('07/02/80', hoy: hoy), 46);
    });

    test('año de 4 dígitos sigue funcionando igual que antes', () {
      expect(aniosCumplidosDesdeFechaNacimientoTexto('07/02/1980', hoy: hoy), 46);
    });

    test('año ambiguo: no elige siglo ni devuelve una edad inventada', () {
      expect(fechaTieneSigloAmbiguo('07/02/26', hoy: hoy), isTrue);
      expect(aniosCumplidosDesdeFechaNacimientoTexto('07/02/26', hoy: hoy), isNull);
    });

    test('una fecha de 4 dígitos nunca es ambigua', () {
      expect(fechaTieneSigloAmbiguo('07/02/1926', hoy: hoy), isFalse);
      expect(fechaTieneSigloAmbiguo(null, hoy: hoy), isFalse);
    });

    test('un bebé de este año no recibe 100 años, ni al revés', () {
      // El caso que hace peligrosa la ambigüedad: 1926 vs 2026.
      final candidatos = aniosPlausiblesParaDosDigitos(26, hoy: hoy);
      expect(candidatos, containsAll([2026, 1926]));
      // Al ser dos, el parser se abstiene en lugar de elegir.
      expect(aniosCumplidosDesdeFechaNacimientoTexto('07/02/26', hoy: hoy), isNull);
    });
  });

  group('parseFechaNacimiento (calendario y ficha)', () {
    test('año de 2 dígitos no ambiguo: resuelve el siglo', () {
      expect(parseFechaNacimiento('07/02/80', hoy: hoy), DateTime(1980, 2, 7));
      expect(parseFechaNacimiento('15/06/10', hoy: hoy), DateTime(2010, 6, 15));
    });

    test('año de 2 dígitos ambiguo: null, decide el dato del API', () {
      expect(parseFechaNacimiento('07/02/26', hoy: hoy), isNull);
    });

    test('año de 4 dígitos no cambia', () {
      expect(parseFechaNacimiento('07/02/1926', hoy: hoy), DateTime(1926, 2, 7));
    });
  });
}
