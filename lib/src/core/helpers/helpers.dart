import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/pages/login/login_page.dart';
import 'package:sistema_vacunacion/src/presentation/state/services.dart';
import 'package:sistema_vacunacion/src/widgets/widgets.dart';

/// Limpia el estado de sesión del equipo y vuelve al login. Compartido por
/// el botón "Cerrar sesión" del drawer y la confirmación al presionar atrás
/// (ver [onWillPop]) — una sola implementación del logout real.
void cerrarSesion(BuildContext context) {
  loadingLoginService.cargarEstado(false);
  sesionEquipoVacunacionService.reiniciar();
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const LoginBody()),
  );
}

/// Confirmación al presionar atrás en una pantalla con sesión activa. Si el
/// usuario confirma, cierra la sesión; si cancela, no hace nada.
Future<bool> onWillPop(BuildContext context) async {
  final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => DialogoAlerta(
            dosBotones: true,
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
            icon: const Icon(
              Icons.new_releases_outlined,
              size: 40.0,
            ),
          ));
  if (confirmar == true && context.mounted) {
    cerrarSesion(context);
  }
  return confirmar ?? false;
}

Widget titulos(BuildContext context, String titulo) {
  return FadeInUpBig(
    from: 25,
    child: Text(
      titulo,
      style: context.sisTipografia.tituloSeccion.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}
