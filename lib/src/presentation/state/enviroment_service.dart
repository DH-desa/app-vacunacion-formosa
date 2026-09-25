import 'dart:async';

import 'package:sistema_vacunacion/src/config/config.dart';

class _EnviromentService {
  AppConfig? envState;

  final StreamController<AppConfig> _envStateStreamController =
      StreamController<AppConfig>.broadcast();

  AppConfig? get getenvState => envState;

  Stream<AppConfig> get envStateStream => _envStateStreamController.stream;

  void cargarEnviroment(AppConfig enviroment) {
    envState = enviroment;

    _envStateStreamController.add(enviroment);
  }

  dispose() {
    _envStateStreamController.close();
  }
}

final enviromentService = _EnviromentService();
