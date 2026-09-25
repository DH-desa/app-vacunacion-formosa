import 'package:sistema_vacunacion/src/domain/repositories/vacunas_repository.dart';
import 'package:sistema_vacunacion/src/data/datasources/vacunas/infovacunas_providers.dart';
import 'package:sistema_vacunacion/src/data/datasources/vacunas/lotesvacunas_providers.dart';
import 'package:sistema_vacunacion/src/data/datasources/vacunas/configvacunas_providers.dart';
import 'package:sistema_vacunacion/src/data/datasources/vacunas/perfilesvacunacion_providers.dart';
import 'package:sistema_vacunacion/src/data/datasources/vacunas/vacunas_condicion_providers.dart';
import 'package:sistema_vacunacion/src/data/datasources/vacunas/vacunas_dosis_provider.dart';
import 'package:sistema_vacunacion/src/data/datasources/vacunas/vacunas_esquema_providers.dart';
import 'package:sistema_vacunacion/src/data/datasources/vacunas/vacunasxperfiles_providers.dart';
import 'package:sistema_vacunacion/src/data/datasources/vacunados/vacunadoscant_providers.dart';

class VacunasRepositoryImpl implements VacunasRepository {
  @override
  Future validarVacunas() => infoVacunasProviers.validarVacunas();

  @override
  Future validarLotes(String? idVacu) =>
      lotesVacunaProvider.validarLotes(idVacu);

  @override
  Future validarConfiguraciones(String? idVacu) =>
      configuracionVacunaProvider.validarConfiguraciones(idVacu);

  @override
  Future obtenerDatosPerfilesVacunacion(String? rela) =>
      perfilesProviders.obtenerDatosPerfilesVacunacion(rela);

  @override
  Future obtenerCondicionesProviders(
          String? sysvacu04, String? sysdesa10_edad) =>
      vacunasCondicion.obtenerCondicionesProviders(sysvacu04, sysdesa10_edad);

  @override
  Future obtenerDosisProviders(
          String id_sysvacu04, String id_sysvacu01, String id_sysvacu02) =>
      vacunasDosisProvider.obtenerDosisProviders(
          id_sysvacu04, id_sysvacu01, id_sysvacu02);

  @override
  Future obtenerEsquemasProviders(
          String? id_sysvacu04, String? id_sysvacu01) =>
      vacunasEsquemaProvider.obtenerEsquemasProviders(
          id_sysvacu04, id_sysvacu01);

  @override
  Future obtenerVacunasxPerfilesProviders(
          String? id, String? dni, String? sexo) =>
      vacunasxPerfiles.obtenerVacunasxPerfilesProviders(id, dni, sexo);

  @override
  Future cantidadVacunas() => cantidadVacunadosProvider.cantidadVacunas();
}

final vacunasRepository = VacunasRepositoryImpl();
