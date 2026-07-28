import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/utils/edad_pdf417_dni_arg.dart';
import 'package:sistema_vacunacion/src/utils/encoding_utils.dart';

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

  /// Solo tipo 'Beneficiario': si se provee, tras cargar el beneficiario en
  /// [beneficiarioService] NO navega a VacunasPage; devuelve el control a la
  /// pantalla anfitriona (que muestra la situación y continúa).
  final VoidCallback? onBeneficiarioCargado;

  const EscanerDni(
    this.tipoEscaneo,
    this.textoBoton, {
    Key? key,
    this.anchoValor,
    this.largoValor,
    this.iconBool,
    this.onBeneficiarioCargado,
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
      MaterialPageRoute<String>(
        builder: (context) => _ScannerPage(
          confirmarEnCamaraAntesDeSalir: widget.tipoEscaneo == 'Beneficiario',
        ),
      ),
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
                  ));
          loadingLoginService.cargarEstado(false);
          break;
        }

        loadingLoginService.cargarEstado(true, mensaje: 'Validando usuario...');
        try {
          final respUsuario =
              await authRepository.validarUsuariosNuevo(dniPersona);
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
                    color: Theme.of(dialogCtx).colorScheme.error);
              });
          loadingLoginService.cargarEstado(false);
        } else {
          if (respUsuario[0].sysofic01_descripcion != null) {
            registradorService.cargarRegistrador(respUsuario[0]);
            if (datosdecargaprovider.versionApp == 'Ok') {
              loadingLoginService.cargarEstado(false);
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => VacunadorPage(
                            infoCargador: respUsuario,
                          )),
                  (Route<dynamic> route) => false);
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
                        color: Theme.of(context).colorScheme.primary);
                  });
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
                      icon: const Icon(
                        Icons.error_outline,
                        size: 40.0,
                      ),
                      color: Theme.of(dialogCtx).colorScheme.error);
                });
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
                  ));
          loadingLoginService.cargarEstado(false);
          break;
        }

        loadingLoginService.cargarEstado(true, mensaje: 'Validando vacunador...');
        try {
          final respUsuario =
              await vacunadorRepository.validarVacunador(dniPersona);
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
                  ));
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
                  ));
          break;
        }

        // La situación (embarazada/puérpera/personal de salud) se pide antes
        // de llamar al webservice: viaja en esa misma consulta.
        final situacion = await _pedirSituacionBeneficiario();
        if (situacion == null || !mounted) break;

        // Mostrar loading inmediatamente antes de la llamada a la API.
        // pushAndRemoveUntil lo descarta solo en el path exitoso;
        // el catch lo cierra manualmente antes de mostrar el error.
        unawaited(showDialog<void>(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: .72),
          builder: (ctx) => const PopScope(
            canPop: false,
            child: LoadingDialogEstrellas(
              mensaje: 'Buscando datos del beneficiario...',
            ),
          ),
        ));
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
                  ));
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
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
    final nombreT =
        _fusionarTextoApiConEscaneo(b0.sysdesa10_nombre, nombrePersona);
    final apellidoT =
        _fusionarTextoApiConEscaneo(b0.sysdesa10_apellido, apellidoPersona);
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

  /// Diálogo previo a la consulta: pide la situación del beneficiario
  /// (condición gestacional excluyente + personal de salud) para poder
  /// enviarla en la misma llamada a `wserv_obtener_datos_persona.php`.
  /// Devuelve `null` si el usuario cancela.
  Future<({CondicionGestacional? condicion, bool personalSalud})?>
      _pedirSituacionBeneficiario() {
    CondicionGestacional? condicion;
    var personalSalud = false;
    return showDialog<({CondicionGestacional? condicion, bool personalSalud})>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => DialogoAlerta(
          tituloAlerta: 'Situación',
          contenido: SingleChildScrollView(
            child: SituacionBeneficiario(
              sexoEsFemenino: sexoPersona == 'F',
              condicion: condicion,
              esPersonalDeSalud: personalSalud,
              onCondicionChanged: (c) => setStateDialog(() => condicion = c),
              onPersonalSaludChanged: (v) =>
                  setStateDialog(() => personalSalud = v),
            ),
          ),
          dosBotones: true,
          textoBotonAlerta: 'Continuar',
          textoBotonAlerta2: 'Cancelar',
          funcion1: () => Navigator.of(dialogContext).pop((
            condicion: condicion,
            personalSalud: personalSalud,
          )),
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
      final nombreB =
          _fusionarTextoApiConEscaneo(b0.sysdesa10_nombre, nombrePersona);
      final apellidoB =
          _fusionarTextoApiConEscaneo(b0.sysdesa10_apellido, apellidoPersona);
      if (nombreB != null) b0.sysdesa10_nombre = nombreB;
      if (apellidoB != null) b0.sysdesa10_apellido = apellidoB;
      setState(() {
        beneficiarioService.cargarBeneficiario(
          b0,
          edadAniosDesdePdf417Escaneado: _edadAniosPdf417Escaneo,
          fechaNacimientoDesdePdf417Escaneado: _fechaNacPdf417Escaneo,
        );
      });

      final notificaciones = await sistemaRepository.validarNotificaciones(
        dni,
        sexoPersona,
        embarazada: embarazada,
        puerpera: puerpera,
        personalSalud: personalSalud,
        edadDias: beneficiarioService.diasDeVidaBeneficiario,
      );
      notificaciones.isNotEmpty
          ? {
              notificacionesDosisService.cargarListaDosis(notificaciones),
            }
          : notificacionesDosisService.cargarRegistro(NotificacionesDosis());
      loadingLoginService.cargarEstado(false);
      if (!mounted) return;
      if (widget.onBeneficiarioCargado != null) {
        // Cierra el loading «Buscando datos...» y devuelve el control a la
        // pantalla anfitriona (situación + continuar se resuelven allí).
        Navigator.of(context).pop();
        widget.onBeneficiarioCargado!();
      } else {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const VacunasPage()),
            (Route<dynamic> route) => false);
      }
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

    final datos = _parsearPdf417DniArgentino(partes);

    setState(() {
      if (datos != null && _kRegexDni.hasMatch(datos.dni)) {
        apellidoPersona = datos.apellido;
        nombrePersona = datos.nombre;
        dniPersona = datos.dni;
        sexoPersona = datos.sexo;
        numeroTramite = datos.tramite;
        codigodebarras = cadenaApi;
        _fechaNacPdf417Escaneo = datos.fechaNacimientoPdf417;
        final anios = aniosCumplidosDesdeFechaNacimientoTexto(
          datos.fechaNacimientoPdf417,
        );
        _edadAniosPdf417Escaneo = anios?.toString();
      } else {
        dniPersona = null;
        _fechaNacPdf417Escaneo = null;
        _edadAniosPdf417Escaneo = null;
      }
    });
  }

}

