import 'package:sistema_vacunacion/src/domain/entities/models.dart';

import 'estado.dart';

class _VacunasporPerfiles {
  final vacunasxperfilEstado = Estado<VacunasxPerfil?>(null);
  final listavacunasxperfilEstado = Estado<List<VacunasxPerfil>>([]);
  final listavacunasxperfilBusquedaEstado = Estado<List<VacunasxPerfil>>([]);

  VacunasxPerfil? get vacunasxPerfil => vacunasxperfilEstado.value;

  bool get existeVacunasxPerfil => vacunasxperfilEstado.value != null;

  void cargarVacunasxPerfil(VacunasxPerfil? perfiles) {
    vacunasxperfilEstado.value = perfiles;
  }

  //Manejo de Listas

  List<VacunasxPerfil> get listavacunasxPerfil =>
      listavacunasxperfilEstado.value;

  bool get existelistaVacunasxPerfiles =>
      listavacunasxperfilEstado.value.isNotEmpty;

  void cargarListaVacunasxPerfil(List<VacunasxPerfil> listavacunasxPerfil) {
    final ordenada = List<VacunasxPerfil>.of(listavacunasxPerfil)
      ..sort((a, b) => (a.sysvacu04_nombre ?? '')
          .compareTo(b.sysvacu04_nombre ?? ''));
    listavacunasxperfilEstado.value = ordenada;
    listavacunasxperfilBusquedaEstado.value = ordenada;
  }

  //---------------------  Manejo de Busqueda --------------------------///

  List<VacunasxPerfil> get listavacunasxPerfilBusqueda =>
      listavacunasxperfilBusquedaEstado.value;

  bool get existeBusquedaxPerfiles =>
      listavacunasxperfilBusquedaEstado.value.isNotEmpty;

  void buscarVacuna(String busqueda) {
    listavacunasxperfilBusquedaEstado.value = listavacunasxperfilEstado.value
        .where((element) =>
            element.sysvacu04_nombre!.toUpperCase().contains(busqueda))
        .toList();
  }

  void reiniciar() {
    vacunasxperfilEstado.reiniciar();
    listavacunasxperfilEstado.reiniciar();
    listavacunasxperfilBusquedaEstado.reiniciar();
  }
}

final vacunasxPerfilService = _VacunasporPerfiles();
