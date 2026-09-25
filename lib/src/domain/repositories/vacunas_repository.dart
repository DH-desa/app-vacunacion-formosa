abstract class VacunasRepository {
  Future validarVacunas();
  Future validarLotes(String? idVacu);
  Future validarConfiguraciones(String? idVacu);
  Future obtenerDatosPerfilesVacunacion(String? rela);
  Future obtenerCondicionesProviders(String? sysvacu04, String? sysdesa10_edad);
  Future obtenerDosisProviders(
      String id_sysvacu04, String id_sysvacu01, String id_sysvacu02);
  Future obtenerEsquemasProviders(String? id_sysvacu04, String? id_sysvacu01);
  Future obtenerVacunasxPerfilesProviders(String? id, String? dni, String? sexo);
  Future cantidadVacunas();
}
