import 'estado.dart';
import 'usuariobeneficiario_service.dart';
import 'situacionbeneficiario_service.dart';
import 'tutor_service.dart';
import 'perfilesvacunacion_service.dart';
import 'vacunasconfiguracion_service.dart';
import 'vacunaslotes_service.dart';
import 'vacunas_dosis_service.dart';
import 'vacunas_condicion_service.dart';
import 'vacunas_esquema_service.dart';
import 'vacunasxperfiles_service.dart';
import 'notificacionesdosis_service.dart';
import 'vacunaspendientes_service.dart';
import 'insertregistro_service.dart';
import 'loadingLogin_service.dart';

/// Estados de la persona atendida: nacen al cargar el beneficiario y mueren
/// solo al buscar otro (reiniciarCicloBeneficiario). Sobreviven a varias
/// vacunas dentro de la misma sesión (reiniciarCicloVacuna NO los toca).
///
/// El historial de dosis (notiDosisEstado, listaDosisAplicadasEstado) vive acá
/// y no en estadosPorVacuna: es dato de la persona, se carga una vez al
/// buscarla/escanearla y debe seguir visible al registrar la 2ª, 3ª... vacuna
/// de la misma visita. Lo mismo el perfil elegido (perfilesVacunacionEstado) y
/// la lista de registros ya confirmados en la visita (visitaRegistrosEstado).
final List<Estado> estadosPorPersona = [
  beneficiarioService.beneficiarioEstado,
  beneficiarioService.edadEstado,
  beneficiarioService.fechaNacEstado,
  tutorService.tutorEstado,
  situacionBeneficiarioService.condicionGestacionalEstado,
  situacionBeneficiarioService.esPersonalDeSaludEstado,
  notificacionesDosisService.notiDosisEstado,
  notificacionesDosisService.listaDosisAplicadasEstado,
  vacunasPendientesService.listaPendientesEstado,
  vacunasPendientesService.mensajeErrorEstado,
  perfilesVacunacionService.perfilesVacunacionEstado,
  insertRegistroService.visitaRegistrosEstado,
];

/// Estados de la vacuna en curso: se reinician entre una dosis y la
/// siguiente de la MISMA persona (reiniciarCicloVacuna), y también al
/// cambiar de persona (reiniciarCicloBeneficiario). Ciclo largo (tema,
/// enviroment, vacunador, registrador, efectores, sesionEquipoVacunacion,
/// cantidadVacunados) NO se registra acá.
final List<Estado> estadosPorVacuna = [
  perfilesVacunacionService.listaPerfilesVacunacionEstado,
  perfilesVacunacionService.mensajeListaPerfilesVaciaEstado,
  vacunasConfiguracionService.vacunasConfiguracionEstado,
  vacunasConfiguracionService.listavacunasConfiguracionEstado,
  vacunasConfiguracionService.listavacunasConfiguracionBusquedaEstado,
  vacunasLotesService.vacunasLotesEstado,
  vacunasLotesService.listavacunaslotesEstado,
  vacunasLotesService.listavacunaslotesBusquedaEstado,
  vacunasDosisService.vacunasDosisEstado,
  vacunasDosisService.listaVacunasDosisEstado,
  vacunasDosisService.listaVacunasDosisBusquedaEstado,
  vacunasCondicionService.vacunasCondicionEstado,
  vacunasCondicionService.listaVacunasCondicionEstado,
  vacunasCondicionService.listaVacunasCondicionBusquedaEstado,
  vacunasEsquemaService.vacunasEsquemaEstado,
  vacunasEsquemaService.listaVacunasEsquemaEstado,
  vacunasEsquemaService.listaVacunasEsquemaBusquedaEstado,
  vacunasxPerfilService.vacunasxperfilEstado,
  vacunasxPerfilService.listavacunasxperfilEstado,
  vacunasxPerfilService.listavacunasxperfilBusquedaEstado,
  insertRegistroService.registroEstado,
  loadingLoginService.loadingVerificarEstado,
  loadingLoginService.loadingDosisEstado,
  loadingLoginService.loadingEsquemaEstado,
  loadingLoginService.loadingCondicionEstado,
  loadingLoginService.cargaPerfilEstado,
  loadingLoginService.cargaLotesEstado,
];

/// Reinicia persona + vacuna. Se llama al buscar un beneficiario nuevo.
void reiniciarCicloBeneficiario() {
  for (final e in [...estadosPorPersona, ...estadosPorVacuna]) {
    e.reiniciar();
  }
}

/// Reinicia solo la vacuna en curso. Se llama para cargar otra dosis a la
/// MISMA persona sin perder beneficiario/tutor.
void reiniciarCicloVacuna() {
  for (final e in estadosPorVacuna) {
    e.reiniciar();
  }
}
