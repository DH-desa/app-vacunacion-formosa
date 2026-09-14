import 'dart:async';

import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/core/helpers/helpers.dart';
import 'package:sistema_vacunacion/src/domain/entities/models.dart';
import 'package:sistema_vacunacion/src/data/repositories/repositories.dart';
import 'package:sistema_vacunacion/src/presentation/state/services.dart';
import 'package:sistema_vacunacion/src/utils/dni_input_utils.dart';
import 'package:sistema_vacunacion/src/widgets/widgets.dart';

import '../pages.dart';

/// Equipo de trabajo / vacunador.
///
/// **Pila frente al teclado (IME)** — cada capa suma; documentado para depurar jank:
/// 1. Android: `windowSoftInputMode` en el manifest (`adjustPan` vs `adjustResize`).
/// 2. [Scaffold.resizeToAvoidBottomInset]: aquí `false` para leer [MediaQuery.viewInsetsOf]
///    en el scroll y no dejar que el body consuma el inset de forma opaca al hijo.
/// 3. [_ScrollConPaddingTeclado]: `viewInsetsOf` + [Transform.translate] (evita animar
///    padding del scroll y relayoutear toda la columna por frame).
/// 4. [CustomInput] / [TextField.scrollPadding]: margen al hacer scroll al foco.
///
/// El [Scaffold] de Material sigue consultando [MediaQuery] en su propio `build`; es
/// limitación del framework, no solo de esta pantalla.
class VacunadorPage extends StatefulWidget {
  static const String nombreRuta = 'VacunadorEstablecimiento';
  final List<Usuarios?> infoCargador;

  const VacunadorPage({super.key, required this.infoCargador});

  @override
  State<VacunadorPage> createState() => _VacunadorPageState();
}

class _VacunadorPageState extends State<VacunadorPage> {
  late final ValueNotifier<bool> mismoVacunador;
  late final ValueNotifier<bool> esTerreno;

  /// Carga inicial de efectores (login / editar equipo).
  bool _efectoresCargando = true;
  String? _efectoresMensajeError;

  /// Evita rebuilds redundantes al invalidar el [Scaffold]: se cachea el valor
  /// y solo se actualiza cuando cambia el [Estado] del vacunador.
  Vacunador? _vacunadorActual;
  void _onVacunadorCambio() {
    if (mounted) setState(() => _vacunadorActual = vacunadorService.vacunador);
  }

