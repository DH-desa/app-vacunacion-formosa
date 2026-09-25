// Entry point temporal para sacar capturas reales de cada pantalla para la
// guía interactiva de web-admin-vacunacion, sin tocar dh.formosa.gob.ar
// (producción). Corre la MISMA app (MyApp real, sin modificar) pero con
// todo el tráfico http interceptado por FakeHttpClient.
//
// flutter run -d macos -t lib/dev_harness/main_captura_guia.dart
//
// No se commitea.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:sistema_vacunacion/src/config/config.dart';
import 'package:sistema_vacunacion/src/presentation/state/enviroment_service.dart';
import 'package:sistema_vacunacion/src/presentation/state/tema_app_service.dart';
import 'package:sistema_vacunacion/main.dart' show MyApp;

import 'fake_http_client.dart';

Future<void> main() async {
  // Todo el setup (bindings incluidos) tiene que correr DENTRO de la zona de
  // runWithClient: si ensureInitialized() corre afuera, Flutter tira "Zone
  // mismatch" porque runApp queda en una zona distinta a la de los bindings.
  await http.runWithClient(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await temaAppService.inicializar();
    // DEV habilita el botón flotante de login sin cámara (ver login_page.dart).
    enviromentService.cargarEnviroment(AppConfig(enviroment: 'DEV'));
    runApp(const MyApp());
  }, FakeHttpClient.new);
}
