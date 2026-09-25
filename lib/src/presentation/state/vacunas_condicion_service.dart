import 'package:sistema_vacunacion/src/domain/entities/vacunas/vacunas_condicion_model.dart';

import 'estado.dart';

class _VacunasCondicionService {
  final vacunasCondicionEstado = Estado<VacunasCondicion?>(null);
  final listaVacunasCondicionEstado = Estado<List<VacunasCondicion>>([]);
  final listaVacunasCondicionBusquedaEstado = Estado<List<VacunasCondicion>>(
    [],
  );

  VacunasCondicion? get vacunasCondicion => vacunasCondicionEstado.value;

  bool get existeVacunasCondicion => vacunasCondicionEstado.value != null;

  void cargarVacunasCondicion(VacunasCondicion? condicion) {
    vacunasCondicionEstado.value = condicion;
  }

  //Manejo de Listas

  List<VacunasCondicion> get listaVacunasCondicion =>
      listaVacunasCondicionEstado.value;

  bool get existelistaVacunasCondicion =>
      listaVacunasCondicionEstado.value.isNotEmpty;

  void cargarListaVacunasCondicion(
      List<VacunasCondicion> listaVacunasCondicion) {
    listaVacunasCondicionEstado.value = listaVacunasCondicion;
    listaVacunasCondicionBusquedaEstado.value = listaVacunasCondicion;
  }

  //---------------------  Manejo de Busqueda --------------------------///

  List<VacunasCondicion> get listaVacunasCondicionBusqueda =>
      listaVacunasCondicionBusquedaEstado.value;

  bool get existeBusquedaCondicion =>
      listaVacunasCondicionBusquedaEstado.value.isNotEmpty;

  void buscarCondicion(String busqueda) {
    listaVacunasCondicionBusquedaEstado.value =
        listaVacunasCondicionEstado.value
            .where((element) =>
                element.sysvacu01_descripcion!.toUpperCase().contains(busqueda))
            .toList();
  }

  void reiniciar() {
    vacunasCondicionEstado.reiniciar();
    listaVacunasCondicionEstado.reiniciar();
    listaVacunasCondicionBusquedaEstado.reiniciar();
  }
}

final vacunasCondicionService = _VacunasCondicionService();
