import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema tipográfico de la app. Una sola fuente de verdad para cada rol
/// visual (títulos, cuerpo, etiquetas, formularios). Todo `fontSize:` hardcoded
/// fuera de este archivo es bug — se ignora `Material 3` density y rompe entre
/// teléfonos con distinta escala de fuente del OS.
@immutable
class SisVacuTipografia extends ThemeExtension<SisVacuTipografia> {
  const SisVacuTipografia({
    required this.tituloTarjeta,
    required this.subtituloTarjeta,
    required this.tituloSeccion,
    required this.displayChico,
    required this.displayMediano,
    required this.encabezadoDrawer,
    required this.etiquetaSeccion,
    required this.textoFormulario,
    required this.textoDestacado,
    required this.textoPrincipal,
    required this.textoSecundario,
    required this.textoChip,
  });

  /// 22pt w700 — encabezados de tarjeta (no pantalla completa).
  final TextStyle tituloTarjeta;

  /// 18pt w700 — subtítulos de tarjeta, equivalente a "titleMedium" del tema.
  final TextStyle subtituloTarjeta;

  /// 20pt w700 — títulos de sheet, diálogo, sección de página.
  final TextStyle tituloSeccion;

  /// 25pt w700 — títulos display (pantalla "Sobre nosotros").
  final TextStyle displayChico;

  /// 26pt w1.15 w700 — título del gradiente de marca principal.
  final TextStyle displayMediano;

  /// 13pt w600 con letterSpacing 2.2 — encabezado del drawer.
  final TextStyle encabezadoDrawer;

  /// 11pt w700 con letterSpacing ~1 — etiquetas uppercase de sección.
  final TextStyle etiquetaSeccion;

  /// 16pt — texto de campos de formulario (D.N.I., inputs grandes).
  final TextStyle textoFormulario;

  /// 15pt w600 — cuerpo destacado (filas de datos, valor de switch).
  final TextStyle textoDestacado;

  /// 14pt — cuerpo principal.
  final TextStyle textoPrincipal;

  /// 13pt — cuerpo secundario (subtítulos, hints, captions).
  final TextStyle textoSecundario;

  /// 12pt w600 — texto de chips y badges.
  final TextStyle textoChip;

  factory SisVacuTipografia.crear() {
    final TextTheme base = GoogleFonts.nunitoTextTheme();
    return SisVacuTipografia(
      tituloTarjeta: base.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ) ??
          const TextStyle(),
      subtituloTarjeta: base.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ) ??
          const TextStyle(),
      tituloSeccion: base.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ) ??
          const TextStyle(),
      displayChico: base.headlineSmall?.copyWith(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ) ??
          const TextStyle(),
      displayMediano: base.headlineSmall?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ) ??
          const TextStyle(),
      encabezadoDrawer: base.labelMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.2,
            height: 1.2,
          ) ??
          const TextStyle(),
      etiquetaSeccion: base.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            height: 1.2,
          ) ??
          const TextStyle(),
      textoFormulario: base.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ) ??
          const TextStyle(),
      textoDestacado: base.titleSmall?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ) ??
          const TextStyle(),
      textoPrincipal: base.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ) ??
          const TextStyle(),
      textoSecundario: base.bodySmall?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ) ??
          const TextStyle(),
      textoChip: base.labelMedium?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ) ??
          const TextStyle(),
    );
  }

  @override
  SisVacuTipografia copyWith({
    TextStyle? tituloTarjeta,
    TextStyle? subtituloTarjeta,
    TextStyle? tituloSeccion,
    TextStyle? displayChico,
    TextStyle? displayMediano,
    TextStyle? encabezadoDrawer,
    TextStyle? etiquetaSeccion,
    TextStyle? textoFormulario,
    TextStyle? textoDestacado,
    TextStyle? textoPrincipal,
    TextStyle? textoSecundario,
    TextStyle? textoChip,
  }) {
    return SisVacuTipografia(
      tituloTarjeta: tituloTarjeta ?? this.tituloTarjeta,
      subtituloTarjeta: subtituloTarjeta ?? this.subtituloTarjeta,
      tituloSeccion: tituloSeccion ?? this.tituloSeccion,
      displayChico: displayChico ?? this.displayChico,
      displayMediano: displayMediano ?? this.displayMediano,
      encabezadoDrawer: encabezadoDrawer ?? this.encabezadoDrawer,
      etiquetaSeccion: etiquetaSeccion ?? this.etiquetaSeccion,
      textoFormulario: textoFormulario ?? this.textoFormulario,
      textoDestacado: textoDestacado ?? this.textoDestacado,
      textoPrincipal: textoPrincipal ?? this.textoPrincipal,
      textoSecundario: textoSecundario ?? this.textoSecundario,
      textoChip: textoChip ?? this.textoChip,
    );
  }

  @override
  SisVacuTipografia lerp(
    ThemeExtension<SisVacuTipografia>? other,
    double t,
  ) {
    if (other is! SisVacuTipografia) return this;
    return SisVacuTipografia(
      tituloTarjeta: TextStyle.lerp(tituloTarjeta, other.tituloTarjeta, t) ?? tituloTarjeta,
      subtituloTarjeta: TextStyle.lerp(subtituloTarjeta, other.subtituloTarjeta, t) ?? subtituloTarjeta,
      tituloSeccion: TextStyle.lerp(tituloSeccion, other.tituloSeccion, t) ?? tituloSeccion,
      displayChico: TextStyle.lerp(displayChico, other.displayChico, t) ?? displayChico,
      displayMediano: TextStyle.lerp(displayMediano, other.displayMediano, t) ?? displayMediano,
      encabezadoDrawer: TextStyle.lerp(encabezadoDrawer, other.encabezadoDrawer, t) ?? encabezadoDrawer,
      etiquetaSeccion: TextStyle.lerp(etiquetaSeccion, other.etiquetaSeccion, t) ?? etiquetaSeccion,
      textoFormulario: TextStyle.lerp(textoFormulario, other.textoFormulario, t) ?? textoFormulario,
      textoDestacado: TextStyle.lerp(textoDestacado, other.textoDestacado, t) ?? textoDestacado,
      textoPrincipal: TextStyle.lerp(textoPrincipal, other.textoPrincipal, t) ?? textoPrincipal,
      textoSecundario: TextStyle.lerp(textoSecundario, other.textoSecundario, t) ?? textoSecundario,
      textoChip: TextStyle.lerp(textoChip, other.textoChip, t) ?? textoChip,
    );
  }
}

extension SisVacuTipografiaContext on BuildContext {
  SisVacuTipografia get sisTipografia {
    final ext = Theme.of(this).extension<SisVacuTipografia>();
    assert(
      ext != null,
      'ThemeData debe incluir SisVacuTipografia en extensions',
    );
    return ext!;
  }
}