/// Resultado del parseo del PDF417 para uso interno del escáner.
class _DatosDniPdf417 {
  const _DatosDniPdf417({
    required this.apellido,
    required this.nombre,
    required this.dni,
    required this.sexo,
    required this.tramite,
    this.fechaNacimientoPdf417,
  });

  final String apellido;
  final String nombre;
  final String dni;
  final String sexo;
  final String tramite;

  /// Fecha de nacimiento tal como viene en el PDF417 (DD/MM/AAAA o ISO).
  final String? fechaNacimientoPdf417;
}

/// DNI viejo (17 campos) primero; luego layout “nuevo” por posiciones (cualquier N≥5);
/// si no aplica, heurística por dígitos y texto.
_DatosDniPdf417? _parsearPdf417DniArgentino(List<String> p) {
  final n = p.length;
  final fn = fechaNacimientoDesdePartesPdf417(p);

  // Formato anterior: PDF417 del reverso (16 o 17 campos con @).
  if (n == 17 || n == 16) {
    final dni = p[1].replaceAll(RegExp(r'\s'), '');
    final sx = _normalizarSexoPdf417(p[8]);
    if (_kRegexDni.hasMatch(dni) && sx != null) {
      return _DatosDniPdf417(
        apellido: p[4],
        nombre: p[5],
        dni: dni,
        sexo: sx,
        tramite: p[10],
        fechaNacimientoPdf417: fn,
      );
    }
    final h = _parseoHeuristicoPdf417(p);
    if (h == null) return null;
    return _DatosDniPdf417(
      apellido: h.apellido,
      nombre: h.nombre,
      dni: h.dni,
      sexo: h.sexo,
      tramite: h.tramite,
      fechaNacimientoPdf417: fn ?? h.fechaNacimientoPdf417,
    );
  }

  if (n >= 5) {
    final dni = p[4].replaceAll(RegExp(r'\s'), '');
    final sx = _normalizarSexoPdf417(p[3]);
    if (_kRegexDni.hasMatch(dni) && sx != null) {
      return _DatosDniPdf417(
        apellido: p[1],
        nombre: p[2],
        dni: dni,
        sexo: sx,
        tramite: p[0],
        fechaNacimientoPdf417: fn,
      );
    }
  }

  final h = _parseoHeuristicoPdf417(p);
  if (h == null) return null;
  return _DatosDniPdf417(
    apellido: h.apellido,
    nombre: h.nombre,
    dni: h.dni,
    sexo: h.sexo,
    tramite: h.tramite,
    fechaNacimientoPdf417: fn ?? h.fechaNacimientoPdf417,
  );
}

