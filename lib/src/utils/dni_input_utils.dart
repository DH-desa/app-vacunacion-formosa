/// Normalización y validación mínima de DNI argentino para ingreso manual.
class DniInputUtils {
  DniInputUtils._();

  static String soloDigitos(String texto) =>
      texto.replaceAll(RegExp(r'[^0-9]'), '');

  /// Solo dígitos, sin espacios ni puntos.
  static String normalizar(String texto) => soloDigitos(texto.trim());

  /// Documento típico 7 u 8 dígitos (sin validar dígito verificador).
  static bool esDniPlausible(String textoNormalizado) {
    final n = textoNormalizado.length;
    return n >= 7 && n <= 8;
  }
}
