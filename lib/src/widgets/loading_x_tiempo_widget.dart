import 'package:flutter/material.dart';

import 'package:sistema_vacunacion/src/config/config.dart';

import 'loading_widget.dart';

/// Diálogo de carga unificado: `LoadingEstrellas` sobre fondo transparente,
/// con mensaje opcional debajo. Único punto de estilo para todo "cargando..."
/// modal de la app.
class LoadingDialogEstrellas extends StatelessWidget {
  final String? mensaje;

  const LoadingDialogEstrellas({Key? key, this.mensaje}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LoadingEstrellas(),
          if (mensaje != null) ...[
            const SizedBox(height: AppEspaciado.lg),
            Text(
              mensaje!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

void mostrarLoadingEstrellasXTiempo(context, int tiempoMili) {
  showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        Future.delayed(Duration(milliseconds: tiempoMili), () {
          Navigator.of(context).pop(true);
        });
        return const LoadingDialogEstrellas();
      });
}
