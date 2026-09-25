import 'package:package_info_plus/package_info_plus.dart';

/// Versión pública desde [pubspec] (solo `MAJOR.MINOR.PATCH`, sin sufijo +build).
/// Una sola lectura por proceso para la etiqueta mostrada en UI.
class InformacionVersionApp {
  InformacionVersionApp._();

  static Future<String>? _futuroEtiqueta;

  /// Texto para chips y pies de pantalla (ej. `4.0.0`). Nunca concatena build number.
  static Future<String> etiquetaSemver() {
    _futuroEtiqueta ??= _calcularEtiqueta();
    return _futuroEtiqueta!;
  }

  static Future<String> _calcularEtiqueta() async {
    try {
      final PackageInfo info = await PackageInfo.fromPlatform();
      return info.version.trim();
    } catch (_) {
      return '?';
    }
  }

  /// Igual que [etiquetaSemver]: solo `version`, útil para APIs tipo `sysappl01_version`.
  static Future<String> soloVersionPublica() async {
    return etiquetaSemver();
  }
}
