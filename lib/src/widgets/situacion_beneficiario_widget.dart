import 'package:flutter/material.dart';

import 'package:sistema_vacunacion/src/config/config.dart';

/// Condición gestacional del beneficiario. Excluyente y opcional: `null` = no marcada.
/// Solo aplica a sexo femenino. No depende de la edad.
enum CondicionGestacional { embarazada, puerpera }

/// Bloque «Situación» del beneficiario: condición gestacional (solo sexo F,
/// excluyente y opcional) + personal de salud (independiente, cualquier sexo).
///
/// No guarda estado: recibe los valores y notifica cambios. La pantalla
/// anfitriona decide dónde persistirlos y cuándo enviarlos.
///
/// Reusa el patrón visual de los chips de sexo (`formulario_documento_widget.dart:193-284`).
class SituacionBeneficiario extends StatelessWidget {
  const SituacionBeneficiario({
    super.key,
    required this.sexoEsFemenino,
    required this.condicion,
    required this.esPersonalDeSalud,
    required this.onCondicionChanged,
    required this.onPersonalSaludChanged,
    this.personalSaludEditable = true,
  });

  /// Habilita el bloque de condición gestacional. Si es `false`, no se muestra.
  final bool sexoEsFemenino;

  /// Condición marcada, o `null` si no se marcó ninguna.
  final CondicionGestacional? condicion;

  final bool esPersonalDeSalud;

  /// Recibe la nueva condición (o `null` al desmarcar la activa).
  final ValueChanged<CondicionGestacional?> onCondicionChanged;

  final ValueChanged<bool> onPersonalSaludChanged;

  /// `false` = solo lectura (switch deshabilitado). Usado en el sheet de
  /// detalle de `VacunasPage`, donde el dato ya quedó fijado al ingresar
  /// al beneficiario y no debe poder tocarse de nuevo ahí.
  final bool personalSaludEditable;

  static const Color _colorEmbarazada = SisVacuMarca.azulFormosa;
  static const Color _colorPuerpera = SisVacuMarca.vercelestePrimario;

  @override
  Widget build(BuildContext context) {
    final bar = context.sisTipografia;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Situación',
          style: bar.textoChip.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: AppSuperficies.textoSecundario(context),
          ),
        ),
        const SizedBox(height: AppEspaciado.sm),

        // Condición gestacional: aparece/desaparece animada según el sexo.
        AnimatedSize(
          duration: AppMotion.entrada,
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: sexoEsFemenino
              ? _bloqueCondicion(context)
              : const SizedBox(width: double.infinity),
        ),

        _filaPersonalSalud(context),
      ],
    );
  }

  Widget _bloqueCondicion(BuildContext context) {
    final bar = context.sisTipografia;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Condición',
          style: bar.textoSecundario.copyWith(
            fontWeight: FontWeight.w600,
            color: AppSuperficies.textoSecundario(context),
          ),
        ),
        const SizedBox(height: AppEspaciado.sm),
        Row(
          children: [
            _chip(
              context,
              seleccionado: condicion == CondicionGestacional.embarazada,
              etiqueta: 'Embarazada',
              icono: Icons.pregnant_woman_rounded,
              colorAcento: _colorEmbarazada,
              onTap: () => onCondicionChanged(
                condicion == CondicionGestacional.embarazada
                    ? null
                    : CondicionGestacional.embarazada,
              ),
            ),
            const SizedBox(width: AppEspaciado.sm),
            _chip(
              context,
              seleccionado: condicion == CondicionGestacional.puerpera,
              etiqueta: 'Puérpera',
              icono: Icons.child_friendly_rounded,
              colorAcento: _colorPuerpera,
              onTap: () => onCondicionChanged(
                condicion == CondicionGestacional.puerpera
                    ? null
                    : CondicionGestacional.puerpera,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppEspaciado.lg),
      ],
    );
  }

  Widget _chip(
    BuildContext context, {
    required bool seleccionado,
    required String etiqueta,
    required IconData icono,
    required Color colorAcento,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    return Expanded(
      child: Material(
        color: seleccionado
            ? colorAcento.withValues(alpha: 0.10)
            : cs.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppEspaciado.radioBoton),
          side: BorderSide(
            color: seleccionado ? colorAcento : cs.outlineVariant,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppEspaciado.radioBoton),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppEspaciado.md,
              horizontal: AppEspaciado.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icono,
                  size: 32,
                  color: seleccionado ? colorAcento : cs.onSurfaceVariant,
                ),
                const SizedBox(height: AppEspaciado.xs),
                Text(
                  etiqueta,
                  style: bar.textoPrincipal.copyWith(
                    fontWeight: seleccionado ? FontWeight.w800 : FontWeight.w600,
                    color: seleccionado ? colorAcento : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filaPersonalSalud(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal de salud',
                style: bar.textoDestacado.copyWith(
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: AppEspaciado.xs),
              Text(
                'Trabaja en el sistema de salud.',
                style: bar.textoSecundario.copyWith(
                  color: AppSuperficies.textoSecundario(context),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: esPersonalDeSalud,
          onChanged: personalSaludEditable ? onPersonalSaludChanged : null,
        ),
      ],
    );
  }
}
