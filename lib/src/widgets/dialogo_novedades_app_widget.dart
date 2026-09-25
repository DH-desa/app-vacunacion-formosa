import 'package:flutter/material.dart';

import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/domain/entities/sistema/changelog_app_models.dart';
import 'package:sistema_vacunacion/src/presentation/state/changelog_app_service.dart';

Future<void> mostrarDialogoNovedadesApp(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext ctx) {
      final ColorScheme cs = Theme.of(ctx).colorScheme;
      final bar = ctx.sisTipografia;
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppEspaciado.md,
          vertical: AppEspaciado.lg,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460, maxHeight: 640),
          padding: const EdgeInsets.fromLTRB(
            AppEspaciado.lg,
            AppEspaciado.lg,
            AppEspaciado.sm,
            AppEspaciado.sm,
          ),
          decoration: AppSuperficies.tarjetaBlanca(ctx, radio: AppEspaciado.radioCampo),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(AppEspaciado.radioTarjeta),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppEspaciado.sm),
                      child: Icon(
                        Icons.history_edu_rounded,
                        color: cs.onPrimaryContainer,
                        size: AppTamanoIcono.mediano,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppEspaciado.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Notas de versión',
                          style: bar.tituloSeccion.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: AppEspaciado.xs),
                        Text(
                          'Novedades · Correcciones · Plataforma',
                          style: bar.etiquetaSeccion.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: AppEspaciado.md),
              Expanded(
                child: _ListaChangelogCargada(colorScheme: cs),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: AppBotones.estiloFilled(Theme.of(context).colorScheme),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ListaChangelogCargada extends StatefulWidget {
  const _ListaChangelogCargada({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  State<_ListaChangelogCargada> createState() => _ListaChangelogCargadaState();
}

class _ListaChangelogCargadaState extends State<_ListaChangelogCargada> {
  late final Future<List<EntradaChangelogApp>> _carga =
      ChangelogAppService.cargar();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = widget.colorScheme;
    final tt = Theme.of(context).textTheme;
    return FutureBuilder<List<EntradaChangelogApp>>(
      future: _carga,
      builder: (BuildContext context,
          AsyncSnapshot<List<EntradaChangelogApp>> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'No se pudo cargar el historial.',
              textAlign: TextAlign.center,
              style: tt.bodyLarge?.copyWith(
                color: cs.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        final List<EntradaChangelogApp> entradas =
            snap.data ?? <EntradaChangelogApp>[];
        if (entradas.isEmpty) {
          return Center(
            child: Text(
              'Aún no hay entradas en el changelog.',
              style: tt.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
        return Scrollbar(
          thumbVisibility: true,
          child: ListView.separated(
            padding: const EdgeInsets.only(right: AppEspaciado.sm, bottom: AppEspaciado.sm),
            itemCount: entradas.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppEspaciado.lg),
            itemBuilder: (BuildContext context, int i) {
              return _TarjetaRelease(entrada: entradas[i], cs: cs);
            },
          ),
        );
      },
    );
  }
}

class _TarjetaRelease extends StatelessWidget {
  const _TarjetaRelease({
    required this.entrada,
    required this.cs,
  });

  final EntradaChangelogApp entrada;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final bar = context.sisTipografia;
    final String? fecha = entrada.fecha;
    final String? titulo = entrada.titulo;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppEspaciado.md,
        AppEspaciado.md,
        AppEspaciado.sm,
        AppEspaciado.sm,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppEspaciado.lg),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppEspaciado.sm,
            runSpacing: AppEspaciado.xs,
            children: <Widget>[
              Text(
                'v${entrada.version}',
                style: bar.textoFormulario.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                ),
              ),
              if (fecha != null && fecha.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppEspaciado.sm, vertical: AppEspaciado.xs),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(AppEspaciado.sm),
                  ),
                  child: Text(
                    fecha,
                    style: bar.etiquetaSeccion.copyWith(
                      letterSpacing: 0,
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          if (titulo != null && titulo.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppEspaciado.sm),
            Text(
              titulo,
              style: bar.textoSecundario.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.3,
                color: cs.onSurface,
              ),
            ),
          ],
          const SizedBox(height: AppEspaciado.md),
          if (entrada.tieneSeccionesTipadas) ...<Widget>[
            if (entrada.features.isNotEmpty)
              _BloqueCategoria(
                cs: cs,
                titulo: 'Novedades',
                conteo: entrada.features.length,
                icono: Icons.auto_awesome_rounded,
                colorAcento: cs.primary,
                fondo: cs.primaryContainer.withValues(alpha: 0.35),
                lineas: entrada.features,
              ),
            if (entrada.fixes.isNotEmpty) ...<Widget>[
              if (entrada.features.isNotEmpty) const SizedBox(height: AppEspaciado.md),
              _BloqueCategoria(
                cs: cs,
                titulo: 'Correcciones',
                conteo: entrada.fixes.length,
                icono: Icons.bug_report_outlined,
                colorAcento: cs.error,
                fondo: cs.errorContainer.withValues(alpha: 0.45),
                lineas: entrada.fixes,
              ),
            ],
            if (entrada.maintenance.isNotEmpty) ...<Widget>[
              if (entrada.features.isNotEmpty || entrada.fixes.isNotEmpty)
                const SizedBox(height: AppEspaciado.md),
              _BloqueCategoria(
                cs: cs,
                titulo: 'Plataforma y mantenimiento',
                conteo: entrada.maintenance.length,
                icono: Icons.precision_manufacturing_outlined,
                colorAcento: cs.tertiary,
                fondo: cs.tertiaryContainer.withValues(alpha: 0.4),
                lineas: entrada.maintenance,
              ),
            ],
          ] else if (entrada.items.isNotEmpty)
            _BloqueCategoria(
              cs: cs,
              titulo: 'Cambios',
              conteo: entrada.items.length,
              icono: Icons.format_list_bulleted_rounded,
              colorAcento: cs.primary,
              fondo: cs.surfaceContainerHighest.withValues(alpha: 0.9),
              lineas: entrada.items,
            )
          else
            Text(
              'Sin detalle para esta versión.',
              style: bar.textoChip.copyWith(
                fontWeight: FontWeight.w400,
                color: cs.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _BloqueCategoria extends StatelessWidget {
  const _BloqueCategoria({
    required this.cs,
    required this.titulo,
    required this.conteo,
    required this.icono,
    required this.colorAcento,
    required this.fondo,
    required this.lineas,
  });

  final ColorScheme cs;
  final String titulo;
  final int conteo;
  final IconData icono;
  final Color colorAcento;
  final Color fondo;
  final List<String> lineas;

  @override
  Widget build(BuildContext context) {
    final bar = context.sisTipografia;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppEspaciado.md,
        AppEspaciado.sm,
        AppEspaciado.sm,
        AppEspaciado.md,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(AppEspaciado.radioTarjeta),
        border: Border(
          left: BorderSide(color: colorAcento, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icono, size: AppTamanoIcono.pequeno, color: colorAcento),
              const SizedBox(width: AppEspaciado.sm),
              Expanded(
                child: Text(
                  titulo,
                  style: bar.textoSecundario.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppEspaciado.sm, vertical: AppEspaciado.xs),
                decoration: BoxDecoration(
                  color: colorAcento.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$conteo',
                  style: bar.etiquetaSeccion.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                    color: colorAcento,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppEspaciado.sm),
          ...lineas.map(
            (String linea) => Padding(
              padding: const EdgeInsets.only(bottom: AppEspaciado.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: AppEspaciado.xs),
                    child: Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(right: AppEspaciado.sm, top: AppEspaciado.xs),
                      decoration: BoxDecoration(
                        color: colorAcento.withValues(alpha: 0.75),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      linea,
                      style: bar.textoSecundario.copyWith(
                        height: 1.42,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}