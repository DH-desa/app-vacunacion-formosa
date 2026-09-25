import 'estado.dart';

/// Preferencias de la sesión de vacunación definidas en «Equipo de trabajo»
/// (p. ej. si la aplicación es en terreno). Persisten hasta cerrar sesión.
class _SesionEquipoVacunacionService {
  /// `true` = vacunación en terreno; `false` = en establecimiento fijo.
  /// Default `false`: la mayoría de las sesiones son en establecimiento fijo.
  final enTerrenoEstado = Estado<bool>(false);

  bool get enTerreno => enTerrenoEstado.value;

  void establecerEnTerreno(bool valor) {
    enTerrenoEstado.value = valor;
  }

  /// Vuelve valores por defecto al salir de la cuenta.
  void reiniciar() {
    enTerrenoEstado.reiniciar();
  }
}

final sesionEquipoVacunacionService = _SesionEquipoVacunacionService();
