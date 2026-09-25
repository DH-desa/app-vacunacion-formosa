import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistencia y estado del modo de apariencia (claro / oscuro / sistema).
class _TemaAppService extends ChangeNotifier {
  ThemeMode _modo = ThemeMode.system;

  ThemeMode get modoTema => _modo;

  static const String _clavePrefs = 'sistema_vacunacion_preferencia_tema';

  /// Cargar preferencia guardada; llamar antes de [runApp] para evitar parpadeo.
  Future<void> inicializar() async {
    final prefs = await SharedPreferences.getInstance();
    _modo = _desdeCadena(prefs.getString(_clavePrefs));
    notifyListeners();
  }

  ThemeMode _desdeCadena(String? valor) {
    switch (valor) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _aCadena(ThemeMode modo) {
    switch (modo) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Guarda en disco y notifica para reconstruir [MaterialApp].
  Future<void> establecerModo(ThemeMode modo) async {
    if (_modo == modo) return;
    _modo = modo;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clavePrefs, _aCadena(modo));
  }
}

final temaAppService = _TemaAppService();