/// M / F / X (género no binario, habilitado por Renaper desde 2021).
/// Devuelve `null` si [raw] no es un valor de sexo reconocible — el caller
/// debe tratarlo como fallo de parseo, nunca asumir un sexo por default.
String? _normalizarSexoPdf417(String raw) {
  final u = raw.trim().toUpperCase();
  if (u == 'M' || u == 'MASCULINO') return 'M';
  if (u == 'X') return 'X';
  if (u == 'F' || u == 'FEMENINO') return 'F';
  return null;
}

_DatosDniPdf417? _parseoHeuristicoPdf417(List<String> p) {
  String? dni;
  int? idxDni;

  // Posición habitual del DNI en layout nuevo (evita confundir con otros números de 7–8 dígitos).
  if (p.length > 4) {
    final t4 = p[4].replaceAll(RegExp(r'\s'), '');
    if (_kRegexDni.hasMatch(t4)) {
      dni = t4;
      idxDni = 4;
    }
  }
  if (dni == null) {
    for (var i = 0; i < p.length; i++) {
      final t = p[i].replaceAll(RegExp(r'\s'), '');
      if (_kRegexDni.hasMatch(t)) {
        dni = t;
        idxDni = i;
        break;
      }
    }
  }
  if (dni == null) return null;

  String? sexo;
  for (final s in p) {
    sexo = _normalizarSexoPdf417(s.trim());
    if (sexo != null) break;
  }
  // Ningún campo tiene un valor de sexo reconocible: parseo no confiable,
  // no asumir "F" por default.
  if (sexo == null) return null;

  final textos = <String>[];
  for (var i = 0; i < p.length; i++) {
    final s = p[i].trim();
    if (s.isEmpty) continue;
    if (i == idxDni) continue;
    final soloDigitos = s.replaceAll(RegExp(r'\s'), '');
    if (_kRegexSoloNums.hasMatch(soloDigitos)) continue;
    if (_kRegexSexo.hasMatch(s)) continue;
    if (s.length < 2) continue;
    textos.add(s);
  }
  textos.sort((a, b) => b.length.compareTo(a.length));
  final apellido = textos.isNotEmpty ? textos[0] : '';
  final nombre = textos.length > 1 ? textos[1] : '';
  final tramite = p.isNotEmpty ? p[0] : '';

  return _DatosDniPdf417(
    apellido: apellido,
    nombre: nombre,
    dni: dni,
    sexo: sexo,
    tramite: tramite,
    fechaNacimientoPdf417: null, // el caller ya calculó fn y hace fn ?? h.fechaNacimientoPdf417
  );
}

