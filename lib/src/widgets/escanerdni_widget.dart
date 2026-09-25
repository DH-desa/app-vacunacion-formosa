import 'dart:async';

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
  /// `null` mientras no se sepa: el QR no trae el campo. Sin default, que
  /// registraría un sexo inventado y elegiría el esquema de vacunación.
  String? sexoPersona;

  /// Lo que confirmó el operador en el panel. Gana sobre el del código: cuando
  /// vino del documento son el mismo valor, y cuando no vino, es el único.
  String? _sexoDesdePanel;

  /// Desde el PDF417 (fecha nac. del DNI).
  String? _fechaNacPdf417Escaneo;
  String? _edadAniosPdf417Escaneo;

  /// Identifica a la persona contra el recurso local y RENAPER: resuelve el sexo
  /// cuando el código no lo trae (QR), avisa cuando el del documento no coincide,
  /// y devuelve la fecha de nacimiento con año de cuatro dígitos.
  /// `false` = no se puede seguir con la consulta.
  Future<bool> _identificarPersona() async {
    if (dniPersona == null) return false;
    IdentificacionBeneficiario ident;
    try {
      ident = await identificacionProviders.identificar(dniPersona!, sexoPersona);
    } catch (_) {
      // Sin identificación no hay sexo para el QR; con PDF417 el documento lo trae
      // y se sigue con ese, como antes de esta validación.
      if (sexoPersona == null) {
        await _avisarIdentificacionSinRespuesta();
        return false;
      }
      return true;
    }
    if (!mounted) return false;

    if (!ident.identificada) {
      if (sexoPersona == null) {
        await _avisarIdentificacionSinRespuesta(mensaje: ident.mensaje);
        return false;
      }
      return true;
    }

    if (ident.estado == 'sexo_no_coincide') {
      final seguir = await _confirmarSexoCorregido(ident);
      if (seguir != true) return false;
    }

    setState(() {
      sexoPersona = ident.sexo;
      if (ident.apellido.isNotEmpty) apellidoPersona = ident.apellido;
      if (ident.nombre.isNotEmpty) nombrePersona = ident.nombre;
      if (ident.nroTramite.isNotEmpty) numeroTramite = ident.nroTramite;
      // La fecha validada reemplaza a la del código: el QR trae el año con dos
      // dígitos y de la edad depende qué vacunas se ofrecen.
      if (ident.fechaNacimiento.isNotEmpty) {
        _fechaNacPdf417Escaneo = ident.fechaNacimiento;
      }
      if (ident.edadAnios.isNotEmpty) _edadAniosPdf417Escaneo = ident.edadAnios;
    });
    return true;
  }

  Future<bool?> _confirmarSexoCorregido(IdentificacionBeneficiario ident) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => DialogoAlerta(
        dosBotones: true,
        envioFuncion2: true,
        envioFuncion1: true,
        funcion1: () => Navigator.of(ctx).pop(true),
        funcion2: () => Navigator.of(ctx).pop(false),
        tituloAlerta: 'El sexo no coincide',
        descripcionAlerta:
            '${ident.mensaje}\n\nSe registrará como ${ident.sexo} '
            '(${ident.apellido}, ${ident.nombre}).',
        textoBotonAlerta: 'Continuar',
        textoBotonAlerta2: 'Cancelar',
        icon: Icon(Icons.info_outline, size: AppTamanoIcono.grande),
        color: Theme.of(ctx).colorScheme.error,
      ),
    );
  }

  Future<void> _avisarIdentificacionSinRespuesta({String mensaje = ''}) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => DialogoAlerta(
        envioFuncion2: false,
        envioFuncion1: false,
        tituloAlerta: 'No se pudo validar la identidad',
        descripcionAlerta: mensaje.isNotEmpty
            ? mensaje
            : 'No se pudo confirmar los datos de la persona. Intente de nuevo o '
                  'cárguela por D.N.I. desde la opción manual.',
        textoBotonAlerta: 'Listo',
        icon: Icon(Icons.info_outline, size: AppTamanoIcono.grande),
        color: Theme.of(ctx).colorScheme.error,
      ),
    );
  }

  /// Red de seguridad: el panel no deja confirmar sin sexo, así que no debería
  /// alcanzarse. Queda porque consultar con sexo vacío escribe en una historia
  /// clínica, y eso no puede depender de una sola barrera.
  Future<void> _avisarSexoNoDisponible() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => DialogoAlerta(
        envioFuncion2: false,
        envioFuncion1: false,
        tituloAlerta: 'Falta el sexo',
        descripcionAlerta:
            'No se pudo determinar el sexo de la persona. Escanee de nuevo o '
            'cárguela por D.N.I. desde la opción manual.',
        textoBotonAlerta: 'Listo',
        icon: Icon(Icons.info_outline, size: AppTamanoIcono.grande),
        color: Theme.of(ctx).colorScheme.error,
      ),
    );
  }

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
    // Beneficiario y Tutor verifican en cámara antes de consultar: son los que
    // mandan sexo a la API y los únicos que pueden necesitar elegirlo.
    final pideConfirmacion =
        widget.tipoEscaneo == 'Beneficiario' || widget.tipoEscaneo == 'Tutor';

    final resultado = await Navigator.push<ResultadoEscaneoDni>(
      context,
      MaterialPageRoute<ResultadoEscaneoDni>(
        builder: (context) => _ScannerPage(confirmarAntesDeSalir: pideConfirmacion),
      ),
    );

    if (!mounted) return;

    // -1 equivale a cancelado.
    if (resultado == null || resultado.cadena == '-1') {
      loadingLoginService.cargarEstado(false);
      return;
    }

    final barcodeScanRes = resultado.cadena;
    _sexoDesdePanel = resultado.sexo;
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

        // El QR no trae el sexo y trae el año con dos dígitos: la identificación
        // resuelve las dos cosas antes de consultar los datos del beneficiario.
        if (!await _identificarPersona()) break;
        if (!mounted) break;
        if (sexoPersona == null) {
          await _avisarSexoNoDisponible();
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

        // Misma identificación que Beneficiario: también consulta con sexo.
        if (!await _identificarPersona()) {
          loadingLoginService.cargarEstado(false);
          break;
        }
        if (!mounted) break;
        if (sexoPersona == null) {
          loadingLoginService.cargarEstado(false);
          await _avisarSexoNoDisponible();
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
    // 'F' explícito: un else mostraría "Femenino" cuando el dato falta.
    final etiquetaSexo = switch (sexoPersona) {
      'M' => 'Masculino',
      'F' => 'Femenino',
      'X' => 'No binario (X)',
      _ => 'Sin especificar',
    };
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
        sexoPersona = datos.sexo ?? _sexoDesdePanel;
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
  }
}

