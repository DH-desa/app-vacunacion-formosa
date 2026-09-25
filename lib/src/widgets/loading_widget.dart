import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import 'package:sistema_vacunacion/src/config/config.dart';

// ignore: must_be_immutable
class LoadingEstrellas extends StatelessWidget {
  const LoadingEstrellas({Key? key}) : super(key: key);

  static const double _fraccionAncho = 0.15;
  static const double _ladoMinimo = AppTamanoIcono.extraGrande;
  static const double _ladoMaximo = 96;

  @override
  Widget build(BuildContext context) {
    final double ladoRoulette = (MediaQuery.sizeOf(context).width * _fraccionAncho)
        .clamp(_ladoMinimo, _ladoMaximo)
        .toDouble();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: ladoRoulette,
          height: ladoRoulette,
          child: Roulette(
            duration: const Duration(seconds: 10),
            spins: 0.5,
            child: const Image(
              image: AssetImage('assets/img/fondo/estrellasNuevas.png'),
            ),
          ),
        ),
        // Text(
        //   'Cargando...',
        //   style: GoogleFonts.nunito(
        //       textStyle: const TextStyle(fontWeight: FontWeight.bold)),
        // )
      ],
    );
  }
}
