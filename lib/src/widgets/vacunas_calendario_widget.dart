import 'package:flutter/material.dart';

import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/domain/calendario/calendario_2026.dart';

/// Listado de vacunas del Calendario Nacional 2026 filtrado por las filas
/// que le corresponden al beneficiario actual ([clasificarBeneficiarioActual]).
///
/// Puramente informativo: no interactúa con el perfil "Vacunas calendario"
/// de la API ni con el flujo de 8 pasos de selección de vacuna.
class VacunasCalendarioFiltradas extends StatelessWidget {
  const VacunasCalendarioFiltradas({super.key, required this.resultado});

  final ResultadoClasificacion resultado;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    final grupos = vacunasPorFilas(resultado.filas);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppEspaciado.lg),
      decoration: AppSuperficies.tarjetaBlanca(
        context,
        radio: AppEspaciado.radioCampo,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Vacunas calendario',
            style: bar.tituloTarjeta.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: AppEspaciado.xs),
          Text(
            'Según edad y situación del beneficiario',
            style: bar.textoChip.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppEspaciado.lg),
          if (grupos.isEmpty)
            Text(
              'Edad no determinada: no se pudo filtrar el calendario.',
              style: bar.textoSecundario.copyWith(
                color: AppSuperficies.textoSecundario(context),
              ),
            )
          else
            for (var i = 0; i < grupos.length; i++) ...[
              if (i > 0) const SizedBox(height: AppEspaciado.lg),
              _bloqueFila(context, grupos[i]),
            ],
        ],
      ),
    );
  }

  Widget _bloqueFila(BuildContext context, VacunasPorFila grupo) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          grupo.fila.etiqueta,
          style: bar.textoSecundario.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: AppEspaciado.sm),
        if (grupo.vacunas.isEmpty)
          Text(
            'Sin vacunas cargadas para esta fila.',
            style: bar.textoChip.copyWith(
              fontWeight: FontWeight.w400,
              color: AppSuperficies.textoSecundario(context),
            ),
          )
        else
          ...grupo.vacunas.map((v) => _filaVacuna(context, v)),
      ],
    );
  }

  Widget _filaVacuna(BuildContext context, VacunaFilaCalendario v) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppEspaciado.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.circle,
            size: 6,
            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(width: AppEspaciado.sm),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: bar.textoPrincipal.copyWith(
                  height: 1.35,
                  color: cs.onSurface,
                ),
                children: [
                  TextSpan(
                    text: v.vacuna,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: ': ${v.indicacion}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
