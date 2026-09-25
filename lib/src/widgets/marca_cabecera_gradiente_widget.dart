import 'package:flutter/material.dart';

import 'package:sistema_vacunacion/src/config/config.dart';

class MarcaCabeceraGradiente extends StatelessWidget {
  const MarcaCabeceraGradiente({
    Key? key,
    required this.titulo,
    this.subtitulo,
    this.alturaMinima = 148,
    this.radioInferior = AppRadio.radioCabeceraGradiente,
    this.acciones,
  }) : super(key: key);

  final String titulo;
  final String? subtitulo;
  final double alturaMinima;
  final double radioInferior;
  final List<Widget>? acciones;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: alturaMinima),
      padding: EdgeInsets.fromLTRB(
        AppEspaciado.xl,
        MediaQuery.paddingOf(context).top + AppEspaciado.md,
        AppEspaciado.xl,
        AppEspaciado.sm,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: oscuro
              ? [
                  cs.primary.withValues(alpha: 0.92),
                  SisVacuMarca.vercelestePrimario,
                ]
              : [
                  SisVacuMarca.vercelesteCuaternario,
                  SisVacuMarca.vercelestePrimario,
                ],
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(radioInferior),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: oscuro ? 0.35 : 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(titulo, style: bar.displayMediano.copyWith(color: Colors.white)),
          if (subtitulo != null && subtitulo!.isNotEmpty) ...[
            const SizedBox(height: AppEspaciado.sm),
            Text(
              subtitulo!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: bar.textoPrincipal.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
          ],
          if (acciones != null && acciones!.isNotEmpty) ...[
            const SizedBox(height: AppEspaciado.md),
            Wrap(
              spacing: AppEspaciado.sm,
              runSpacing: AppEspaciado.sm,
              children: acciones!,
            ),
          ],
        ],
      ),
    );
  }
}
