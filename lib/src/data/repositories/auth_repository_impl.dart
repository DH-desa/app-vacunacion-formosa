import 'package:sistema_vacunacion/src/domain/repositories/auth_repository.dart';
import 'package:sistema_vacunacion/src/data/datasources/login_providers.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future validarUsuarios(String dni) => usuariosProviers.validarUsuarios(dni);

  @override
  Future validarUsuariosNuevo(String? dni) =>
      usuariosProviers.validarUsuariosNuevo(dni);
}

final authRepository = AuthRepositoryImpl();
