import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import 'package:sistema_vacunacion/src/config/config.dart';

class TitulosContainerPage extends StatelessWidget {
  final String? title;
  final Color? colorTitle;
  final double? sizeTitle;
  final double? widthThickness;

  const TitulosContainerPage({
    Key? key,
    this.title,
    this.colorTitle,
    this.sizeTitle,
    this.widthThickness,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    return Column(
      children: [
        FadeInUpBig(
          from: 25,
          child: Row(
            children: [
              Text(
                title!,
                style: bar.tituloTarjeta.copyWith(
                  fontSize: sizeTitle ?? bar.tituloTarjeta.fontSize,
                  fontWeight: FontWeight.w600,
                  color: colorTitle ?? cs.onSurface,
                ),
              ),
            ],
          ),
        ),
        FadeInDownBig(
          from: 25,
          child: Divider(
            color: cs.primary.withValues(alpha: 0.45),
            thickness: widthThickness,
          ),
        ),
      ],
    );
  }
}