  @override
  void initState() {
    super.initState();
    mismoVacunador = ValueNotifier<bool>(true);
    esTerreno = ValueNotifier<bool>(sesionEquipoVacunacionService.enTerreno);
    _vacunadorActual = vacunadorService.vacunador;
    vacunadorService.vacunadorEstado.addListener(_onVacunadorCambio);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarListaEfectoresInicial();
    });
  }

  @override
  void dispose() {
    // sesionEquipoVacunacionService ya se actualiza on-change del switch
    // (más abajo, _filaSwitch de "¿Es en terreno?"); escribirlo de nuevo acá
    // era una segunda fuente de verdad redundante.
    vacunadorService.vacunadorEstado.removeListener(_onVacunadorCambio);
    mismoVacunador.dispose();
    esTerreno.dispose();
    super.dispose();
  }

  Future<void> _cargarListaEfectoresInicial() async {
    if (!mounted) return;
    setState(() {
      _efectoresCargando = true;
      _efectoresMensajeError = null;
    });
    try {
      final String dni = registradorService.registrador!.flxcore03_dni!;
      await efectoresRepository.obtenerDatosEfectores(dni);
      if (!mounted) return;
      final List<Efectores> lista = efectoresService.listaEfectores;
      if (lista.isEmpty) {
        setState(() {
          _efectoresMensajeError =
              'No hay establecimientos disponibles para su usuario.';
          _efectoresCargando = false;
        });
        return;
      }
      setState(() {
        _efectoresMensajeError = null;
        _efectoresCargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _efectoresMensajeError =
            'No se pudieron cargar los establecimientos. Revise la conexión.';
        _efectoresCargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) onWillPop(context);
        },
        child: Scaffold(
          backgroundColor: cs.surface,
          // Ver doc en [VacunadorPage]: inset lo maneja [_ScrollConPaddingTeclado], no el resize del body.
          resizeToAvoidBottomInset: false,
          appBar: const AppBarSesion(titulo: 'Equipo de trabajo'),
          drawer: const BodyDrawer(),
          body: _ScrollConPaddingTeclado(
            child: RepaintBoundary(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RepaintBoundary(
                    child: _tarjetaResumenEquipo(
                      context,
                      _vacunadorActual != null,
                    ),
                  ),
                  const SizedBox(height: AppEspaciado.lg),
                  if (_vacunadorActual == null) ...[
                    RepaintBoundary(child: _tarjetaOpcionesVacunacion(context)),
                    const SizedBox(height: AppEspaciado.lg),
                  ],
                  ValueListenableBuilder<bool>(
                    valueListenable: mismoVacunador,
                    builder: (context, esMismo, _) {
                      final hayVacunador = _vacunadorActual != null;
                      if (esMismo || hayVacunador) {
                        return const SizedBox.shrink();
                      }
                      return RepaintBoundary(
                        child: _RegistroVacunadorPanel(
                          onValidarDni: verificarEsencialText,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppEspaciado.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppEspaciado.xs),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: mismoVacunador,
                      builder: (context, esMismoVacunador, _) {
                        final hayV = _vacunadorActual != null;
                        final puedeAvanzar = esMismoVacunador || hayV;
                        return BotonCustom(
                          text: puedeAvanzar
                              ? 'Siguiente'
                              : 'Asigná al vacunador para continuar',
                          enabled: puedeAvanzar,
                          onPressed: () {
                            if (!puedeAvanzar) return;
                            if (!esMismoVacunador) {
                              verificarVacunador();
                            } else {
                              vacunadorService.cargarVacunador(
                                Vacunador(
                                  id_sysdesa12: registradorService
                                      .registrador!
                                      .flxcore03_dni,
                                  sysdesa06_nombre: registradorService
                                      .registrador!
                                      .flxcore03_nombre,
                                  sysdesa06_nro_documento: registradorService
                                      .registrador!
                                      .flxcore03_dni,
                                ),
                              );
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const BusquedaBeneficiario(),
                                ),
                                (Route<dynamic> route) => false,
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _etiquetaSeccion(BuildContext context, String texto) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppEspaciado.sm, top: AppEspaciado.xs),
      child: Text(
        texto.toUpperCase(),
        style: bar.etiquetaSeccion.copyWith(
          letterSpacing: 1.05,
          color: cs.onSurfaceVariant.withValues(alpha: 0.95),
        ),
      ),
    );
  }

  Widget _tarjetaResumenEquipo(BuildContext context, bool hayVacunador) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen',
                      style: bar.tituloTarjeta.copyWith(color: cs.onSurface),
                    ),
                    const SizedBox(height: AppEspaciado.xs),
                    Text(
                      'Efector, registrador y vacunador asignado',
                      style: bar.textoSecundario.copyWith(
                        height: 1.35,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ayuda: vacunador, efector y modo en terreno',
                style: AppBotones.estiloIconoAyuda(cs),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => DialogoAlerta(
                      envioFuncion2: false,
                      envioFuncion1: false,
                      tituloAlerta: 'Información',
                      descripcionAlerta:
                          'Seleccione el interruptor si es la misma persona que registra y realiza la vacunación.\nSi corresponde, cambie el efector con el ícono del hospital.\n«En terreno» se guarda para el registro de cada vacuna aplicada.',
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
                icon: const FaIcon(FontAwesomeIcons.circleInfo, size: 20),
              ),
            ],
          ),
          if (_efectoresCargando) ...[
            const SizedBox(height: AppEspaciado.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppEspaciado.xs),
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: cs.surfaceContainerHighest,
              ),
            ),
          ],
          if (_efectoresMensajeError != null) ...[
            const SizedBox(height: AppEspaciado.md),
            Material(
              color: cs.errorContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppEspaciado.radioBoton),
              child: Padding(
                padding: const EdgeInsets.all(AppEspaciado.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.wifi_off_rounded, color: cs.error, size: 22),
                        const SizedBox(width: AppEspaciado.sm),
                        Expanded(
                          child: Text(
                            _efectoresMensajeError!,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onErrorContainer,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        style: AppBotones.estiloTexto(cs),
                        onPressed: _cargarListaEfectoresInicial,
                        child: const Text('Reintentar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppEspaciado.md),
          _etiquetaSeccion(context, 'Establecimiento'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                  child: ValueListenableBuilder<Usuarios?>(
                    valueListenable: registradorService.registradorEstado,
                    builder: (context, registrador, _) {
                      final desc = registrador?.sysofic01_descripcion ?? '';
                      return Text(
                        desc,
                        style: bar.textoFormulario.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: cs.onSurface,
                        ),
                      );
                    },
                  ),
              ),
              Material(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppEspaciado.radioBoton),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppEspaciado.radioBoton),
                  onTap: () => _abrirSelectorEfectores(context),
                  child: Padding(
                    padding: const EdgeInsets.all(AppEspaciado.md),
                    child: FaIcon(
                      FontAwesomeIcons.hospital,
                      // Tamaño fijo: sin [MediaQuery] / responsive_builder en la tarjeta (menos invalidaciones con IME).
                      size: AppTamanoIcono.pequeno,
                      color: cs.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppEspaciado.md),
          _etiquetaSeccion(context, 'Modalidad'),
          ValueListenableBuilder<bool>(
            valueListenable: esTerreno,
            builder: (context, enTerrenoValor, _) {
              return Text(
                enTerrenoValor
                    ? 'Vacunación en terreno (campaña o salida)'
                    : 'En establecimiento fijo',
                style: bar.textoDestacado.copyWith(
                  height: 1.35,
                  color: cs.onSurface,
                ),
              );
            },
          ),
          const SizedBox(height: AppEspaciado.lg),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.45)),
          const SizedBox(height: AppEspaciado.lg),
          _etiquetaSeccion(context, 'Personas'),
          _filaPersona(
            context,
            etiqueta: 'Registrador',
            valor: registradorService.registrador!.flxcore03_nombre!
                .toUpperCase(),
          ),
          const SizedBox(height: AppEspaciado.md),
          ValueListenableBuilder<bool>(
            valueListenable: mismoVacunador,
            builder: (context, esMismoVacunador, _) {
              final valorVacunador = hayVacunador
                  ? vacunadorService.vacunador!.sysdesa06_nombre!
                  : (!esMismoVacunador
                        ? 'Falta asignar'
                        : registradorService.registrador!.flxcore03_nombre!);
              final destacarPendiente = !hayVacunador && !esMismoVacunador;
              return _filaPersona(
                context,
                etiqueta: 'Vacunador',
                valor: valorVacunador,
                destacarAlerta: destacarPendiente,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _filaPersona(
    BuildContext context, {
    required String etiqueta,
    required String valor,
    bool destacarAlerta = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: context.escala(compacto: 92.0, normal: 102.0, grande: 112.0),
          child: Text(
            etiqueta,
            style: bar.textoSecundario.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: Text(
              valor,
              style: bar.textoDestacado.copyWith(
                fontWeight: destacarAlerta ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: destacarAlerta ? 1.2 : 0,
                color: destacarAlerta ? cs.error : cs.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tarjetaOpcionesVacunacion(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppEspaciado.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppEspaciado.radioCampo),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Opciones de sesión',
            style: bar.textoChip.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppEspaciado.md),
          ValueListenableBuilder<bool>(
            valueListenable: mismoVacunador,
            builder: (context, valor, _) {
              return _filaSwitch(
                context,
                titulo: '¿Es el mismo vacunador?',
                valor: valor,
                onChanged: (v) => mismoVacunador.value = v,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppEspaciado.sm),
            child: Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: esTerreno,
            builder: (context, valor, _) {
              return _filaSwitch(
                context,
                titulo: '¿Es en terreno?',
                valor: valor,
                onChanged: (v) {
                  esTerreno.value = v;
                  sesionEquipoVacunacionService.establecerEnTerreno(v);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _filaSwitch(
    BuildContext context, {
    required String titulo,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;
    final suave = cs.onSurface.withValues(alpha: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          titulo,
          style: bar.textoDestacado.copyWith(
            height: 1.25,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: AppEspaciado.xs),
        Text(
          valor ? 'Respuesta actual: Sí' : 'Respuesta actual: No',
          style: bar.textoSecundario.copyWith(
            fontWeight: FontWeight.w800,
            color: cs.primary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppEspaciado.sm),
        // No — Switch — Sí: con el thumb a la izquierda = No, a la derecha = Sí.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'No',
                textAlign: TextAlign.end,
                style: bar.textoDestacado.copyWith(
                  fontWeight: valor ? FontWeight.w500 : FontWeight.w800,
                  color: valor ? suave : cs.onSurface,
                ),
              ),
            ),
            Switch(value: valor, onChanged: onChanged),
            Expanded(
              child: Text(
                'Sí',
                textAlign: TextAlign.start,
                style: bar.textoDestacado.copyWith(
                  fontWeight: valor ? FontWeight.w800 : FontWeight.w500,
                  color: valor ? cs.onSurface : suave,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _abrirSelectorEfectores(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bar = context.sisTipografia;

    showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppEspaciado.lg,
                    AppEspaciado.sm,
                    AppEspaciado.lg,
                    AppEspaciado.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_hospital_rounded, color: cs.primary),
                      const SizedBox(width: AppEspaciado.sm),
                      Text(
                        'Efectores',
                        style: bar.tituloSeccion.copyWith(
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _ListaEfectoresHoja(
                    scrollController: scrollController,
                    efectoresCargando: _efectoresCargando,
                    mensajeError: _efectoresMensajeError,
                    onReintentar: _cargarListaEfectoresInicial,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> verificarVacunador() async {
    if (vacunadorService.existeVacunador) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const BusquedaBeneficiario()),
        (Route<dynamic> route) => false,
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext dialogCtx) => DialogoAlerta(
          envioFuncion2: false,
          envioFuncion1: false,
          tituloAlerta: 'Falta el vacunador',
          descripcionAlerta:
              'Escanee o ingrese el D.N.I. del vacunador para continuar.',
          textoBotonAlerta: 'Listo',
          color: Theme.of(dialogCtx).colorScheme.error,
          icon: const Icon(Icons.new_releases_outlined, size: 40),
        ),
      );
    }
  }

  Future<void> verificarEsencialText(
    String dni,
    TextEditingController controladorCampo,
  ) async {
    final String dniNorm = DniInputUtils.normalizar(dni);
    if (!DniInputUtils.esDniPlausible(dniNorm)) {
      if (!mounted) return;
      final cs = Theme.of(context).colorScheme;
      final tt = Theme.of(context).textTheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 2,
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.inverseSurface,
          duration: const Duration(seconds: 3),
          content: Text(
            'Ingrese un D.N.I. válido (7 u 8 dígitos, sin puntos).',
            style: tt.bodyMedium?.copyWith(
              color: cs.onInverseSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
      return;
    }

    try {
      final respUsuario = await vacunadorRepository.validarVacunador(dniNorm);
      if (!mounted) return;

      if (respUsuario[0].codigo_mensaje == '0') {
        controladorCampo.clear();
        await showDialog<void>(
          context: context,
          builder: (BuildContext dialogCtx) => DialogoAlerta(
            envioFuncion2: false,
            envioFuncion1: false,
            tituloAlerta: 'No se pudo validar',
            descripcionAlerta:
                respUsuario[0].mensaje ??
                'Revise el documento e intente de nuevo.',
            textoBotonAlerta: 'Listo',
            color: Theme.of(dialogCtx).colorScheme.error,
            icon: const Icon(Icons.new_releases_outlined, size: 40),
          ),
        );
        return;
      }

      vacunadorService.cargarVacunador(respUsuario[0]);
      controladorCampo.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 2,
          backgroundColor: SisVacuMarca.vercelestePrimario,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2500),
          content: Text(
            'Vacunador asignado correctamente',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogCtx) => DialogoAlerta(
          envioFuncion2: false,
          envioFuncion1: false,
          tituloAlerta: 'Error de conexión',
          descripcionAlerta:
              'No se pudo consultar el vacunador. Revise su conexión e intente de nuevo.',
          textoBotonAlerta: 'Listo',
          color: Theme.of(dialogCtx).colorScheme.error,
          icon: const Icon(Icons.wifi_off_rounded, size: 40),
        ),
      );
    }
  }

}

/// Lista de efectores dentro del modal: carga, error con reintento o ítems.
class _ListaEfectoresHoja extends StatefulWidget {
  const _ListaEfectoresHoja({
    required this.scrollController,
    required this.efectoresCargando,
    required this.mensajeError,
    required this.onReintentar,
  });

  final ScrollController scrollController;
  final bool efectoresCargando;
  final String? mensajeError;
  final Future<void> Function() onReintentar;

  @override
  State<_ListaEfectoresHoja> createState() => _ListaEfectoresHojaState();
}

class _ListaEfectoresHojaState extends State<_ListaEfectoresHoja> {
  bool _reintentando = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final bar = context.sisTipografia;

    return ValueListenableBuilder<List<Efectores>>(
      valueListenable: efectoresService.listaEfectoresEstado,
      builder: (context, lista, _) {
        final n = lista.length;
        final vacio = n == 0;
        final cargando = vacio && (widget.efectoresCargando || _reintentando);
        final errorSinDatos =
            vacio &&
            widget.mensajeError != null &&
            !widget.efectoresCargando &&
            !_reintentando;

        if (cargando) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppEspaciado.md),
                Text(
                  'Obteniendo establecimientos…',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        if (errorSinDatos) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppEspaciado.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded, size: 48, color: cs.error),
                const SizedBox(height: AppEspaciado.md),
                Text(
                  widget.mensajeError!,
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppEspaciado.lg),
                FilledButton.icon(
                  onPressed: () async {
                    setState(() => _reintentando = true);
                    await widget.onReintentar();
                    if (mounted) setState(() => _reintentando = false);
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: widget.scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppEspaciado.xl),
          itemCount: n,
          itemBuilder: (BuildContext context, int index) {
            final item = lista[index];
            return ListTile(
              key: ValueKey(item.relaSysofic01 ?? item.sysofic01Descripcion),
              leading: CircleAvatar(
                backgroundColor: cs.primary.withValues(alpha: 0.12),
                child: FaIcon(
                  FontAwesomeIcons.hospital,
                  size: 18,
                  color: cs.primary,
                ),
              ),
              title: Text(
                item.sysofic01Descripcion ?? '',
                style: bar.textoDestacado.copyWith(
                  color: cs.onSurface,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppEspaciado.radioBoton),
              ),
              onTap: () {
                final String nom = item.sysofic01Descripcion ?? '';
                registradorService.editarEfectorUsuario(item);
                final ScaffoldMessengerState? ms = ScaffoldMessenger.maybeOf(
                  context,
                );
                Navigator.of(context).pop();
                ms?.showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: cs.primary,
                    duration: const Duration(seconds: 2),
                    content: Text(
                      'Establecimiento: $nom',
                      style: tt.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Desplaza el contenido hacia arriba con el teclado sin animar el **padding** del
/// scroll: cambiar padding en cada frame relayoutea toda la columna (caro).
/// [Transform.translate] solo actualiza la capa de pintura; el hijo mantiene el
/// mismo layout. [MediaQuery.viewInsetsOf] limita rebuilds **de este** elemento al
/// aspecto `viewInsets`, no al resto de [MediaQuery]. En Android, `adjustPan` en el
/// manifest suele reducir métricas por animación frente a `adjustResize`.
///
/// No evita que el [Scaffold] padre vuelva a ejecutar su `build` si el framework lo
/// marca por IME; solo acota el trabajo en este subárbol.
class _ScrollConPaddingTeclado extends StatelessWidget {
  const _ScrollConPaddingTeclado({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppEspaciado.lg,
        AppEspaciado.md,
        AppEspaciado.lg,
        AppEspaciado.xl,
      ),
      child: Transform.translate(offset: Offset(0, -inset), child: child),
    );
  }
}

/// Panel D.N.I. en estado propio: foco diferido para no competir con la transición
/// de ruta ni el primer layout; [autoFocus] inmediato en el [TextField] se evita.
/// El ingreso manual usa [CustomInput] (scrollPadding por defecto; ver su documentación).
class _RegistroVacunadorPanel extends StatefulWidget {
  const _RegistroVacunadorPanel({required this.onValidarDni});

  final Future<void> Function(String dni, TextEditingController controlador)
  onValidarDni;

  @override
  State<_RegistroVacunadorPanel> createState() =>
      _RegistroVacunadorPanelState();
}

class _RegistroVacunadorPanelState extends State<_RegistroVacunadorPanel> {
  late final TextEditingController _controlador;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controlador = TextEditingController();
    _focus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future<void>.delayed(const Duration(milliseconds: 480), () {
        if (mounted) {
          _focus.requestFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    _controlador.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      'Registro del vacunador',
                      style: bar.tituloTarjeta.copyWith(color: cs.onSurface),
                    ),
                    const SizedBox(height: AppEspaciado.xs),
                    Text(
                      'Código del frente o reverso del D.N.I., o ingreso manual',
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
                tooltip: 'Ayuda: escanear o cargar D.N.I. del vacunador',
                style: AppBotones.estiloIconoAyuda(cs),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) => DialogoAlerta(
                      envioFuncion2: false,
                      envioFuncion1: false,
                      tituloAlerta: 'Información',
                      descripcionAlerta:
                          'Registre al vacunador con «Escanear documento» (código del frente en DNI nuevo, PDF417 del reverso en DNI anterior) o ingrese el D.N.I. sin puntos y confirme con el teclado.',
                      textoBotonAlerta: 'Listo',
                      color: SisVacuMarca.vercelesteCuaternario,
                      icon: const Icon(
                        Icons.info,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
                icon: const FaIcon(FontAwesomeIcons.circleInfo, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppEspaciado.lg),
          Text(
            'Escanee el código del D.N.I. del vacunador (frente o reverso según el tipo de tarjeta) o ingréselo manualmente.',
            textAlign: TextAlign.center,
            style: bar.textoPrincipal.copyWith(
              height: 1.45,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppEspaciado.xl),
          FormularioDocumento(
            tipoEscaneo: 'Vacunador',
            textoBotonEscaneo: 'Escanear documento',
            anchoEscaner: 44,
            mostrarSexo: false,
            controladorDni: _controlador,
            focusNode: _focus,
            onVerificar: (dni, _) =>
                widget.onValidarDni(dni, _controlador),
          ),
        ],
      ),
    );
  }
}
