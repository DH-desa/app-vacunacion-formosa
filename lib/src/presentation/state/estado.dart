import 'package:flutter/foundation.dart';

/// Único contenedor de estado observable de la app.
/// - `value`: la única fuente de verdad (getter/setter de ValueNotifier).
/// - `reiniciar()`: vuelve al valor inicial. Mismo contrato para TODO estado.
/// Observar en UI con `ValueListenableBuilder`.
class Estado<T> extends ValueNotifier<T> {
  Estado(this._inicial) : super(_inicial);
  final T _inicial;
  void reiniciar() => value = _inicial;

  /// Fuerza notificación tras mutar `value` in-place (el setter compara por
  /// identidad y no dispara solo en ese caso).
  void notificar() => notifyListeners();
}
