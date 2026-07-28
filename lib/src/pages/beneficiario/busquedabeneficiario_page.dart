import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:sistema_vacunacion/src/config/config.dart';
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

  /// Escaneo: true cuando el beneficiario ya fue cargado por [EscanerDni]
  /// y la tarjeta pasa a mostrar sexo detectado + situación + continuar.
  bool _beneficiarioEscaneado = false;

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
        if (!didPop) onWillPop();
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
    final tt = Theme.of(context).textTheme;
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
                      style: tt.labelLarge?.copyWith(
                        fontSize: 12,
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
                          'Si el beneficiario tiene el D.N.I., use el modo Escanear y enfoque la cámara al código de barras; el sexo se detecta solo y luego completa la situación. Si no lo tiene, use Carga manual e ingrese número, sexo y situación.',
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
                label: Text('Escanear D.N.I.'),
                icon: Icon(Icons.qr_code_scanner_rounded),
              ),
              ButtonSegment(
                value: 'manual',
                label: Text('Carga manual'),
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

  /// Modo escaneo: botón de cámara; tras cargar el beneficiario (con la
  /// situación ya pedida y enviada por [EscanerDni] antes de la consulta)
  /// muestra el resumen escaneado y el botón continuar.
  Widget _modoEscaneo(BuildContext context) {
    final b = beneficiarioService.beneficiario;
    final sexo = b?.sysdesa10_sexo;
    // Antes el fallback era "Femenino" incluso con sexo desconocido, mientras
    // el bloque de condición gestacional (sexoEsFemenino: sexo == 'F') se
    // ocultaba igual: la etiqueta contradecía lo que mostraba la pantalla.
    final etiquetaSexo = sexo == 'M'
        ? 'Masculino'
        : sexo == 'F'
            ? 'Femenino'
            : sexo == 'X'
                ? 'No binario (X)'
                : 'Sin dato';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EscanerDni(
          'Beneficiario',
          _beneficiarioEscaneado ? 'Escanear otro D.N.I.' : 'Escanear documento',
          anchoValor: 44,
          onBeneficiarioCargado: _alCargarBeneficiarioEscaneado,
        ),
        if (_beneficiarioEscaneado && b != null) ...[
          const SizedBox(height: AppEspaciado.lg),
          _resumenEscaneado(context, b, etiquetaSexo),
          const SizedBox(height: AppEspaciado.lg),
          FilledButton.icon(
            style: AppBotones.estiloFilledIconCta(
              padding: const EdgeInsets.symmetric(
                horizontal: AppEspaciado.radioCampo,
                vertical: AppEspaciado.md + AppEspaciado.xs,
              ),
            ),
            onPressed: _continuarEscaneado,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Continuar'),
          ),
        ],
      ],
    );
  }

  /// Datos detectados del escaneo (solo lectura).
  Widget _resumenEscaneado(
    BuildContext context,
    Beneficiario b,
    String etiquetaSexo,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final nombre =
        '${b.sysdesa10_nombre ?? ''} ${b.sysdesa10_apellido ?? ''}'.trim();

    Widget fila(String etiqueta, String valor) => Padding(
          padding: const EdgeInsets.only(bottom: AppEspaciado.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  etiqueta,
                  style: tt.labelMedium?.copyWith(
                    color: AppSuperficies.textoSecundario(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  valor,
                  style: tt.titleSmall?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppEspaciado.md),
      decoration: AppSuperficies.campoBusqueda(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (nombre.isNotEmpty) fila('Nombre', nombre),
          fila('D.N.I.', b.sysdesa10_dni ?? ''),
          fila('Sexo', etiquetaSexo),
        ],
      ),
    );
  }

  void _alCargarBeneficiarioEscaneado() {
    setState(() {
      _beneficiarioEscaneado = true;
    });
  }

  void _continuarEscaneado() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const VacunasPage()),
      (Route<dynamic> route) => false,
    );
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

  /// Diálogo de confirmación + loading antes de consultar el padrón.
  /// Conserva el comportamiento previo del botón «Verificar datos».
  void _confirmarYBuscar(String dni, String? sexo) {
    showDialog(
      context: context,
      builder: (context) {
        return DialogoAlerta(
          tituloAlerta: 'Verificar datos',
          descripcionAlerta: 'D.N.I.: $dni — Sexo: $sexo',
          textoBotonAlerta: 'Verificar',
          textoBotonAlerta2: 'Cancelar',
          funcion1: () {
            obtenerDatosBeneficiario(context, dni, sexo);
            Navigator.of(context).pop();
            setState(() {
              loading = true;
            });
            retornarLoading(context, 'Espere por favor');
          },
          funcion2: () => Navigator.pop(context),
          envioFuncion1: true,
          envioFuncion2: true,
          icon: const FaIcon(FontAwesomeIcons.check, color: Colors.white),
          color: SisVacuMarca.vercelesteCuaternario,
        );
      },
    );
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
      if (!mounted) return;

      _cerrarDialogoCargaSiAbierta();

      if (notificaciones.isNotEmpty) {
        notificacionesDosisService.cargarListaDosis(notificaciones);
      } else {
        notificacionesDosisService.cargarRegistro(NotificacionesDosis());
      }

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

  Future<bool> onWillPop() async {
    final mensajeExit = await showDialog(
      context: context,
      builder: (context) => DialogoAlerta(
        envioFuncion2: true,
        envioFuncion1: true,
        tituloAlerta: '¿Cerrar sesión?',
        descripcionAlerta:
            'Si sale, deberá iniciar sesión otra vez escaneando su documento.',
        textoBotonAlerta: 'Sí, salir',
        textoBotonAlerta2: 'No',
        funcion1: () => Navigator.of(context).pop(true),
        funcion2: () => Navigator.of(context).pop(false),
        color: Theme.of(context).colorScheme.error,
        icon: const Icon(Icons.new_releases_outlined, size: 40),
      ),
    );
    return mensajeExit ?? false;
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
    final tt = Theme.of(context).textTheme;

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
                  style: tt.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  'registradas',
                  style: tt.labelSmall?.copyWith(
                    fontSize: 11,
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
                width: MediaQuery.of(context).size.width * 0.14,
                height: MediaQuery.of(context).size.width * 0.14,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: ValueListenableBuilder<modelo.CantidadVacunados?>(
                  valueListenable: cantidadVacunasService.cantidadVacunadosEstado,
                  builder: (BuildContext context, cantidadVacunados, _) {
                    if (cantidadVacunados == null) {
                      return SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      );
                    }
                    return Text(
                      cantidadVacunados.cantidad_aplicaciones!,
                      style: tt.titleMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: getValueForScreenType(
                          context: context,
                          mobile: 17,
                        ),
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
