import 'package:flutter/material.dart';

import 'package:sistema_vacunacion/src/config/config.dart';

class _PasoMeta {
  const _PasoMeta(this.etiqueta, this.icono);
  final String etiqueta;
  final IconData icono;
}

const List<_PasoMeta> _metasPasosVacunas = [
  _PasoMeta('Perfil', Icons.assignment_ind_outlined),
  _PasoMeta('Vacuna', Icons.vaccines_outlined),
  _PasoMeta('Condición', Icons.health_and_safety_outlined),
  _PasoMeta('Esquema', Icons.account_tree_outlined),
  _PasoMeta('Dosis', Icons.numbers_outlined),
  _PasoMeta('Fecha', Icons.calendar_today_outlined),
  _PasoMeta('Lote', Icons.inventory_2_outlined),
  _PasoMeta('Confirmar', Icons.fact_check_outlined),
];

const List<Color> _coloresPasosVacunas = [
  Color(0xFF004B8E),
  Color(0xFF00796B),
  Color(0xFF00897A),
  Color(0xFF0097A7),
  Color(0xFF00695C),
  Color(0xFF009688),
];

/// Contenedor del flujo: header compacto (badge de paso + resumen de lo ya
/// elegido) + contenido del paso. El resumen solo lista pasos con valor, en
/// un `Wrap` que crece con el progreso — antes era una grilla fija de 6 chips
/// de 56dp en 3 filas, ocupando ~250dp incluso en el paso 1 sin nada elegido.
class VacunasPanelFlujo extends StatefulWidget {
  const VacunasPanelFlujo({
    super.key,
    required this.pasoActual,
    required this.onIrAPaso,
    required this.child,
    this.perfil,
    this.vacuna,
    this.condicion,
    this.esquema,
    this.dosis,
    this.fecha,
    this.lote,
  });

  final int pasoActual;
  final ValueChanged<int> onIrAPaso;
  final Widget child;
  final String? perfil;
  final String? vacuna;
  final String? condicion;
  final String? esquema;
  final String? dosis;
  final String? fecha;
  final String? lote;

  @override
  State<VacunasPanelFlujo> createState() => _VacunasPanelFlujoState();
}

class _VacunasPanelFlujoState extends State<VacunasPanelFlujo> {
  final List<_ItemSeleccion> _items = [];

  @override
  void didUpdateWidget(VacunasPanelFlujo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _actualizarItems();
  }

  @override
  void initState() {
    super.initState();
    _actualizarItems();
  }

  void _actualizarItems() {
    _items.clear();
    _items.addAll([
      _ItemSeleccion(
        numeroPaso: 1,
        nombre: 'Perfil',
        valor: widget.perfil,
        indiceColor: 0,
      ),
      _ItemSeleccion(
        numeroPaso: 2,
        nombre: 'Vacuna',
        valor: widget.vacuna,
        indiceColor: 1,
      ),
      _ItemSeleccion(
        numeroPaso: 3,
        nombre: 'Condición',
        valor: widget.condicion,
        indiceColor: 2,
      ),
      _ItemSeleccion(
        numeroPaso: 4,
        nombre: 'Esquema',
        valor: widget.esquema,
        indiceColor: 3,
      ),
      _ItemSeleccion(
        numeroPaso: 5,
        nombre: 'Dosis',
        valor: widget.dosis,
        indiceColor: 4,
      ),
      _ItemSeleccion(
        numeroPaso: 7,
        nombre: 'Lote',
        valor: widget.lote,
        valorSecundario: widget.fecha,
        indiceColor: 5,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final nombrePaso =
        (widget.pasoActual >= 1 &&
            widget.pasoActual <= _metasPasosVacunas.length)
        ? _metasPasosVacunas[widget.pasoActual - 1].etiqueta
        : '';

    final completados = _items.where((i) => i.tieneValor).toList();

    return Container(
      decoration: AppSuperficies.tarjetaBlanca(context, radio: AppEspaciado.xl),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppEspaciado.xl),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              AppEspaciado.lg,
              AppEspaciado.lg,
              AppEspaciado.lg,
              completados.isEmpty ? AppEspaciado.lg : AppEspaciado.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          AppEspaciado.radioCampo,
                        ),
                      ),
                      child: Text(
                        'PASO ${widget.pasoActual} DE ${_metasPasosVacunas.length}',
                        style: tt.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      nombrePaso.toUpperCase(),
                      style: tt.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                if (completados.isNotEmpty) ...[
                  const SizedBox(height: AppEspaciado.sm),
                  Wrap(
                    spacing: AppEspaciado.sm,
                    runSpacing: AppEspaciado.xs,
                    children: completados
                        .map(
                          (item) => _ChipCompacto(
                            item: item,
                            onTap: () => widget.onIrAPaso(item.numeroPaso),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          Container(
            color: cs.surfaceContainerLowest,
            child: Padding(
              padding: const EdgeInsets.all(AppEspaciado.lg),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemSeleccion {
  const _ItemSeleccion({
    required this.numeroPaso,
    required this.nombre,
    this.valor,
    this.valorSecundario,
    required this.indiceColor,
  });

  final int numeroPaso;
  final String nombre;
  final String? valor;
  final String? valorSecundario;
  final int indiceColor;
  bool get tieneValor => valor != null && valor!.isNotEmpty;
}

/// Chip compacto de una línea: "Nombre: valor". Reemplaza a la tarjeta de
/// 56dp por selección — solo se renderiza para pasos ya completados, así el
/// header no ocupa espacio con selecciones vacías.
class _ChipCompacto extends StatelessWidget {
  const _ChipCompacto({required this.item, required this.onTap});

  final _ItemSeleccion item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final oscuro = cs.brightness == Brightness.dark;
    final colorBase = _coloresPasosVacunas[item.indiceColor];
    final fondo = oscuro
        ? colorBase.withValues(alpha: 0.22)
        : colorBase.withValues(alpha: 0.12);
    final borde = oscuro
        ? colorBase.withValues(alpha: 0.75)
        : colorBase.withValues(alpha: 0.55);
    final texto = oscuro ? colorBase.withValues(alpha: 1.0) : colorBase;

    final valorCompleto =
        item.valorSecundario != null && item.valorSecundario!.isNotEmpty
        ? '${item.valor} · ${item.valorSecundario}'
        : item.valor!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppEspaciado.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppEspaciado.sm,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.circular(AppEspaciado.sm),
            border: Border.all(color: borde, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, size: 12, color: texto),
              const SizedBox(width: 4),
              Text(
                '${item.nombre}: ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: texto,
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  valorCompleto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: texto,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Título + subtítulo por paso del flujo (coherente con cabecera de pantalla).
class VacunasTituloSeccionPaso extends StatelessWidget {
  const VacunasTituloSeccionPaso({
    super.key,
    this.etiqueta,
    required this.titulo,
    this.subtitulo,
  });

  final String? etiqueta;
  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bar = context.sisTipografia;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppEspaciado.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (etiqueta != null) ...[
            Text(
              etiqueta!,
              style: tt.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: cs.tertiary,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            titulo,
            style: bar.tituloTarjeta.copyWith(
              fontSize: 16,
              height: 1.1,
              color: cs.onSurface,
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitulo!,
              style: tt.bodyMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.3,
                color: AppSuperficies.textoSecundario(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