// Compiled once — se usan en cada evento de scan.
final _kRegexDni      = RegExp(r'^\d{7,8}$');
final _kRegexSexo     = RegExp(r'^[MFX]$', caseSensitive: false);
final _kRegexSoloNums = RegExp(r'^\d+$');

/// El DNI argentino usa exclusivamente PDF417. Code128/Code93 corresponden a
/// licencias de conducir y productos — incluirlos triplica el trabajo nativo por frame.
const int _kFormatosCodigoDniArgentino = Format.pdf417;

/// True si [crudo] tiene forma de lectura de DNI (@ + DNI 7–8 dígitos parseable).
bool _cadenaEsLecturaPlausibleDniArgentino(String crudo) {
  final s = crudo.trim();
  if (s.isEmpty || !s.contains('@')) return false;
  final partes = s.split('@').map((e) => e.trim()).toList();
  final datos = _parsearPdf417DniArgentino(partes);
  return datos != null && _kRegexDni.hasMatch(datos.dni);
}

class _ScannerPage extends StatefulWidget {
  const _ScannerPage({
    this.confirmarEnCamaraAntesDeSalir = false,
  });

  /// Si es true (beneficiario), se muestra confirmación sobre la cámara antes del `pop`.
  final bool confirmarEnCamaraAntesDeSalir;

  @override
  State<_ScannerPage> createState() => _ScannerPageState();
}

