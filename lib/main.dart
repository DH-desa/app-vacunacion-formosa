import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/core/debug/dev_overlay.dart';
import 'package:sistema_vacunacion/src/presentation/state/enviroment_service.dart';
import 'package:sistema_vacunacion/src/presentation/state/tema_app_service.dart';

import 'src/pages/pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Solo reportar crashes de builds release: los de kDebugMode son ruido de
  // desarrollo, no señal real de producción.
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    kReleaseMode,
  );
  FlutterError.onError = (errorDetails) {
    FlutterError.presentError(errorDetails);
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await temaAppService.inicializar();
  _buildReleaseErrorWidgetBuilder();
  AppConfig appconfig = AppConfig(enviroment: 'DEV');
  enviromentService.cargarEnviroment(appconfig);

  runApp(const MyApp());
}

_buildReleaseErrorWidgetBuilder() {
  if (kReleaseMode) {
    ErrorWidget.builder = (errorDetails) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        color: Colors.black12,
        child: const Text(
          'No se pudo mostrar este contenido.\nProbá volver atrás e intentar de nuevo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      );
    };
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: temaAppService,
      builder: (context, _) {
        return _buildMaterialApp();
      },
    );
  }

  MaterialApp _buildMaterialApp() {
    final env = enviromentService.envState?.enviroment;
    return MaterialApp(
      debugShowCheckedModeBanner: env == 'DEV',
      builder: (context, child) {
        final clamped = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Limitar solo el máximo: los widgets de Flutter pueden aplicar
            // límites menores al mismo TextScaler (por ejemplo, el calendario).
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: 1.3),
          ),
          child: env == 'DEV' ? DevOverlay(child: child!) : child!,
        );
        return clamped;
      },
      initialRoute: LoginBody.nombreRuta,
      theme: SisVacuTheme.light.theme,
      darkTheme: SisVacuTheme.light.temaOscuro,
      themeMode: temaAppService.modoTema,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale("es", "ES"), // Español
      ],
      routes: {
        LoginBody.nombreRuta: (BuildContext context) => const LoginBody(),
        VacunadorPage.nombreRuta: (BuildContext context) =>
            const VacunadorPage(infoCargador: []),
        BusquedaBeneficiario.nombreRuta: (context) =>
            const BusquedaBeneficiario(),
        VacunasPage.nombreRuta: (BuildContext context) => const VacunasPage(),
      },
    );
  }
}
