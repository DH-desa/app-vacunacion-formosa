import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/core/helpers/helpers.dart';
import 'package:sistema_vacunacion/src/domain/entities/models.dart';
import 'package:sistema_vacunacion/src/pages/pages.dart';
import 'package:sistema_vacunacion/src/pages/vacuna/vacunas_ui_helpers.dart';
import 'package:sistema_vacunacion/src/data/datasources/providers.dart';
import 'package:sistema_vacunacion/src/data/repositories/repositories.dart';
import 'package:sistema_vacunacion/src/domain/calendario/calendario_2026.dart';
import 'package:sistema_vacunacion/src/presentation/state/services.dart';
import 'package:sistema_vacunacion/src/utils/edad_beneficiario.dart';
import 'package:sistema_vacunacion/src/widgets/widgets.dart';

class VacunasPage extends StatefulWidget {
  const VacunasPage({super.key});
  static const String nombreRuta = 'VacunasPage';
  @override
  _VacunasPageState createState() => _VacunasPageState();
}

class _VacunasPageState extends State<VacunasPage> {
  bool mostrarTutor = false;

  int pasos = 1;
  PerfilesVacunacion? _selectPerfil;
  VacunasxPerfil? _selectVacunas;

  /// Vía de registro elegida ANTES del paso 1: 'perfil' -> wizard actual
  /// (perfil → vacuna → condición → ...); 'pendientes' -> listado de
  /// wserv_listados_vacunas.php (aún sin conectar, placeholder). Son dos
  /// caminos distintos, no un filtro dentro del wizard de perfil.
  String _modoRegistro = 'pendientes';

  /// Solo aplica a la vía 'pendientes': si está activado, bloquea la
  /// selección de una dosis cuando una dosis anterior de la misma vacuna
  /// sigue pendiente (no aplicada). Habilitable/deshabilitable en pantalla.
  bool _validarOrdenDosis = true;
  VacunasCondicion? _selectCondicion;
  VacunasEsquema? _selectEsquema;
  VacunasDosis? _selectDosis;

  DateTime _selectFecha = DateTime.now();

  List<InfoVacunas>? listaVacunas;
  List<VacunasCondicion>? listaCondiciones;
  List<VacunasEsquema>? listaEsquemas;
  List<VacunasDosis>? listaDosis;
  List<Lotes>? listaLotes;
  Lotes? _selectLote;
  final TextEditingController controladorDni = TextEditingController();
  final TextEditingController controladorBusqueda = TextEditingController();
  final TextEditingController controladorBusquedaVacunas =
      TextEditingController();
  final TextEditingController controladorBusquedaCondicion =
      TextEditingController();
  final TextEditingController controladorBusquedaEsquema =
      TextEditingController();
  final TextEditingController controladorBusquedaDosis =
      TextEditingController();
  final TextEditingController controladorBusquedaLotes =
      TextEditingController();
  final TextEditingController controladorBusquedaHistorialDosis =
      TextEditingController();
  final TextEditingController controladorLoteManual = TextEditingController();
  late FocusNode focusNode;

  bool _recargandoPerfiles = false;
  bool _recargandoPendientes = false;
  bool _cargandoLotePendiente = false;
  bool _registrando = false;

  final ScrollController _generalScroll = ScrollController();

  // Scroll controllers de cada paso — a nivel de clase para evitar recreación
  // en cada rebuild (setState) y garantizar su dispose correcto.
  final ScrollController _scrollVacunas = ScrollController();
  final ScrollController _scrollCondiciones = ScrollController();
  final ScrollController _scrollEsquemas = ScrollController();

  @override
  void initState() {
    super.initState();
    mostrarTutor = false;
    pasos = 1;
    listaCondiciones = [];
    listaEsquemas = [];
    listaDosis = [];
    listaVacunas = [];
    listaLotes = [];
    focusNode = FocusNode();
    cargarPerfilesService(registradorService.registrador!.id_flxcore03!);
    _heredarPerfilDeLaVisita();
  }

