import 'package:sistema_vacunacion/src/domain/entities/vacunas/vacunas_dosis_model.dart';

import 'estado.dart';

class _VacunasDosisService {
  final vacunasDosisEstado = Estado<VacunasDosis?>(null);
  final listaVacunasDosisEstado = Estado<List<VacunasDosis>>([]);
  final listaVacunasDosisBusquedaEstado = Estado<List<VacunasDosis>>([]);

  VacunasDosis? get vacunasDosis => vacunasDosisEstado.value;

  bool get existeVacunasDosis => vacunasDosisEstado.value != null;

  void cargarVacunasDosis(VacunasDosis? dosis) {
    vacunasDosisEstado.value = dosis;
  }

  //Manejo de Listas

  List<VacunasDosis> get listaVacunasDosis => listaVacunasDosisEstado.value;

  bool get existelistaVacunasDosis =>
      listaVacunasDosisEstado.value.isNotEmpty;

  void cargarListaVacunasDosis(List<VacunasDosis> listaVacunasDosis) {
    listaVacunasDosisEstado.value = listaVacunasDosis;
    listaVacunasDosisBusquedaEstado.value = listaVacunasDosis;
  }

  //---------------------  Manejo de Busqueda --------------------------///

  List<VacunasDosis> get listaVacunasDosisBusqueda =>
      listaVacunasDosisBusquedaEstado.value;

  bool get existeBusquedaDosis =>
      listaVacunasDosisBusquedaEstado.value.isNotEmpty;

  void buscarDosis(String busqueda) {
    listaVacunasDosisBusquedaEstado.value = listaVacunasDosisEstado.value
        .where((element) =>
            element.sysvacu05_nombre!.toUpperCase().contains(busqueda))
        .toList();
  }

  void reiniciar() {
    vacunasDosisEstado.reiniciar();
    listaVacunasDosisEstado.reiniciar();
    listaVacunasDosisBusquedaEstado.reiniciar();
  }
}

final vacunasDosisService = _VacunasDosisService();
