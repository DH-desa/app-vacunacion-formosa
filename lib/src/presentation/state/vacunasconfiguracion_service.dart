import 'package:sistema_vacunacion/src/domain/entities/models.dart';

import 'estado.dart';

class _VacunasConfiguracion {
  final vacunasConfiguracionEstado = Estado<ConfiVacuna?>(null);
  final listavacunasConfiguracionEstado = Estado<List<ConfiVacuna>>([]);
  final listavacunasConfiguracionBusquedaEstado = Estado<List<ConfiVacuna>>(
    [],
  );

  ConfiVacuna? get vacunasConfiguracion => vacunasConfiguracionEstado.value;

  bool get existeVacunasConfiguracion =>
      vacunasConfiguracionEstado.value != null;

  void cargarVacunasConfiguracion(ConfiVacuna? configuraciones) {
    vacunasConfiguracionEstado.value = configuraciones;
  }

  //----------------------------Manejo de Listas-------------------------//

  List<ConfiVacuna> get listavacunasConfiguracion =>
      listavacunasConfiguracionEstado.value;

  bool get existelistaVacunasConfiguraciones =>
      listavacunasConfiguracionEstado.value.isNotEmpty;

  void cargarListaVacunasConfiguracion(
      List<ConfiVacuna> listavacunasConfiguracion) {
    listavacunasConfiguracionEstado.value = listavacunasConfiguracion;
    listavacunasConfiguracionBusquedaEstado.value = listavacunasConfiguracion;
  }

  //---------------------  Manejo de Busqueda --------------------------///

  List<ConfiVacuna> get listavacunasConfiguracionBusqueda =>
      listavacunasConfiguracionBusquedaEstado.value;

  bool get existeBusquedaxConfiguracion =>
      listavacunasConfiguracionBusquedaEstado.value.isNotEmpty;

  void buscarConfiguracion(String busqconfiguracion) {
    listavacunasConfiguracionBusquedaEstado.value =
        listavacunasConfiguracionEstado.value
            .where((element) => element.sysvacu02_descripcion!
                .toUpperCase()
                .contains(busqconfiguracion))
            .toList();
  }

  void reiniciar() {
    vacunasConfiguracionEstado.reiniciar();
    listavacunasConfiguracionEstado.reiniciar();
    listavacunasConfiguracionBusquedaEstado.reiniciar();
  }
}

final vacunasConfiguracionService = _VacunasConfiguracion();
