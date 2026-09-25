import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/data/datasources/providers.dart';
import 'package:sistema_vacunacion/src/utils/informacion_version_app_util.dart';
import 'package:sistema_vacunacion/src/widgets/widgets.dart';

class SobreNosotrosPage extends StatelessWidget {
  const SobreNosotrosPage({Key? key}) : super(key: key);

  static const _logosInstitucionales = [
    _LogoInfo('assets/img/fondo/logo_direccion_informatica.png', 'Dirección de Informática y Comunicaciones'),
    _LogoInfo('assets/img/fondo/gobiernoFormosa.png', 'Gobierno de Formosa'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBarSesion(
        titulo: 'Sobre nosotros',
        leading: IconButton(
          style: IconButton.styleFrom(
            foregroundColor: cs.onPrimary,
            backgroundColor: cs.onPrimary.withValues(alpha: 0.18),
          ),
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppEspaciado.xl,
            vertical: AppEspaciado.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _EntradaAnimada(
                    child: _TarjetaIdentidad(logos: _logosInstitucionales),
                  ),
                  const SizedBox(height: AppEspaciado.xl),
                  _EntradaAnimada(
                    delay: const Duration(milliseconds: 80),
                    child: _AccesoNovedades(),
                  ),
                  const SizedBox(height: AppEspaciado.xl),
                  const _EntradaAnimada(
                    delay: Duration(milliseconds: 160),
                    child: _FormularioConsultas(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoInfo {
  const _LogoInfo(this.asset, this.nombre);
  final String asset;
  final String nombre;
}

/// Fade + slide-up genérico para cascada de secciones.
class _EntradaAnimada extends StatelessWidget {
  const _EntradaAnimada({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.entrada + delay,
      curve: Curves.easeOutCubic,
      builder: (context, valor, hijo) {
        return Opacity(
          opacity: valor.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - valor) * 16),
            child: hijo,
          ),
        );
      },
      child: child,
    );
  }
}

class _TarjetaIdentidad extends StatelessWidget {
  const _TarjetaIdentidad({required this.logos});

  final List<_LogoInfo> logos;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;
    final bar = context.sisTipografia;
    final oscuro = tema.brightness == Brightness.dark;

    final decoracionTarjeta = BoxDecoration(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppEspaciado.radioTarjeta),
      border: oscuro
          ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.3))
          : null,
      boxShadow: [
        BoxShadow(
          color: cs.shadow.withValues(alpha: oscuro ? 0.55 : 0.12),
          offset: const Offset(0, 6),
          blurRadius: 16,
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppEspaciado.xl,
        vertical: AppEspaciado.xxl,
      ),
      decoration: decoracionTarjeta,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            FontAwesomeIcons.syringe,
            size: AppTamanoIcono.mediano,
            color: cs.primary,
          ),
          const SizedBox(height: AppEspaciado.lg),
          Text(
            'Sistema Vacunación',
            textAlign: TextAlign.center,
            style: bar.tituloSeccion.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppEspaciado.sm),
          FutureBuilder<String>(
            future: InformacionVersionApp.etiquetaSemver(),
            builder: (BuildContext context, AsyncSnapshot<String> snap) {
              final String v = snap.data ?? '…';
              return Text(
                'Versión $v',
                style: bar.textoSecundario.copyWith(
                  color: AppSuperficies.textoSecundario(context),
                  letterSpacing: 1.0,
                ),
              );
            },
          ),
          const SizedBox(height: AppEspaciado.xxl),
          Divider(color: cs.outlineVariant),
          const SizedBox(height: AppEspaciado.xl),
          Text(
            'Desarrollado por',
            textAlign: TextAlign.center,
            style: bar.textoSecundario.copyWith(
              color: AppSuperficies.textoSecundario(context),
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: AppEspaciado.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (int i = 0; i < logos.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppEspaciado.lg),
                    child: SizedBox(
                      height: 48,
                      child: VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: cs.outlineVariant,
                      ),
                    ),
                  ),
                Expanded(
                  child: _LogoInstitucional(info: logos[i], delayIndice: i),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AccesoNovedades extends StatelessWidget {
  const _AccesoNovedades();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;

    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(AppEspaciado.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => mostrarDialogoNovedadesApp(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppEspaciado.lg,
            vertical: AppEspaciado.md,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppEspaciado.radioBoton),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.history_edu_rounded, color: cs.primary, size: 20),
              ),
              const SizedBox(width: AppEspaciado.md),
              Expanded(
                child: Text(
                  'Novedades de la versión',
                  style: bar.textoFormulario.copyWith(
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
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
    );
  }
}

const _tiposFeedback = [
  ('bug', 'Reportar un problema'),
  ('sugerencia', 'Sugerir una mejora'),
  ('otro', 'Otra cosa'),
];

final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

class _FormularioConsultas extends StatefulWidget {
  const _FormularioConsultas();

  @override
  State<_FormularioConsultas> createState() => _FormularioConsultasState();
}

class _FormularioConsultasState extends State<_FormularioConsultas> {
  String _tipo = _tiposFeedback.first.$1;
  final _mensajeCtrl = TextEditingController();
  final _contactoCtrl = TextEditingController();
  bool _enviando = false;
  ({bool ok, String texto})? _resultado;

  @override
  void dispose() {
    _mensajeCtrl.dispose();
    _contactoCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final mensaje = _mensajeCtrl.text.trim();
    final contacto = _contactoCtrl.text.trim();

    if (mensaje.isEmpty) {
      setState(() => _resultado = (ok: false, texto: 'Contanos qué pasó.'));
      return;
    }
    if (!_emailRegex.hasMatch(contacto)) {
      setState(() => _resultado = (ok: false, texto: 'Ingresá un email válido.'));
      return;
    }

    setState(() {
      _enviando = true;
      _resultado = null;
    });

    try {
      await feedbackProvider.enviarFeedback(tipo: _tipo, mensaje: mensaje, contacto: contacto);
      setState(() {
        _resultado = (ok: true, texto: 'Gracias, lo recibimos correctamente.');
        _mensajeCtrl.clear();
        _contactoCtrl.clear();
      });
    } catch (e) {
      setState(() => _resultado = (ok: false, texto: '$e'));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;
    final bar = context.sisTipografia;
    final oscuro = tema.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppEspaciado.xl),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppEspaciado.radioTarjeta),
        border: oscuro
            ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: oscuro ? 0.55 : 0.12),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consultas y sugerencias',
            style: bar.tituloSeccion.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppEspaciado.xs),
          Text(
            'Reportá un problema o sugerí una mejora sobre esta aplicación.',
            style: bar.textoSecundario.copyWith(
              color: AppSuperficies.textoSecundario(context),
            ),
          ),
          const SizedBox(height: AppEspaciado.lg),
          Wrap(
            spacing: AppEspaciado.sm,
            runSpacing: AppEspaciado.sm,
            children: [
              for (final (valor, etiqueta) in _tiposFeedback)
                _ChipFeedback(
                  etiqueta: etiqueta,
                  seleccionado: _tipo == valor,
                  onTap: () => setState(() => _tipo = valor),
                ),
            ],
          ),
          const SizedBox(height: AppEspaciado.lg),
          TextField(
            controller: _mensajeCtrl,
            maxLength: 2000,
            maxLines: 4,
            decoration: InputDecoration(
              filled: true,
              fillColor: cs.surfaceContainer,
              hintText: 'Describí el problema o la sugerencia...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppEspaciado.radioBoton),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppEspaciado.sm),
          TextField(
            controller: _contactoCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              filled: true,
              fillColor: cs.surfaceContainer,
              hintText: 'Email de contacto',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppEspaciado.radioBoton),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_resultado != null) ...[
            const SizedBox(height: AppEspaciado.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppEspaciado.md,
                vertical: AppEspaciado.sm,
              ),
              decoration: BoxDecoration(
                color: (_resultado!.ok ? cs.primaryContainer : cs.errorContainer)
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppEspaciado.radioBoton),
              ),
              child: Row(
                children: [
                  Icon(
                    _resultado!.ok ? Icons.check_circle_outline : Icons.error_outline,
                    size: AppTamanoIcono.pequeno,
                    color: _resultado!.ok ? cs.primary : cs.error,
                  ),
                  const SizedBox(width: AppEspaciado.sm),
                  Expanded(
                    child: Text(
                      _resultado!.texto,
                      style: bar.textoChip.copyWith(
                        color: _resultado!.ok ? cs.onPrimaryContainer : cs.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppEspaciado.lg),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _enviando ? null : _enviar,
              style: AppBotones.estiloFilled(cs),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(_enviando ? 'Enviando...' : 'Enviar'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de selección propio: ChoiceChip de Material anima su color de
/// selección con un tween interno que en este proyecto se ve como un
/// parpadeo (confirmado midiendo píxeles frame a frame). Acá el único
/// color que se anima es el que fijamos en `color`, sin scrim/ripple
/// de por medio.
class _ChipFeedback extends StatelessWidget {
  const _ChipFeedback({
    required this.etiqueta,
    required this.seleccionado,
    required this.onTap,
  });

  final String etiqueta;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppEspaciado.radioBoton),
        child: AnimatedContainer(
          duration: AppMotion.rapida,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: seleccionado ? cs.primaryContainer : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppEspaciado.radioBoton),
            border: Border.all(
              color: cs.outline.withValues(alpha: oscuro ? 0.42 : 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check,
                size: AppTamanoIcono.pequeno,
                color: seleccionado ? cs.primary : Colors.transparent,
              ),
              const SizedBox(width: AppEspaciado.xs),
              Text(
                etiqueta,
                style: bar.textoChip.copyWith(
                  color: seleccionado ? cs.onPrimaryContainer : cs.onSurface,
                  fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoInstitucional extends StatefulWidget {
  const _LogoInstitucional({required this.info, required this.delayIndice});

  final _LogoInfo info;
  final int delayIndice;

  @override
  State<_LogoInstitucional> createState() => _LogoInstitucionalState();
}

class _LogoInstitucionalState extends State<_LogoInstitucional> {
  bool _presionado = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    Widget logo = Image.asset(widget.info.asset, fit: BoxFit.contain, height: 88);
    if (oscuro) {
      logo = ColorFiltered(
        colorFilter: ColorFilter.mode(cs.onSurface, BlendMode.srcIn),
        child: logo,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.entrada + Duration(milliseconds: 80 * widget.delayIndice),
      curve: Curves.easeOutCubic,
      builder: (context, valor, hijo) {
        return Opacity(opacity: valor.clamp(0.0, 1.0), child: hijo);
      },
      child: Tooltip(
        message: widget.info.nombre,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _presionado = true),
          onTapUp: (_) => setState(() => _presionado = false),
          onTapCancel: () => setState(() => _presionado = false),
          child: AnimatedScale(
            scale: _presionado ? 0.92 : 1.0,
            duration: AppMotion.rapida,
            curve: Curves.easeOut,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppEspaciado.sm),
              child: logo,
            ),
          ),
        ),
      ),
    );
  }
}
