import 'package:flutter/material.dart';

/// Breakpoints de ancho para el rango real de celulares en portrait (la app
/// no soporta tablet ni landscape, ver `main.dart`). Gobierna solo LAYOUT
/// (paddings, anchos, alturas de banners) — nunca `fontSize`: el tamaño de
/// texto lo controla exclusivamente el `textScaler` del SO (clampado en
/// `main.dart`). Mezclar ambos sistemas de escala es el bug a evitar.
///
/// Usar `context.escala(...)` solo cuando el valor deba variar entre celular
/// chico/mediano/grande para evitar overflow o desproporción real (anchos de
/// tarjetas/columnas, alturas de banners decorativos, paddings de página
/// completa). NO usarlo para íconos de acción/chip (ya cubiertos por
/// `AppTamanoIcono`), radios de borde, espaciados chicos (`AppEspaciado`
/// xs/sm/md), ni elementos de tamaño intrínsecamente fijo (viewfinder de
/// cámara, badges). Regla práctica: si el elemento no cambia visualmente
/// entre 360dp y 430dp de ancho, se queda fijo.
enum AppBreakpoint { compacto, normal, grande }

class AppBreakpoints {
  AppBreakpoints._();

  /// iPhone SE / Android chicos (~360-375dp) por debajo de este ancho.
  static const double anchoCompacto = 380;

  /// iPhone Pro Max / Android grandes (~428-480dp) desde este ancho.
  static const double anchoGrande = 420;

  static AppBreakpoint deAncho(double ancho) {
    if (ancho < anchoCompacto) return AppBreakpoint.compacto;
    if (ancho < anchoGrande) return AppBreakpoint.normal;
    return AppBreakpoint.grande;
  }
}

extension AppBreakpointContext on BuildContext {
  AppBreakpoint get breakpoint =>
      AppBreakpoints.deAncho(MediaQuery.sizeOf(this).width);

  /// Elige un valor según el ancho de pantalla actual. `grande` es opcional:
  /// si no se pasa, celulares grandes usan el valor de `normal`.
  T escala<T>({required T compacto, required T normal, T? grande}) {
    switch (breakpoint) {
      case AppBreakpoint.compacto:
        return compacto;
      case AppBreakpoint.normal:
        return normal;
      case AppBreakpoint.grande:
        return grande ?? normal;
    }
  }
}