/// PDF417 (documentos vigentes) y QR (electrónico 2026). Conviven, así que el
/// lector acepta los dos. Code128/Code93 quedan afuera: son licencias y
/// productos, y cada formato extra cuesta trabajo nativo por frame.
const int _kFormatosCodigoDniArgentino = Format.pdf417 | Format.qrCode;

/// Lo que devuelve la cámara. El sexo viaja aparte de la cadena porque en el
/// QR no sale del código: lo elige el operador en el panel.
class ResultadoEscaneoDni {
  const ResultadoEscaneoDni(this.cadena, this.sexo);
  final String cadena;
  final String? sexo;
}

class _ScannerPage extends StatefulWidget {
  const _ScannerPage({this.confirmarAntesDeSalir = false});

  /// Beneficiario y Tutor verifican la lectura antes de consultar; Registrador
  /// y Vacunador salen directo porque solo usan el DNI.
  final bool confirmarAntesDeSalir;

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

  /// Lectura esperando confirmación en el panel.
  String? _cadenaPendiente;
  DatosDniPdf417? _datosPendientes;
  String? _sexoElegido;

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
  void _onDetected(String rawValue, String? sexo) {
    if (_detected || !mounted) return;
    _detected = true;
    _timerConsejo?.cancel();
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(ResultadoEscaneoDni(rawValue, sexo));
  }

  /// Abre el panel en vez de salir. El sexo del documento se precarga; si no
  /// vino (QR), queda en null y el botón de confirmar no se habilita.
  void _abrirPanel(String cadena, DatosDniPdf417 datos) {
    _timerConsejo?.cancel();
    _timerSinDeteccion?.cancel();
    HapticFeedback.lightImpact();
    setState(() {
      _cadenaPendiente = cadena;
      _datosPendientes = datos;
      _sexoElegido = datos.sexo;
    });
  }

