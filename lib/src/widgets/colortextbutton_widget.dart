import 'package:flutter/material.dart';

import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/widgets/widgets.dart';

class ColorTextButton extends StatelessWidget {
  final String text;
  final double? anchoValor;
  final void Function() onPressed;
  final Icon? iconoBoton;
  final bool? iconoBool;
  final Color? color;

  const ColorTextButton(
    this.text, {
    Key? key,
    required this.onPressed,
    required this.anchoValor,
    this.iconoBoton,
    this.iconoBool,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color textColor = color != null
        ? (ThemeData.estimateBrightnessForColor(color!) == Brightness.dark
            ? Colors.white
            : cs.onSurface)
        : cs.onSurface;

    return BaseButton(
      ancho: anchoValor,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppEspaciado.radioBoton),
          ),
          textStyle: TextStyle(
            fontSize: AppBotones.fontSizeBoton,
            fontWeight: AppBotones.fontWeightBoton,
          ),
          iconSize: AppBotones.iconoTamano,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconoBool == true && iconoBoton != null)
              IconTheme(
                data: IconThemeData(color: textColor, size: AppTamanoIcono.pequeno),
                child: iconoBoton!,
              ),
            if (iconoBool == true && iconoBoton != null)
              const SizedBox(width: AppEspaciado.sm),
            Text(text),
          ],
        ),
      ),
    );
  }
}