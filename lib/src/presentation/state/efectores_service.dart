import 'package:sistema_vacunacion/src/domain/entities/models.dart';

import 'estado.dart';

class _EfectoresrService {
  final efectoresEstado = Estado<Efectores?>(null);
  final listaEfectoresEstado = Estado<List<Efectores>>([]);

  Efectores? get efectores => efectoresEstado.value;

  bool get existeEfectores => efectoresEstado.value != null;

  List<Efectores> get listaEfectores => listaEfectoresEstado.value;

  bool get existeListaEfectores => listaEfectoresEstado.value.isNotEmpty;

  void cargarEfectores(Efectores? efectores) {
    efectoresEstado.value = efectores;
  }

  void cargarListaEfectores(List<Efectores> listaEfectores) {
    listaEfectoresEstado.value = listaEfectores;
  }
}

final efectoresService = _EfectoresrService();
