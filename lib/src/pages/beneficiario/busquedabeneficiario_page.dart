import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/core/helpers/helpers.dart';
import 'package:sistema_vacunacion/src/domain/entities/models.dart';
import 'package:sistema_vacunacion/src/domain/entities/vacunados/cantidadvacunados_models.dart'
    as modelo;
import 'package:sistema_vacunacion/src/data/datasources/providers.dart';
import 'package:sistema_vacunacion/src/data/repositories/repositories.dart';
import 'package:sistema_vacunacion/src/presentation/state/services.dart';
import 'package:sistema_vacunacion/src/utils/edad_beneficiario.dart';
import 'package:sistema_vacunacion/src/widgets/widgets.dart';

import '../pages.dart';

class BusquedaBeneficiario extends StatefulWidget {
  const BusquedaBeneficiario({super.key});
  static const String nombreRuta = 'BusquedaBeneficiario';

  @override
  State<BusquedaBeneficiario> createState() => _BusquedaBeneficiarioState();
}

class _BusquedaBeneficiarioState extends State<BusquedaBeneficiario> {
  bool loading = false;
  late TextEditingController dniController;
  late FocusNode focusNode;

  /// Modo de entrada elegido: 'escaneo' | 'manual'. Uno solo visible por vez.
  String _modo = 'escaneo';

  @override
  void initState() {
    super.initState();
    reiniciarCicloBeneficiario();
    dniController = TextEditingController();
    focusNode = FocusNode();
    if (vacunadorService.existeVacunador != false) {
      _incrementoVacunados();
    }
  }

