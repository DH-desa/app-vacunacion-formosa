import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/core/helpers/helpers.dart';
import 'package:sistema_vacunacion/src/domain/entities/models.dart';
import 'package:sistema_vacunacion/src/pages/drawer/components/sobrenosotros_page.dart';
import 'package:sistema_vacunacion/src/pages/pages.dart';
import 'package:sistema_vacunacion/src/presentation/state/services.dart';
import 'package:sistema_vacunacion/src/utils/informacion_version_app_util.dart';
import 'package:sistema_vacunacion/src/widgets/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Menú lateral con cabecera de marca, navegación clara y selector de tema (solo iconos).
class BodyDrawer extends StatefulWidget {
  final List<Vacunador>? infoVacunador;

  const BodyDrawer({Key? key, this.infoVacunador}) : super(key: key);

  @override
  State<BodyDrawer> createState() => _BodyDrawerState();
}

class _BodyDrawerState extends State<BodyDrawer> {
  late final DateFormat _formatoDia;

  @override
  void initState() {
    super.initState();
    _formatoDia = DateFormat.EEEE('es');
  }

  String _capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return '${texto[0].toUpperCase()}${texto.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final nombre = registradorService.registrador!.flxcore03_nombre!;

    return Drawer(
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(AppEspaciado.radioCampo)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CabeceraDrawer(
              nombreUsuario: nombre,
              subtituloDia: _capitalizar(_formatoDia.format(DateTime.now())),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppEspaciado.lg,
                  vertical: AppEspaciado.sm,
                ),
                children: [
                  const _EtiquetaSeccion(texto: 'Menú'),
                  const SizedBox(height: AppEspaciado.xs),
                  _FilaNavegacion(
                    icono: FontAwesomeIcons.solidPenToSquare,
                    titulo: 'Editar equipo de trabajo',
                    onTap: () {
                      vacunadorService.cargarVacunador(null);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const VacunadorPage(infoCargador: []),
                        ),
                      );
                    },
                  ),
                  _FilaNavegacion(
                    icono: FontAwesomeIcons.info,
                    titulo: 'Sobre nosotros',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SobreNosotrosPage(),
                      ),
                    ),
                  ),
                  _FilaNavegacion(
                    icono: FontAwesomeIcons.solidFilePdf,
                    titulo: 'Descargar PDF',
                    onTap: _launchPDF,
                  ),
                  const SizedBox(height: AppEspaciado.lg),
                  const _EtiquetaSeccion(texto: 'Apariencia'),
                  const SizedBox(height: AppEspaciado.sm),
                  const _SelectorTemaSoloIconos(),
                  const SizedBox(height: AppEspaciado.lg),
                  Divider(
                    height: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.45),
                  ),
                  const SizedBox(height: AppEspaciado.sm),
                  _FilaNavegacion(
                    icono: FontAwesomeIcons.powerOff,
                    titulo: 'Cerrar sesión',
                    colorIcono: cs.error,
                    esDestacadoSalida: true,
                    onTap: () => cerrarSesion(context),
                  ),
                ],
              ),
            ),
            _PieDrawer(),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPDF() async {
    const url =
        'https://drive.google.com/file/d/1qD3x3xvzmIVuJlR_UtMzdX619A4F7gAz/view?usp=sharing';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

/// Cabecera con gradiente de marca y tipografía jerárquica.
class _CabeceraDrawer extends StatelessWidget {
  const _CabeceraDrawer({
    required this.nombreUsuario,
    required this.subtituloDia,
  });

  final String nombreUsuario;
  final String subtituloDia;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          AppEspaciado.xl,
          AppEspaciado.xl,
          AppEspaciado.xl,
          AppEspaciado.xl + 4,
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
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(AppRadio.radioDialog),
            bottomRight: Radius.circular(AppRadio.radioDialog),
          ),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: oscuro ? 0.35 : 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppEspaciado.xs),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.22),
              ),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white.withValues(alpha: 0.95),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppEspaciado.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(AppEspaciado.sm),
                    child: Image.asset(
                      'assets/img/fondo/escudoColor.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppEspaciado.lg),
            Text(
              subtituloDia,
              style: bar.textoSecundario.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.85),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: AppEspaciado.xs),
            Text(
              'Bienvenido',
              style: bar.encabezadoDrawer.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: AppEspaciado.sm),
            Text(
              nombreUsuario,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: bar.subtituloTarjeta.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EtiquetaSeccion extends StatelessWidget {
  const _EtiquetaSeccion({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    return Padding(
      padding: const EdgeInsets.only(left: AppEspaciado.xs, top: AppEspaciado.xs),
      child: Text(
        texto.toUpperCase(),
        style: bar.etiquetaSeccion.copyWith(
          letterSpacing: 1.1,
          color: cs.onSurfaceVariant.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

/// Fila táctil amplia con icono en contenedor redondeado (patrón Material 3).
class _FilaNavegacion extends StatelessWidget {
  const _FilaNavegacion({
    required this.icono,
    required this.titulo,
    required this.onTap,
    this.colorIcono,
    this.esDestacadoSalida = false,
  });

  final FaIconData icono;
  final String titulo;
  final VoidCallback onTap;
  final Color? colorIcono;
  final bool esDestacadoSalida;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    final color = colorIcono ?? cs.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppEspaciado.xs),
      child: Material(
        color: esDestacadoSalida
            ? cs.errorContainer.withValues(alpha: 0.22)
            : cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppEspaciado.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppEspaciado.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppEspaciado.md,
              vertical: AppEspaciado.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: esDestacadoSalida
                        ? cs.error.withValues(alpha: 0.14)
                        : cs.primary.withValues(alpha: 0.12),
borderRadius: BorderRadius.circular(AppEspaciado.radioBoton),
                  ),
                  alignment: Alignment.center,
                  child: FaIcon(icono, size: 20, color: color),
                ),
                const SizedBox(width: AppEspaciado.md),
                Expanded(
                  child: Text(
                    titulo,
                    style: bar.textoFormulario.copyWith(
                      fontWeight: esDestacadoSalida
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: esDestacadoSalida ? cs.error : cs.onSurface,
                      height: 1.2,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                  size: AppTamanoIcono.mediano,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tres modos de tema: solo iconos + tooltip (evita cortes de texto y doble línea).
class _SelectorTemaSoloIconos extends StatelessWidget {
  const _SelectorTemaSoloIconos();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppEspaciado.xs),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppRadio.radioFAB),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: ListenableBuilder(
        listenable: temaAppService,
        builder: (context, _) {
          return Row(
            children: [
              Expanded(
                child: _BotonTema(
                  icono: Icons.brightness_auto_rounded,
                  tooltip: 'Según el sistema',
                  seleccionado: temaAppService.modoTema == ThemeMode.system,
                  onTap: () => temaAppService.establecerModo(ThemeMode.system),
                ),
              ),
              Expanded(
                child: _BotonTema(
                  icono: Icons.light_mode_rounded,
                  tooltip: 'Tema claro',
                  seleccionado: temaAppService.modoTema == ThemeMode.light,
                  onTap: () => temaAppService.establecerModo(ThemeMode.light),
                ),
              ),
              Expanded(
                child: _BotonTema(
                  icono: Icons.dark_mode_rounded,
                  tooltip: 'Tema oscuro',
                  seleccionado: temaAppService.modoTema == ThemeMode.dark,
                  onTap: () => temaAppService.establecerModo(ThemeMode.dark),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BotonTema extends StatelessWidget {
  const _BotonTema({
    required this.icono,
    required this.tooltip,
    required this.seleccionado,
    required this.onTap,
  });

  final IconData icono;
  final String tooltip;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppEspaciado.xs, vertical: AppEspaciado.xs),
      child: Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          label: tooltip,
          selected: seleccionado,
          child: Material(
            color: seleccionado ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppEspaciado.radioBoton),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppEspaciado.radioBoton),
              splashColor: cs.primary.withValues(alpha: 0.2),
              child: SizedBox(
                height: AppTamanoIcono.extraGrande,
                child: Icon(
                  icono,
                  size: AppTamanoIcono.mediano,
                  color: seleccionado ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PieDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppEspaciado.lg,
        AppEspaciado.sm,
        AppEspaciado.lg,
        AppEspaciado.lg,
      ),
      child: Column(
        children: [
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.35)),
          const SizedBox(height: AppEspaciado.sm),
          FutureBuilder<String>(
            future: InformacionVersionApp.etiquetaSemver(),
            builder: (BuildContext context, AsyncSnapshot<String> snap) {
              final String etiqueta = snap.data ?? '…';
                  return Column(
                    children: [
                      Text(
                        'v$etiqueta',
                        style: bar.textoChip.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.2,
                        ),
                      ),
                  Tooltip(
                    message: 'Ver novedades de la versión',
                    child: TextButton.icon(
                      style: AppBotones.estiloTextoPequeno(cs),
                      onPressed: () => mostrarDialogoNovedadesApp(context),
                      icon: const Icon(Icons.article_outlined),
                      label: const Text('Novedades de la versión'),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppEspaciado.sm),
        ],
      ),
    );
  }
}