/// 90% del ancho: cropPercent=1.0 recorta un cuadrado centrado de lado
/// min(ancho, alto) (ver flutter_zxing reader_widget.dart), NO el fotograma
/// completo — en cámara portrait eso descarta buena parte de la imagen
/// arriba/abajo. PDF417 es horizontal y ancho, necesita área generosa pero
/// no conviene bajar de 0.7.
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

  /// Contador de códigos detectados que no son válidos para el DNI.
  int _contadorLecturasInvalidas = 0;

  /// Timestamp de la última lectura válida o inválida.
  DateTime? _ultimaLecturaIntentada;

  /// Panel de verificación in-camera (solo beneficiario).
  bool _panelConfirmacionVisible = false;
  String? _cadenaPendienteConfirmacion;
  String? _confirmacionDni;
  String? _confirmacionSexoEtiqueta;

  @override
  void initState() {
    super.initState();
    _timerConsejo = Timer(const Duration(seconds: 4), () {
      if (!mounted || _detected) return;
      setState(() => _mostrarConsejoLargo = true);
    });
    _iniciarTemporizadorSinDeteccion();
  }

  Timer? _timerSinDeteccion;

  void _iniciarTemporizadorSinDeteccion() {
    _timerSinDeteccion?.cancel();
    _ultimaLecturaIntentada = DateTime.now();
    _timerSinDeteccion = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || _detected || _panelConfirmacionVisible) return;
      final ahora = DateTime.now();
      final desdeUltima = _ultimaLecturaIntentada != null
          ? ahora.difference(_ultimaLecturaIntentada!).inSeconds
          : 999;
      if (desdeUltima >= 8) {
        _mostrarMensajeSinDeteccion();
        _ultimaLecturaIntentada = ahora;
      }
    });
  }

  @override
  void dispose() {
    _timerConsejo?.cancel();
    _timerSinDeteccion?.cancel();
    super.dispose();
  }

  /// **No llamar a [CameraController.stopImageStream] aquí.**
  ///
  /// Si paramos el stream antes del `pop`, al desmontarse [ReaderWidget] el
  /// `dispose` de `flutter_zxing` ejecuta `_stopCamera()` con lógica invertida:
  /// cuando *ya no* hay stream vuelve a invocar `stopImageStream()`, y el plugin
  /// `camera` lanza `CameraException(No camera is streaming images, ...)` —
  /// error no capturado que rompe el flujo (logcat: línea reader_widget.dart:318).
  /// El cierre correcto lo hace `_disposeController()` del paquete, que sí verifica
  /// `isStreamingImages` antes de detener.
  void _onDetected(String rawValue) {
    if (_detected || !mounted) return;
    _detected = true;
    _timerConsejo?.cancel();
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(rawValue);
  }

  /// Muestra feedback cuando se detecta un código que no corresponde al DNI.
  /// [codigoDetectado] puede ser null si solo se quiere mostrar el mensaje genérico.
  /// [forzarMensaje] reemplaza el mensaje calculado por uno personalizado.
  void _avisarCodigoNoEsDni({String? codigoDetectado, String? forzarMensaje}) {
    if (!mounted || _detected || _panelConfirmacionVisible) return;
    final ahora = DateTime.now();
    if (_ultimoAvisoLecturaInvalida != null &&
        ahora.difference(_ultimoAvisoLecturaInvalida!) <
            const Duration(seconds: 1)) {
      return;
    }
    _ultimoAvisoLecturaInvalida = ahora;
    _contadorLecturasInvalidas++;
    final tt = Theme.of(context).textTheme;

    String mensaje;
    if (forzarMensaje != null) {
      mensaje = forzarMensaje;
    } else if (_contadorLecturasInvalidas >= 3) {
      mensaje = 'Seguís intentando con un código que no corresponde al DNI.\n'
          'Tarjeta nueva (plástico): PDF417 del frente.\n'
          'Tarjeta anterior (cartón): PDF417 del reverso.';
    } else {
      mensaje = 'Ese código no es del DNI argentino.\n'
          'Usá el código de barras del frente (tarjeta nueva) o del reverso (tarjeta anterior).\n'
          'Mantené la cámara abierta.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        duration: Duration(seconds: _contadorLecturasInvalidas >= 3 ? 5 : 3),
        backgroundColor: const Color(0xE6000000),
        content: Text(
          codigoDetectado != null && codigoDetectado.contains('@') && forzarMensaje == null
              ? 'Se leyó un PDF417 pero no tiene el formato del DNI argentino.\n$mensaje'
              : mensaje,
          style: tt.bodyMedium?.copyWith(
            color: Colors.white,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  /// Muestra mensaje cuando no se detecta ningún código durante un período.
  void _mostrarMensajeSinDeteccion() {
    if (!mounted || _detected || _panelConfirmacionVisible) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xE6000000),
        content: Text(
          'No se detectó ningún código. Acercá el DNI al marco y asegurate de que esté bien iluminado.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                height: 1.35,
              ),
        ),
      ),
    );
  }

  void _procesarCodigoLeido(Code result) {
    if (_detected || _panelConfirmacionVisible) return;
    _ultimaLecturaIntentada = DateTime.now();
    final decodificado = decodificarCadenaPdf417Argentino(
      result.rawBytes,
      result.text,
    ).trim();
    if (decodificado.isEmpty) return;
    if (!(result.isValid || decodificado.contains('@'))) return;
    if (!_cadenaEsLecturaPlausibleDniArgentino(decodificado)) {
      _avisarCodigoNoEsDni(codigoDetectado: decodificado);
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _contadorLecturasInvalidas = 0;
    if (widget.confirmarEnCamaraAntesDeSalir) {
      _abrirPanelConfirmacion(decodificado);
    } else {
      _onDetected(decodificado);
    }
  }

  void _abrirPanelConfirmacion(String crudo) {
    final partes = crudo.split('@').map((e) => e.trim()).toList();
    final datos = _parsearPdf417DniArgentino(partes);
    if (datos == null || !_kRegexDni.hasMatch(datos.dni)) {
      _avisarCodigoNoEsDni();
      return;
    }
    final sx = datos.sexo;
    final etiquetaSexo = sx == 'M' ? 'Masculino' : sx == 'X' ? 'No binario (X)' : 'Femenino';
    setState(() {
      _panelConfirmacionVisible = true;
      _cadenaPendienteConfirmacion = crudo;
      _confirmacionDni = datos.dni;
      _confirmacionSexoEtiqueta = etiquetaSexo;
    });
    HapticFeedback.lightImpact();
  }

  void _cerrarPanelConfirmacionReescanear() {
    setState(() {
      _panelConfirmacionVisible = false;
      _cadenaPendienteConfirmacion = null;
      _confirmacionDni = null;
      _confirmacionSexoEtiqueta = null;
    });
  }

  void _confirmarLecturaYsalir() {
    final s = _cadenaPendienteConfirmacion;
    if (s == null) return;
    _onDetected(s);
  }

  void _salirSinConfirmar() {
    if (!mounted) return;
    _timerConsejo?.cancel();
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
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
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ReaderWidget(
            codeFormat: _kFormatosCodigoDniArgentino,
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
            // PDF417 impreso en DNI moderno es legible sin estrategias extra.
            tryHarder: false,
            tryDownscale: true,
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
          ),
          if (!_panelConfirmacionVisible)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  // Deja libre la esquina inferior izquierda (linterna del lector).
                  padding: const EdgeInsets.fromLTRB(52, 0, 16, 14),
                  child: Material(
                    color: Colors.transparent,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.62),
                        borderRadius:
                            BorderRadius.circular(AppEspaciado.radioBoton),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
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
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Tarjeta nueva (plástico): PDF417 del frente. '
                                    'Tarjeta anterior (cartón): PDF417 del reverso. '
                                    'Centrá el código de barras en el marco.',
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
                                padding:
                                    const EdgeInsets.only(top: 10, left: 4),
                                child: Text(
                                  'Si no detecta: probá el otro lado del DNI, más luz o linterna, '
                                  'sin reflejos, y documento firme.',
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
          if (_panelConfirmacionVisible) _PanelConfirmacionLecturaDni(
            dni: _confirmacionDni ?? '',
            sexoEtiqueta: _confirmacionSexoEtiqueta ?? '',
            onConfirmar: _confirmarLecturaYsalir,
            onEscanearDeNuevo: _cerrarPanelConfirmacionReescanear,
            onSalir: _salirSinConfirmar,
          ),
        ],
      ),
    );
  }
}

