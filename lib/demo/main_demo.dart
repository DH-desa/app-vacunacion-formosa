// Entry point de la DEMO educativa. Corre la MISMA app real (MyApp, sin
// modificar) pero con todo el tráfico http interceptado por
// DemoFakeHttpClient: nada llega a dh.formosa.gob.ar, todo se responde con
// JSON falso que respeta las claves que la app espera. Consecuencia: se
// puede usar sin miedo, equivocarse y registrar vacunas sin impacto en BD.
//
// Cómo correr (Android físico con cámara):
//   flutter run -d <id-dispositivo> --flavor demo -t lib/demo/main_demo.dart
// Cómo buildear un APK demo:
//   flutter build apk --flavor demo -t lib/demo/main_demo.dart
//
// El --flavor es obligatorio (build.gradle define flavorDimensions "env"
// con demo/prod): sin él, Gradle no sabe qué applicationId instalar y el
// dispositivo puede terminar mostrando la build vieja del otro flavor.
//
// Produción (sin -t, --flavor prod) corre lib/main.dart con el backend
// real: la demo no lo afecta porque la intercepción vive en ESTE archivo,
// no en MyApp.
//
// Ver docs/demo_guia.md para la matriz de validaciones y DNI de muestra.

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/presentation/state/enviroment_service.dart';
import 'package:sistema_vacunacion/src/presentation/state/tema_app_service.dart';
import 'package:sistema_vacunacion/main.dart' show MyApp;

import 'demo_fake_http_client.dart';

Future<void> main() async {
  // Todo el setup (bindings incluidos) tiene que correr DENTRO de la zona de
  // runWithClient: si ensureInitialized() corre afuera, Flutter tira "Zone
  // mismatch" porque runApp queda en una zona distinta a la de los bindings.
  await http.runWithClient(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await temaAppService.inicializar();
    // Entorno DEMO: la app se ve idéntica a producción (sin botón DESA, sin
    // DevOverlay, sin banner de debug). Esos artefactos solo viven en 'DEV'.
    enviromentService.cargarEnviroment(AppConfig(enviroment: 'DEMO'));
    runApp(const MyApp());
  }, DemoFakeHttpClient.new);
}