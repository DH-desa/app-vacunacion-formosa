// ignore_for_file: file_names

import 'estado.dart';

class _LoadingLoginService {
  final loadingEstado = Estado<bool>(false);
  final primerInicioEstado = Estado<bool>(true);
  final cargaPerfilEstado = Estado<bool>(true);
  final cargaLotesEstado = Estado<bool>(true);
  final loadingCondicionEstado = Estado<bool>(true);
  final loadingEsquemaEstado = Estado<bool>(true);
  final loadingDosisEstado = Estado<bool>(true);
  final loadingVerificarEstado = Estado<bool>(true);
  final loadingMensajeEstado = Estado<String>('');

  bool? get getEstadoLoginState => loadingEstado.value;

  String get loadingMensaje => loadingMensajeEstado.value;

  void cargarEstado(bool estado, {String? mensaje}) {
    if (mensaje != null) {
      loadingMensajeEstado.value = mensaje;
    }
    loadingEstado.value = estado;
  }
  //--------------- Manejo Primer Dosis -----------//

  bool? get getLoadingVerificarState => loadingVerificarEstado.value;

  void cargarVerificar(bool estado) {
    loadingVerificarEstado.value = estado;
  }

  //--------------- Manejo Primer Dosis -----------//

  bool? get getLoadingDosisState => loadingDosisEstado.value;

  void cargarDosis(bool estado) {
    loadingDosisEstado.value = estado;
  }

//--------------- Manejo Primer Esquema -----------//

  bool? get getLoadingEsquemaState => loadingEsquemaEstado.value;

  void cargarEsquema(bool estado) {
    loadingEsquemaEstado.value = estado;
  }

//--------------- Manejo Primer condicion -----------//

  bool? get getLoadingCondicionState => loadingCondicionEstado.value;

  void cargarCondicion(bool estado) {
    loadingCondicionEstado.value = estado;
  }
//--------------- Manejo Primer Inicio -----------//

  bool? get getEstadoPrimerInicioState => primerInicioEstado.value;

  void cargarPrimerInicio(bool estado) {
    primerInicioEstado.value = estado;
  }
//--------------- Manejo Carga Perfiles -----------//

  bool? get getCargaPerfilState => cargaPerfilEstado.value;

  void cargaPerfil(bool estado) {
    cargaPerfilEstado.value = estado;
  }

  //--------------- Manejo Carga Lotes -----------//

  bool? get getCargaLotesState => cargaLotesEstado.value;

  void cargaLotes(bool estado) {
    cargaLotesEstado.value = estado;
  }
}

final loadingLoginService = _LoadingLoginService();