  /// Si ya se eligió un perfil en una vacuna anterior de la MISMA visita
  /// (perfilesVacunacionService, ciclo persona), lo reutiliza y arranca en el
  /// paso 2 en vez de pedirlo de nuevo. Para cambiarlo, el operador vuelve al
  /// paso 1 con el stepper (ya permite retroceder) y elige otro.
  Future<void> _heredarPerfilDeLaVisita() async {
    final perfilHeredado = perfilesVacunacionService.efectores;
    if (perfilHeredado == null) return;
    setState(() {
      _selectPerfil = perfilHeredado;
      pasos = 2;
    });
    loadingLoginService.cargaPerfil(true);
    listaLotes!.clear();
    try {
      final tempLista = await vacunasxPerfiles.obtenerVacunasxPerfilesProviders(
        perfilHeredado.id_sysvacu12,
        beneficiarioService.beneficiario!.sysdesa10_dni,
        beneficiarioService.beneficiario!.sysdesa10_sexo,
      );
      if (!mounted) return;
      // `obtenerVacunasxPerfilesProviders` solo devuelve `null` (cargó bien)
      // o `0` (int) cuando el perfil no tiene vacunas configuradas — nunca
      // una `List` con `codigo_mensaje`.
      if (tempLista == 0) {
        showDialog(
          context: _scaffoldKey.currentContext!,
          builder: (dialogCtx) => DialogoAlerta(
            envioFuncion2: false,
            envioFuncion1: false,
            tituloAlerta: 'Sin vacunas configuradas',
            descripcionAlerta:
                'El perfil "${perfilHeredado.sysvacu12_descripcion}" no tiene vacunas configuradas.',
            textoBotonAlerta: 'Listo',
            icon: const Icon(Icons.error_outline, size: 40),
            color: Theme.of(dialogCtx).colorScheme.error,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      showDialog(
        context: _scaffoldKey.currentContext!,
        builder: (dialogCtx) => DialogoAlerta(
          envioFuncion2: false,
          envioFuncion1: false,
          tituloAlerta: 'Sin conexión',
          descripcionAlerta:
              'No se pudieron cargar las vacunas del perfil. Revise la red e intente de nuevo.',
          textoBotonAlerta: 'Listo',
          icon: const Icon(Icons.wifi_off_rounded, size: 40),
          color: Theme.of(dialogCtx).colorScheme.error,
        ),
      );
    } finally {
      // Pase lo que pase (éxito, sin vacunas, o error de red) el spinner de
      // paso 2 tiene que apagarse: si no, `containerVacunas()` queda
      // colgado en `LoadingEstrellas()` para siempre.
      if (mounted) loadingLoginService.cargaPerfil(false);
    }
  }

  @override
  void dispose() {
    _generalScroll.dispose();
    _scrollVacunas.dispose();
    _scrollCondiciones.dispose();
    _scrollEsquemas.dispose();
    focusNode.dispose();
    controladorDni.dispose();
    controladorBusqueda.dispose();
    controladorBusquedaLotes.dispose();
    controladorBusquedaVacunas.dispose();
    controladorBusquedaCondicion.dispose();
    controladorBusquedaEsquema.dispose();
    controladorBusquedaDosis.dispose();
    controladorBusquedaHistorialDosis.dispose();
    controladorLoteManual.dispose();
    super.dispose();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Ancla para el banner de alerta de tutor: `Scrollable.ensureVisible`
  /// scrollea hasta acá al tocarlo, sin necesidad de que el operador busque.
  final GlobalKey _tutorSectionKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) onWillPop(_scaffoldKey.currentContext ?? context);
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: cs.surface,
        appBar: AppBarSesion(
          titulo: 'Vacunas',
          leading: Center(
            child: IconButton(
              style: IconButton.styleFrom(
                foregroundColor: cs.onPrimary,
                backgroundColor: cs.onPrimary.withValues(alpha: 0.2),
              ),
              tooltip: 'Historial de dosis aplicadas',
              onPressed: _mostrarHistorialDosis,
              icon: const FaIcon(FontAwesomeIcons.hospitalUser, size: 20),
            ),
          ),
          actions: [
            IconButton(
              style: IconButton.styleFrom(
                foregroundColor: cs.onPrimary,
                backgroundColor: cs.onPrimary.withValues(alpha: 0.2),
              ),
              tooltip: 'Calendario de vacunación sugerido',
              onPressed: _mostrarCalendarioSheet,
              icon: const Icon(Icons.calendar_month_outlined, size: 20),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _bannerIdentidad(),
                _bannerAlertaTutor(),
                Expanded(
                  child: RawScrollbar(
                    thumbColor: cs.primary.withValues(alpha: 0.42),
                    thumbVisibility: true,
                    radius: const Radius.circular(AppEspaciado.radioBoton),
                    thickness: 6,
                    controller: _generalScroll,
                    child: SingleChildScrollView(
                      controller: _generalScroll,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppEspaciado.lg,
                        AppEspaciado.sm,
                        AppEspaciado.lg,
                        AppEspaciado.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          VacunasPanelFlujo(
                            pasoActual: pasos,
                            onIrAPaso: (p) {
                              // Vía "Pendientes": no hay editor por-campo para Vacuna
                              // (containerVacunas depende del perfil, que acá nunca se
                              // eligió). Igual que "Cambiar" en containerVerificar,
                              // reabrir Vacuna vuelve al paso 1 (lista de pendientes).
                              final destino =
                                  (_modoRegistro == 'pendientes' && p == 2)
                                  ? 1
                                  : p;
                              setState(() {
                                _limpiarDesdePaso(destino);
                                pasos = destino;
                              });
                            },
                            // Vía "Pendientes": el pendiente elegido precarga vacuna,
                            // condición, esquema y dosis; Condición/Esquema/Dosis/Lote
                            // quedan fijos, solo Vacuna (paso 2) sigue editable.
                            puedeIrAPaso: _modoRegistro == 'pendientes'
                                ? (p) => p == 2
                                : null,
                            perfil: _selectPerfil?.sysvacu12_descripcion,
                            vacuna: _selectVacunas?.sysvacu04_nombre,
                            condicion: _selectCondicion?.sysvacu01_descripcion,
                            esquema: _selectEsquema?.sysvacu02_descripcion,
                            dosis: _selectDosis?.sysvacu05_nombre,
                            fecha: pasos > 6
                                ? '${_selectFecha.day.toString().padLeft(2, '0')}/${_selectFecha.month.toString().padLeft(2, '0')}/${_selectFecha.year}'
                                : null,
                            lote: _selectLote?.sysdesa18_lote,
                            nombrePasoOverride:
                                (_modoRegistro == 'pendientes' && pasos == 1)
                                ? 'Pendientes'
                                : null,
                            pasoActualDisplay: _modoRegistro == 'pendientes'
                                ? _pasoMostradoPendientes(pasos)
                                : null,
                            totalPasosDisplay: _modoRegistro == 'pendientes'
                                ? 3
                                : null,
                            child: containerPasos(),
                          ),
                          const SizedBox(height: AppEspaciado.md),
                          _seccionVacunasVisita(),
                          KeyedSubtree(
                            key: _tutorSectionKey,
                            child: containerTutor(),
                          ),
                          SizedBox(
                            height:
                                MediaQuery.paddingOf(context).bottom +
                                AppEspaciado.xl,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_registrando) _overlayRegistrando(),
          ],
        ),
        bottomNavigationBar: _barraAccionesFija(cs),
      ),
    );
  }

  /// Overlay de carga mientras se envía el registro al backend (antes vivía
  /// en `ConfirmarDatos._loadingOverlay`, antes de fusionar esa pantalla acá).
  Widget _overlayRegistrando() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      color: cs.scrim.withValues(alpha: 0.82),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppEspaciado.md),
            Text(
              'Espere, por favor…',
              style: tt.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Banner fijo (fuera del scroll) con nombre · D.N.I. de la persona en
  /// pantalla. Siempre visible sin costar espacio del formulario: una sola
  /// línea. Tocar abre el detalle completo en un bottom sheet
  /// (`_mostrarDetalleBeneficiarioSheet`); no reemplaza a `containerBeneficiario`,
  /// que sigue más abajo con el resto de datos y la situación editable.
  Widget _bannerIdentidad() {
    final b = beneficiarioService.beneficiario;
    if (b == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    final nombre = [
      b.sysdesa10_nombre,
      b.sysdesa10_apellido,
    ].where((s) => (s ?? '').trim().isNotEmpty).join(' ').trim();
    final dni = b.sysdesa10_dni?.trim() ?? '';
    final etiqueta = [
      if (nombre.isNotEmpty) nombre,
      if (dni.isNotEmpty) 'DNI $dni',
    ].join(' · ');
    final esMenor = _beneficiarioRequierePanelTutor();

    return Material(
      color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
      child: InkWell(
        onTap: _mostrarDetalleBeneficiarioSheet,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppEspaciado.lg,
            vertical: AppEspaciado.sm,
          ),
          child: Row(
            children: [
              Icon(Icons.badge_outlined, size: 16, color: cs.primary),
              const SizedBox(width: AppEspaciado.sm),
              Expanded(
                child: Text(
                  etiqueta.isNotEmpty ? etiqueta : 'Beneficiario',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bar.textoChip.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ),
              if (esMenor) ...[
                const SizedBox(width: AppEspaciado.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppEspaciado.sm,
                    vertical: AppEspaciado.xs,
                  ),
                  decoration: BoxDecoration(
                    color: cs.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'MENOR',
                    style: bar.etiquetaSeccion.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.tertiary,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: AppEspaciado.xs),
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Banner fijo de alerta: menor sin tutor cargado. Tocar scrollea hasta el
  /// panel de tutor (`_tutorSectionKey`) en vez de obligar a bajar a ciegas.
  Widget _bannerAlertaTutor() {
    if (beneficiarioService.beneficiario == null) {
      return const SizedBox.shrink();
    }
    final requiere = _beneficiarioRequierePanelTutor();
    final tut = tutorService.tutor;
    final yaCargado = tut != null && _tutorTieneDocumentoCargado(tut);
    if (!requiere || yaCargado) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    return Material(
      color: cs.errorContainer.withValues(alpha: 0.35),
      child: InkWell(
        onTap: () {
          final ctx = _tutorSectionKey.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(
              ctx,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppEspaciado.lg,
            vertical: AppEspaciado.sm,
          ),
          child: Row(
            children: [
              Icon(Icons.family_restroom_outlined, size: 16, color: cs.error),
              const SizedBox(width: AppEspaciado.sm),
              Expanded(
                child: Text(
                  'Menor de edad: falta cargar el tutor',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: bar.textoChip.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.error,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: cs.error),
            ],
          ),
        ),
      ),
    );
  }

  /// Barra fija de acciones (fuera del scroll): "Cancelar" siempre disponible
  /// + la acción de avance del paso actual cuando ese paso la tiene (Fecha
  /// carga lotes; Verificar registra). El resto de los pasos avanza solo con
  /// tocar una opción de la lista, sin botón propio — pero el botón de avance
  /// se muestra siempre, deshabilitado, para que la barra nunca cambie de
  /// alto ni de ancho relativo entre pasos.
  Widget _barraAccionesFija(ColorScheme cs) {
    final String? etiquetaAvance;
    final VoidCallback? alAvanzar;
    if (pasos == 6) {
      etiquetaAvance = 'Continuar';
      alAvanzar = _cargarLotesYAvanzar;
    } else if (pasos == 7 && _fechaFueraDeRangoLotes) {
      etiquetaAvance = 'Continuar';
      alAvanzar = _confirmarLoteManual;
    } else if (pasos == 8) {
      etiquetaAvance = 'Registrar';
      alAvanzar = _registrando ? null : _alPresionarContinuarRegistro;
    } else {
      etiquetaAvance = null;
      alAvanzar = null;
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppEspaciado.lg,
          AppEspaciado.sm,
          AppEspaciado.lg,
          AppEspaciado.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: AppBotones.estiloOutlinedPeligro(cs),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar'),
                onPressed: _registrando
                    ? null
                    : () => _mostrarDialogoCancelarRegistro(cs),
              ),
            ),
            const SizedBox(width: AppEspaciado.sm),
            Expanded(
              child: FilledButton(
                style: AppBotones.estiloFilledPrimario(cs),
                onPressed: alAvanzar,
                child: Text(etiquetaAvance ?? 'Continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarHistorialDosis() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppEspaciado.radioCampo),
        ),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.52,
          minChildSize: 0.32,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return vacunasAplicadas(scrollController: scrollController);
          },
        );
      },
    );
  }

  /// Calendario sugerido (`VacunasCalendarioFiltradas`, solo informativo) en
  /// bottom sheet: antes era el bloque más alto de la página, siempre
  /// expandido en el medio del flujo, compitiendo con el formulario por
  /// espacio.
  void _mostrarCalendarioSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppEspaciado.radioCampo),
        ),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return _calendarioSheetContenido(
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  Widget _calendarioSheetContenido({ScrollController? scrollController}) {
    if (!beneficiarioService.existeBeneficiario) {
      return Padding(
        padding: const EdgeInsets.all(AppEspaciado.lg),
        child: Text(
          'Cargue un beneficiario para ver el calendario sugerido.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppEspaciado.lg,
        AppEspaciado.sm,
        AppEspaciado.lg,
        AppEspaciado.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: AppEspaciado.xs,
              decoration: BoxDecoration(
                color: cs.outlineVariant.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(AppEspaciado.xs),
              ),
            ),
          ),
          const SizedBox(height: AppEspaciado.radioCampo),
          VacunasCalendarioFiltradas(resultado: clasificarBeneficiarioActual()),
        ],
      ),
    );
  }

  /// Detalle completo del beneficiario en bottom sheet, abierto desde el
  /// banner de identidad fijo. Único lugar con el detalle completo y la
  /// situación editable (antes duplicados en `containerBeneficiario`, una
  /// tarjeta que competía por espacio con el formulario en el scroll).
  void _mostrarDetalleBeneficiarioSheet() {
    final b = beneficiarioService.beneficiario;
    if (b == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppEspaciado.radioCampo),
        ),
      ),
      builder: (BuildContext dialogCtx) {
        final cs = Theme.of(dialogCtx).colorScheme;
        final bar = context.sisTipografia;
        final filasDetalle = _filasDetalleBeneficiario(context, b);
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppEspaciado.lg,
                AppEspaciado.md,
                AppEspaciado.lg,
                AppEspaciado.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: AppEspaciado.xs,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(AppEspaciado.xs),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppEspaciado.radioCampo),
                  Text(
                    'Beneficiario',
                    style: bar.tituloTarjeta.copyWith(color: cs.onSurface),
                  ),
                  const SizedBox(height: AppEspaciado.lg),
                  for (final fila in filasDetalle) ...[
                    fila,
                    const SizedBox(height: AppEspaciado.md),
                  ],
                  const SizedBox(height: AppEspaciado.sm),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: AppEspaciado.lg),
                  _bloqueSituacionInline(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Diálogo de «Cancelar registro» con dos destinos distintos: descartar
  /// solo la vacuna en curso (conserva beneficiario/tutor de la visita) o
  /// salir del todo a buscar otra persona. Antes solo existía el segundo,
  /// perdiendo la persona por cancelar una vacuna.
  void _mostrarDialogoCancelarRegistro(ColorScheme cs) {
    showDialog<void>(
      context: _scaffoldKey.currentContext!,
      builder: (BuildContext dialogCtx) => DialogoAlerta(
        tituloAlerta: 'Cancelar registro',
        descripcionAlerta:
            '¿Qué querés hacer con los datos no guardados de esta vacuna?',
        icon: Icon(Icons.warning_amber_rounded, size: AppTamanoIcono.grande),
        color: cs.error,
        accionesExtra: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            style: AppBotones.estiloOutlined(cs),
            child: const Text('Volver'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const BusquedaBeneficiario(),
                ),
                (Route<dynamic> route) => false,
              );
            },
            style: AppBotones.estiloOutlined(cs),
            child: const Text('Salir y buscar otra persona'),
          ),
        ],
        textoBotonAlerta: 'Eliminar esta vacuna',
        funcion1: () {
          Navigator.of(dialogCtx).pop();
          reiniciarCicloVacuna();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const VacunasPage()),
            (Route<dynamic> route) => false,
          );
        },
      ),
    );
  }

  Widget containerPasos() {
    // 1 -> Perfiles // 2 -> Vacuna // 3 -> Condicion // 4 -> Esquema // 5 -> Dosis // 6 -> Fecha // 7 -> Lote // 8 -> Verificar
    final Widget child;
    switch (pasos) {
      case 1:
        child = _paso1Via();
        break;
      case 2:
        child = containerVacunas();
        break;
      case 3:
        child = containerCondiciones();
        break;
      case 4:
        child = containerEsquemas();
        break;
      case 5:
        child = containerDosis();
        break;
      case 6:
        child = containerFecha();
        break;
      case 7:
        child = containerLotes();
        break;
      case 8:
        child = containerVerificar();
        break;
      default:
        child = containerPerfiles();
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey<int>(pasos), child: child),
    );
  }

  Widget vacunasAplicadas({ScrollController? scrollController}) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppEspaciado.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppEspaciado.sm),
          Center(
            child: Container(
              width: 44,
              height: AppEspaciado.xs,
              decoration: BoxDecoration(
                color: cs.outlineVariant.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(AppEspaciado.xs),
              ),
            ),
          ),
          const SizedBox(height: AppEspaciado.radioCampo),
          Text(
            'Historial de dosis',
            style: bar.tituloTarjeta.copyWith(color: cs.onSurface),
          ),
          const SizedBox(height: AppEspaciado.xs),
          Text(
            'Beneficiario en pantalla · solo lectura',
            style: bar.textoSecundario.copyWith(
              fontWeight: FontWeight.w600,
              color: AppSuperficies.textoSecundario(context),
            ),
          ),
          Container(
            decoration: AppSuperficies.campoBusqueda(context),
            clipBehavior: Clip.antiAlias,
            child: TextField(
              autocorrect: false,
              controller: controladorBusquedaHistorialDosis,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: cs.onSurfaceVariant,
                ),
                focusedBorder: InputBorder.none,
                border: InputBorder.none,
                hintText: 'Buscar vacuna…',
                hintStyle: bar.textoDestacado.copyWith(
                  fontWeight: FontWeight.w400,
                  color: AppSuperficies.textoSecundario(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppEspaciado.lg),
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controladorBusquedaHistorialDosis,
              builder: (BuildContext context, textoBusqueda, _) {
                return ValueListenableBuilder<List<InsertRegistros>>(
                  valueListenable: insertRegistroService.visitaRegistrosEstado,
                  builder: (BuildContext context, visitaRegistros, _) {
                    return ValueListenableBuilder<List<NotificacionesDosis>>(
                      valueListenable:
                          notificacionesDosisService.listaDosisAplicadasEstado,
                      builder: (BuildContext context, historialCompleto, _) {
                        // Única fuente del historial previo:
                        // `wserv_listados_vacunas` (`vacunas_aplicadas`), la
                        // misma que ya se consulta en cada carga de
                        // beneficiario. `obtener_aplicaciones_beneficiario`
                        // se dejó de usar acá: para el DNI 53790032 devolvía
                        // solo 12 de las 42 aplicaciones reales.
                        // Se combina con lo aplicado en esta visita (memoria,
                        // siempre al día), sin duplicar si el backend ya
                        // llegó a reflejar el mismo registro (misma dosis +
                        // vacuna + fecha).
                        final filasVisita = visitaRegistros
                            .map(
                              (r) => (
                                titulo: '${r.nombreDosis} · ${r.nombreVacuna}',
                                fecha: r.fecha_aplicacion ?? '',
                              ),
                            )
                            .toList();
                        final filasHistorial = historialCompleto
                            .map(
                              (d) => (
                                titulo:
                                    '${d.sysvacu05_nombre} · ${d.sysvacu04_nombre}',
                                fecha: d.sysdesa10_fecha_aplicacion ?? '',
                              ),
                            )
                            .where(
                              (fh) => !filasVisita.any(
                                (fv) =>
                                    fv.titulo == fh.titulo &&
                                    fv.fecha == fh.fecha,
                              ),
                            )
                            .toList();
                        final consulta = textoBusqueda.text
                            .trim()
                            .toLowerCase();
                        final filas = [...filasVisita, ...filasHistorial]
                            .where(
                              (f) =>
                                  consulta.isEmpty ||
                                  f.titulo.toLowerCase().contains(consulta),
                            )
                            .toList();
                        return filas.isNotEmpty
                            ? ListView.builder(
                                controller: scrollController,
                                padding: EdgeInsets.only(
                                  bottom:
                                      AppEspaciado.xl +
                                      MediaQuery.of(context).padding.bottom,
                                ),
                                itemCount: filas.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final fila = filas[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppEspaciado.sm,
                                    ),
                                    child: Material(
                                      color: cs.surfaceContainerHighest
                                          .withValues(alpha: 0.55),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppEspaciado.radioCampo,
                                        ),
                                        side: BorderSide(
                                          color: cs.outlineVariant.withValues(
                                            alpha: 0.38,
                                          ),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                          AppEspaciado.md,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              fila.titulo,
                                              style: bar.textoDestacado.copyWith(
                                                height: 1.25,
                                                color: cs.onSurface,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: AppEspaciado.sm,
                                            ),
                                            Text(
                                              'Aplicación ${fila.fecha}',
                                              style: bar.textoSecundario.copyWith(
                                                color:
                                                    AppSuperficies.textoSecundario(
                                                      context,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    AppEspaciado.xl,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.vaccines_outlined,
                                        size: AppTamanoIcono.extraGrande,
                                        color: cs.onSurfaceVariant.withValues(
                                          alpha: 0.65,
                                        ),
                                      ),
                                      const SizedBox(height: AppEspaciado.md),
                                      Text(
                                        'Sin dosis registradas',
                                        textAlign: TextAlign.center,
                                        style: bar.subtituloTarjeta.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: AppEspaciado.sm),
                                      Text(
                                        'Cuando existan aplicaciones previas, aparecerán aquí.',
                                        textAlign: TextAlign.center,
                                        style: bar.textoPrincipal.copyWith(
                                          height: 1.35,
                                          color: AppSuperficies.textoSecundario(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _decoracionTarjetaIdentidadVacunas() {
    final cs = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppEspaciado.radioCampo),
      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      boxShadow: [
        BoxShadow(
          color: cs.shadow.withValues(alpha: 0.08),
          blurRadius: 22,
          offset: const Offset(0, 10),
          spreadRadius: -6,
        ),
      ],
    );
  }

  Widget _encabezadoIdentidadColapsable({
    required IconData icono,
    required String rol,
    required String nombreDestacado,
    String? lineaContexto,
    required bool expandido,
    required VoidCallback onAlternar,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppEspaciado.radioCampo),
        onTap: onAlternar,
        child: Padding(
          padding: const EdgeInsets.all(AppEspaciado.xs),
          child: VacunasEncabezadoAcento(
            icono: icono,
            color: cs.primary,
            etiqueta: rol,
            titulo: nombreDestacado,
            subtitulo: lineaContexto,
            trailing: Icon(
              expandido ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: cs.onSurfaceVariant,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  /// No muestra filas con cadena vacía; [ceroEsVacio] para C.U.I.L. / trámite cuando el API manda "0".
  bool _beneficiarioValorVisible(String? valor, {bool ceroEsVacio = false}) {
    final t = valor?.trim() ?? '';
    if (t.isEmpty) return false;
    if (ceroEsVacio && t == '0') return false;
    return true;
  }

  List<Widget> _filasDetalleBeneficiario(BuildContext context, Beneficiario b) {
    final bar = context.sisTipografia;
    final filas = <Widget>[];
    void agregar(String etiqueta, String? valor, {bool ceroEsVacio = false}) {
      if (!_beneficiarioValorVisible(valor, ceroEsVacio: ceroEsVacio)) return;
      filas.add(_filaDatoBeneficiario(etiqueta, valor!.trim()));
    }

    agregar('Nombre', b.sysdesa10_nombre);
    agregar('Apellido', b.sysdesa10_apellido);
    agregar('D.N.I.', b.sysdesa10_dni);
    final sexoRaw = b.sysdesa10_sexo?.trim();
    if (sexoRaw != null && sexoRaw.isNotEmpty) {
      agregar('Sexo registrado', _sexoRegistradoLegible(sexoRaw));
    }
    final fnDni = beneficiarioService.fechaNacimientoDesdePdf417Escaneado;
    if (fnDni != null && fnDni.trim().isNotEmpty) {
      filas.add(_filaDatoBeneficiario('Fecha de nacimiento', fnDni.trim()));
    } else {
      agregar('Fecha de nacimiento', b.sysdesa10_fecha_nacimiento);
    }
    final edadDni = beneficiarioService.edadAniosDesdePdf417Escaneado;
    if (edadDni != null && edadDni.trim().isNotEmpty) {
      filas.add(_filaDatoBeneficiario('Edad', '${edadDni.trim()} años'));
    } else if (_beneficiarioValorVisible(b.sysdesa10_edad)) {
      filas.add(
        _filaDatoBeneficiario('Edad', '${b.sysdesa10_edad!.trim()} años'),
      );
    }
    agregar('C.U.I.L.', b.sysdesa10_cuil, ceroEsVacio: true);
    agregar('N.º de trámite', b.sysdesa10_nro_tramite, ceroEsVacio: true);

    if (filas.isEmpty) {
      filas.add(
        Text(
          'Sin datos de identificación',
          style: bar.textoPrincipal.copyWith(
            height: 1.35,
            color: AppSuperficies.textoSecundario(context),
          ),
        ),
      );
    }
    return filas;
  }

  List<Widget> _filasDetalleTutor(BuildContext context, Tutor t) {
    final bar = context.sisTipografia;
    final filas = <Widget>[];
    void agregar(String etiqueta, String? valor) {
      if (!_beneficiarioValorVisible(valor)) return;
      filas.add(_filaDatoBeneficiario(etiqueta, valor!.trim()));
    }

    agregar('Nombre', t.sysdesa10_nombre_tutor);
    agregar('Apellido', t.sysdesa10_apellido_tutor);
    agregar('D.N.I.', t.sysdesa10_dni_tutor);
    final sexoRaw = t.sysdesa10_sexo_tutor?.trim();
    if (sexoRaw != null && sexoRaw.isNotEmpty) {
      agregar('Sexo registrado', _sexoRegistradoLegible(sexoRaw));
    }

    if (filas.isEmpty) {
      filas.add(
        Text(
          'Sin datos del tutor',
          style: bar.textoPrincipal.copyWith(
            height: 1.35,
            color: AppSuperficies.textoSecundario(context),
          ),
        ),
      );
    }
    return filas;
  }

  String _sexoRegistradoLegible(String? codigo) {
    if (codigo == null || codigo.trim().isEmpty) return '—';
    switch (codigo.trim().toUpperCase()) {
      case 'M':
        return 'Masculino';
      case 'F':
        return 'Femenino';
      default:
        return codigo;
    }
  }

  /// Situación editable sin volver a buscar al beneficiario: antes solo se
  /// fijaba en `BusquedaBeneficiario`/`EscanerDni` y no había forma de
  /// corregirla si el operador se enteraba de la condición ya en `VacunasPage`
  /// (única salida previa: cancelar el registro entero). Vive dentro del
  /// cuerpo colapsable de `containerBeneficiario`: es un atributo de la
  /// persona, no un bloque aparte.
  Widget _bloqueSituacionInline() {
    final b = beneficiarioService.beneficiario;
    if (b == null) return const SizedBox.shrink();
    final sexoEsFemenino = b.sysdesa10_sexo == 'F';
    return ValueListenableBuilder<CondicionGestacional?>(
      valueListenable: situacionBeneficiarioService.condicionGestacionalEstado,
      builder: (BuildContext context, condicion, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: situacionBeneficiarioService.esPersonalDeSaludEstado,
          builder: (BuildContext context, esPersonalDeSalud, _) {
            return SituacionBeneficiario(
              sexoEsFemenino: sexoEsFemenino,
              condicion: condicion,
              esPersonalDeSalud: esPersonalDeSalud,
              personalSaludEditable: false,
              onCondicionChanged: (c) =>
                  situacionBeneficiarioService.cargarSituacion(
                    condicionGestacional: c,
                    esPersonalDeSalud: esPersonalDeSalud,
                  ),
              onPersonalSaludChanged: (v) =>
                  situacionBeneficiarioService.cargarSituacion(
                    condicionGestacional: condicion,
                    esPersonalDeSalud: v,
                  ),
            );
          },
        );
      },
    );
  }

  /// Vacunas ya registradas con éxito en esta visita (ciclo persona): línea
  /// compacta que al tocarla abre el bottom sheet de historial
  /// (`_mostrarHistorialDosis`, ya incluye las de esta visita tras
  /// refrescarse en `_refrescarHistorialDosis`).
  Widget _seccionVacunasVisita() {
    return ValueListenableBuilder<List<InsertRegistros>>(
      valueListenable: insertRegistroService.visitaRegistrosEstado,
      builder: (BuildContext context, visita, _) {
        if (visita.isEmpty) return const SizedBox.shrink();
        final cs = Theme.of(context).colorScheme;
        final bar = context.sisTipografia;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppEspaciado.sm),
          child: Material(
            color: cs.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppEspaciado.radioCampo),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppEspaciado.radioCampo),
              onTap: _mostrarHistorialDosis,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppEspaciado.md,
                  vertical: AppEspaciado.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: cs.primary,
                    ),
                    const SizedBox(width: AppEspaciado.sm),
                    Expanded(
                      child: Text(
                        '${visita.length} aplicada${visita.length == 1 ? '' : 's'} en esta visita',
                        style: bar.textoChip.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _filaDatoBeneficiario(String etiqueta, String valor) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppEspaciado.lg,
        vertical: AppEspaciado.md + AppEspaciado.xs,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppEspaciado.lg),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 12,
            child: Text(
              etiqueta,
              style: bar.textoChip.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                height: 1.3,
                color: AppSuperficies.textoSecundario(context),
              ),
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: bar.textoDestacado.copyWith(
                height: 1.35,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const double _alturaListaPaso = 280;

  Widget _scrollbarConTema({
    required ScrollController controller,
    required Widget child,
  }) {
    final cs = Theme.of(context).colorScheme;
    return RawScrollbar(
      thumbVisibility: true,
      thickness: 5,
      radius: const Radius.circular(AppEspaciado.radioBoton),
      thumbColor: cs.primary.withValues(alpha: 0.42),
      controller: controller,
      child: child,
    );
  }

  Widget _tarjetaOpcionFila({
    required bool seleccionado,
    required String titulo,
    String? subtitulo,
    required VoidCallback onTap,
    bool fueraDeLimite = false,
    bool deshabilitado = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    final advertencia = cs.brightness == Brightness.dark
        ? Colors.amber.shade300
        : Colors.amber.shade800;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppEspaciado.sm),
      child: Material(
        color: seleccionado
            ? cs.primaryContainer.withValues(alpha: 0.5)
            : cs.surfaceContainerHighest.withValues(alpha: 0.42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppEspaciado.lg),
          side: BorderSide(
            color: fueraDeLimite
                ? advertencia
                : seleccionado
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: 0.4),
            width: seleccionado || fueraDeLimite ? 1.5 : 1,
          ),
        ),
        child: Opacity(
          opacity: deshabilitado ? 0.5 : 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppEspaciado.lg),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppEspaciado.md,
                vertical: AppEspaciado.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: bar.textoDestacado.copyWith(
                            fontWeight: seleccionado
                                ? FontWeight.w800
                                : FontWeight.w600,
                            height: 1.25,
                            color: cs.onSurface,
                          ),
                        ),
                        if (subtitulo != null) ...[
                          const SizedBox(height: AppEspaciado.xs),
                          Text(
                            subtitulo,
                            style: bar.textoChip.copyWith(
                              fontWeight: FontWeight.w400,
                              color: AppSuperficies.textoSecundario(context),
                            ),
                          ),
                        ],
                        if (fueraDeLimite) ...[
                          const SizedBox(height: AppEspaciado.xs),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: advertencia,
                              ),
                              const SizedBox(width: AppEspaciado.xs),
                              Text(
                                'Fuera de límite',
                                style: bar.etiquetaSeccion.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: advertencia,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    deshabilitado
                        ? Icons.lock_outline_rounded
                        : Icons.chevron_right_rounded,
                    color: seleccionado
                        ? cs.primary
                        : cs.onSurfaceVariant.withValues(alpha: 0.45),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tutor dado de alta con D.N.I.
  bool _tutorTieneDocumentoCargado(Tutor? t) {
    if (t == null) return false;
    final dni = t.sysdesa10_dni_tutor?.trim() ?? '';
    return dni.isNotEmpty;
  }

  /// Tarjeta colapsable del tutor ya validado (solo datos).
  Widget _columnaTarjetaTutor(Tutor tut) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Builder(
          builder: (context) {
            final n = tut.sysdesa10_nombre_tutor?.trim() ?? '';
            final a = tut.sysdesa10_apellido_tutor?.trim() ?? '';
            final sub = [n, a].where((s) => s.isNotEmpty).join(' ');
            final nombreTutor = sub.isNotEmpty
                ? sub
                : 'Sin nombre en el registro';
            final dniT = tut.sysdesa10_dni_tutor?.trim() ?? '';
            final lineaTutor = dniT.isNotEmpty
                ? 'Documento $dniT'
                : 'Tutor o responsable';
            final cs = Theme.of(context).colorScheme;
            final filasT = _filasDetalleTutor(context, tut);
            final bloquesT = <Widget>[];
            for (var i = 0; i < filasT.length; i++) {
              if (i > 0) {
                bloquesT.add(const SizedBox(height: AppEspaciado.md));
              }
              bloquesT.add(filasT[i]);
            }
            return Container(
              clipBehavior: Clip.antiAlias,
              decoration: _decoracionTarjetaIdentidadVacunas(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeInUpBig(
                    from: 14,
                    duration: const Duration(milliseconds: 380),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppEspaciado.lg,
                        AppEspaciado.lg,
                        AppEspaciado.md,
                        AppEspaciado.md,
                      ),
                      child: _encabezadoIdentidadColapsable(
                        icono: Icons.family_restroom_outlined,
                        rol: 'Tutor o responsable',
                        nombreDestacado: nombreTutor,
                        lineaContexto: lineaTutor,
                        expandido: mostrarTutor,
                        onAlternar: () {
                          setState(() {
                            mostrarTutor = !mostrarTutor;
                          });
                        },
                      ),
                    ),
                  ),
                  if (mostrarTutor)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppEspaciado.lg,
                        0,
                        AppEspaciado.lg,
                        AppEspaciado.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: cs.outlineVariant.withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: AppEspaciado.lg),
                          ...bloquesT,
                          const SizedBox(height: AppEspaciado.lg),
                          OutlinedButton.icon(
                            style: AppBotones.estiloOutlinedAccion(cs),
                            onPressed: () {
                              setState(() {
                                tutorService.reiniciar();
                                mostrarTutor = false;
                              });
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Cambiar tutor'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppEspaciado.lg),
      ],
    );
  }

  /// Menor o edad desconocida: **siempre** se muestra el formulario aunque ya haya
  /// un tutor en memoria (evita que un D.N.I. residual oculte el registro).
  Widget containerTutor() {
    if (beneficiarioService.beneficiario == null) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<Tutor?>(
      valueListenable: tutorService.tutorEstado,
      builder: (BuildContext context, Tutor? tut, _) {
        final requiereRegistroTutor = _beneficiarioRequierePanelTutor();

        if (!requiereRegistroTutor) {
          if (tut != null && _tutorTieneDocumentoCargado(tut)) {
            return _columnaTarjetaTutor(tut);
          }
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (tut != null && _tutorTieneDocumentoCargado(tut)) ...[
              _columnaTarjetaTutor(tut),
              const SizedBox(height: AppEspaciado.md),
            ],
            if (tut == null || !_tutorTieneDocumentoCargado(tut))
              _panelRegistroTutorMenor(context),
          ],
        );
      },
    );
  }

  /// Sin perfiles: mensaje claro y reintentar.
  Widget _vacunasPaso1SinPerfiles() {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    final detalle = perfilesVacunacionService.mensajeListaPerfilesVacia;
    final texto =
        detalle ??
        'No hay perfiles de vacunación asignados a su usuario en este momento. '
            'Si cree que es un error, contacte a su supervisor o intente cargar de nuevo.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const VacunasTituloSeccionPaso(
          etiqueta: 'PASO 1',
          titulo: 'Perfil de vacunación',
          subtitulo: 'Elija el contexto del registro (campaña o estrategia).',
        ),
        Container(
          padding: const EdgeInsets.all(AppEspaciado.lg),
          decoration: AppSuperficies.tarjeta(
            context,
            radio: AppEspaciado.radioCampo,
          ),
          child: Column(
            children: [
              Icon(Icons.assignment_late_outlined, size: 48, color: cs.primary),
              const SizedBox(height: AppEspaciado.md),
              Text(
                texto,
                textAlign: TextAlign.center,
                style: bar.textoDestacado.copyWith(
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppEspaciado.lg),
              FilledButton.icon(
                style: AppBotones.estiloFilledIconCta(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppEspaciado.xl,
                    vertical: AppEspaciado.lg,
                  ),
                ),
                onPressed: _recargandoPerfiles
                    ? null
                    : _reintentarCargaPerfiles,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar carga'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _reintentarCargaPerfiles() async {
    final id = registradorService.registrador?.id_flxcore03;
    if (id == null || id.isEmpty) return;
    setState(() => _recargandoPerfiles = true);
    try {
      await cargarPerfilesService(id);
    } finally {
      if (mounted) setState(() => _recargandoPerfiles = false);
    }
  }

  /// Reintento de la vía "Pendientes": misma llamada que ya repuebla el
  /// historial y `vacunasPendientesService` (`_refrescarHistorialDosis`).
  /// Si el servidor responde bien, `marcarError` se limpia solo dentro de
  /// `cargarListaPendientes`.
  Future<void> _reintentarCargaPendientes() async {
    setState(() => _recargandoPendientes = true);
    await _refrescarHistorialDosis();
    if (mounted) setState(() => _recargandoPendientes = false);
  }

  /// La vía "pendientes" reutiliza los pasos compartidos del wizard
  /// "por perfil" (7=Lote, 8=Confirmar) pero saltando directo del paso 1 a
  /// Lote — no pasa por Fecha (6): la fecha de aplicación siempre es la del
  /// momento del registro, no editable. Son solo 3 pasos reales, no 8.
  /// Mapeo único de paso real -> posición mostrada, para no repetir esta
  /// cuenta en cada lugar que muestra "PASO X" (header, títulos de sección,
  /// navegación).
  int _pasoMostradoPendientes(int pasoReal) {
    const mapa = {1: 1, 7: 2, 8: 3};
    return mapa[pasoReal] ?? pasoReal;
  }

  /// Etiqueta "PASO X" para los pasos 6/7/8, compartidos entre las dos vías:
  /// en 'pendientes' usa la numeración de 4 pasos; en 'perfil', la de 8 tal
  /// cual estaba (sin sufijo "DE 8", como el resto de los títulos de paso).
  String _etiquetaPasoCompartido(int pasoReal) {
    if (_modoRegistro == 'pendientes') {
      return 'PASO ${_pasoMostradoPendientes(pasoReal)} DE 4';
    }
    return 'PASO $pasoReal';
  }

  /// Bifurcación previa al paso 1: elegir la vía de registro. 'perfil' sigue
  /// el wizard actual (perfil → vacuna → condición → ...); 'pendientes' usa
  /// el listado de `wserv_listados_vacunas.php` (aún sin conectar).
  Widget _paso1Via() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'perfil',
              label: Text('Por perfil'),
              icon: Icon(Icons.list_alt_rounded),
            ),
            ButtonSegment(
              value: 'pendientes',
              label: Text('Pendientes'),
              icon: Icon(Icons.pending_actions_rounded),
            ),
          ],
          selected: {_modoRegistro},
          onSelectionChanged: (s) => setState(() => _modoRegistro = s.first),
        ),
        const SizedBox(height: AppEspaciado.md),
        _modoRegistro == 'pendientes'
            ? _listaVacunasPendientes()
            : containerPerfiles(),
      ],
    );
  }

  /// Vía "Pendientes": lee `vacunas_pendientes` de `wserv_listados_vacunas.php`
  /// (ya bajado junto con el historial al cargar el beneficiario, ver
  /// `vacunasPendientesService`). Al tocar una, precarga vacuna/condición/
  /// esquema/dosis con los datos que ya trae el pendiente y salta directo al
  /// paso 6 (Fecha) — esa combinación ya viene resuelta, no hace falta
  /// repreguntarla.
  Widget _listaVacunasPendientes() {
    return ValueListenableBuilder<String?>(
      valueListenable: vacunasPendientesService.mensajeErrorEstado,
      builder: (BuildContext context, mensajeError, _) {
        return ValueListenableBuilder<List<VacunaPendiente>>(
          valueListenable: vacunasPendientesService.listaPendientesEstado,
          builder: (BuildContext context, lista, _) =>
              _contenidoListaPendientes(lista, mensajeError),
        );
      },
    );
  }

  Widget _contenidoListaPendientes(
    List<VacunaPendiente> listaCompleta,
    String? mensajeError,
  ) {
    if (_recargandoPendientes || _cargandoLotePendiente) {
      return const LoadingEstrellas();
    }
    // Fuera de límite (aplicacion_dentro_limite == 0) no se ofrece para
    // registrar desde acá: no bloquea la vía "Vacuna" (paso 2), solo esta
    // lista de pendientes.
    final lista = listaCompleta
        .where((p) => p.aplicacion_dentro_limite != 0)
        .toList();
    if (lista.isEmpty) {
      // Distingue "está al día" (sin mensaje de error) de "no se pudo
      // consultar" (con mensaje): en este último caso no hay que decirle al
      // operador que no tiene nada pendiente, sino dejarlo reintentar.
      if (mensajeError != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _avisoPendientes(mensajeError, Icons.wifi_off_rounded),
            const SizedBox(height: AppEspaciado.md),
            OutlinedButton.icon(
              style: AppBotones.estiloOutlinedSecundario(),
              onPressed: _reintentarCargaPendientes,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        );
      }
      return _avisoPendientes(
        'No hay vacunas pendientes registradas para esta persona.',
        Icons.check_circle_outline,
      );
    }
    // Agrupadas por vacuna y con sus dosis consecutivas en orden (1ra, 2da,
    // 3er... Refuerzo al final).
    final ordenada = [...lista]
      ..sort((a, b) {
        final vacunaA = (a.sysvacu04_nombre ?? '').toLowerCase();
        final vacunaB = (b.sysvacu04_nombre ?? '').toLowerCase();
        final comparacionVacuna = vacunaA.compareTo(vacunaB);
        if (comparacionVacuna != 0) return comparacionVacuna;
        final ordenA = _ordenDosisPendiente(a.sysvacu05_nombre) ?? 0;
        final ordenB = _ordenDosisPendiente(b.sysvacu05_nombre) ?? 0;
        return ordenA.compareTo(ordenB);
      });
    final consulta = controladorBusquedaVacunas.text.trim().toLowerCase();
    final filtrada = consulta.isEmpty
        ? ordenada
        : ordenada
              .where(
                (p) =>
                    (p.sysvacu04_nombre ?? '').toLowerCase().contains(consulta),
              )
              .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: AppSuperficies.campoBusqueda(context),
          clipBehavior: Clip.antiAlias,
          child: TextField(
            autocorrect: false,
            controller: controladorBusquedaVacunas,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              focusedBorder: InputBorder.none,
              border: InputBorder.none,
              hintText: 'Buscar vacuna…',
              hintStyle: context.sisTipografia.textoDestacado.copyWith(
                fontWeight: FontWeight.w400,
                color: AppSuperficies.textoSecundario(context),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: AppEspaciado.md),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _validarOrdenDosis,
          onChanged: (v) => setState(() => _validarOrdenDosis = v),
          title: Text(
            'Controlar orden de dosis',
            style: context.sisTipografia.textoSecundario.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Bloquea una dosis si la anterior de esa vacuna sigue pendiente',
            style: context.sisTipografia.etiquetaSeccion.copyWith(
              letterSpacing: 0,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: AppEspaciado.sm),
        if (filtrada.isEmpty)
          _avisoPendientes(
            'No hay vacunas pendientes que coincidan con "$consulta".',
            Icons.search_off_rounded,
          ),
        ...filtrada.map((p) {
          final seleccionado =
              _selectVacunas?.id_sysvacu04 == p.rela_sysvacu04 &&
              _selectDosis?.id_sysvacu05 == p.rela_sysvacu05;
          final bloqueada = _dosisBloqueadaPorOrden(p, lista);
          return _tarjetaOpcionFila(
            seleccionado: seleccionado,
            titulo: p.sysvacu04_nombre ?? 'Vacuna',
            subtitulo: [
              if ((p.sysvacu05_nombre ?? '').isNotEmpty) p.sysvacu05_nombre!,
              if ((p.sysvacu01_descripcion ?? '').isNotEmpty)
                p.sysvacu01_descripcion!,
            ].join(' · '),
            deshabilitado: bloqueada,
            onTap: bloqueada
                ? () => _avisarDosisBloqueada(p)
                : () => _seleccionarPendiente(p),
          );
        }),
        if (filtrada.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppEspaciado.xs),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${filtrada.length} '
                '${filtrada.length == 1 ? 'vacuna' : 'vacunas'}',
                style: context.sisTipografia.etiquetaSeccion.copyWith(
                  letterSpacing: 0,
                  fontWeight: FontWeight.w400,
                  color: AppSuperficies.textoSecundario(context),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Orden de una dosis a partir de su nombre ("1ra Dosis" -> 1, "Refuerzo"
  /// -> orden alto, después de cualquier dosis numerada). "Unica Dosis" no
  /// tiene dosis previa, no se evalúa.
  int? _ordenDosisPendiente(String? nombre) {
    final n = (nombre ?? '').toLowerCase();
    if (n.contains('unica')) return null;
    final match = RegExp(r'(\d+)').firstMatch(n);
    if (match != null) return int.parse(match.group(1)!);
    if (n.contains('refuerzo')) return 999;
    return null;
  }

  /// true si, con el switch activado, existe otra dosis pendiente de la
  /// misma vacuna con orden menor (todavía no aplicada).
  bool _dosisBloqueadaPorOrden(VacunaPendiente p, List<VacunaPendiente> lista) {
    if (!_validarOrdenDosis) return false;
    final orden = _ordenDosisPendiente(p.sysvacu05_nombre);
    if (orden == null) return false;
    return lista.any((o) {
      if (o.rela_sysvacu04 != p.rela_sysvacu04) return false;
      if (o.rela_sysvacu05 == p.rela_sysvacu05) return false;
      final ordenOtra = _ordenDosisPendiente(o.sysvacu05_nombre);
      return ordenOtra != null && ordenOtra < orden;
    });
  }

  void _avisarDosisBloqueada(VacunaPendiente p) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Falta aplicar una dosis anterior de ${p.sysvacu04_nombre ?? 'esta vacuna'} '
          'antes de registrar "${p.sysvacu05_nombre}". '
          'Podés desactivar "Controlar orden de dosis" para forzarlo.',
        ),
      ),
    );
  }

  Widget _avisoPendientes(String texto, IconData icono) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppEspaciado.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppEspaciado.radioCampo),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: cs.onSurfaceVariant),
          const SizedBox(height: AppEspaciado.sm),
          Text(
            texto,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// Vía "Pendientes": no pasa por el paso de Fecha (6), no editable acá —
  /// siempre la fecha del momento del registro. Dispara `_cargarLotesYAvanzar`
  /// (misma validación de lotes que la vía "por perfil") en vez de solo
  /// cambiar `pasos`, así también contempla vacunas con fecha < 1/1/2025 sin
  /// lotes registrados. Mientras carga, `_contenidoListaPendientes` muestra
  /// el spinner en lugar de la lista.
  Future<void> _seleccionarPendiente(VacunaPendiente p) async {
    listaLotes!.clear();
    setState(() {
      _selectVacunas = VacunasxPerfil(
        id_sysvacu04: p.rela_sysvacu04,
        sysvacu04_nombre: p.sysvacu04_nombre,
      );
      _selectCondicion = VacunasCondicion(
        id_sysvacu01: p.rela_sysvacu01,
        sysvacu01_descripcion: p.sysvacu01_descripcion,
      );
      _selectEsquema = VacunasEsquema(
        id_sysvacu02: p.rela_sysvacu02,
        sysvacu02_descripcion: p.sysvacu02_descripcion,
      );
      _selectDosis = VacunasDosis(
        id_sysvacu05: p.rela_sysvacu05,
        sysvacu05_nombre: p.sysvacu05_nombre,
      );
      _selectFecha = DateTime.now();
      _cargandoLotePendiente = true;
    });
    await _cargarLotesYAvanzar();
    if (mounted) setState(() => _cargandoLotePendiente = false);
  }

  Widget containerPerfiles() {
    return ValueListenableBuilder<List<PerfilesVacunacion>>(
      valueListenable: perfilesVacunacionService.listaPerfilesVacunacionEstado,
      builder: (BuildContext context, lista, _) {
        if (_recargandoPerfiles) {
          return const LoadingEstrellas();
        }
        if (lista.isEmpty) {
          return _vacunasPaso1SinPerfiles();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const VacunasTituloSeccionPaso(
              etiqueta: 'PASO 1',
              titulo: 'Perfil de vacunación',
              subtitulo:
                  'Elija el contexto del registro (campaña o estrategia).',
            ),
            Wrap(
              spacing: AppEspaciado.sm,
              runSpacing: AppEspaciado.sm,
              children: lista.map((perfil) {
                return FilterChip(
                  label: Text(perfil.sysvacu12_descripcion!),
                  selected: _selectPerfil == perfil,
                  showCheckmark: true,
                  onSelected: (_) async {
                    loadingLoginService.cargaPerfil(true);
                    listaLotes!.clear();
                    setState(() {
                      _selectPerfil = perfil;
                      // Cambiar de perfil invalida toda la selección
                      // posterior: si no se limpia, el header puede seguir
                      // mostrando (y dejando tocar) chips de Condición/
                      // Esquema/Dosis/Lote de la vacuna anterior.
                      _limpiarDesdePaso(2);
                    });
                    // Perfil de la visita: se hereda en la próxima vacuna de
                    // la misma persona (ver _heredarPerfilDeLaVisita).
                    perfilesVacunacionService.cargarPerfilesVacu(perfil);
                    try {
                      final tempLista = await vacunasxPerfiles
                          .obtenerVacunasxPerfilesProviders(
                            perfil.id_sysvacu12,
                            beneficiarioService.beneficiario!.sysdesa10_dni,
                            beneficiarioService.beneficiario!.sysdesa10_sexo,
                          );
                      if (!mounted) return;
                      // `obtenerVacunasxPerfilesProviders` solo devuelve
                      // `null` (cargó bien) o `0` (int, sin vacunas
                      // configuradas) — nunca una `List`.
                      if (tempLista == 0) {
                        showDialog(
                          context: _scaffoldKey.currentContext!,
                          builder: (dialogCtx) => DialogoAlerta(
                            envioFuncion2: false,
                            envioFuncion1: false,
                            tituloAlerta: 'Sin vacunas configuradas',
                            descripcionAlerta:
                                'El perfil "${perfil.sysvacu12_descripcion}" no tiene vacunas configuradas.',
                            textoBotonAlerta: 'Listo',
                            icon: const Icon(Icons.error_outline, size: 40),
                            color: Theme.of(dialogCtx).colorScheme.error,
                          ),
                        );
                      } else {
                        setState(() => pasos++);
                      }
                    } catch (_) {
                      if (!mounted) return;
                      showDialog(
                        context: _scaffoldKey.currentContext!,
                        builder: (dialogCtx) => DialogoAlerta(
                          envioFuncion2: false,
                          envioFuncion1: false,
                          tituloAlerta: 'Sin conexión',
                          descripcionAlerta:
                              'No se pudieron cargar las vacunas del perfil. Revise la red e intente de nuevo.',
                          textoBotonAlerta: 'Listo',
                          icon: const Icon(Icons.wifi_off_rounded, size: 40),
                          color: Theme.of(dialogCtx).colorScheme.error,
                        ),
                      );
                    } finally {
                      if (mounted) loadingLoginService.cargaPerfil(false);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  /// Limpia las selecciones de los pasos posteriores a [pasoDestino] (2 a 7)
  /// al volver atrás en el wizard (header, "Cambiar", elegir un perfil o una
  /// vacuna distintos). Evita que un chip viejo (p. ej. Esquema/Dosis/Lote
  /// de la vacuna anterior) quede visible y tocable junto a una selección
  /// nueva, mezclando datos de dos vacunas distintas en el registro.
  void _limpiarDesdePaso(int pasoDestino) {
    if (pasoDestino <= 1) _selectVacunas = null;
    if (pasoDestino <= 2) _selectCondicion = null;
    if (pasoDestino <= 3) _selectEsquema = null;
    if (pasoDestino <= 4) _selectDosis = null;
    if (pasoDestino <= 5) {
      _selectLote = null;
      listaLotes!.clear();
      controladorLoteManual.clear();
    }
  }

  /// Antes del 1/1/2025 no se registró el lote de cada aplicación: no hay
  /// nada que listar. En vez de la lista de lotes, se habilita un input
  /// manual (serie del lote si el operador la tiene, "0" por defecto si no).
  bool get _fechaFueraDeRangoLotes =>
      _selectFecha.isBefore(DateTime(2025, 1, 1));

  /// Paso 2 — seleccionar vacuna y avanzar al paso de condición.
  Future<void> _seleccionarVacuna(VacunasxPerfil v) async {
    setState(() {
      _selectVacunas = v;
      _limpiarDesdePaso(2);
      controladorBusqueda.clear();
    });
    try {
      final ben = beneficiarioService.beneficiario!;
      final edadEscaneo = beneficiarioService.edadAniosDesdePdf417Escaneado
          ?.trim();
      final edadParam = (edadEscaneo != null && edadEscaneo.isNotEmpty)
          ? edadEscaneo
          : (ben.sysdesa10_edad?.trim().isNotEmpty == true
                ? ben.sysdesa10_edad!.trim()
                : '');
      final tempLista = await vacunasRepository.obtenerCondicionesProviders(
        _selectVacunas!.id_sysvacu04,
        edadParam.isNotEmpty ? edadParam : ben.sysdesa10_edad,
      );
      if (!mounted) return;
      if (tempLista[0].codigo_mensaje == "0") {
        showDialog(
          context: _scaffoldKey.currentContext!,
          builder: (dialogCtx) => DialogoAlerta(
            envioFuncion2: false,
            envioFuncion1: false,
            tituloAlerta: 'No se pudieron cargar las condiciones',
            descripcionAlerta: tempLista[0].mensaje,
            textoBotonAlerta: 'Listo',
            icon: const Icon(Icons.error_outline, size: 40),
            color: Theme.of(dialogCtx).colorScheme.error,
          ),
        );
      } else {
        if (loadingLoginService.getLoadingCondicionState!) {
          mostrarLoadingEstrellasXTiempo(context, 800);
        }
        setState(() {
          listaCondiciones = tempLista;
          vacunasCondicionService.cargarListaVacunasCondicion(tempLista);
          pasos++;
        });
      }
    } catch (_) {
      if (!mounted) return;
      showDialog(
        context: _scaffoldKey.currentContext!,
        builder: (dialogCtx) => DialogoAlerta(
          envioFuncion2: false,
          envioFuncion1: false,
          tituloAlerta: 'Sin conexión',
          descripcionAlerta:
              'No se pudieron cargar las condiciones. Revise la red e intente de nuevo.',
          textoBotonAlerta: 'Listo',
          icon: const Icon(Icons.wifi_off_rounded, size: 40),
          color: Theme.of(dialogCtx).colorScheme.error,
        ),
      );
    } finally {
      // Pase lo que pase, apaga el spinner: si no, paso 3 queda colgado.
      if (mounted) loadingLoginService.cargarCondicion(false);
    }
  }

  /// Paso 3 — seleccionar condición y avanzar al paso de esquema.
  Future<void> _seleccionarCondicion(VacunasCondicion cond) async {
    listaEsquemas!.clear();
    setState(() {
      _selectCondicion = cond;
      _limpiarDesdePaso(3);
      controladorBusquedaCondicion.clear();
    });
    try {
      final tempLista = await vacunasRepository.obtenerEsquemasProviders(
        _selectVacunas!.id_sysvacu04!,
        _selectCondicion!.id_sysvacu01,
      );
      if (!mounted) return;
      if (tempLista[0].codigo_mensaje == "0") {
        showDialog(
          context: _scaffoldKey.currentContext!,
          builder: (dialogCtx) => DialogoAlerta(
            envioFuncion2: false,
            envioFuncion1: false,
            tituloAlerta: 'No se pudieron cargar los esquemas',
            descripcionAlerta: tempLista[0].mensaje,
            textoBotonAlerta: 'Listo',
            icon: const Icon(Icons.error_outline, size: 40),
            color: Theme.of(dialogCtx).colorScheme.error,
          ),
        );
      } else {
        if (loadingLoginService.getLoadingEsquemaState!) {
          mostrarLoadingEstrellasXTiempo(context, 800);
        }
        setState(() {
          listaEsquemas = tempLista;
          vacunasEsquemaService.cargarListavacunasEsquema(tempLista);
          pasos++;
        });
      }
    } catch (_) {
      if (!mounted) return;
      showDialog(
        context: _scaffoldKey.currentContext!,
        builder: (dialogCtx) => DialogoAlerta(
          envioFuncion2: false,
          envioFuncion1: false,
          tituloAlerta: 'Sin conexión',
          descripcionAlerta:
              'No se pudieron cargar los esquemas. Revise la red e intente de nuevo.',
          textoBotonAlerta: 'Listo',
          icon: const Icon(Icons.wifi_off_rounded, size: 40),
          color: Theme.of(dialogCtx).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) loadingLoginService.cargarEsquema(false);
    }
  }

  /// Paso 4 — seleccionar esquema y avanzar al paso de dosis.
  Future<void> _seleccionarEsquema(VacunasEsquema esq) async {
    setState(() {
      _selectEsquema = esq;
      _limpiarDesdePaso(4);
      controladorBusquedaEsquema.clear();
    });
    try {
      final tempLista = await vacunasRepository.obtenerDosisProviders(
        _selectVacunas!.id_sysvacu04!,
        _selectCondicion!.id_sysvacu01!,
        _selectEsquema!.id_sysvacu02!,
      );
      if (!mounted) return;
      if (tempLista[0].codigo_mensaje == "0") {
        showDialog(
          context: _scaffoldKey.currentContext!,
          builder: (dialogCtx) => DialogoAlerta(
            envioFuncion2: false,
            envioFuncion1: false,
            tituloAlerta: 'No se pudieron cargar las dosis',
            descripcionAlerta: tempLista[0].mensaje,
            textoBotonAlerta: 'Listo',
            icon: const Icon(Icons.error_outline, size: 40),
            color: Theme.of(dialogCtx).colorScheme.error,
          ),
        );
      } else {
        if (loadingLoginService.getLoadingDosisState!) {
          mostrarLoadingEstrellasXTiempo(context, 800);
        }
        setState(() {
          listaDosis = tempLista;
          vacunasDosisService.cargarListaVacunasDosis(tempLista);
          pasos++;
        });
      }
    } catch (_) {
      if (!mounted) return;
      showDialog(
        context: _scaffoldKey.currentContext!,
        builder: (dialogCtx) => DialogoAlerta(
          envioFuncion2: false,
          envioFuncion1: false,
          tituloAlerta: 'Sin conexión',
          descripcionAlerta:
              'No se pudieron cargar las dosis. Revise la red e intente de nuevo.',
          textoBotonAlerta: 'Listo',
          icon: const Icon(Icons.wifi_off_rounded, size: 40),
          color: Theme.of(dialogCtx).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) loadingLoginService.cargarDosis(false);
    }
  }

  Widget containerVacunas() {
    return ValueListenableBuilder<bool>(
      valueListenable: loadingLoginService.cargaPerfilEstado,
      builder: (BuildContext context, cargaPerfil, _) {
        return cargaPerfil
            ? const LoadingEstrellas()
            : ValueListenableBuilder<List<VacunasxPerfil>>(
                valueListenable:
                    vacunasxPerfilService.listavacunasxperfilEstado,
                builder: (BuildContext context, listaVacunasxPerfil, _) {
                  return listaVacunasxPerfil.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const VacunasTituloSeccionPaso(
                              etiqueta: 'PASO 2',
                              titulo: 'Vacuna',
                              subtitulo:
                                  'Busque por nombre o elija una opción de la lista.',
                            ),
                            _listaVacunasPorPerfil(listaVacunasxPerfil),
                          ],
                        )
                      : const SizedBox.shrink();
                },
              );
      },
    );
  }

  Widget _listaVacunasPorPerfil(List<VacunasxPerfil> listaVacunasxPerfil) {
    final bar = context.sisTipografia;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: AppSuperficies.campoBusqueda(context),
          clipBehavior: Clip.antiAlias,
          child: TextField(
            autocorrect: false,
            controller: controladorBusqueda,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.search_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              focusedBorder: InputBorder.none,
              border: InputBorder.none,
              hintText: 'Buscar vacuna…',
              hintStyle: bar.textoDestacado.copyWith(
                fontWeight: FontWeight.w400,
                color: AppSuperficies.textoSecundario(context),
              ),
            ),
            focusNode: focusNode,
            onChanged: (value) {
              vacunasxPerfilService.buscarVacuna(value.toUpperCase());
              if (value.length >= 3) {
                focusNode.unfocus();
              }
            },
          ),
        ),
        const SizedBox(height: AppEspaciado.md),
        ValueListenableBuilder<List<VacunasxPerfil>>(
          valueListenable:
              vacunasxPerfilService.listavacunasxperfilBusquedaEstado,
          builder: (BuildContext context, listaBusquedaVacunas, _) {
            return controladorBusqueda.text.isEmpty
                ? SizedBox(
                    height: _alturaListaPaso,
                    child: _scrollbarConTema(
                      controller: _scrollVacunas,
                      child: ListView.builder(
                        controller: _scrollVacunas,
                        physics: const BouncingScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: listaVacunasxPerfil.length,
                        itemBuilder: (BuildContext context, int index) {
                          final v = listaVacunasxPerfil[index];
                          return _tarjetaOpcionFila(
                            seleccionado: _selectVacunas == v,
                            titulo: v.sysvacu04_nombre!,
                            onTap: () => _seleccionarVacuna(v),
                          );
                        },
                      ),
                    ),
                  )
                : SizedBox(
                    height: _alturaListaPaso,
                    child: _scrollbarConTema(
                      controller: _scrollVacunas,
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: listaBusquedaVacunas.length,
                        itemBuilder: (BuildContext context, int index) {
                          final v = listaBusquedaVacunas[index];
                          return _tarjetaOpcionFila(
                            seleccionado: _selectVacunas == v,
                            titulo: v.sysvacu04_nombre!,
                            onTap: () => _seleccionarVacuna(v),
                          );
                        },
                      ),
                    ),
                  );
          },
        ),
      ],
    );
  }

  Widget containerCondiciones() {
    final bar = context.sisTipografia;
    return ValueListenableBuilder<bool>(
      valueListenable: loadingLoginService.loadingCondicionEstado,
      builder: (BuildContext context, loadingCondicion, _) {
        return loadingCondicion
            ? const LoadingEstrellas()
            : ValueListenableBuilder<List<VacunasCondicion>>(
                valueListenable:
                    vacunasCondicionService.listaVacunasCondicionEstado,
                builder: (BuildContext context, listaCondicion, _) {
                  return listaCondicion.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const VacunasTituloSeccionPaso(
                              etiqueta: 'PASO 3',
                              titulo: 'Condición',
                              subtitulo:
                                  'Indicación o situación clínica asociada a la aplicación.',
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  decoration: AppSuperficies.campoBusqueda(
                                    context,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: TextField(
                                    autocorrect: false,
                                    controller: controladorBusquedaCondicion,
                                    keyboardType: TextInputType.text,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                      focusedBorder: InputBorder.none,
                                      border: InputBorder.none,
                                      hintText: 'Buscar condición…',
                                      hintStyle: bar.textoDestacado.copyWith(
                                        fontWeight: FontWeight.w400,
                                        color:
                                            AppSuperficies.textoSecundario(
                                              context,
                                            ),
                                      ),
                                    ),
                                    focusNode: focusNode,
                                    onChanged: (value) {
                                      vacunasCondicionService.buscarCondicion(
                                        value.toUpperCase(),
                                      );
                                      if (value.length >= 3) {
                                        focusNode.unfocus();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: AppEspaciado.md),
                                ValueListenableBuilder<List<VacunasCondicion>>(
                                  valueListenable: vacunasCondicionService
                                      .listaVacunasCondicionBusquedaEstado,
                                  builder: (BuildContext context, listaBusquedaCondicion, _) {
                                    return controladorBusquedaCondicion
                                            .text
                                            .isEmpty
                                        ? SizedBox(
                                            height: _alturaListaPaso,
                                            child: _scrollbarConTema(
                                              controller: _scrollCondiciones,
                                              child: ListView.builder(
                                                controller: _scrollCondiciones,
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                shrinkWrap: true,
                                                itemCount:
                                                    listaCondicion.length,
                                                itemBuilder:
                                                    (
                                                      BuildContext context,
                                                      int index,
                                                    ) {
                                                      final cond =
                                                          listaCondicion[index];
                                                      return _tarjetaOpcionFila(
                                                        seleccionado:
                                                            _selectCondicion ==
                                                            cond,
                                                        titulo: cond
                                                            .sysvacu01_descripcion!,
                                                        onTap: () =>
                                                            _seleccionarCondicion(
                                                              cond,
                                                            ),
                                                      );
                                                    },
                                              ),
                                            ),
                                          )
                                        : SizedBox(
                                            height: _alturaListaPaso,
                                            child: _scrollbarConTema(
                                              controller: _scrollCondiciones,
                                              child: ListView.builder(
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                shrinkWrap: true,
                                                itemCount:
                                                    listaBusquedaCondicion
                                                        .length,
                                                itemBuilder:
                                                    (
                                                      BuildContext context,
                                                      int index,
                                                    ) {
                                                      final cond =
                                                          listaBusquedaCondicion[index];
                                                      return _tarjetaOpcionFila(
                                                        seleccionado:
                                                            _selectCondicion ==
                                                            cond,
                                                        titulo: cond
                                                            .sysvacu01_descripcion!,
                                                        onTap: () =>
                                                            _seleccionarCondicion(
                                                              cond,
                                                            ),
                                                      );
                                                    },
                                              ),
                                            ),
                                          );
                                  },
                                ),
                              ],
                            ),
                          ],
                        )
                      : const SizedBox.shrink();
                },
              );
      },
    );
  }

  Widget containerEsquemas() {
    final bar = context.sisTipografia;
    return ValueListenableBuilder<bool>(
      valueListenable: loadingLoginService.loadingEsquemaEstado,
      builder: (BuildContext context, loadingEsquema, _) {
        return loadingEsquema
            ? const LoadingEstrellas()
            : ValueListenableBuilder<List<VacunasEsquema>>(
                valueListenable:
                    vacunasEsquemaService.listaVacunasEsquemaEstado,
                builder: (BuildContext context, listaEsquema, _) {
                  return listaEsquema.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const VacunasTituloSeccionPaso(
                              etiqueta: 'PASO 4',
                              titulo: 'Esquema',
                              subtitulo:
                                  'Calendario o pauta de aplicación para esta vacuna.',
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  decoration: AppSuperficies.campoBusqueda(
                                    context,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: TextField(
                                    autocorrect: false,
                                    controller: controladorBusquedaEsquema,
                                    keyboardType: TextInputType.text,
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                      focusedBorder: InputBorder.none,
                                      border: InputBorder.none,
                                      hintText: 'Buscar esquema…',
                                      hintStyle: bar.textoDestacado.copyWith(
                                        fontWeight: FontWeight.w400,
                                        color:
                                            AppSuperficies.textoSecundario(
                                              context,
                                            ),
                                      ),
                                    ),
                                    focusNode: focusNode,
                                    onChanged: (value) {
                                      vacunasEsquemaService.buscaresquema(
                                        value.toUpperCase(),
                                      );
                                      if (value.length >= 3) {
                                        focusNode.unfocus();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: AppEspaciado.md),
                                ValueListenableBuilder<List<VacunasEsquema>>(
                                  valueListenable: vacunasEsquemaService
                                      .listaVacunasEsquemaBusquedaEstado,
                                  builder: (BuildContext context, listaBusquedaEsquema, _) {
                                    return controladorBusquedaEsquema
                                            .text
                                            .isEmpty
                                        ? SizedBox(
                                            height: _alturaListaPaso,
                                            child: _scrollbarConTema(
                                              controller: _scrollEsquemas,
                                              child: ListView.builder(
                                                controller: _scrollEsquemas,
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                shrinkWrap: true,
                                                itemCount: listaEsquema.length,
                                                itemBuilder:
                                                    (
                                                      BuildContext context,
                                                      int index,
                                                    ) {
                                                      final esq =
                                                          listaEsquema[index];
                                                      return _tarjetaOpcionFila(
                                                        seleccionado:
                                                            _selectEsquema ==
                                                            esq,
                                                        titulo: esq
                                                            .sysvacu02_descripcion!,
                                                        onTap: () =>
                                                            _seleccionarEsquema(
                                                              esq,
                                                            ),
                                                      );
                                                    },
                                              ),
                                            ),
                                          )
                                        : SizedBox(
                                            height: _alturaListaPaso,
                                            child: _scrollbarConTema(
                                              controller: _scrollEsquemas,
                                              child: ListView.builder(
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                shrinkWrap: true,
                                                itemCount:
                                                    listaBusquedaEsquema.length,
                                                itemBuilder:
                                                    (
                                                      BuildContext context,
                                                      int index,
                                                    ) {
                                                      final esq =
                                                          listaBusquedaEsquema[index];
                                                      return _tarjetaOpcionFila(
                                                        seleccionado:
                                                            _selectEsquema ==
                                                            esq,
                                                        titulo: esq
                                                            .sysvacu02_descripcion!,
                                                        onTap: () =>
                                                            _seleccionarEsquema(
                                                              esq,
                                                            ),
                                                      );
                                                    },
                                              ),
                                            ),
                                          );
                                  },
                                ),
                              ],
                            ),
                          ],
                        )
                      : const SizedBox.shrink();
                },
              );
      },
    );
  }

  Widget containerDosis() {
    return ValueListenableBuilder<bool>(
      valueListenable: loadingLoginService.loadingDosisEstado,
      builder: (BuildContext context, loadingDosisFlag, _) {
        return loadingDosisFlag
            ? const LoadingEstrellas()
            : ValueListenableBuilder<List<VacunasDosis>>(
                valueListenable: vacunasDosisService.listaVacunasDosisEstado,
                builder: (BuildContext context, listaDosis, _) {
                  return listaDosis.isNotEmpty
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const VacunasTituloSeccionPaso(
                              etiqueta: 'PASO 5',
                              titulo: 'Dosis',
                              subtitulo:
                                  'Número o tipo de dosis según el esquema elegido.',
                            ),
                            Wrap(
                              spacing: AppEspaciado.sm,
                              runSpacing: AppEspaciado.sm,
                              children: listaDosis
                                  .map(
                                    (d) => FilterChip(
                                      label: Text(d.sysvacu05_nombre!),
                                      selected: _selectDosis == d,
                                      showCheckmark: true,
                                      onSelected: (_) {
                                        listaLotes!.clear();
                                        setState(() {
                                          _selectLote = null;
                                          _selectDosis = d;
                                          pasos++;
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        )
                      : const SizedBox.shrink();
                },
              );
      },
    );
  }

  /// Avanza de Fecha (paso 6) a Lote: valida lotes disponibles para la vacuna
  /// elegida. Hoisteado a nivel de clase (antes función local de
  /// `containerFecha`) para poder dispararlo también desde la barra de
  /// acciones fija (`_barraAccionesFija`), no solo desde un botón dentro del
  /// contenido del paso.
  /// Botón "Cambiar vacuna" de los diálogos de error de `_cargarLotesYAvanzar`.
  /// En 'pendientes' no hay editor de vacuna por-campo (ver comentario en
  /// `containerVerificar`): vuelve al paso 1 (lista de pendientes), no al 2.
  void _volverACambiarVacuna(BuildContext dialogCtx) {
    Navigator.of(dialogCtx).pop();
    final destino = _modoRegistro == 'pendientes' ? 1 : 2;
    setState(() {
      pasos = destino;
      _limpiarDesdePaso(destino);
    });
  }

  Future<void> _cargarLotesYAvanzar() async {
    if (_fechaFueraDeRangoLotes) {
      // No hay lotes registrados para aplicaciones tan viejas: se salta la
      // consulta y `containerLotes()` muestra el input manual.
      setState(() => pasos = 7);
      return;
    }
    loadingLoginService.cargaLotes(false);
    try {
      final tempLista = await vacunasRepository.validarLotes(
        _selectVacunas!.id_sysvacu04,
      );
      if (!mounted) return;
      if (tempLista.isEmpty) {
        showDialog(
          context: _scaffoldKey.currentContext!,
          builder: (dialogCtx) => DialogoAlerta(
            envioFuncion2: true,
            envioFuncion1: true,
            tituloAlerta: 'Sin lotes disponibles',
            descripcionAlerta:
                'No hay lotes registrados para esta vacuna. Seleccione otra dosis o cambie la vacuna.',
            textoBotonAlerta: 'Cambiar vacuna',
            textoBotonAlerta2: 'Cambiar dosis',
            funcion1: () => _volverACambiarVacuna(dialogCtx),
            funcion2: () => Navigator.of(dialogCtx).pop(),
            icon: const Icon(Icons.inventory_2_outlined, size: 40),
            color: Theme.of(dialogCtx).colorScheme.tertiary,
          ),
        );
        return;
      }
      if (tempLista[0].codigo_mensaje == "0") {
        showDialog(
          context: _scaffoldKey.currentContext!,
          builder: (dialogCtx) => DialogoAlerta(
            envioFuncion2: true,
            envioFuncion1: true,
            tituloAlerta: 'No se pudieron cargar los lotes',
            descripcionAlerta:
                tempLista[0].mensaje ??
                'Intente con otra dosis o cambie la vacuna.',
            textoBotonAlerta: 'Cambiar vacuna',
            textoBotonAlerta2: 'Reintentar',
            funcion1: () => _volverACambiarVacuna(dialogCtx),
            funcion2: () => Navigator.of(dialogCtx).pop(),
            icon: const Icon(Icons.error_outline, size: 40),
            color: Theme.of(_scaffoldKey.currentContext!).colorScheme.error,
          ),
        );
        return;
      }
      if (loadingLoginService.getCargaLotesState!) {
        mostrarLoadingEstrellasXTiempo(context, 800);
      }
      setState(() {
        listaLotes = tempLista;
        vacunasLotesService.cargarListaVacunasLotes(tempLista);
      });
      loadingLoginService.cargaLotes(false);
      // `pasos = 7` (no `pasos++`): reusado también desde la vía
      // "Pendientes" (`_seleccionarPendiente`), que dispara esto sin haber
      // pasado por el paso 6 (Fecha).
      setState(() => pasos = 7);
    } catch (_) {
      if (!mounted) return;
      showDialog(
        context: _scaffoldKey.currentContext!,
        builder: (dialogCtx) => DialogoAlerta(
          envioFuncion2: true,
          envioFuncion1: true,
          tituloAlerta: 'Error de conexión',
          descripcionAlerta:
              'No se pudieron obtener los lotes. Revise la conexión o cambie la vacuna.',
          textoBotonAlerta: 'Cambiar vacuna',
          textoBotonAlerta2: 'Cerrar',
          funcion1: () => _volverACambiarVacuna(dialogCtx),
          funcion2: () => Navigator.of(dialogCtx).pop(),
          color: Theme.of(dialogCtx).colorScheme.error,
          icon: const Icon(Icons.wifi_off_rounded, size: 40),
        ),
      );
    }
  }

  Widget containerFecha() {
    final cs = Theme.of(context).colorScheme;
    final fechaFmt =
        '${_selectFecha.day.toString().padLeft(2, '0')}/${_selectFecha.month.toString().padLeft(2, '0')}/${_selectFecha.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VacunasTituloSeccionPaso(
          etiqueta: _etiquetaPasoCompartido(6),
          titulo: 'Fecha de Aplicación',
          subtitulo: 'Seleccione la fecha en que se aplicó la vacuna.',
        ),
        const SizedBox(height: AppEspaciado.md),
        Container(
          padding: const EdgeInsets.all(AppEspaciado.lg),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppEspaciado.radioCampo),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: VacunasEncabezadoAcento(
            icono: Icons.calendar_today_outlined,
            color: cs.tertiary,
            etiqueta: 'Fecha seleccionada',
            titulo: fechaFmt,
            trailing: TextButton.icon(
              style: AppBotones.estiloTextoPequeno(cs),
              onPressed: () async {
                final fechaNacimiento = _fechaNacimientoBeneficiario();
                final DateTime primeraFecha =
                    fechaNacimiento != null &&
                        fechaNacimiento.isAfter(DateTime(2021))
                    ? fechaNacimiento
                    : DateTime(2021);
                final DateTime? nueva = await showDatePicker(
                  context: context,
                  initialDate: _selectFecha.isBefore(primeraFecha)
                      ? primeraFecha
                      : _selectFecha,
                  firstDate: primeraFecha,
                  lastDate: DateTime.now(),
                );
                if (nueva != null && mounted) setState(() => _selectFecha = nueva);
              },
              icon: const Icon(Icons.edit_calendar_outlined),
              label: const Text('Cambiar'),
            ),
          ),
        ),
      ],
    );
  }

  Widget containerLotes() {
    final cs = Theme.of(context).colorScheme;
    final fechaFmt =
        '${_selectFecha.day.toString().padLeft(2, '0')}/${_selectFecha.month.toString().padLeft(2, '0')}/${_selectFecha.year}';
    if (_fechaFueraDeRangoLotes) {
      return _loteManual(fechaFmt);
    }
    return ValueListenableBuilder<List<Lotes>>(
      valueListenable: vacunasLotesService.listavacunaslotesEstado,
      builder: (BuildContext context, lotesDisponibles, _) {
        return lotesDisponibles.isEmpty
            ? _sinLotesDisponibles()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VacunasTituloSeccionPaso(
                    etiqueta: _etiquetaPasoCompartido(7),
                    titulo: 'Lote',
                    subtitulo:
                        'Seleccione el lote disponible para registrar la aplicación.',
                  ),
                  if (_modoRegistro == 'pendientes') ...[
                    Container(
                      padding: const EdgeInsets.all(AppEspaciado.lg),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(
                          AppEspaciado.radioCampo,
                        ),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                      child: VacunasEncabezadoAcento(
                        icono: Icons.calendar_today_outlined,
                        color: cs.tertiary,
                        etiqueta: 'Fecha de aplicación',
                        titulo: fechaFmt,
                      ),
                    ),
                    const SizedBox(height: AppEspaciado.md),
                  ],
                  Wrap(
                    spacing: AppEspaciado.sm,
                    runSpacing: AppEspaciado.sm,
                    children: lotesDisponibles
                        .map(
                          (lote) => FilterChip(
                            label: Text(lote.sysdesa18_lote!),
                            selected: _selectLote == lote,
                            showCheckmark: true,
                            onSelected: (_) {
                              loadingLoginService.cargarVerificar(false);
                              setState(() {
                                _selectLote = lote;
                                pasos++;
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
              );
      },
    );
  }

  /// Aplicaciones con fecha anterior al 1/1/2025: no hay lote registrado en
  /// el sistema para validar contra una lista, así que se pide la serie a
  /// mano. Si el operador no la tiene, se registra con "0" (ver
  /// `_confirmarLoteManual`).
  Widget _loteManual(String fechaFmt) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VacunasTituloSeccionPaso(
          etiqueta: _etiquetaPasoCompartido(7),
          titulo: 'Lote',
          subtitulo:
              'No hay lotes registrados para aplicaciones anteriores al '
              '01/01/2025. Cargue la serie si la tiene, o continúe sin ella.',
        ),
        Container(
          padding: const EdgeInsets.all(AppEspaciado.lg),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppEspaciado.radioCampo),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VacunasEncabezadoAcento(
                icono: Icons.calendar_today_outlined,
                color: cs.tertiary,
                etiqueta: 'Fecha de aplicación',
                titulo: fechaFmt,
              ),
              const SizedBox(height: AppEspaciado.md),
              TextField(
                controller: controladorLoteManual,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Serie del lote (opcional)',
                  hintText: 'Sin serie: se registra con "0"',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Confirma el paso Lote cuando la fecha está fuera de rango (ver
  /// `_loteManual`): sin serie cargada, se registra "0".
  void _confirmarLoteManual() {
    final serie = controladorLoteManual.text.trim();
    loadingLoginService.cargarVerificar(false);
    setState(() {
      _selectLote = Lotes(
        id_sysdesa18: '0',
        sysdesa18_lote: serie.isEmpty ? '0' : serie,
      );
      pasos++;
    });
  }

  Widget _sinLotesDisponibles() {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VacunasTituloSeccionPaso(
          etiqueta: _etiquetaPasoCompartido(7),
          titulo: 'Sin lotes disponibles',
          subtitulo: 'No hay lotes registrados para la vacuna seleccionada.',
        ),
        Container(
          padding: const EdgeInsets.all(AppEspaciado.xl),
          decoration: BoxDecoration(
            color: cs.errorContainer.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(AppEspaciado.radioCampo),
            border: Border.all(color: cs.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: cs.error),
              const SizedBox(height: AppEspaciado.md),
              Text(
                'Sin lotes registrados',
                textAlign: TextAlign.center,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: AppEspaciado.sm),
              Text(
                'No hay lotes disponibles para esta vacuna. Puede cambiar la dosis o volver a seleccionar otra vacuna.',
                textAlign: TextAlign.center,
                style: bar.textoPrincipal.copyWith(
                  height: 1.4,
                  color: AppSuperficies.textoSecundario(context),
                ),
              ),
              const SizedBox(height: AppEspaciado.lg),
              if (_modoRegistro == 'pendientes')
                OutlinedButton.icon(
                  style: AppBotones.estiloOutlinedSecundario(),
                  onPressed: () => setState(() {
                    pasos = 1;
                    _limpiarDesdePaso(1);
                  }),
                  icon: const Icon(Icons.pending_actions_rounded),
                  label: const Text('Volver a pendientes'),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      style: AppBotones.estiloOutlinedSecundario(),
                      onPressed: () => setState(() {
                        pasos = 5;
                        _limpiarDesdePaso(5);
                      }),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Cambiar dosis'),
                    ),
                    const SizedBox(width: AppEspaciado.md),
                    OutlinedButton.icon(
                      style: AppBotones.estiloOutlinedSecundario(),
                      onPressed: () => setState(() {
                        pasos = 2;
                        _limpiarDesdePaso(2);
                      }),
                      icon: const Icon(Icons.vaccines_outlined),
                      label: const Text('Cambiar vacuna'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget containerVerificar() {
    final cs = Theme.of(context).colorScheme;
    Widget filaResumen(
      String etiqueta,
      String? valor,
      int paso,
      IconData icono,
    ) {
      final bar = context.sisTipografia;
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppEspaciado.md,
          vertical: AppEspaciado.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadio.radioTooltip),
              ),
              child: Icon(icono, size: AppTamanoIcono.pequeno, color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: AppEspaciado.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etiqueta,
                    style: bar.etiquetaSeccion.copyWith(
                      letterSpacing: 0.5,
                      color: AppSuperficies.textoSecundario(context),
                    ),
                  ),
                  const SizedBox(height: AppEspaciado.xs),
                  Text(
                    valor?.isNotEmpty == true ? valor! : '—',
                    style: bar.textoPrincipal.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton(
              style: AppBotones.estiloTextoPequeno(cs),
              onPressed: () => setState(() {
                _limpiarDesdePaso(paso);
                pasos = paso;
              }),
              child: const Text('Cambiar'),
            ),
          ],
        ),
      );
    }

    // En 'pendientes' la vacuna/condición/esquema/dosis se resolvieron
    // juntas al tocar una fila; no hay editor por-campo válido en esta vía
    // (containerVacunas/Condiciones/Esquemas/Dosis asumen el wizard "por
    // perfil" con sus propias listas cargadas). "Cambiar" en esas 4 filas
    // vuelve al paso 1 (la lista de pendientes) en vez de a esos pasos.
    final pasoEditarCombo = _modoRegistro == 'pendientes' ? 1 : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VacunasTituloSeccionPaso(
          etiqueta: _etiquetaPasoCompartido(8),
          titulo: 'Confirmar y registrar',
          subtitulo:
              'Revise los datos y toque "Registrar" abajo. Toque "Cambiar" en cualquier fila para corregir.',
        ),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppEspaciado.radioCampo),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vía "Pendientes" no pasa por selección de perfil: no mostrar
              // una fila "Perfil" vacía que no corresponde a ese flujo.
              if (_modoRegistro != 'pendientes') ...[
                filaResumen(
                  'Perfil',
                  _selectPerfil?.sysvacu12_descripcion,
                  1,
                  Icons.assignment_ind_outlined,
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: AppEspaciado.md,
                  endIndent: AppEspaciado.md,
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
              ],
              filaResumen(
                'Vacuna',
                _selectVacunas?.sysvacu04_nombre,
                pasoEditarCombo ?? 2,
                Icons.vaccines_outlined,
              ),
              Divider(
                height: 1,
                thickness: 1,
                indent: AppEspaciado.md,
                endIndent: AppEspaciado.md,
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
              filaResumen(
                'Condición',
                _selectCondicion?.sysvacu01_descripcion,
                pasoEditarCombo ?? 3,
                Icons.health_and_safety_outlined,
              ),
              Divider(
                height: 1,
                thickness: 1,
                indent: AppEspaciado.md,
                endIndent: AppEspaciado.md,
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
              filaResumen(
                'Esquema',
                _selectEsquema?.sysvacu02_descripcion,
                pasoEditarCombo ?? 4,
                Icons.account_tree_outlined,
              ),
              Divider(
                height: 1,
                thickness: 1,
                indent: AppEspaciado.md,
                endIndent: AppEspaciado.md,
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
              filaResumen(
                'Dosis',
                _selectDosis?.sysvacu05_nombre,
                pasoEditarCombo ?? 5,
                Icons.numbers_outlined,
              ),
              Divider(
                height: 1,
                thickness: 1,
                indent: AppEspaciado.md,
                endIndent: AppEspaciado.md,
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
              filaResumen(
                'Fecha de Aplicación',
                '${_selectFecha.day.toString().padLeft(2, '0')}/${_selectFecha.month.toString().padLeft(2, '0')}/${_selectFecha.year}',
                6,
                Icons.calendar_today_outlined,
              ),
              Divider(
                height: 1,
                thickness: 1,
                indent: AppEspaciado.md,
                endIndent: AppEspaciado.md,
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
              filaResumen(
                'Lote',
                _selectLote?.sysdesa18_lote,
                7,
                Icons.inventory_2_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Edad numérica desde el WS (`8`, `"12"`, `"8 años"`, etc.).
  /// Valores &gt; 120 se ignoran (a veces mandan año de nacimiento en el campo edad).
  int? _edadNumericaBeneficiario(String? raw) => parseEdadAnios(raw);

  /// Años cumplidos desde fecha de nacimiento si el campo edad no viene o no parsea.
  int? _edadAniosDesdeFechaNacimiento(String? raw) {
    final dt = parseFechaNacimiento(raw);
    if (dt == null) return null;
    return edadAniosDesde(dt, DateTime.now());
  }

  /// Fecha de nacimiento del beneficiario actual, misma prioridad que el
  /// clasificador de calendario (`calendario_2026.dart`): PDF417 escaneado
  /// antes que el dato del API.
  DateTime? _fechaNacimientoBeneficiario() {
    return parseFechaNacimiento(
          beneficiarioService.fechaNacimientoDesdePdf417Escaneado,
        ) ??
        parseFechaNacimiento(
          beneficiarioService.beneficiario?.sysdesa10_fecha_nacimiento,
        );
  }

  /// Panel tutor: primero edad del **DNI escaneado**; si no hay (búsqueda manual), datos del API.
  bool _beneficiarioRequierePanelTutor() {
    final b = beneficiarioService.beneficiario;
    if (b == null) return false;
    final eScan = beneficiarioService.edadAniosDesdePdf417Escaneado?.trim();
    if (eScan != null && eScan.isNotEmpty) {
      final n = int.tryParse(eScan);
      if (n != null) return n < 18;
    }
    final c = _edadNumericaBeneficiario(b.sysdesa10_edad);
    final f = _edadAniosDesdeFechaNacimiento(b.sysdesa10_fecha_nacimiento);
    if (c != null && c < 18) return true;
    if (f != null && f < 18) return true;
    if (c == null && f == null) return true;
    return false;
  }

  bool _beneficiarioSinDatoEdadParseable() {
    final esc = beneficiarioService.edadAniosDesdePdf417Escaneado?.trim();
    if (esc != null && esc.isNotEmpty) return false;
    final b = beneficiarioService.beneficiario;
    if (b == null) return true;
    final c = _edadNumericaBeneficiario(b.sysdesa10_edad);
    final f = _edadAniosDesdeFechaNacimiento(b.sysdesa10_fecha_nacimiento);
    return c == null && f == null;
  }

  /// Formulario escanear / D.N.I. / sexo del tutor (solo invocar si es menor o sin edad).
  Widget _panelRegistroTutorMenor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    final sinDatoEdad = _beneficiarioSinDatoEdadParseable();

    return FadeInUpBig(
      from: 14,
      duration: const Duration(milliseconds: 400),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: _decoracionTarjetaIdentidadVacunas(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Encabezado ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppEspaciado.lg,
                AppEspaciado.lg,
                AppEspaciado.md,
                AppEspaciado.lg,
              ),
              child: VacunasEncabezadoAcento(
                icono: Icons.family_restroom_outlined,
                color: cs.tertiary,
                etiqueta: 'Menor de edad',
                titulo: 'Tutor o responsable',
                subtitulo: 'Reverso del D.N.I. con la cámara o datos abajo.',
                trailing: IconButton(
                  tooltip: 'Ayuda: registrar tutor o responsable',
                  style: AppBotones.estiloIconoAyuda(cs),
                  onPressed: () {
                    showDialog(
                      context: _scaffoldKey.currentContext!,
                      builder: (BuildContext context) => DialogoAlerta(
                        envioFuncion2: false,
                        envioFuncion1: false,
                        tituloAlerta: 'Información',
                        descripcionAlerta:
                            'Escanee el código del D.N.I. (frente o reverso según la tarjeta) o ingrese número y sexo como en el documento.',
                        textoBotonAlerta: 'Listo',
                        color: cs.primary,
                        icon: const Icon(Icons.info_outline_rounded, size: 40),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline_rounded),
                ),
              ),
            ),

            Divider(
              height: 1,
              thickness: 1,
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),

            // ── Cuerpo ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppEspaciado.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner opcional: edad desconocida
                  if (sinDatoEdad) ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(
                          AppEspaciado.radioBoton,
                        ),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppEspaciado.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: cs.primary,
                            ),
                            const SizedBox(width: AppEspaciado.sm),
                            Expanded(
                              child: Text(
                                'No se recibió la edad desde el servidor. '
                                'Si el beneficiario es menor, cargue al tutor o '
                                'responsable; si es mayor, puede ignorar este bloque.',
                                style: bar.textoSecundario.copyWith(
                                  height: 1.35,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppEspaciado.lg),
                  ],

                  // Captura del documento del tutor (escaneo + ingreso manual)
                  FormularioDocumento(
                    tipoEscaneo: 'Tutor',
                    textoBotonEscaneo: 'Escanear',
                    anchoEscaner: 52,
                    controladorDni: controladorDni,
                    focusNode: focusNode,
                    onVerificar: (dni, sexo) =>
                        obtenerDatosBeneficiario(context, dni, sexo!),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Valida que todos los datos necesarios estén presentes antes de registrar.
  /// Devuelve el mensaje de error o null si todo está OK.
  String? _validarDatosRegistro() {
    if (beneficiarioService.beneficiario!.sysdesa10_dni == '') {
      return 'Hubo un error con el Beneficiario';
    }
    if (_beneficiarioRequierePanelTutor() && !tutorService.existeTutor) {
      return 'El beneficiario es menor de edad. Debe cargar los datos del Tutor';
    }
    if (_selectVacunas == null) return 'Debe seleccionar una Vacuna';
    if (_selectCondicion == null) return 'Debe seleccionar una Condición';
    if (_selectEsquema == null) return 'Debe seleccionar un Esquema';
    if (_selectDosis == null) return 'Debe seleccionar una Dosis';
    if (_selectLote == null) return 'Debe seleccionar un Lote';
    return null;
  }

  /// Compara vacuna+dosis seleccionadas contra el historial del back
  /// (`notificacionesDosisService`) y contra lo ya registrado en esta visita
  /// (`insertRegistroService.visitaRegistros`). Solo hay nombres en común
  /// entre ambas fuentes (el historial no trae ids), por eso compara por
  /// nombre, sin distinguir mayúsculas/espacios.
  bool _vacunaDosisYaAplicada() {
    final vacuna = _selectVacunas?.sysvacu04_nombre?.trim().toLowerCase();
    final dosis = _selectDosis?.sysvacu05_nombre?.trim().toLowerCase();
    if (vacuna == null || dosis == null) return false;

    bool coincide(String? v, String? d) =>
        v?.trim().toLowerCase() == vacuna && d?.trim().toLowerCase() == dosis;

    final enHistorial = notificacionesDosisService.listaDosisAplicadas.any(
      (n) => coincide(n.sysvacu04_nombre, n.sysvacu05_nombre),
    );
    final enVisita = insertRegistroService.visitaRegistros.any(
      (r) => coincide(r.nombreVacuna, r.nombreDosis),
    );
    return enHistorial || enVisita;
  }

  /// Construye el objeto InsertRegistros con o sin datos de tutor según edad.
  InsertRegistros _construirRegistro() {
    final conTutor =
        _beneficiarioRequierePanelTutor() && tutorService.existeTutor;
    return InsertRegistros(
      id_flxcore03: registradorService.registrador!.id_flxcore03,
      id_sysdesa12: vacunadorService.vacunador!.id_sysdesa12,
      id_sysdesa18: _selectLote!.id_sysdesa18,
      id_sysofic01: registradorService.registrador!.rela_sysofic01,
      id_sysvacu01: _selectCondicion!.id_sysvacu01!,
      id_sysvacu02: _selectEsquema!.id_sysvacu02!,
      id_sysvacu05: _selectDosis!.id_sysvacu05!,
      nombreVacuna: _selectVacunas!.sysvacu04_nombre,
      nombreCondicion: _selectCondicion!.sysvacu01_descripcion,
      nombreEsquema: _selectEsquema!.sysvacu02_descripcion,
      nombreDosis: _selectDosis!.sysvacu05_nombre,
      nombreLote: _selectLote!.sysdesa18_lote,
      id_sysvacu04: _selectVacunas!.id_sysvacu04,
      sysdesa10_apellido: beneficiarioService.beneficiario!.sysdesa10_apellido,
      sysdesa10_cadena_dni:
          beneficiarioService.beneficiario!.sysdesa10_cadena_dni,
      sysdesa10_dni: beneficiarioService.beneficiario!.sysdesa10_dni,
      sysdesa10_nombre: beneficiarioService.beneficiario!.sysdesa10_nombre,
      sysdesa10_nro_tramite:
          beneficiarioService.beneficiario!.sysdesa10_nro_tramite,
      sysdesa10_sexo: beneficiarioService.beneficiario!.sysdesa10_sexo,
      sysdesa10_edad: beneficiarioService.beneficiario!.sysdesa10_edad,
      fecha_aplicacion: _selectFecha.toString(),
      sysdesa10_fecha_nacimiento:
          beneficiarioService.beneficiario!.sysdesa10_fecha_nacimiento,
      vacunador_registrador:
          registradorService.registrador!.flxcore03_dni ==
              vacunadorService.vacunador!.id_sysdesa12
          ? '1'
          : '0',
      // Incluido en el POST; el backend debe leerlo cuando esté disponible.
      vacunacion_en_terreno: sesionEquipoVacunacionService.enTerreno
          ? '1'
          : '0',
      sysdesa10_apellido_tutor: conTutor
          ? tutorService.tutor!.sysdesa10_apellido_tutor
          : '',
      sysdesa10_dni_tutor: conTutor
          ? tutorService.tutor!.sysdesa10_dni_tutor
          : '',
      sysdesa10_nombre_tutor: conTutor
          ? tutorService.tutor!.sysdesa10_nombre_tutor
          : '',
      sysdesa10_sexo_tutor: conTutor
          ? tutorService.tutor!.sysdesa10_sexo_tutor
          : '',
      // La condición gestacional solo aplica a sexo femenino: se descarta acá
      // por si quedó cargada con un sexo declarado distinto al confirmado por el back.
      condicion_gestacional_beneficiario:
          beneficiarioService.beneficiario!.sysdesa10_sexo == 'F'
          ? situacionBeneficiarioService.condicionGestacional?.name
          : null,
      es_personal_salud: situacionBeneficiarioService.esPersonalDeSalud
          ? '1'
          : '0',
    );
  }

  /// Acción de la barra fija en el paso 8. Antes navegaba a una pantalla
  /// aparte (`ConfirmarDatos`) que repetía el mismo resumen de la vacuna y
  /// las mismas tarjetas de beneficiario/tutor ya vistas — dos revisiones
  /// idénticas seguidas. El paso 8 pasa a ser directamente la pantalla de
  /// confirmación y registro: valida, avisa si la vacuna ya figura aplicada,
  /// y si el operador confirma, registra.
  void _alPresionarContinuarRegistro() {
    final error = _validarDatosRegistro();
    if (error != null) {
      showDialog(
        context: _scaffoldKey.currentContext!,
        builder: (dialogCtx) => DialogoAlerta(
          envioFuncion2: false,
          envioFuncion1: false,
          tituloAlerta: 'Faltan datos para continuar',
          descripcionAlerta: error,
          textoBotonAlerta: 'Listo',
          icon: const Icon(Icons.error_outline, size: 40),
          color: Theme.of(dialogCtx).colorScheme.error,
        ),
      );
      return;
    }
    if (_vacunaDosisYaAplicada()) {
      showDialog(
        context: _scaffoldKey.currentContext!,
        builder: (dialogCtx) => DialogoAlerta(
          dosBotones: true,
          envioFuncion1: true,
          envioFuncion2: true,
          funcion1: () {
            Navigator.of(dialogCtx).pop();
            _registrarVacunacion();
          },
          funcion2: () => Navigator.of(dialogCtx).pop(),
          tituloAlerta: 'Vacuna ya registrada',
          descripcionAlerta:
              'Esta vacuna y dosis ya figuran aplicadas para esta persona '
              '(historial o esta misma visita). ¿Continuar igual?',
          textoBotonAlerta: 'Continuar igual',
          textoBotonAlerta2: 'Volver',
          icon: const Icon(Icons.warning_amber_rounded, size: 40),
          color: Theme.of(dialogCtx).colorScheme.error,
        ),
      );
      return;
    }
    _registrarVacunacion();
  }

  /// Recarga el historial de dosis del beneficiario en memoria tras un
  /// registro exitoso, para que la vacuna recién aplicada aparezca antes de
  /// cargar la siguiente de la misma visita. Misma llamada que
  /// `busquedabeneficiario_page.dart:378-390`. Si falla, sigue el flujo: el
  /// historial queda con los datos previos, no bloquea la carga de otra vacuna.
  Future<void> _refrescarHistorialDosis() async {
    final b = beneficiarioService.beneficiario;
    if (b == null) return;
    try {
      final condicion = situacionBeneficiarioService.condicionGestacional;
      final notificaciones = await sistemaRepository.validarNotificaciones(
        b.sysdesa10_dni,
        b.sysdesa10_sexo,
        embarazada: condicion == CondicionGestacional.embarazada,
        puerpera: condicion == CondicionGestacional.puerpera,
        personalSalud: situacionBeneficiarioService.esPersonalDeSalud,
        edadDias: beneficiarioService.diasDeVidaBeneficiario,
      );
      if (notificaciones.isNotEmpty) {
        notificacionesDosisService.cargarListaDosis(notificaciones);
      } else {
        notificacionesDosisService.cargarRegistro(NotificacionesDosis());
      }
    } catch (_) {
      // Sin conexión: se mantiene el historial cargado hasta ahora, pero
      // la vía Pendientes no puede confundir esto con "no tiene nada
      // pendiente" (misma llamada trae "vacunas_pendientes").
      vacunasPendientesService.marcarError(
        'No se pudo actualizar las vacunas pendientes. Revise la conexión.',
      );
    }
  }

  /// Envía el registro al backend. Antes vivía en `ConfirmarDatos.enviarDatos`;
  /// se trae acá porque esa pantalla dejó de existir (ver comentario arriba).
  Future<void> _registrarVacunacion() async {
    insertRegistroService.cargarRegistro(_construirRegistro());
    setState(() => _registrando = true);
    try {
      final mensaje = await sistemaRepository.insertRegistroProd();
      if (!mounted) return;
      setState(() => _registrando = false);
      if (mensaje[0].codigo_mensaje == "0") {
        showDialog(
          context: _scaffoldKey.currentContext!,
          builder: (dialogCtx) => DialogoAlerta(
            envioFuncion2: false,
            envioFuncion1: true,
            funcion1: () => Navigator.of(dialogCtx).pop(),
            tituloAlerta: 'Atención',
            descripcionAlerta: mensaje[0].mensaje,
            textoBotonAlerta: 'Reintentar',
            color: Theme.of(dialogCtx).colorScheme.error,
            icon: const Icon(Icons.error, size: 40.0),
          ),
        );
      } else {
        // Registro exitoso: queda en "vacunas de esta visita" (ciclo persona)
        // sin importar qué botón elija el operador a continuación.
        insertRegistroService.agregarRegistroVisita(
          insertRegistroService.registro!,
        );
        // Se refresca acá (no solo al elegir "otra vacuna") para que el
        // historial ya muestre la vacuna recién aplicada apenas se toque
        // el ícono/píldora de historial, sin depender de qué botón elija
        // el operador en el diálogo de éxito.
        await _refrescarHistorialDosis();
        if (!mounted) return;
        showDialog(
          context: _scaffoldKey.currentContext!,
          barrierDismissible: false,
          builder: (dialogCtx) => DialogoAlerta(
            dosBotones: true,
            envioFuncion2: true,
            funcion2: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const BusquedaBeneficiario(),
              ),
              (Route<dynamic> route) => false,
            ),
            envioFuncion1: true,
            funcion1: () {
              if (_modoRegistro == 'pendientes') {
                // No se re-navega a una VacunasPage nueva: initState()
                // corre _heredarPerfilDeLaVisita() y, como el perfil de la
                // visita ya quedó fijado, fuerza pasos=2 (paso "por perfil")
                // salteando la lista de pendientes. Se resetea en la misma
                // instancia para volver directo al paso 1 con pendientes.
                Navigator.of(dialogCtx).pop();
                reiniciarCicloVacuna();
                // `reiniciarCicloVacuna()` vacía `listaPerfilesVacunacionEstado`
                // (es de estadosPorVacuna). Como acá no hay `initState` nuevo
                // que la vuelva a pedir, si el operador después cambia a "Por
                // perfil" se queda con la lista vacía ("no se pudieron cargar
                // los perfiles") sin que haya fallado nada. Se repide ahora.
                final idRegistrador =
                    registradorService.registrador?.id_flxcore03;
                if (idRegistrador != null && idRegistrador.isNotEmpty) {
                  cargarPerfilesService(idRegistrador);
                }
                setState(() {
                  pasos = 1;
                  _selectPerfil = null;
                  _limpiarDesdePaso(1);
                });
              } else {
                reiniciarCicloVacuna();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const VacunasPage()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            tituloAlerta: 'Información',
            descripcionAlerta:
                '${mensaje[0].mensaje}\n\n¿Aplicar otra vacuna a la misma persona?',
            textoBotonAlerta: 'Sí, otra vacuna',
            textoBotonAlerta2: 'No, finalizar',
            color: Theme.of(dialogCtx).colorScheme.primary,
            icon: const Icon(Icons.check_circle, size: 40.0),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _registrando = false);
      showDialog(
        context: _scaffoldKey.currentContext!,
        builder: (dialogCtx) => DialogoAlerta(
          envioFuncion2: false,
          envioFuncion1: false,
          tituloAlerta: 'Error de conexión',
          descripcionAlerta:
              'No se pudo registrar la vacunación. Revise la conexión a internet e intente de nuevo.',
          textoBotonAlerta: 'Entendido',
          color: Theme.of(dialogCtx).colorScheme.error,
          icon: const Icon(Icons.wifi_off_rounded, size: 40),
        ),
      );
    }
  }

  /// Carga tutor desde padrón (mismo servicio que beneficiario).
  Future<void> obtenerDatosBeneficiario(
    BuildContext context1,
    String dni,
    String sexoPersona,
  ) async {
    try {
      final datosBeneficiario = await beneficiarioProviders
          .obtenerDatosBeneficiario('', dni, sexoPersona);
      if (!mounted) return;
      if (datosBeneficiario[0].codigo_mensaje == '0') {
        await showDialog<void>(
          context: _scaffoldKey.currentContext!,
          builder: (BuildContext dialogCtx) => DialogoAlerta(
            envioFuncion2: false,
            envioFuncion1: false,
            tituloAlerta: 'No se pudo validar al tutor',
            descripcionAlerta: datosBeneficiario[0].mensaje,
            textoBotonAlerta: 'Listo',
            color: Theme.of(dialogCtx).colorScheme.error,
            icon: const Icon(Icons.error_outline, size: 40),
          ),
        );
        return;
      }
      confirmarTutor(datosBeneficiario[0]);
    } catch (_) {
      if (!mounted) return;
      await showDialog<void>(
        context: _scaffoldKey.currentContext!,
        builder: (BuildContext dialogCtx) => DialogoAlerta(
          envioFuncion2: false,
          envioFuncion1: false,
          tituloAlerta: 'Sin conexión',
          descripcionAlerta:
              'No se pudieron obtener los datos del tutor. Revise la red e intente de nuevo.',
          textoBotonAlerta: 'Listo',
          color: Theme.of(dialogCtx).colorScheme.error,
          icon: const Icon(Icons.wifi_off_rounded, size: 40),
        ),
      );
    }
  }

  void confirmarTutor(Beneficiario tutor) {
    setState(() {
      tutorService.cargarTutor(Tutor.desdeBeneficiario(tutor));
    });
  }

  cargarPerfilesService(String id) async {
    await vacunasRepository.obtenerDatosPerfilesVacunacion(id);
  }
}
