import 'package:flutter/material.dart';

import 'package:sistema_vacunacion/src/config/config.dart';

class DialogoAlerta extends StatelessWidget {
  final String? tituloAlerta;
  final String? descripcionAlerta;
  final String? textoBotonAlerta;
  final String? textoBotonAlerta2;
  final bool envioFuncion1;
  final bool envioFuncion2;
  final void Function()? funcion1;
  final void Function()? funcion2;
  final Color? color;
  final Icon? icon;
  final bool dosBotones;
  final Widget? contenido;
  final List<Widget>? accionesExtra;

  const DialogoAlerta({
    Key? key,
    this.tituloAlerta,
    this.descripcionAlerta,
    this.textoBotonAlerta,
    this.textoBotonAlerta2,
    this.envioFuncion1 = true,
    this.envioFuncion2 = true,
    this.funcion1,
    this.funcion2,
    this.color,
    this.icon,
    this.dosBotones = false,
    this.contenido,
    this.accionesExtra,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color acento = color ?? cs.primary;
    final Color textoSobreAcento = Colors.white;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppEspaciado.radioCampo),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppEspaciado.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon!.icon,
                    color: acento,
                    size: 40,
                  ),
                  const SizedBox(width: AppEspaciado.md),
                ],
                Expanded(
                  child: Text(
                    tituloAlerta ?? 'Alerta',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppEspaciado.md),
            contenido ??
                Text(
                  descripcionAlerta ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        color: AppSuperficies.textoSecundario(context),
                      ),
                ),
            const SizedBox(height: AppEspaciado.xl),
            if (accionesExtra != null)
              Column(
                children: [
                  for (final accion in accionesExtra!) ...[
                    SizedBox(width: double.infinity, child: accion),
                    const SizedBox(height: AppEspaciado.sm),
                  ],
                ],
              ),
            if (dosBotones)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => funcion2!(),
                      style: AppBotones.estiloOutlined(cs),
                      child: Text(textoBotonAlerta2!),
                    ),
                  ),
                  const SizedBox(width: AppEspaciado.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => funcion1!(),
                      style: AppBotones.estiloFilled(cs).copyWith(
                        backgroundColor: WidgetStateProperty.all(acento),
                        foregroundColor: WidgetStateProperty.all(textoSobreAcento),
                      ),
                      child: Text(textoBotonAlerta!),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (envioFuncion1) {
                      funcion1!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  style: AppBotones.estiloFilled(cs).copyWith(
                    backgroundColor: WidgetStateProperty.all(acento),
                    foregroundColor: WidgetStateProperty.all(textoSobreAcento),
                  ),
                  child: Text(textoBotonAlerta!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}