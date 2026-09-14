import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/core/debug/dev_log_service.dart';
import 'package:sistema_vacunacion/src/utils/edad_pdf417_dni_arg.dart';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';
import 'package:sistema_vacunacion/src/utils/pdf417_dni_arg_parser.dart';

import 'package:sistema_vacunacion/src/domain/entities/models.dart';
import 'package:sistema_vacunacion/src/pages/pages.dart';
import 'package:sistema_vacunacion/src/data/datasources/providers.dart';
import 'package:sistema_vacunacion/src/data/repositories/repositories.dart';
import 'package:sistema_vacunacion/src/presentation/state/services.dart';
import 'package:sistema_vacunacion/src/widgets/widgets.dart';

class EscanerDni extends StatefulWidget {
  final String textoBoton;
  final String tipoEscaneo; // REGISTRADOR / VACUNADOR / BENEFICIARIO / TUTOR
  final double? anchoValor;
  final double? largoValor;
  final bool? iconBool;

  const EscanerDni(
    this.tipoEscaneo,
    this.textoBoton, {
    Key? key,
    this.anchoValor,
    this.largoValor,
    this.iconBool,
  }) : super(key: key);

  @override
  _EscanerDniState createState() => _EscanerDniState();
}

class _EscanerDniState extends State<EscanerDni> {
  /// Texto exacto devuelto por el lector (PDF417); el API debe recibir esto, no `List.toString()`.
  String _cadenaPdf417Cruda = '';
  late List<String> conSplit;
  String? nombrePersona;
  String? apellidoPersona;
  String? dniPersona;
  String? numeroTramite;
  String? codigodebarras;
  String sexoPersona = "F";

  /// Desde el PDF417 (fecha nac. del DNI).
  String? _fechaNacPdf417Escaneo;
  String? _edadAniosPdf417Escaneo;

  Future<void> _mostrarSinConexionRed() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => DialogoAlerta(
        envioFuncion2: false,
        envioFuncion1: false,
        tituloAlerta: 'Sin conexión',
        descripcionAlerta:
            'No se pudo contactar al servidor. Revise la red e intente de nuevo.',
        textoBotonAlerta: 'Listo',
        color: Theme.of(ctx).colorScheme.error,
        icon: Icon(Icons.wifi_off_rounded, size: AppTamanoIcono.grande),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BotonCustom(
      height: widget.anchoValor ?? 40,
      width: widget.largoValor ?? double.infinity,
      iconoBool: widget.iconBool ?? true,
      // Tamaño fijo: no suscribir el botón a MediaQuery (teclado / rotación).
      iconoBoton: const FaIcon(
        FontAwesomeIcons.barcode,
        size: AppTamanoIcono.mediano,
      ),
      text: widget.textoBoton,
      onPressed: () async {
        // No activar overlay de carga durante la cámara: solo al volver y
        // consultar al servidor (Registrador / Vacunador / Tutor).
        loadingLoginService.cargarPrimerInicio(false);
        try {
          await scanBarcodeNormal();
        } catch (e) {
          if (!mounted) return;
          loadingLoginService.cargarEstado(false);
          await showDialog<void>(
            context: context,
            builder: (BuildContext ctx) => DialogoAlerta(
              envioFuncion2: false,
              envioFuncion1: false,
              tituloAlerta: 'No se pudo completar',
              descripcionAlerta:
                  'Hubo un problema con el escaneo o con la consulta. Intente de nuevo; si continúa, contacte a soporte técnico.',
              textoBotonAlerta: 'Listo',
              color: Theme.of(ctx).colorScheme.error,
              icon: Icon(Icons.error_outline, size: AppTamanoIcono.grande),
            ),
          );
        }
      },
    );
  }

  Future<void> scanBarcodeNormal() async {
    final String? barcodeScanRes = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(builder: (context) => const _ScannerPage()),
    );

    if (!mounted) return;

    // -1 equivale a cancelado.
    if (barcodeScanRes == null || barcodeScanRes == '-1') {
      loadingLoginService.cargarEstado(false);
      return;
    }

    _cadenaPdf417Cruda = barcodeScanRes;
    conSplit = barcodeScanRes.split('@');