  @override
  void dispose() {
    focusNode.dispose();
    dniController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const duracionAnimacion = 1000;
    const duracionDelay = 0;

    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) onWillPop(context);
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        drawer: const BodyDrawer(),
        appBar: const AppBarSesion(titulo: 'Buscar beneficiario'),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppEspaciado.lg,
            AppEspaciado.md,
            AppEspaciado.lg,
            AppEspaciado.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeIn(
                duration: const Duration(milliseconds: duracionAnimacion),
                delay: const Duration(milliseconds: duracionDelay),
                child: const ResumenSesionVacunacion(compendio: true),
              ),
              const SizedBox(height: AppEspaciado.lg),
              FadeInUp(
                from: 14,
                duration: const Duration(milliseconds: duracionAnimacion),
                delay: const Duration(milliseconds: duracionDelay),
                child: _tarjetaCaptura(context),
              ),
              const SizedBox(height: AppEspaciado.xl),
              const CantidadVacunados(),
            ],
          ),
        ),
      ),
    );
  }

  /// Tarjeta de captura del beneficiario con selector de modo: escaneo del
  /// D.N.I. o carga manual. Se muestra un solo formulario por vez.
  Widget _tarjetaCaptura(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Datos del beneficiario',
                      style: bar.tituloTarjeta.copyWith(color: cs.onSurface),
                    ),
                    const SizedBox(height: AppEspaciado.xs),
                    Text(
                      'Elegí cómo cargar el documento',
                      style: bar.textoChip.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ayuda: escanear o cargar D.N.I. del beneficiario',
                style: AppBotones.estiloIconoAyuda(cs),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => DialogoAlerta(
                      envioFuncion2: false,
                      envioFuncion1: false,
                      tituloAlerta: 'Información',
                      descripcionAlerta:
                          'Si el beneficiario tiene el D.N.I., use el modo Escanear y enfoque la cámara al código de barras; el sexo se detecta solo y luego completa la situación. Si no lo tiene, use Manual e ingrese número, sexo y situación.',
                      textoBotonAlerta: 'Entendido',
                      color: SisVacuMarca.vercelesteCuaternario,
                      icon: const Icon(
                        Icons.info,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
                icon: FaIcon(
                  FontAwesomeIcons.circleInfo,
                  size: AppTamanoIcono.pequeno,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppEspaciado.lg),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'escaneo',
                label: Text('Escanear'),
                icon: Icon(Icons.qr_code_scanner_rounded),
              ),
              ButtonSegment(
                value: 'manual',
                label: Text('Manual'),
                icon: Icon(Icons.keyboard_alt_outlined),
              ),
            ],
            selected: {_modo},
            onSelectionChanged: (s) => setState(() => _modo = s.first),
          ),
          const SizedBox(height: AppEspaciado.lg),
          AnimatedSize(
            duration: AppMotion.entrada,
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _modo == 'escaneo' ? _modoEscaneo(context) : _modoManual(),
          ),
        ],
      ),
    );
  }

  /// Modo escaneo: botón de cámara. [EscanerDni] pide la situación, consulta
  /// y navega directo a VacunasPage al cargar el beneficiario.
  Widget _modoEscaneo(BuildContext context) {
    return EscanerDni('Beneficiario', 'Escanear documento', anchoValor: 44);
  }

  /// Modo manual: D.N.I. + sexo + situación (reactiva al sexo) + verificar.
  Widget _modoManual() {
    return FormularioDocumento(
      tipoEscaneo: 'Beneficiario',
      textoBotonEscaneo: '',
      mostrarEscaner: false,
      mostrarSituacion: true,
      controladorDni: dniController,
      focusNode: focusNode,
      etiquetaBoton: 'Verificar datos',
      onVerificar: _confirmarYBuscar,
    );
  }

  /// El formulario ya mostró D.N.I./sexo/situación antes de este botón: no
  /// hace falta reconfirmarlos en un diálogo aparte. Va directo a loading +
  /// consulta (mismo criterio que el escaneo por cámara).
  void _confirmarYBuscar(String dni, String? sexo) {
    setState(() => loading = true);
    retornarLoading(context, 'Espere por favor');
    obtenerDatosBeneficiario(context, dni, sexo);
  }

  Future<void> obtenerDatosBeneficiario(
    BuildContext context1,
    String? dni,
    String? sexoPersona,
  ) async {
    try {
      final condicion = situacionBeneficiarioService.condicionGestacional;
      final datosBeneficiario = await beneficiarioProviders.obtenerDatosPersona(
        '',
        dni,
        sexoPersona,
        embarazada: condicion == CondicionGestacional.embarazada,
        puerpera: condicion == CondicionGestacional.puerpera,
        personalSalud: situacionBeneficiarioService.esPersonalDeSalud,
      );
      // El historial es información complementaria: si el webservice falla,
      // no debe bloquear la carga del beneficiario (que ya se obtuvo bien).
      try {
        final nacimiento = parseFechaNacimiento(
          datosBeneficiario.isNotEmpty
              ? datosBeneficiario[0].sysdesa10_fecha_nacimiento
              : null,
        );
        final notificaciones = await sistemaRepository.validarNotificaciones(
          dni,
          sexoPersona,
          embarazada: condicion == CondicionGestacional.embarazada,
          puerpera: condicion == CondicionGestacional.puerpera,
          personalSalud: situacionBeneficiarioService.esPersonalDeSalud,
          edadDias: nacimiento == null
              ? null
              : diasDeVidaDesde(nacimiento, DateTime.now()).toString(),
        );
        if (notificaciones.isNotEmpty) {
          notificacionesDosisService.cargarListaDosis(notificaciones);
        } else {
          notificacionesDosisService.cargarRegistro(NotificacionesDosis());
        }
      } catch (_) {
        notificacionesDosisService.cargarRegistro(NotificacionesDosis());
        // La misma llamada trae "vacunas_pendientes": si falló, la vía
        // Pendientes no puede confundir esto con "no tiene nada pendiente".
        vacunasPendientesService.marcarError(
          'No se pudo consultar las vacunas pendientes. Revise la conexión.',
        );
      }
      if (!mounted) return;

      _cerrarDialogoCargaSiAbierta();

      if (datosBeneficiario[0].codigo_mensaje == '0') {
        showDialog(
          context: context,
          builder: (BuildContext context) => DialogoAlerta(
            envioFuncion2: false,
            envioFuncion1: true,
            funcion1: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const BusquedaBeneficiario(),
                ),
                (Route<dynamic> route) => false,
              );
            },
            tituloAlerta: 'No se pudo continuar',
            descripcionAlerta: datosBeneficiario[0].mensaje,
            textoBotonAlerta: 'Listo',
            color: Theme.of(context).colorScheme.error,
            icon: const Icon(Icons.error, size: 40),
          ),
        );
        return;
      }
      await confirmarBeneficiario(datosBeneficiario[0]);
    } catch (_) {
      if (!mounted) return;
      _cerrarDialogoCargaSiAbierta();
      showDialog(
        context: context,
        builder: (BuildContext context) => DialogoAlerta(
          envioFuncion2: false,
          envioFuncion1: false,
          tituloAlerta: 'Sin conexión',
          descripcionAlerta:
              'No se pudieron obtener los datos del beneficiario. Revise la red e intente de nuevo.',
          textoBotonAlerta: 'Listo',
          color: Theme.of(context).colorScheme.error,
          icon: const Icon(Icons.wifi_off_rounded, size: 40),
        ),
      );
    }
  }

  /// Cierra el [AlertDialog] de «Espere por favor» si sigue abierto.
  void _cerrarDialogoCargaSiAbierta() {
    final NavigatorState nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    }
    setState(() {
      loading = false;
    });
  }

  Future<void> confirmarBeneficiario(Beneficiario? beneficiario) async {
    beneficiarioService.cargarBeneficiario(beneficiario);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const VacunasPage()),
      (Route<dynamic> route) => false,
    );
  }

  void retornarLoading(BuildContext context, String mensaje) {
    if (loading) {
      showDialog(
        context: context,
        builder: (context) => LoadingDialogEstrellas(mensaje: mensaje),
      );
    }
  }

  Future<void> _incrementoVacunados() async {
    final cantidadVacunas = await vacunasRepository.cantidadVacunas();
    cantidadVacunasService.cargarCantidadVacunados(cantidadVacunas[0]);
  }
}

