import 'package:sistema_vacunacion/src/domain/entities/models.dart';

import 'estado.dart';

class _VacunasLotes {
  final vacunasLotesEstado = Estado<Lotes?>(null);
  final listavacunaslotesEstado = Estado<List<Lotes>>([]);
  final listavacunaslotesBusquedaEstado = Estado<List<Lotes>>([]);

  Lotes? get vacunasLotes => vacunasLotesEstado.value;

  bool get existeVacunasLotes => vacunasLotesEstado.value != null;

  void cargarVacunasLotes(Lotes? lotes) {
    vacunasLotesEstado.value = lotes;
  }

  //Manejo de Listas

  List<Lotes> get listavacunasLotes => listavacunaslotesEstado.value;

  bool get existelistaVacunasLotes => listavacunaslotesEstado.value.isNotEmpty;

  void cargarListaVacunasLotes(List<Lotes> listavacunaslotes) {
    listavacunaslotesEstado.value = listavacunaslotes;
    listavacunaslotesBusquedaEstado.value = listavacunaslotes;
  }

  //---------------------  Manejo de Busqueda --------------------------///

  List<Lotes> get listavacunasLotesBusqueda =>
      listavacunaslotesBusquedaEstado.value;

  bool get existeBusquedaxLotes =>
      listavacunaslotesBusquedaEstado.value.isNotEmpty;

  void buscarLotes(String lotes) {
    listavacunaslotesBusquedaEstado.value = listavacunaslotesEstado.value
        .where(
            (element) => element.sysdesa18_lote!.toUpperCase().contains(lotes))
        .toList();
  }

  void reiniciar() {
    vacunasLotesEstado.reiniciar();
    listavacunaslotesEstado.reiniciar();
    listavacunaslotesBusquedaEstado.reiniciar();
  }
}

final vacunasLotesService = _VacunasLotes();