    switch (widget.tipoEscaneo) {
      case 'Registrador':
        capturarTipoDni();

        // Si no se extrajo un DNI válido (7–8 dígitos),
        // dniPersona queda null. Mostrar error y abortar antes de llamar a la API.
        if (dniPersona == null) {
          showDialog(
            context: context,
            builder: (BuildContext dialogCtx) => DialogoAlerta(
              envioFuncion2: false,
              envioFuncion1: false,
              tituloAlerta: 'Error de lectura',
              descripcionAlerta:
                  'El formato del documento no fue reconocido. Intente de nuevo.',
              textoBotonAlerta: 'Listo',
              icon: Icon(Icons.error_outline, size: AppTamanoIcono.grande),
              color: Theme.of(dialogCtx).colorScheme.error,
            ),
          );
          loadingLoginService.cargarEstado(false);
          break;
        }

        loadingLoginService.cargarEstado(true, mensaje: 'Validando usuario...');
        try {
          final respUsuario = await authRepository.validarUsuariosNuevo(
            dniPersona,
          );
          if (!mounted) {
            loadingLoginService.cargarEstado(false);
            break;
          }
          if (respUsuario[0].flxcore03_dni == '') {
            showDialog(
              context: context,
              builder: (BuildContext dialogCtx) {
                return DialogoAlerta(
                  envioFuncion2: false,
                  envioFuncion1: false,
                  tituloAlerta: 'No se pudo iniciar sesión',
                  descripcionAlerta: respUsuario[0].mensaje,
                  textoBotonAlerta: 'Listo',
                  icon: const Icon(
                    Icons.error_outline,
                    size: AppTamanoIcono.grande,
                  ),
                  color: Theme.of(dialogCtx).colorScheme.error,
                );
              },
            );
            loadingLoginService.cargarEstado(false);
          } else {
            if (respUsuario[0].sysofic01_descripcion != null) {
              registradorService.cargarRegistrador(respUsuario[0]);
              if (datosdecargaprovider.versionApp == 'Ok') {
                loadingLoginService.cargarEstado(false);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        VacunadorPage(infoCargador: respUsuario),
                  ),
                  (Route<dynamic> route) => false,
                );
              } else {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return DialogoAlerta(
                      envioFuncion2: false,
                      envioFuncion1: false,
                      tituloAlerta: 'Actualice la aplicación',
                      descripcionAlerta:
                          'Hay una versión nueva obligatoria. Descargue la actualización para continuar.',
                      textoBotonAlerta: 'Listo',
                      icon: Icon(
                        Icons.system_update_rounded,
                        size: AppTamanoIcono.grande,
                      ),
                      color: Theme.of(context).colorScheme.primary,
                    );
                  },
                );
                loadingLoginService.cargarEstado(false);
              }
            } else {
              showDialog(
                context: context,
                builder: (BuildContext dialogCtx) {
                  return DialogoAlerta(
                    envioFuncion2: false,
                    envioFuncion1: false,
                    tituloAlerta: 'Datos incompletos en el servidor',
                    descripcionAlerta:
                        'No se obtuvo el establecimiento asociado a su usuario. Reintente el escaneo o contacte a soporte técnico.',
                    textoBotonAlerta: 'Listo',
                    icon: const Icon(Icons.error_outline, size: 40.0),
                    color: Theme.of(dialogCtx).colorScheme.error,
                  );
                },
              );
              loadingLoginService.cargarEstado(false);
            }
          }
        } catch (_) {
          if (!mounted) break;
          loadingLoginService.cargarEstado(false);
          await _mostrarSinConexionRed();
        }
        break;
      case 'Vacunador':
        capturarTipoDni();

        // Misma guarda que Registrador: abortar si el formato no fue reconocido.
        if (dniPersona == null) {
          showDialog(
            context: context,
            builder: (BuildContext dialogCtx) => DialogoAlerta(
              envioFuncion2: false,
              envioFuncion1: false,
              tituloAlerta: 'Error de lectura',
              descripcionAlerta:
                  'El formato del documento no fue reconocido. Intente de nuevo.',
              textoBotonAlerta: 'Listo',
              icon: Icon(Icons.error_outline, size: AppTamanoIcono.grande),
              color: Theme.of(dialogCtx).colorScheme.error,
            ),
          );
          loadingLoginService.cargarEstado(false);
          break;
        }

        loadingLoginService.cargarEstado(
          true,
          mensaje: 'Validando vacunador...',
        );
        try {
          final respUsuario = await vacunadorRepository.validarVacunador(
            dniPersona,
          );
          if (!mounted) {
            loadingLoginService.cargarEstado(false);
            break;
          }
          if (respUsuario[0].codigo_mensaje == '0') {
            showDialog(
              context: context,
              builder: (BuildContext dialogCtx) => DialogoAlerta(
                envioFuncion2: false,
                envioFuncion1: false,
                tituloAlerta: 'No se pudo validar el vacunador',
                descripcionAlerta: respUsuario[0].mensaje,
                textoBotonAlerta: 'Listo',
                color: Theme.of(dialogCtx).colorScheme.error,
                icon: Icon(
                  Icons.new_releases_outlined,
                  size: AppTamanoIcono.grande,
                ),
              ),
            );
            loadingLoginService.cargarEstado(false);
          } else {
            setState(() {
              vacunadorService.cargarVacunador(respUsuario[0]);
            });
            loadingLoginService.cargarEstado(false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: SisVacuMarca.vercelestePrimario,
                  duration: const Duration(seconds: 2),
                  content: Text(
                    'Vacunador asignado correctamente',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }
          }
        } catch (_) {
          if (!mounted) break;
          loadingLoginService.cargarEstado(false);
          await _mostrarSinConexionRed();
        }
        break;

      case 'Beneficiario':
        capturarTipoDni();
        if (dniPersona == null) {
          showDialog(
            context: context,
            builder: (BuildContext dialogCtx) => DialogoAlerta(
              envioFuncion2: false,
              envioFuncion1: false,
              tituloAlerta: 'Error de lectura',
              descripcionAlerta:
                  'El formato del documento no fue reconocido. Intente de nuevo.',
              textoBotonAlerta: 'Listo',
              icon: Icon(Icons.error_outline, size: AppTamanoIcono.grande),
              color: Theme.of(dialogCtx).colorScheme.error,
            ),
          );
          break;
        }

        // La situación (embarazada/puérpera/personal de salud) se pide antes
        // de llamar al webservice: viaja en esa misma consulta.
        final situacion = await _pedirSituacionBeneficiario();
        if (situacion == null || !mounted) break;

        // Mostrar loading inmediatamente antes de la llamada a la API.
        // pushAndRemoveUntil lo descarta solo en el path exitoso;
        // el catch lo cierra manualmente antes de mostrar el error.
        unawaited(
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black.withValues(alpha: .72),
            builder: (ctx) => const PopScope(
              canPop: false,
              child: LoadingDialogEstrellas(
                mensaje: 'Buscando datos del beneficiario...',
              ),
            ),
          ),
        );
        try {
          await obtenerDatosBeneficiario(
            dniPersona,
            embarazada: situacion.condicion == CondicionGestacional.embarazada,
            puerpera: situacion.condicion == CondicionGestacional.puerpera,
            personalSalud: situacion.personalSalud,
          );
        } catch (e) {
          if (!mounted) break;
          // Cerrar el dialog de loading antes de mostrar el error.
          Navigator.of(context).pop();
          final String detalle = e is Exception
              ? e.toString().replaceFirst('Exception: ', '').trim()
              : '';
          await showDialog<void>(
            context: context,
            builder: (BuildContext ctx) => DialogoAlerta(
              envioFuncion2: false,
              envioFuncion1: false,
              tituloAlerta: 'Sin conexión',
              descripcionAlerta: detalle.isNotEmpty
                  ? 'No se pudieron obtener los datos del beneficiario.\n\n$detalle'
                  : 'No se pudieron obtener los datos del beneficiario. Revise la red e intente de nuevo.',
              textoBotonAlerta: 'Listo',
              color: Theme.of(ctx).colorScheme.error,
              icon: Icon(Icons.wifi_off_rounded, size: AppTamanoIcono.grande),
            ),
          );
        }
        break;

      case 'Tutor':
        capturarTipoDni();

        // Misma guarda: si el formato no fue reconocido, dniPersona es null
        // y obtenerDatosTutor no debe llamar al servicio.
        if (dniPersona == null) {
          showDialog(
            context: context,
            builder: (BuildContext dialogCtx) => DialogoAlerta(
              envioFuncion2: false,
              envioFuncion1: false,
              tituloAlerta: 'Error de lectura',
              descripcionAlerta:
                  'El formato del documento no fue reconocido. Intente de nuevo.',
              textoBotonAlerta: 'Listo',
              icon: Icon(Icons.error_outline, size: AppTamanoIcono.grande),
              color: Theme.of(dialogCtx).colorScheme.error,
            ),
          );
          loadingLoginService.cargarEstado(false);
          break;
        }

        loadingLoginService.cargarEstado(true, mensaje: 'Validando tutor...');
        try {
          await obtenerDatosTutor(dniPersona);
          if (!mounted) break;
          loadingLoginService.cargarEstado(false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: SisVacuMarca.vercelestePrimario,
              margin: const EdgeInsets.all(AppEspaciado.lg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppEspaciado.radioBoton),
              ),
              content: Text(
                'Tutor cargado correctamente',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          );
        } catch (e) {
          if (!mounted) break;
          loadingLoginService.cargarEstado(false);
          final String detalle = e is Exception
              ? e.toString().replaceFirst('Exception: ', '').trim()
              : '';
          await showDialog<void>(
            context: context,
            builder: (BuildContext ctx) => DialogoAlerta(
              envioFuncion2: false,
              envioFuncion1: false,
              tituloAlerta: 'No se pudo validar al tutor',
              descripcionAlerta: detalle.isNotEmpty
                  ? detalle
                  : 'Revise la red e intente de nuevo.',
              textoBotonAlerta: 'Listo',
              color: Theme.of(ctx).colorScheme.error,
              icon: Icon(Icons.error_outline, size: AppTamanoIcono.grande),
            ),
          );
        }
        break;

      default:
    }
  }

  Future<void> obtenerDatosTutor(String? dni) async {
    final datosBeneficiario = await beneficiarioProviders
        .obtenerDatosBeneficiario(codigodebarras, dni, sexoPersona);
    if (datosBeneficiario.isEmpty) {
      throw Exception('El servidor no devolvió datos del documento.');
    }
    final b0 = datosBeneficiario[0];
    if (b0.codigo_mensaje == '0') {
      final msg = b0.mensaje?.toString().trim() ?? '';
      throw Exception(
        msg.isNotEmpty ? msg : 'No se pudieron validar los datos del tutor.',
      );
    }
    final nombreT = _fusionarTextoApiConEscaneo(
      b0.sysdesa10_nombre,
      nombrePersona,
    );
    final apellidoT = _fusionarTextoApiConEscaneo(
      b0.sysdesa10_apellido,
      apellidoPersona,
    );
    tutorService.cargarTutor(
      Tutor(
        sysdesa10_nombre_tutor: nombreT,
        sysdesa10_apellido_tutor: apellidoT,
        sysdesa10_dni_tutor: b0.sysdesa10_dni,
        sysdesa10_sexo_tutor: b0.sysdesa10_sexo,
      ),
    );
  }

  /// Prioriza el texto del PDF417 ya decodificado en pantalla si la API viene mal.
  String? _fusionarTextoApiConEscaneo(String? api, String? localEscaneo) {
    final a = api?.trim() ?? '';
    final l = localEscaneo?.trim() ?? '';
    if (a.isNotEmpty && !textoNombreDesdeServidorPareceCorrupto(a)) return a;
    if (l.isNotEmpty) return l;
    return a.isEmpty ? null : a;
  }

  /// Único diálogo de confirmación del flujo Beneficiario: muestra el
  /// DNI/sexo leídos (verificación) y pide la situación (condición
  /// gestacional excluyente + personal de salud) para enviarla en la misma
  /// llamada a `wserv_obtener_datos_persona.php`. Devuelve `null` si cancela.
  Future<({CondicionGestacional? condicion, bool personalSalud})?>
  _pedirSituacionBeneficiario() {
    CondicionGestacional? condicion;
    var personalSalud = false;
    final etiquetaSexo = sexoPersona == 'M'
        ? 'Masculino'
        : sexoPersona == 'X'
        ? 'No binario (X)'
        : 'Femenino';
    return showDialog<({CondicionGestacional? condicion, bool personalSalud})>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => DialogoAlerta(
          tituloAlerta: 'Verificar y continuar',
          contenido: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('D.N.I. $dniPersona — $etiquetaSexo'),
                const SizedBox(height: AppEspaciado.md),
                SituacionBeneficiario(
                  sexoEsFemenino: sexoPersona == 'F',
                  condicion: condicion,
                  esPersonalDeSalud: personalSalud,
                  onCondicionChanged: (c) =>
                      setStateDialog(() => condicion = c),
                  onPersonalSaludChanged: (v) =>
                      setStateDialog(() => personalSalud = v),
                ),
              ],
            ),
          ),
          dosBotones: true,
          textoBotonAlerta: 'Continuar',
          textoBotonAlerta2: 'Cancelar',
          funcion1: () => Navigator.of(
            dialogContext,
          ).pop((condicion: condicion, personalSalud: personalSalud)),
          funcion2: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    );
  }

  Future<void> obtenerDatosBeneficiario(
    String? dni, {
    required bool embarazada,
    required bool puerpera,
    required bool personalSalud,
  }) async {
    try {
      situacionBeneficiarioService.cargarSituacion(
        condicionGestacional: embarazada
            ? CondicionGestacional.embarazada
            : puerpera
            ? CondicionGestacional.puerpera
            : null,
        esPersonalDeSalud: personalSalud,
      );
      final datosBeneficiario = await beneficiarioProviders.obtenerDatosPersona(
        codigodebarras,
        dni,
        sexoPersona,
        embarazada: embarazada,
        puerpera: puerpera,
        personalSalud: personalSalud,
      );
      final b0 = datosBeneficiario[0];
      if (b0.codigo_mensaje == '0') {
        loadingLoginService.cargarEstado(false);
        if (!mounted) return;
        // Cierra el diálogo «Buscando datos...» antes de mostrar el error.
        Navigator.of(context).pop();
        await showDialog<void>(
          context: context,
          builder: (BuildContext dialogCtx) => DialogoAlerta(
            envioFuncion2: false,
            envioFuncion1: false,
            tituloAlerta: 'No se pudo continuar',
            descripcionAlerta: b0.mensaje,
            textoBotonAlerta: 'Listo',
            color: Theme.of(dialogCtx).colorScheme.error,
            icon: const Icon(Icons.error, size: 40),
          ),
        );
        return;
      }
      final nombreB = _fusionarTextoApiConEscaneo(
        b0.sysdesa10_nombre,
        nombrePersona,
      );
      final apellidoB = _fusionarTextoApiConEscaneo(
        b0.sysdesa10_apellido,
        apellidoPersona,
      );
      if (nombreB != null) b0.sysdesa10_nombre = nombreB;
      if (apellidoB != null) b0.sysdesa10_apellido = apellidoB;
      setState(() {
        beneficiarioService.cargarBeneficiario(
          b0,
          edadAniosDesdePdf417Escaneado: _edadAniosPdf417Escaneo,
          fechaNacimientoDesdePdf417Escaneado: _fechaNacPdf417Escaneo,
        );
      });

      // El historial es información complementaria: si el webservice falla,
      // no debe bloquear la carga del beneficiario (que ya se obtuvo bien).
      try {
        final notificaciones = await sistemaRepository.validarNotificaciones(
          dni,
          sexoPersona,
          embarazada: embarazada,
          puerpera: puerpera,
          personalSalud: personalSalud,
          edadDias: beneficiarioService.diasDeVidaBeneficiario,
        );
        notificaciones.isNotEmpty
            ? {notificacionesDosisService.cargarListaDosis(notificaciones)}
            : notificacionesDosisService.cargarRegistro(NotificacionesDosis());
      } catch (_) {
        notificacionesDosisService.cargarRegistro(NotificacionesDosis());
        // La misma llamada trae "vacunas_pendientes": si falló, la vía
        // Pendientes no puede confundir esto con "no tiene nada pendiente".
        vacunasPendientesService.marcarError(
          'No se pudo consultar las vacunas pendientes. Revise la conexión.',
        );
      }
      loadingLoginService.cargarEstado(false);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const VacunasPage()),
        (Route<dynamic> route) => false,
      );
    } catch (_) {
      loadingLoginService.cargarEstado(false);
      rethrow;
    }
  }

  /// Interpreta el PDF417 del DNI argentino con separador `@`.
  /// Soporta DNI viejo (17 campos), DNI nuevo (8/9 y variantes con más campos
  /// si mantienen apellido, nombre, sexo y DNI en las posiciones habituales)
  /// y un respaldo heurístico si la cantidad de partes cambia.
  void capturarTipoDni() {
    final partes = conSplit.map((e) => e.trim()).toList();
    final cadenaApi = _cadenaPdf417Cruda.trim().isNotEmpty
        ? _cadenaPdf417Cruda.trim()
        : partes.join('@');

    final datos = parsearPdf417DniArgentino(partes);
    final anios = datos == null
        ? null
        : aniosCumplidosDesdeFechaNacimientoTexto(datos.fechaNacimientoPdf417);
    _logCapturaTipoDni(partes, datos, anios);

    setState(() {
      if (datos != null && kRegexDniPdf417.hasMatch(datos.dni)) {
        apellidoPersona = datos.apellido;
        nombrePersona = datos.nombre;
        dniPersona = datos.dni;
        sexoPersona = datos.sexo;
        numeroTramite = datos.tramite;
        codigodebarras = cadenaApi;
        _fechaNacPdf417Escaneo = datos.fechaNacimientoPdf417;
        _edadAniosPdf417Escaneo = anios?.toString();
      } else {
        dniPersona = null;
        _fechaNacPdf417Escaneo = null;
        _edadAniosPdf417Escaneo = null;
      }
    });
  }

  /// Diagnóstico temporal: vuelca al Dev Log Panel cómo se separaron los
  /// campos del PDF417 (índice a índice) y qué le asignó a cada uno, para
  /// investigar edades mal calculadas sin adivinar sobre el código.
  void _logCapturaTipoDni(
    List<String> partes,
    DatosDniPdf417? datos,
    int? anios,
  ) {
    final mensaje = datos == null
        ? 'No se pudo parsear la estructura (${partes.length} campos)'
        : 'Parseado OK (${partes.length} campos)';
    final camposLog = {
      'partes': {for (var i = 0; i < partes.length; i++) '$i': partes[i]},
      if (datos != null) ...{
        'dni': datos.dni,
        'apellido': datos.apellido,
        'nombre': datos.nombre,
        'sexo': datos.sexo,
        'tramite': datos.tramite,
        'fechaNacimientoPdf417': datos.fechaNacimientoPdf417,
        'aniosCalculados': anios,
      },
    };
    devLogService.log(
      DevLogTipo.info,
      'EscanerDNI/campos',
      mensaje,
      datos: camposLog,
    );
    // Ver nota en encoding_utils.dart: el Dev Log Panel no es alcanzable en
    // este build (enviroment queda en 'PROD'); esto va a consola además.
    if (kDebugMode) {
      debugPrint('[EscanerDNI/campos] $mensaje · $camposLog');
    }
  }
}

