import 'dart:io' show Platform;

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/config/appsize_config.dart';
import 'package:sistema_vacunacion/src/data/datasources/providers.dart';
import 'package:sistema_vacunacion/src/data/repositories/repositories.dart';
import 'package:sistema_vacunacion/src/presentation/state/services.dart';
import 'package:sistema_vacunacion/src/utils/informacion_version_app_util.dart';
import 'package:sistema_vacunacion/src/widgets/widgets.dart';

import 'package:url_launcher/url_launcher.dart';

import '../pages.dart';

class LoginBody extends StatefulWidget {
  static const String nombreRuta = '/Login';

  const LoginBody({super.key});

  @override
  State<LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<LoginBody> {
  /// Etiqueta de versión desde pubspec (solo X.Y.Z, sin +build).
  String _etiquetaSemver = '…';

  final String nombreApp = 'Sistema de vacunación general';

  List<String>? conSplit;
  List<String>? escaneados;
  String? nombrePersona;
  String? apellidoPersona;
  String? dniPersona;
  String sexoPersona = 'F';
  final controladorDni = TextEditingController();

  @override
  void initState() {
    super.initState();
    datosdecargaprovider.versionApp = 'Ok';
    _cargarEtiquetaSemver();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SizeConfiguracion().init(context);
  }

  Future<void> _cargarEtiquetaSemver() async {
    final String s = await InformacionVersionApp.etiquetaSemver();
    if (!mounted) return;
    setState(() => _etiquetaSemver = s);
  }

  @override
  void dispose() {
    controladorDni.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: cs.surface,
          floatingActionButton: enviromentService.envState!.enviroment == 'DEV'
              ? FloatingActionButton.extended(
                  heroTag: 'botonDesa',
                  icon: const Icon(Icons.perm_data_setting_sharp),
                  backgroundColor: cs.errorContainer,
                  foregroundColor: cs.onErrorContainer,
                  label: const Text('DESA'),
                  isExtended: true,
                  tooltip: 'PARA SU USO EN DESARROLLO!',
                  onPressed: () async {
                    final respUsuario = await authRepository
                        .validarUsuariosNuevo('36355149');
                    registradorService.cargarRegistrador(respUsuario[0]);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VacunadorPage(infoCargador: respUsuario),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                )
              : null,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MarcaCabeceraGradiente(
                titulo: 'Bienvenido',
                subtitulo: nombreApp,
                alturaMinima: 162,
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppEspaciado.lg,
                    0,
                    AppEspaciado.lg,
                    AppEspaciado.lg,
                  ),
                  child: Transform.translate(
                    offset: const Offset(0, -32),
                    child: Column(
                      children: [
                        FadeInUp(
                          duration: const Duration(milliseconds: 520),
                          child: const _TarjetaLoginAcceso(),
                        ),
                        const SizedBox(height: AppEspaciado.lg),
                        FadeIn(
                          delay: const Duration(milliseconds: 200),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppEspaciado.sm,
                            runSpacing: AppEspaciado.xs,
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppEspaciado.md,
                                  vertical: AppEspaciado.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest.withValues(
                                    alpha: 0.75,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppEspaciado.radioCampo,
                                  ),
                                ),
                                child: Text(
                                  'v$_etiquetaSemver',
                                  style: tt.labelLarge?.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Tooltip(
                                message: 'Ver novedades de la versión',
                                child: TextButton.icon(
                                  style: AppBotones.estiloTextoPequeno(cs),
                                  onPressed: () =>
                                      mostrarDialogoNovedadesApp(context),
                                  icon: const Icon(Icons.article_outlined),
                                  label: const Text('Novedades'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppEspaciado.sm),
                        FadeInLeft(
                          delay: const Duration(milliseconds: 400),
                          child: Text(
                            'Para uso interno — Ministerio de Desarrollo Humano',
                            textAlign: TextAlign.center,
                            style: tt.bodySmall?.copyWith(
                              fontSize: 12,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.9),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppEspaciado.lg,
                    0,
                    AppEspaciado.lg,
                    AppEspaciado.sm,
                  ),
                  child: BounceInUp(
                    from: 12,
                    delay: const Duration(milliseconds: 500),
                    child: Image.asset(
                      'assets/img/fondo/AZUL_TODOS_UNIDOS.png',
                      fit: BoxFit.contain,
                      height: MediaQuery.of(context).size.height * 0.062,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? cs.onSurface.withValues(alpha: 0.8)
                          : null,
                      colorBlendMode:
                          Theme.of(context).brightness == Brightness.dark
                          ? BlendMode.srcIn
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: loadingLoginService.loadingEstado,
          builder: (BuildContext context, loading, _) {
            if (loading) {
              return Container(
                height: double.infinity,
                width: double.infinity,
                color: cs.scrim.withValues(alpha: .72),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LoadingEstrellas(),
                      if (loadingLoginService.loadingMensaje.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            loadingLoginService.loadingMensaje,
                            textAlign: TextAlign.center,
                            style: tt.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }
            return loadingLoginService.getEstadoPrimerInicioState!
                ? const SizedBox.shrink()
                : FutureBuilder(
                    future: Future.delayed(const Duration(milliseconds: 1000)),
                    builder:
                        (
                          BuildContext context,
                          AsyncSnapshot<dynamic> snapshot,
                        ) {
                          return snapshot.connectionState ==
                                  ConnectionState.waiting
                              ? Container(
                                  height: double.infinity,
                                  width: double.infinity,
                                  color: cs.scrim.withValues(alpha: .72),
                                  child: const Center(
                                    child: LoadingEstrellas(),
                                  ),
                                )
                              : const SizedBox.shrink();
                        },
                  );
          },
        ),
      ],
    );
  }

  void mostrarAlertaActualizacion(BuildContext context, String mensaje) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => DialogoAlerta(
        tituloAlerta: 'Actualización disponible',
        descripcionAlerta: mensaje,
        icon: Icon(
          Icons.system_update_alt_rounded,
          size: AppTamanoIcono.grande,
        ),
        color: Theme.of(ctx).colorScheme.primary,
        dosBotones: !Platform.isIOS,
        textoBotonAlerta: 'Cerrar',
        textoBotonAlerta2: 'Descargar APK',
        envioFuncion1: false,
        funcion2: !Platform.isIOS
            ? () {
                Navigator.of(ctx).pop();
                _launchURL();
              }
            : null,
      ),
    );
  }

  Future<void> _launchURL() async {
    const url =
        'https://dh.formosa.gob.ar/modulos/webservice/php/version_3_0/v3.0.0.apk';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

/// Tarjeta principal con logo, llamada a la acción y escáner.
class _TarjetaLoginAcceso extends StatelessWidget {
  const _TarjetaLoginAcceso();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ancho = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppEspaciado.xl),
      decoration: AppSuperficies.tarjeta(
        context,
      ).copyWith(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Image.asset(
            Theme.of(context).brightness == Brightness.light
                ? 'assets/logo/VacunApp2_claro.png'
                : 'assets/logo/VacunApp2.png',
            fit: BoxFit.contain,
            width: ancho * 0.52,
          ),
          const SizedBox(height: AppEspaciado.xl),
          Text(
            'Acceso al sistema',
            style: tt.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.15,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppEspaciado.sm),
          Text(
            'Escanee su D.N.I. para continuar',
            textAlign: TextAlign.center,
            style: tt.titleMedium?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.3,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppEspaciado.xs),
          Text(
            'Escanee el código del frente (DNI nuevo), del reverso (DNI anterior).',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(
              fontSize: 13,
              height: 1.4,
              color: cs.onSurfaceVariant.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: AppEspaciado.xl),
          SizedBox(
            width: double.infinity,
            child: ElasticIn(
              delay: const Duration(milliseconds: 280),
              child: EscanerDni(
                'Registrador',
                'Escanear documento',
                iconBool: false,
                anchoValor: MediaQuery.of(context).size.width * 0.11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
