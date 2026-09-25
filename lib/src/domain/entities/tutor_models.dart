import 'package:sistema_vacunacion/src/domain/entities/usuarios/usuariobeneficiario_models.dart';

class Tutor {
  // ignore: non_constant_identifier_names
  String? sysdesa10_apellido_tutor;
  // ignore: non_constant_identifier_names
  String? sysdesa10_nombre_tutor;
  // ignore: non_constant_identifier_names
  String? sysdesa10_dni_tutor;
  // ignore: non_constant_identifier_names
  String? sysdesa10_sexo_tutor;

  Tutor({
    // ignore: non_constant_identifier_names
    required this.sysdesa10_apellido_tutor,
    // ignore: non_constant_identifier_names
    required this.sysdesa10_nombre_tutor,
    // ignore: non_constant_identifier_names
    required this.sysdesa10_dni_tutor,
    // ignore: non_constant_identifier_names
    required this.sysdesa10_sexo_tutor,
  });

  /// Mismos datos personales que devuelve el endpoint de beneficiario (tutor en escaneo).
  factory Tutor.desdeBeneficiario(Beneficiario b) {
    return Tutor(
      sysdesa10_apellido_tutor: b.sysdesa10_apellido,
      sysdesa10_nombre_tutor: b.sysdesa10_nombre,
      sysdesa10_dni_tutor: b.sysdesa10_dni,
      sysdesa10_sexo_tutor: b.sysdesa10_sexo,
    );
  }
}
