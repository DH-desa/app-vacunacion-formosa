import 'dart:io';

import 'package:flutter/material.dart';

class BackgroundHeader extends StatelessWidget {
  final Widget? child;
  final File? image;

  static const double _fraccionTopFondoBlanco = 0.485;

  const BackgroundHeader({Key? key, this.child, this.image}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        _buildPhotoBackground(context, image, size),
        Positioned(
          top: size.width * _fraccionTopFondoBlanco,
          child: _whiteBackground(context, size),
        ),
        child!,
      ],
    );
  }

  Widget _buildPhotoBackground(BuildContext context, File? image, Size size) {
    return SingleChildScrollView(
      child: SizedBox(
        height: size.height,
        width: size.width,
        child: Center(
          child: image != null
              ? Image.file(
                  image,
                  height: size.height,
                  width: size.width,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  'assets/img/fondo/bkgroundApp.png',
                  height: size.height,
                  width: size.width,
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }

  Widget _whiteBackground(BuildContext context, Size size) {
    return Stack(
      children: [
        Container(
          height: size.height,
          width: size.width,
          color: Theme.of(context).colorScheme.surface,
        ),
      ],
    );
  }
}
