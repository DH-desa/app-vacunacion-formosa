import 'package:sistema_vacunacion/src/domain/entities/vacunas/vacunas_esquema_model.dart';

import 'estado.dart';

class _VacunasEsquemaService {
  final vacunasEsquemaEstado = Estado<VacunasEsquema?>(null);
  final listaVacunasEsquemaEstado = Estado<List<VacunasEsquema>>([]);
  final listaVacunasEsquemaBusquedaEstado = Estado<List<VacunasEsquema>>([]);

  VacunasEsquema? get vacunasEsquema => vacunasEsquemaEstado.value;

  bool get existevacunasEsquema => vacunasEsquemaEstado.value != null;

  void cargarvacunasEsquema(VacunasEsquema? esquema) {
    vacunasEsquemaEstado.value = esquema;
  }

  //Manejo de Listas

  List<VacunasEsquema> get listavacunasEsquema =>
      listaVacunasEsquemaEstado.value;

  bool get existelistavacunasEsquema =>
      listaVacunasEsquemaEstado.value.isNotEmpty;

  void cargarListavacunasEsquema(List<VacunasEsquema> listavacunasEsquema) {
    listaVacunasEsquemaEstado.value = listavacunasEsquema;
    listaVacunasEsquemaBusquedaEstado.value = listavacunasEsquema;
  }

  //---------------------  Manejo de Busqueda --------------------------///

  List<VacunasEsquema> get listavacunasEsquemaBusqueda =>
      listaVacunasEsquemaBusquedaEstado.value;

  bool get existeBusquedaesquema =>
      listaVacunasEsquemaBusquedaEstado.value.isNotEmpty;

  void buscaresquema(String busqueda) {
    listaVacunasEsquemaBusquedaEstado.value = listaVacunasEsquemaEstado.value
        .where((element) =>
            element.sysvacu02_descripcion!.toUpperCase().contains(busqueda))
        .toList();
  }

  void reiniciar() {
    vacunasEsquemaEstado.reiniciar();
    listaVacunasEsquemaEstado.reiniciar();
    listaVacunasEsquemaBusquedaEstado.reiniciar();
  }
}

final vacunasEsquemaService = _VacunasEsquemaService();