/// Confirmación sobre el preview de cámara (sin modal en la ruta anterior).
class _PanelConfirmacionLecturaDni extends StatelessWidget {
  const _PanelConfirmacionLecturaDni({
    required this.dni,
    required this.sexoEtiqueta,
    required this.onConfirmar,
    required this.onEscanearDeNuevo,
    required this.onSalir,
  });

  final String dni;
  final String sexoEtiqueta;
  final VoidCallback onConfirmar;
  final VoidCallback onEscanearDeNuevo;
  final VoidCallback onSalir;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final colorAcento = SisVacuMarca.vercelesteCuaternario;

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.72),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: onSalir,
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Cerrar cámara',
                  ),
                ),
                const Spacer(),
                FaIcon(
                  FontAwesomeIcons.circleCheck,
                  size: AppTamanoIcono.extraGrande,
                  color: colorAcento,
                ),
                const SizedBox(height: 16),
                Text(
                  'Verificar lectura',
                  style: tt.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppEspaciado.radioBoton),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'D.N.I.',
                        style: tt.labelMedium?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dni,
                        style: tt.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sexo registrado',
                        style: tt.labelMedium?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sexoEtiqueta,
                        style: tt.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onConfirmar,
                    style: AppBotones.estiloFilledCta(),
                    child: const Text('Confirmar y continuar'),
                  ),
                ),
                const SizedBox(height: AppEspaciado.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onEscanearDeNuevo,
                    style: AppBotones.estiloOutlinedSobreOscuro(),
                    child: const Text('Escanear de nuevo'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onSalir,
                  style: AppBotones.estiloTextoSobreOscuro(),
                  child: const Text('Salir sin cargar'),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
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
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Preparando cámara…',
              style: tt.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
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
