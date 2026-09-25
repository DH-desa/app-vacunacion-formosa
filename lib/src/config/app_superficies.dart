import 'package:flutter/material.dart';

import 'app_spacing_config.dart';

class AppSuperficies {
  AppSuperficies._();

  static BoxDecoration tarjeta(BuildContext context, {double? radio}) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;
    final sombraAlpha = tema.brightness == Brightness.dark ? 0.42 : 0.09;
    return BoxDecoration(
      color: cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(radio ?? AppEspaciado.radioTarjeta),
      boxShadow: [
        BoxShadow(
          color: cs.shadow.withValues(alpha: sombraAlpha),
          offset: const Offset(0, 4),
          blurRadius: 8,
        ),
      ],
    );
  }

  static BoxDecoration tarjetaBlanca(BuildContext context, {double radio = 20}) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;
    final sombraAlpha = tema.brightness == Brightness.dark ? 0.42 : 0.09;
    return BoxDecoration(
      color: cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(radio),
      boxShadow: [
        BoxShadow(
          color: cs.shadow.withValues(alpha: sombraAlpha),
          offset: const Offset(0, 4),
          blurRadius: 8,
        ),
      ],
    );
  }

  static Color textoSecundario(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72);
  }

  static Color indicadorApagado(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);
  }

  static Color textoSobreAcentoMarca() => Colors.white;

  static BoxDecoration campoBusqueda(BuildContext context) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;
    final a = tema.brightness == Brightness.dark ? 0.28 : 0.07;
    return BoxDecoration(
      color: cs.surfaceContainer,
      borderRadius: BorderRadius.circular(AppEspaciado.radioCampo),
      boxShadow: [
        BoxShadow(
          color: cs.shadow.withValues(alpha: a),
          offset: const Offset(0, 5),
          blurRadius: 5,
        ),
      ],
    );
  }
}