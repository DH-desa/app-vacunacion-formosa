abstract class AuthRepository {
  Future validarUsuarios(String dni);
  Future validarUsuariosNuevo(String? dni);
}
