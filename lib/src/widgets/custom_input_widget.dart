import 'package:flutter/material.dart';

import 'package:sistema_vacunacion/src/config/config.dart';

class CustomInput extends StatelessWidget {
  final IconData icon;
  final String placeholder;
  final TextEditingController textController;
  final TextInputType keyboardType;
  final Function()? funcion;
  final EdgeInsets scrollPadding;

  final bool isPassword;
  final bool funcionTerminar;
  final bool autoFocus;
  final int maxLength;
  final FocusNode focusNode;

  const CustomInput({
    super.key,
    required this.icon,
    required this.placeholder,
    required this.textController,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.autoFocus = false,
    this.funcionTerminar = false,
    this.maxLength = 8,
    required this.focusNode,
    this.funcion,
    this.scrollPadding = const EdgeInsets.only(bottom: 120),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.only(
        top: AppEspaciado.xs,
        left: AppEspaciado.xs,
        bottom: AppEspaciado.xs,
        right: AppEspaciado.lg,
      ),
      margin: const EdgeInsets.symmetric(horizontal: AppEspaciado.lg),
      decoration: AppSuperficies.campoBusqueda(context),
      child: TextField(
        autofocus: autoFocus,
        focusNode: focusNode,
        maxLength: maxLength,
        autocorrect: false,
        controller: textController,
        keyboardType: keyboardType,
        obscureText: isPassword,
        onEditingComplete: funcionTerminar ? funcion : null,
        scrollPadding: scrollPadding,
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainer,
          prefixIcon: Icon(icon, size: AppTamanoIcono.mediano),
          focusedBorder: InputBorder.none,
          border: InputBorder.none,
          hintText: placeholder,
        ),
      ),
    );
  }
}