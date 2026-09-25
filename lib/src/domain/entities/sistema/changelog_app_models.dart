/// Entrada de notas de versión (assets/app/changelog.json).
///
/// Formato recomendado: [features], [fixes], [maintenance]. El campo [items]
/// queda como compatibilidad con versiones antiguas del JSON.
class EntradaChangelogApp {
  EntradaChangelogApp({
    required this.version,
    this.fecha,
    this.titulo,
    this.features = const <String>[],
    this.fixes = const <String>[],
    this.maintenance = const <String>[],
    this.items = const <String>[],
  });

  final String version;
  final String? fecha;
  final String? titulo;
  final List<String> features;
  final List<String> fixes;
  final List<String> maintenance;
  final List<String> items;

  bool get tieneSeccionesTipadas =>
      features.isNotEmpty ||
      fixes.isNotEmpty ||
      maintenance.isNotEmpty;

  static List<String> _listaDesdeClave(Map<String, dynamic> json, String clave) {
    final dynamic raw = json[clave];
    if (raw is! List<dynamic>) return <String>[];
    return raw.map((dynamic e) => e.toString()).toList();
  }

  factory EntradaChangelogApp.fromJson(Map<String, dynamic> json) {
    return EntradaChangelogApp(
      version: json['version']?.toString() ?? '?',
      fecha: json['fecha']?.toString(),
      titulo: json['titulo']?.toString(),
      features: _listaDesdeClave(json, 'features'),
      fixes: _listaDesdeClave(json, 'fixes'),
      maintenance: _listaDesdeClave(json, 'maintenance'),
      items: _listaDesdeClave(json, 'items'),
    );
  }
}