/// Resultado del parseo del PDF417 para uso interno del escáner.
/// El DNI argentino usa exclusivamente PDF417. Code128/Code93 corresponden a
/// licencias de conducir y productos — incluirlos triplica el trabajo nativo por frame.
const int _kFormatosCodigoDniArgentino = Format.pdf417;

class _ScannerPage extends StatefulWidget {
  const _ScannerPage();

  @override
  State<_ScannerPage> createState() => _ScannerPageState();
}

// cropPercent=0 (frame completo, sin crop) se probó en dispositivo: mismo
// tiempo de detección que 0.9 (n=8 c/u, DNI fijo) pero decode 2x más lento y
// sin marco guía (reader_widget.dart: el overlay no se dibuja si cropPercent==0).
// Sin beneficio medido — se descarta.
const double _kCropDecodificacionPdf417 = 0.9;

/// Marco visual: guía dentro del área real de decodificación.
const double _kMarcoGuiaVisualPdf417 = 0.78;

class _ScannerPageState extends State<_ScannerPage> {
  // Guard para evitar múltiples pops — onScan puede dispararse varias veces
  // mientras el widget todavía está en el árbol al momento de navegar.
  bool _detected = false;

  Timer? _timerConsejo;
  bool _mostrarConsejoLargo = false;
  DateTime? _ultimoAvisoLecturaInvalida;

