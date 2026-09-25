import 'package:sistema_vacunacion/src/domain/entities/models.dart';

import 'estado.dart';

class _RegistradorService {
  final registradorEstado = Estado<Usuarios?>(null);

  Usuarios? get registrador => registradorEstado.value;

  bool get existeRegistrador => registradorEstado.value != null;

  void cargarRegistrador(Usuarios? registrador) {
    registradorEstado.value = registrador;
  }

  void reiniciar() {
    registradorEstado.reiniciar();
  }

  //---------------- Editar el Efector de un Registrador ---------------------------//

  void editarEfectorUsuario(Efectores nuevoEfector) {
    final r = registradorEstado.value!;
    registradorEstado.value = Usuarios(
      id_flxcore03: r.id_flxcore03,
      flxcore03_dni: r.flxcore03_dni,
      flxcore03_nombre: r.flxcore03_nombre,
      rela_sysofic01: nuevoEfector.relaSysofic01,
      sysofic01_descripcion: nuevoEfector.sysofic01Descripcion,
      codigo_mensaje: r.codigo_mensaje,
      mensaje: r.mensaje,
    );
  }
}

final registradorService = _RegistradorService();
