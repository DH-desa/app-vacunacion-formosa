import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_spacing_config.dart';
import 'app_typography_extension.dart';

/// Colores de marca (no cambian con el brillo; se usan en acentos y AppBar).
class SisVacuMarca {
  SisVacuMarca._();

  static const Color vercelesteCuaternario = Color(0xff009CAF);
  static const Color vercelestePrimario = Color(0xff005661);
  static const Color verceleste = Color(0xFF00B0C7);
  static const Color vercelesteTerciario = Color(0xff00D1ED);
  static const Color verdefuerte = Color.fromRGBO(118, 214, 203, 1);
  static const Color primaryRed = Color(0xFFFE3D2E);
  static const Color primaryGreen = Color(0xFF39E489);
  static const Color azulFormosa = Color(0xff004B8E);
}

class SisVacuTheme {
  /// Tema claro por defecto (paleta legacy + colores de marca).
  static final SisVacuTheme light = SisVacuTheme._claro();

  /// Instancia oscura solo referencial; el [ThemeData] oscuro sale de [temaOscuro].
  static final SisVacuTheme dark = SisVacuTheme._oscuro();

  @Deprecated('Usar SisVacuTheme.light')
  static SisVacuTheme get defaultTheme => light;

  ThemeData get theme => _construirThemeData(_esquemaClaro());
  ThemeData get temaOscuro => _construirThemeData(_esquemaOscuro());

  final int? id;
  final Color? primaryGreen;
  final Color? primaryRed;
  final Color? verdefuerte;
  final Color? verdeclaro;
  final Color? black;
  final Color? white;
  final Color? grey200;
  final Color? verceleste;
  final Color? vercelestePrimario;
  final Color? vercelesteSecundario;
  final Color? vercelesteTerciario;
  final Color? vercelesteCuaternario;
  final Color? azulFormosa;
  final Color? yellow700;
  final Color? pink;
  final Color? orange;
  final Color? purple;
  final Color? red;
  final Color? inputsColor;
  final Brightness? brightness;
  final Color? borderContainers;

  const SisVacuTheme._({
    this.id,
    this.primaryGreen,
    this.primaryRed,
    this.verdefuerte,
    this.verdeclaro,
    this.black,
    this.white,
    this.grey200,
    this.verceleste,
    this.vercelestePrimario,
    this.vercelesteSecundario,
    this.vercelesteTerciario,
    this.vercelesteCuaternario,
    this.azulFormosa,
    this.yellow700,
    this.pink,
    this.orange,
    this.purple,
    this.red,
    this.inputsColor,
    this.brightness,
    this.borderContainers,
  });

  factory SisVacuTheme._claro() {
    return SisVacuTheme._(
      id: 1,
      primaryGreen: SisVacuMarca.primaryGreen,
      primaryRed: SisVacuMarca.primaryRed,
      verdefuerte: SisVacuMarca.verdefuerte,
      verdeclaro: const Color.fromRGBO(189, 233, 227, 1),
      borderContainers: const Color.fromRGBO(202, 215, 230, 1),
      black: const Color(0xff071C07),
      white: const Color(0xffF2F2F2),
      grey200: Colors.grey[200],
      verceleste: SisVacuMarca.verceleste,
      vercelestePrimario: SisVacuMarca.vercelestePrimario,
      vercelesteSecundario: const Color(0xff00C6E0),
      vercelesteTerciario: SisVacuMarca.vercelesteTerciario,
      vercelesteCuaternario: SisVacuMarca.vercelesteCuaternario,
      azulFormosa: SisVacuMarca.azulFormosa,
      yellow700: Colors.yellow[700],
      pink: Colors.pink,
      orange: Colors.orange,
      purple: Colors.purple,
      red: Colors.red,
      inputsColor: const Color.fromRGBO(199, 224, 211, 0.57),
      brightness: Brightness.light,
    );
  }

  /// Referencia para futuras extensiones; colores de marca accesibles via [SisVacuMarca].
  factory SisVacuTheme._oscuro() {
    return SisVacuTheme._(
      id: 2,
      primaryGreen: SisVacuMarca.primaryGreen,
      primaryRed: SisVacuMarca.primaryRed,
      verdefuerte: SisVacuMarca.verdefuerte,
      verdeclaro: const Color.fromRGBO(60, 90, 86, 1),
      borderContainers: const Color(0xFF3D4A55),
      black: const Color(0xFFE8E8E8),
      white: const Color(0xFF121212),
      grey200: Colors.grey[700],
      verceleste: const Color(0xFF4DD0E1),
      vercelestePrimario: const Color(0xFF80DEEA),
      vercelesteSecundario: const Color(0xFF4DD0E1),
      vercelesteTerciario: const Color(0xFF6FF4FF),
      vercelesteCuaternario: const Color(0xFF5BC8D8),
      azulFormosa: const Color(0xFF6BA3D6),
      yellow700: Colors.yellow[400],
      pink: Colors.pink[200],
      orange: Colors.orange[300],
      purple: Colors.purple[200],
      red: Colors.red[300],
      inputsColor: const Color.fromRGBO(80, 120, 100, 0.45),
      brightness: Brightness.dark,
    );
  }

