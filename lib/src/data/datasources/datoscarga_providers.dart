class DatosdeCarga {
  String dniVacunador = '';
  String nombreVacunador = '';
  String dniCargador = '';
  String nombreCargador = '';
  String idOficina = '';
  String nombreOficina = '';
  //
  String dniBeneficiario = '';
  String apellidoBeneficiaro = '';
  String nombreBeneficiario = '';
  String sexoBeneficiario = '';
  String numeroTramiteBeneficiario = '';
  int estadoVacunado = 0;

  String bkCodigodeBarras = '';

  String idVacuna = ''; //ID De la vacuna evento onchange de combovacunas
  String idLote = ''; //ID Del lote evento onchange de comboLotes
  String idConfiguracion = ''; //ID De la Configuracion onchange de comboConfig

  String? fechaVacuna = '';
  String? diasTranscurridos = '';
  String? proximaVacuna = '';

  String idVacunador = '';
  String idCargador = '';

  String versionApp = '';
}

final datosdecargaprovider = DatosdeCarga();
