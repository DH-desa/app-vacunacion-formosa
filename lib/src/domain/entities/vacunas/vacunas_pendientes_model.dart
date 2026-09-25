/// Vacuna pendiente (esperada por rango etario/condición y aún no aplicada),
/// tal como la devuelve `wserv_listados_vacunas.php` en la clave
/// `vacunas_pendientes`. No trae `codigo_mensaje`/`mensaje` como el resto de
/// los modelos de vacunas: si no hay pendientes, la lista viene vacía.
class VacunaPendiente {
  List<VacunaPendiente> items = [];
  VacunaPendiente({
    // ignore: non_constant_identifier_names
    this.rela_sysvacu01,
    // ignore: non_constant_identifier_names
    this.sysvacu01_descripcion,
    // ignore: non_constant_identifier_names
    this.rela_sysvacu02,
    // ignore: non_constant_identifier_names
    this.sysvacu02_descripcion,
    // ignore: non_constant_identifier_names
    this.rela_sysvacu04,
    // ignore: non_constant_identifier_names
    this.sysvacu04_nombre,
    // ignore: non_constant_identifier_names
    this.rela_sysvacu05,
    // ignore: non_constant_identifier_names
    this.sysvacu05_nombre,
    // ignore: non_constant_identifier_names
    this.aplicacion_dentro_limite,
  });

  // ignore: non_constant_identifier_names
  String? rela_sysvacu01;
  // ignore: non_constant_identifier_names
  String? sysvacu01_descripcion;
  // ignore: non_constant_identifier_names
  String? rela_sysvacu02;
  // ignore: non_constant_identifier_names
  String? sysvacu02_descripcion;
  // ignore: non_constant_identifier_names
  String? rela_sysvacu04;
  // ignore: non_constant_identifier_names
  String? sysvacu04_nombre;
  // ignore: non_constant_identifier_names
  String? rela_sysvacu05;
  // ignore: non_constant_identifier_names
  String? sysvacu05_nombre;
  // ignore: non_constant_identifier_names
  int? aplicacion_dentro_limite;

  VacunaPendiente.fromJsonMap(Map<String, dynamic> json) {
    rela_sysvacu01 = json['rela_sysvacu01']?.toString();
    sysvacu01_descripcion = json['sysvacu01_descripcion']?.toString();
    rela_sysvacu02 = json['rela_sysvacu02']?.toString();
    sysvacu02_descripcion = json['sysvacu02_descripcion']?.toString();
    rela_sysvacu04 = json['rela_sysvacu04']?.toString();
    sysvacu04_nombre = json['sysvacu04_nombre']?.toString();
    rela_sysvacu05 = json['rela_sysvacu05']?.toString();
    sysvacu05_nombre = json['sysvacu05_nombre']?.toString();
    aplicacion_dentro_limite = int.tryParse(
      json['aplicacion_dentro_limite']?.toString() ?? '',
    );
  }

  VacunaPendiente.fromJsonList(List<dynamic>? jsonList) {
    if (jsonList == null) return;
    for (final item in jsonList) {
      if (item is! Map) continue;
      items.add(VacunaPendiente.fromJsonMap(Map<String, dynamic>.from(item)));
    }
  }
}