  ColorScheme _esquemaClaro() {
    // Base clara + tonos surface M3 (jerarquía de capas sin depender de defaults).
    return ColorScheme.light(
      primary: vercelesteCuaternario!,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFB8E8EF),
      onPrimaryContainer: const Color(0xFF003741),
      secondary: verdefuerte!,
      onSecondary: black!,
      surface: const Color(0xFFF5F6F8),
      onSurface: black!,
      error: primaryRed!,
      onError: Colors.white,
      tertiary: vercelesteTerciario,
      outline: borderContainers,
    ).copyWith(
      onSurfaceVariant: const Color(0xFF536066),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF0F2F4),
      surfaceContainer: const Color(0xFFEAECEF),
      surfaceContainerHigh: const Color(0xFFE2E6EA),
      surfaceContainerHighest: const Color(0xFFDADFE4),
      outlineVariant: const Color(0xFFC5CCD4),
      scrim: Colors.black,
    );
  }

  ColorScheme _esquemaOscuro() {
    return ColorScheme.fromSeed(
      seedColor: SisVacuMarca.vercelesteCuaternario,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF5DD4E8),
      onPrimary: const Color(0xFF001920),
      primaryContainer: const Color(0xFF004C5C),
      onPrimaryContainer: const Color(0xFFB8EEF7),
      secondary: const Color(0xFF7FD0C2),
      onSecondary: const Color(0xFF001F1A),
      tertiary: const Color(0xFF68D6EE),
      surface: const Color(0xFF121212),
      onSurface: const Color(0xFFECECEC),
      onSurfaceVariant: const Color(0xFFB8C0C6),
      surfaceContainerLowest: const Color(0xFF0C0C0C),
      surfaceContainerLow: const Color(0xFF181818),
      surfaceContainer: const Color(0xFF1E1E1E),
      surfaceContainerHigh: const Color(0xFF2C2C2C),
      surfaceContainerHighest: const Color(0xFF383838),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
      outline: const Color(0xFF8E9AA3),
      outlineVariant: const Color(0xFF5A656E),
    );
  }

  ThemeData _construirThemeData(ColorScheme colorScheme) {
    final bool oscuro = colorScheme.brightness == Brightness.dark;
    final TextTheme textoBase = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
    ).textTheme;
    final TextTheme nunito = GoogleFonts.nunitoTextTheme(textoBase).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      primaryColor: SisVacuMarca.vercelesteCuaternario,
      scaffoldBackgroundColor: colorScheme.surface,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: nunito,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: oscuro ? 4 : 3,
        shadowColor: Colors.black.withValues(alpha: oscuro ? 0.4 : 0.2),
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.nunito(
          textStyle: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            height: 1.2,
            letterSpacing: -0.2,
            color: colorScheme.onPrimary,
          ),
        ),
        toolbarHeight: kToolbarHeight,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        actionsIconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: oscuro ? 0 : 1,
        color: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppEspaciado.radioTarjeta),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: colorScheme.onSurface.withValues(alpha: 0.12),
        deleteIconColor: colorScheme.onSurfaceVariant,
        checkmarkColor: colorScheme.primary,
        labelStyle: nunito.labelLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          height: 1.2,
        ),
        secondaryLabelStyle: nunito.labelLarge?.copyWith(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          height: 1.2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        side: BorderSide(
          color: colorScheme.outline.withValues(alpha: oscuro ? 0.42 : 0.35),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppEspaciado.radioBoton),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadio.radioFAB),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppEspaciado.lg,
            vertical: AppEspaciado.sm,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppEspaciado.radioBoton)),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppEspaciado.lg,
            vertical: AppEspaciado.sm,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppEspaciado.radioBoton)),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppEspaciado.lg,
            vertical: AppEspaciado.sm,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppEspaciado.radioBoton)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppEspaciado.md,
            vertical: AppEspaciado.sm,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppEspaciado.radioBoton)),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: oscuro ? 0.6 : 0.85,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppEspaciado.radioCampo),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: oscuro ? 0.45 : 0.38),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppEspaciado.radioCampo),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: oscuro ? 0.45 : 0.35),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppEspaciado.radioCampo),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppEspaciado.lg,
          vertical: AppEspaciado.sm,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.38);
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          // Apagado: thumb claro sobre carril más oscuro (mejor contraste que outline/track similares).
          if (oscuro) {
            return colorScheme.surfaceContainerHigh;
          }
          return colorScheme.surfaceContainerLowest;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.surfaceContainerHighest.withValues(alpha: 0.45);
          }
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          if (oscuro) {
            return colorScheme.onSurface.withValues(alpha: 0.38);
          }
          return colorScheme.onSurface.withValues(alpha: 0.24);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return colorScheme.onSurface.withValues(alpha: oscuro ? 0.28 : 0.2);
        }),
        trackOutlineWidth: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return 0.0;
          }
          return 1.0;
        }),
        // Icono en el thumb: encendido/apagado se entiende sin cambiar de widget.
        thumbIcon: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return Icon(
              Icons.remove_rounded,
              size: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.38),
            );
          }
          if (states.contains(WidgetState.selected)) {
            return Icon(
              Icons.check_rounded,
              size: 18,
              color: colorScheme.primary,
            );
          }
          return Icon(
            Icons.close_rounded,
            size: 18,
            color: colorScheme.onSurface.withValues(alpha: 0.72),
          );
        }),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 3,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: nunito.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: colorScheme.inversePrimary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppEspaciado.radioBoton)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadio.radioDialog),
        ),
        titleTextStyle: nunito.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: nunito.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        modalBackgroundColor: colorScheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppEspaciado.radioCampo)),
        ),
        dragHandleColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
        showDragHandle: false,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: colorScheme.surfaceContainerHighest,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        textColor: colorScheme.onSurface,
        titleTextStyle: nunito.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: nunito.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppEspaciado.radioBoton),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 450),
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadio.radioTooltip),
        ),
        textStyle: nunito.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline
            .withValues(alpha: oscuro ? 0.35 : 0.45),
        thickness: 1,
        space: 1,
      ),
      bannerTheme: const MaterialBannerThemeData(),
      extensions: <ThemeExtension<dynamic>>[
        SisVacuTipografia.crear(),
      ],
    );
  }
}
