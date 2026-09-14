/// Escala de espaciado base 4/8 pt para márgenes y gutters coherentes.
class AppEspaciado {
  AppEspaciado._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const double radioTarjeta = 14;
  static const double radioBoton = 12;
  static const double radioCampo = 20;
}

class AppTamanoIcono {
  AppTamanoIcono._();

  static const double pequeno = 18;
  static const double mediano = 24;
  static const double grande = 40;
  static const double extraGrande = 48;
}

class AppRadio {
  AppRadio._();

  static const double radioCabeceraGradiente = 28;
  static const double radioFAB = 16;
  static const double radioDialog = 24;
  static const double radioTooltip = 10;
}

class AppMotion {
  AppMotion._();

  static const Duration rapida = Duration(milliseconds: 180);
  static const Duration estandar = Duration(milliseconds: 260);
  static const Duration entrada = Duration(milliseconds: 320);
}