import 'dart:io';

import 'package:flutter/material.dart';

class BackgroundComplete extends StatelessWidget {
  final Widget? child;
  final File? image;

  const BackgroundComplete({Key? key, this.child, this.image})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [_buildPhotoBackground(context, image), child!]);
  }

  Widget _buildPhotoBackground(BuildContext context, File? image) {
    final size = MediaQuery.sizeOf(context);
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
                  'assets/img/fondo/bkgroundCompleta.png',
                  height: size.height,
                  width: size.width,
                  fit: BoxFit.fill,
                ),
        ),
      ),
    );
  }
}
