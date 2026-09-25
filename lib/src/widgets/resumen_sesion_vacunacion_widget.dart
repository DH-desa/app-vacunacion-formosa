import 'package:flutter/material.dart';

import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/presentation/state/services.dart';

/// Tarjeta colapsable con establecimiento + modalidad de la sesión.
/// `mostrarNotaBackend`, `colapsable` y `expandidoInicial` se quitaron: en el
/// único uso real (`busquedabeneficiario_page.dart:86`) nunca variaban de su
/// default, eran dead flexibility.
class ResumenSesionVacunacion extends StatefulWidget {
  const ResumenSesionVacunacion({
    Key? key,
    this.compendio = false,
  }) : super(key: key);

  final bool compendio;

  @override
  State<ResumenSesionVacunacion> createState() =>
      _ResumenSesionVacunacionState();
}

class _ResumenSesionVacunacionState extends State<ResumenSesionVacunacion> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;

    final String establecimiento =
        registradorService.registrador?.sysofic01_descripcion ?? '—';

    final double pad = widget.compendio ? AppEspaciado.md : AppEspaciado.lg;
    final double anchoEtiqueta = widget.compendio ? 96 : 112;

    return Container(
      width: double.infinity,
      decoration: AppSuperficies.tarjetaBlanca(
        context,
        radio: AppEspaciado.radioCampo,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expandido = !_expandido),
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, pad, pad * 0.35, pad),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sesión de vacunación',
                            style: (widget.compendio
                                    ? bar.subtituloTarjeta
                                    : bar.tituloTarjeta)
                                .copyWith(color: cs.onSurface),
                          ),
                          if (!_expandido) ...[
                            const SizedBox(height: AppEspaciado.xs),
                            Text(
                              establecimiento,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: (widget.compendio
                                      ? bar.textoChip
                                      : bar.textoSecundario)
                                  .copyWith(
                                fontWeight: FontWeight.w400,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      _expandido
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: cs.primary,
                      size: AppTamanoIcono.mediano,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expandido)
            Padding(
              padding: EdgeInsets.fromLTRB(
                pad,
                AppEspaciado.sm,
                pad,
                pad,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lo que se usará al registrar la aplicación',
                    style: (widget.compendio
                            ? bar.textoChip
                            : bar.textoSecundario)
                        .copyWith(
                      height: 1.35,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(
                      height: widget.compendio
                          ? AppEspaciado.md
                          : AppEspaciado.lg),
                  _fila(
                    context,
                    anchoEtiqueta: anchoEtiqueta,
                    compendio: widget.compendio,
                    etiqueta: 'Establecimiento',
                    valor: establecimiento,
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable:
                        sesionEquipoVacunacionService.enTerrenoEstado,
                    builder: (BuildContext context, enTerreno, _) => _fila(
                      context,
                      anchoEtiqueta: anchoEtiqueta,
                      compendio: widget.compendio,
                      etiqueta: 'Modalidad',
                      valor: enTerreno
                          ? 'En terreno (campaña o salida)'
                          : 'En establecimiento fijo',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _fila(
    BuildContext context, {
    required double anchoEtiqueta,
    required bool compendio,
    required String etiqueta,
    required String valor,
  }) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppEspaciado.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: anchoEtiqueta,
            child: Text(
              etiqueta,
              style: (compendio ? bar.textoChip : bar.textoSecundario)
                  .copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: (compendio ? bar.textoPrincipal : bar.textoDestacado)
                  .copyWith(
                height: 1.3,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