  // Diagnóstico: frames fallidos consecutivos y timing de cada intento.
  int _framesFallidosConsecutivos = 0;
  final Stopwatch _cronometroSesionEscaneo = Stopwatch();

  // tryHarder progresivo: probado, sin evidencia de mejora (ver conversación).
  // Desconectado del ReaderWidget pero se deja el mecanismo por si se retoma.
  bool _tryHarderActivo = false;
  static const int _kUmbralFramesParaTryHarder = 12;

  // Total de frames en la sesión — si no avanza con la cámara "viva", el
  // isolate de decode de flutter_zxing puede estar colgado.
  int _framesTotalesSesion = 0;

  @override
  void initState() {
    super.initState();
    _cronometroSesionEscaneo.start();
    _timerConsejo = Timer(const Duration(seconds: 4), () {
      if (!mounted || _detected) return;
      setState(() => _mostrarConsejoLargo = true);
    });
    _iniciarTemporizadorSinDeteccion();
  }

  Timer? _timerSinDeteccion;
  int _framesTotalesUltimoTick = 0;

  // Detecta cámara "viva" pero decode realmente colgado (framesTotales no
  // avanza entre ticks) — distinto de simplemente ir fallando.
  void _iniciarTemporizadorSinDeteccion() {
    _timerSinDeteccion?.cancel();
    _timerSinDeteccion = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || _detected) return;
      devLogService.log(
        DevLogTipo.info,
        'EscanerDNI/latido',
        'framesTotales=$_framesTotalesSesion',
      );
      if (_framesTotalesSesion == _framesTotalesUltimoTick) {
        _mostrarSnackBarEstado('La cámara no está procesando. Reintentá.');
      }
      _framesTotalesUltimoTick = _framesTotalesSesion;
    });
  }

  @override
  void dispose() {
    _cronometroSesionEscaneo.stop();
    _timerConsejo?.cancel();
    _timerSinDeteccion?.cancel();
    super.dispose();
  }

  // No llamar a stopImageStream() acá: dispose() de flutter_zxing ya lo hace
  // y llamarlo dos veces rompe con CameraException (reader_widget.dart:318).
  void _onDetected(String rawValue) {
    if (_detected || !mounted) return;
    _detected = true;
    _timerConsejo?.cancel();
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(rawValue);
  }

  // Feedback cuando se detecta un código que no corresponde al DNI.
  // Throttle de 3s (= duración del SnackBar) para que no se pisen entre sí.
  void _avisarCodigoNoEsDni({String? codigoDetectado, String? forzarMensaje}) {
    if (!mounted || _detected) return;
    final ahora = DateTime.now();
    if (_ultimoAvisoLecturaInvalida != null &&
        ahora.difference(_ultimoAvisoLecturaInvalida!) <
            const Duration(seconds: 3)) {
      return;
    }
    _ultimoAvisoLecturaInvalida = ahora;
    _mostrarSnackBarEstado(
      forzarMensaje ?? 'Ese código no es del DNI. Probá el otro lado.',
    );
  }

  void _mostrarSnackBarEstado(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(AppEspaciado.lg, 0, AppEspaciado.lg, 88),
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xE6000000),
        content: Text(
          texto,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  void _procesarCodigoLeido(Code result) {
    if (_detected) return;
    _framesTotalesSesion++;
    _logDiagnosticoFrame(result, exitoso: true, framesFallidosPrevios: _framesFallidosConsecutivos);
    _framesFallidosConsecutivos = 0;
    final decodificado = decodificarCadenaPdf417Argentino(
      result.rawBytes,
      result.text,
    ).trim();
    if (decodificado.isEmpty) return;
    if (!(result.isValid || decodificado.contains('@'))) return;
    if (!cadenaEsLecturaPlausibleDniArgentino(decodificado)) {
      _avisarCodigoNoEsDni(codigoDetectado: decodificado);
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _onDetected(decodificado);
  }

  void _onFrameFallido(Code result) {
    if (_detected || !mounted) return;
    _framesTotalesSesion++;
    _framesFallidosConsecutivos++;
    if (!_tryHarderActivo &&
        _framesFallidosConsecutivos >= _kUmbralFramesParaTryHarder) {
      setState(() => _tryHarderActivo = true);
      debugPrint(
        '[EscanerDNI/tryHarder] Escalado a true tras $_framesFallidosConsecutivos fallidos '
        '(${(_cronometroSesionEscaneo.elapsedMilliseconds / 1000).toStringAsFixed(1)}s)',
      );
    }
    if (_framesFallidosConsecutivos % 10 == 0) {
      _logDiagnosticoFrame(
        result,
        exitoso: false,
        framesFallidosPrevios: _framesFallidosConsecutivos,
      );
    }
  }

  void _logDiagnosticoFrame(
    Code result, {
    required bool exitoso,
    required int framesFallidosPrevios,
  }) {
    final mensaje = exitoso
        ? 'Frame OK tras $framesFallidosPrevios fallidos'
        : 'Frame fallido #$framesFallidosPrevios';
    final datos = {
      'segundosDesdeApertura':
          (_cronometroSesionEscaneo.elapsedMilliseconds / 1000).toStringAsFixed(1),
      'duracionDecodeMs': result.duration,
      // Code.imageWidth/imageHeight requieren logging nativo; Code.position sí trae el tamaño real.
      'imageWidth': result.position?.imageWidth,
      'imageHeight': result.position?.imageHeight,
      'error': result.error,
    };
    devLogService.log(DevLogTipo.info, 'EscanerDNI/frame', mensaje, datos: datos);
    if (kDebugMode) {
      debugPrint('[EscanerDNI/frame] $mensaje · $datos');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bar = context.sisTipografia;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Escanear DNI',
          textAlign: TextAlign.center,
          style: bar.subtituloTarjeta.copyWith(
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ReaderWidget(
            codeFormat: _kFormatosCodigoDniArgentino,
            // veryHigh probado: este equipo igual entrega 1280x720, sin efecto.
            resolution: ResolutionPreset.high,
            cropPercent: _kCropDecodificacionPdf417,
            // El marco no coincide con el crop: es solo guía; el lector usa todo el encuadre.
            scannerOverlay: ScannerOverlayBorder(
              cutOutSize: _kMarcoGuiaVisualPdf417,
              borderColor: SisVacuMarca.vercelestePrimario,
              borderWidth: 3,
              overlayColor: const Color.fromRGBO(0, 0, 0, 0.52),
              borderRadius: AppEspaciado.radioBoton,
              borderLength: 26,
            ),
            // Por defecto el paquete espera 1 s tras un éxito; aquí no aporta y retrasa reintentos.
            scanDelaySuccess: Duration.zero,
            // Un poco más de aire entre intentos reduce lecturas sobre fotogramas movidos.
            scanDelay: const Duration(milliseconds: 240),
            tryHarder: false, // probado, sin mejora (ver _tryHarderActivo).
            // Apagado: decodificaba cada frame 2 veces (nativo + downscale).
            tryDownscale: false,
            // Innecesario para DNI argentino (siempre fondo claro) y duplica
            // el costo de decodificación por frame (decodifica dos veces).
            tryInverted: false,
            showToggleCamera: false,
            showGallery: false,
            loading: const _CamaraCargando(),
            onControllerCreated: (controller, err) {
              if (err != null && mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!mounted) return;
                  await showDialog<void>(
                    context: context,
                    builder: (ctx) => DialogoAlerta(
                      tituloAlerta: 'No se pudo abrir la cámara',
                      descripcionAlerta:
                          'Comprobá permisos y que otra app no esté usando la cámara.\n\n$err',
                      icon: Icon(
                        Icons.videocam_off_rounded,
                        size: AppTamanoIcono.grande,
                      ),
                      color: Theme.of(ctx).colorScheme.error,
                      envioFuncion1: false,
                      textoBotonAlerta: 'Cerrar',
                    ),
                  );
                  if (mounted) Navigator.of(context).pop(null);
                });
              }
            },
            showFlashlight: true,
            onScan: _procesarCodigoLeido,
            onScanFailure: _onFrameFallido,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                // Deja libre la esquina inferior izquierda (linterna del lector).
                padding: const EdgeInsets.fromLTRB(52, 0, AppEspaciado.lg, AppEspaciado.md),
                child: Material(
                  color: Colors.transparent,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(
                        AppEspaciado.radioBoton,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppEspaciado.md,
                        vertical: AppEspaciado.md,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.center_focus_strong_outlined,
                                size: AppTamanoIcono.mediano,
                                color: SisVacuMarca.vercelestePrimario,
                              ),
                              const SizedBox(width: AppEspaciado.sm),
                              Expanded(
                                child: Text(
                                  'Centrá el código de barras (frente o reverso) en el marco.',
                                  style: tt.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    height: 1.35,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 350),
                            crossFadeState: _mostrarConsejoLargo
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: const SizedBox(width: double.infinity),
                            secondChild: Padding(
                              padding: const EdgeInsets.only(top: AppEspaciado.sm, left: AppEspaciado.xs),
                              child: Text(
                                'Si no detecta: DNI derecho, sin inclinar, con buena luz.',
                                style: tt.bodySmall?.copyWith(
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pantalla mientras la cámara inicializa (antes era solo negro).
class _CamaraCargando extends StatelessWidget {
  const _CamaraCargando();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: AppTamanoIcono.grande,
              height: AppTamanoIcono.grande,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppEspaciado.lg),
            Text(
              'Preparando cámara…',
              style: tt.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppEspaciado.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppEspaciado.xxl),
              child: Text(
                'Puede tardar unos segundos la primera vez.',
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(
                  color: Colors.white70,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
