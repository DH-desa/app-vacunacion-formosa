import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:sistema_vacunacion/src/domain/entities/sistema/changelog_app_models.dart';

/// Carga el historial de versiones embebido (sin red).
class ChangelogAppService {
  ChangelogAppService._();

  static const String rutaAsset = 'assets/app/changelog.json';

  static Future<List<EntradaChangelogApp>> cargar() async {
    final String raw = await rootBundle.loadString(rutaAsset);
    final Map<String, dynamic> decoded =
        jsonDecode(raw) as Map<String, dynamic>;
    final List<dynamic> listado =
        decoded['releases'] as List<dynamic>? ?? <dynamic>[];
    return listado
        .map((dynamic e) => EntradaChangelogApp.fromJson(
              Map<String, dynamic>.from(e as Map<dynamic, dynamic>),
            ))
        .toList();
  }
}