/// Resumen de dosis aplicadas (misma línea visual que el resto de tarjetas).
class CantidadVacunados extends StatefulWidget {
  const CantidadVacunados({super.key});

  @override
  State<CantidadVacunados> createState() => _CantidadVacunadosState();
}

class _CantidadVacunadosState extends State<CantidadVacunados> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    final double ladoInsignia =
        (MediaQuery.sizeOf(context).width * 0.14).clamp(48, 96).toDouble();

    return FadeInUp(
      from: 16,
      duration: const Duration(milliseconds: 800),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppEspaciado.lg),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppEspaciado.radioCampo),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.38)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Vacunaciones',
                  style: bar.etiquetaSeccion.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  'registradas',
                  style: bar.etiquetaSeccion.copyWith(
                    letterSpacing: 0,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppEspaciado.lg),
            Bounce(
              manualTrigger: false,
              from: 8,
              infinite: true,
              duration: const Duration(milliseconds: 2000),
              child: Container(
                alignment: Alignment.center,
                width: ladoInsignia,
                height: ladoInsignia,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: ValueListenableBuilder<modelo.CantidadVacunados?>(
                  valueListenable:
                      cantidadVacunasService.cantidadVacunadosEstado,
                  builder: (BuildContext context, cantidadVacunados, _) {
                    if (cantidadVacunados == null) {
                      return SizedBox(
                        width: AppTamanoIcono.mediano,
                        height: AppTamanoIcono.mediano,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      );
                    }
                    return Text(
                      cantidadVacunados.cantidad_aplicaciones!,
                      style: bar.subtituloTarjeta.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
