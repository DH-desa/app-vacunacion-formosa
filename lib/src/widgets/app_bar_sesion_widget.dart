import 'package:flutter/material.dart';

import 'package:sistema_vacunacion/src/config/config.dart';

class AppBarSesion extends StatelessWidget implements PreferredSizeWidget {
  const AppBarSesion({
    Key? key,
    required this.titulo,
    this.leading,
    this.actions,
  }) : super(key: key);

  final String titulo;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bar = theme.appBarTheme;

    final TextStyle? baseTitulo = bar.titleTextStyle;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: bar.scrolledUnderElevation ?? 3,
      shadowColor: bar.shadowColor,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.none,
      systemOverlayStyle: bar.systemOverlayStyle,
      centerTitle: true,
      iconTheme: bar.iconTheme,
      actionsIconTheme: bar.actionsIconTheme,
      leading: leading,
      automaticallyImplyLeading: leading == null,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(AppEspaciado.radioCampo),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.45 : 0.18,
              ),
              offset: const Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
          border: Border(
            bottom: BorderSide(
              color: cs.onPrimary.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
        ),
        child: const SizedBox.expand(),
      ),
      title: Text(
        titulo,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: baseTitulo,
      ),
      actions: actions,
    );
  }
}