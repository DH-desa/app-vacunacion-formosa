<?php

include "../../conexion/link_mysql.php";
include "../../../../lib/functions.php";

$sysdesa06_nro_documento = $_GET['sysdesa06_nro_documento'];
$vacunador = array();
mysqli_set_charset($conexion, "utf8mb4");

if($sysdesa06_nro_documento != ""){

	$qr_vacunador="SELECT id_sysdesa12,sysdesa06_nro_documento,concat (sysdesa06_apellido, ' ', sysdesa06_nombre) AS nombre FROM sys_desa_12_vacunador
	left outer join sys_desa_06_cab_personas on id_sysdesa06 = rela_sysdesa06
	left outer join sys_desa_13_tipo_vacunador on id_sysdesa13 = rela_sysdesa13
	WHERE sysdesa06_nro_documento='$sysdesa06_nro_documento' and sysdesa12_habilitado=1";

		$result = mysqli_query($conexion, $qr_vacunador);
		$num_rows=mysqli_num_rows($result);
	if ($num_rows>0)
	{
		 $row = mysqli_fetch_assoc($result);
		 $vacunador[] = array(
			'id_sysdesa12' => $row["id_sysdesa12"],
			'sysdesa06_nro_documento' => $row['sysdesa06_nro_documento'],
			'sysdesa06_nombre' => $row["nombre"] ,
			'codigo_mensaje' => "",
			'mensaje' => "1",
		);

	}else{
	   $vacunador[] = array(
		   'id_sysdesa12' => "",
			'sysdesa06_nro_documento' => "",
			'sysdesa06_nombre' => "" ,
			'codigo_mensaje' => "0",
			'mensaje' => "No hay registros",
		);

	}

}else{

$vacunador[] = array(
		   'id_sysdesa12' => "",
			'sysdesa06_nro_documento' => "",
			'sysdesa06_nombre' => "" ,
			'codigo_mensaje' => "0",
			'mensaje' => "No se recibió el número de documento",
		);

}





	

//echo json_encode(array('usuario' => $usuario));
echo json_encode(array('vacunador' => $vacunador), JSON_UNESCAPED_UNICODE);

?>