  void _cerrarPanelYReescanear() {
    setState(() {
      _cadenaPendiente = null;
      _datosPendientes = null;
      _sexoElegido = null;
    });
    _iniciarTemporizadorSinDeteccion();
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
    if (_detected || _cadenaPendiente != null) return;
    _framesTotalesSesion++;
    _logDiagnosticoFrame(result, exitoso: true, framesFallidosPrevios: _framesFallidosConsecutivos);
    _framesFallidosConsecutivos = 0;
    // El QR es ASCII con `@`: sale por la primera comprobación y no entra al
    // reintento Latin-1, que es específico del PDF417.
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

    if (!widget.confirmarAntesDeSalir) {
      _onDetected(decodificado, null);
      return;
    }
    final datos = parsearPdf417DniArgentino(
      decodificado.split('@').map((e) => e.trim()).toList(),
    );
    // cadenaEsLecturaPlausible ya garantizó que parsea; el null check es por tipo.
    if (datos == null) {
      _onDetected(decodificado, null);
      return;
    }
    _abrirPanel(decodificado, datos);
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
      // Con dos formatos suben las lecturas espurias: saber cuál las produce.
      'formato': result.format?.name,
    };
    devLogService.log(DevLogTipo.info, 'EscanerDNI/frame', mensaje, datos: datos);
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
          if (_cadenaPendiente != null && _datosPendientes != null)
            _PanelConfirmacionLecturaDni(
              datos: _datosPendientes!,
              // Sin sexo en el código (QR) igual se puede confirmar: lo resuelve
              // la identificación por D.N.I., no el operador.
              onConfirmar: () => _onDetected(_cadenaPendiente!, _sexoElegido),
              onEscanearDeNuevo: _cerrarPanelYReescanear,
              onSalir: () => Navigator.of(context).pop(null),
            ),
        ],
      ),
    );
  }
}

/// Verificación antes de consultar: muestra lo leído y, cuando el código no
/// trajo el sexo (QR), lo pide. El sexo del documento no se puede editar.
class _PanelConfirmacionLecturaDni extends StatelessWidget {
  const _PanelConfirmacionLecturaDni({
    required this.datos,
    required this.onConfirmar,
    required this.onEscanearDeNuevo,
    required this.onSalir,
  });

  final DatosDniPdf417 datos;
  /// `null` deshabilita el botón: falta elegir el sexo.
  final VoidCallback? onConfirmar;
  final VoidCallback onEscanearDeNuevo;
  final VoidCallback onSalir;

  static String etiquetaSexo(String? s) => switch (s) {
    'M' => 'Masculino',
    'F' => 'Femenino',
    'X' => 'No binario (X)',
    _ => 'Sin especificar',
  };

  Widget _dato(TextTheme tt, String rotulo, String valor, {bool grande = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: tt.labelMedium?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: (grande ? tt.headlineSmall : tt.titleMedium)?.copyWith(
            color: Colors.white,
            fontWeight: grande ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: grande ? 0.5 : 0,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final sexoVinoDelDocumento = datos.sexo != null;
    final nombreCompleto = '${datos.apellido}, ${datos.nombre}'.trim();

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.86),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: onSalir,
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Cerrar cámara',
                    ),
                  ),
                  Text(
                    'Verificar lectura',
                    textAlign: TextAlign.center,
                    style: tt.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppEspaciado.radioBoton),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _dato(tt, 'D.N.I.', datos.dni, grande: true),
                        if (nombreCompleto.length > 2) ...[
                          const SizedBox(height: 14),
                          _dato(tt, 'Nombre', nombreCompleto),
                        ],
                        const SizedBox(height: 14),
                        if (sexoVinoDelDocumento)
                          _dato(tt, 'Sexo registrado', etiquetaSexo(datos.sexo))
                        else
                          Text(
                            'El QR no incluye el sexo: se valida por D.N.I. al continuar',
                            style: tt.labelMedium?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: onConfirmar,
                    style: AppBotones.estiloFilledCta(),
                    child: const Text('Confirmar y continuar'),
                  ),
                  const SizedBox(height: AppEspaciado.sm),
                  OutlinedButton(
                    onPressed: onEscanearDeNuevo,
                    style: AppBotones.estiloOutlinedSobreOscuro(),
                    child: const Text('Escanear de nuevo'),
                  ),
                  TextButton(
                    onPressed: onSalir,
                    style: AppBotones.estiloTextoSobreOscuro(),
                    child: const Text('Salir sin cargar'),
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
