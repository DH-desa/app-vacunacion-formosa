<?php
include "../../../../lib/functions.php";
include "../../conexion/link_mysql.php";
//include "../../../../lib/link_msq.php";

$id_sysdesa12 = $_GET['id_sysdesa12'];
$vacunador_registrador = $_GET['vacunador_registrador']; //SI ES IGUAL A 1, EL VACUNADOR Y EL REGISTRADOR SON LA MISMA PERSONA
$usuario = array();
mysqli_set_charset($conexion, "utf8");
// mysqli_set_charset($conexion, "utf8mb4");
$id_sysdesa12=trim($id_sysdesa12);
if($id_sysdesa12 !=""){
    
	if($vacunador_registrador == 1){ 
	   $id_vacunador = obtener_datos_vacunador($conexion, $id_sysdesa12);
	}else{
	   $id_vacunador = $id_sysdesa12;
	}
	$sysdesa10_fecha_alta=date('Y-m-d');  
	
	//DESARROLLO
	/*$qr_usuario="SELECT count(*) as cantidad_aplicaciones FROM sys_desa_99_cab_nomivac_pruebas 
	             WHERE rela_sysdesa12= $id_vacunador and sysdesa10_fecha_alta = '$sysdesa10_fecha_alta' "; */
	
	//RODUCCIÓN
	$qr_usuario="SELECT count(*) as cantidad_aplicaciones FROM sys_desa_10_cab_nomivac 
	             WHERE rela_sysdesa12= $id_vacunador and sysdesa10_fecha_alta = '$sysdesa10_fecha_alta' ";

			$result = mysqli_query($conexion, $qr_usuario);
			//$result = flex_query($qr_usuario,$link_msq);
			$num_rows=mysqli_num_rows($result);
            //$num_rows = flex_num_rows($result);
		if ($num_rows>0)
		{    
			 $row = mysqli_fetch_assoc($result);
             //$row = flex_fetch_assoc($result);
			 //$flxcore03_nombre = $row['flxcore03_nombre'];
			 //$flxcore03_nombre = $conexion->real_escape_string($flxcore03_nombre);
              $cantidad_aplicaciones=$row["cantidad_aplicaciones"];
		
			 $usuario[] = array(
				'id_sysdesa12' => $id_vacunador,
				'cantidad_aplicaciones' => $row['cantidad_aplicaciones'],
				'codigo_mensaje' => '',
				'mensaje' =>'',
			);

		}else{
		   $usuario[] = array(
				'id_sysdesa12' => '',
				'cantidad_aplicaciones' => '',
				'codigo_mensaje' => '0',
				'mensaje' =>'No hay registradores cargados para el vacunador indicado',
			);

		}
}else{
     $mensaje = "DNI o ID del Vacunador Vacío. Debe enviar este dato.";
	 
     $usuario[] = array(
				'id_sysdesa12' => "",
				'cantidad_vacunas' => "",
				'codigo_mensaje' => '0',
				'mensaje' =>($mensaje),
			);

}

function obtener_datos_vacunador($conexion, $dni){
       $qr_vacunador="SELECT id_sysdesa12 FROM sys_desa_12_vacunador
		left outer join sys_desa_06_cab_personas on id_sysdesa06 = rela_sysdesa06
		left outer join sys_desa_13_tipo_vacunador on id_sysdesa13 = rela_sysdesa13
		WHERE sysdesa06_nro_documento='$dni' and sysdesa12_habilitado=1";

    $result = mysqli_query($conexion, $qr_vacunador);
	$num_rows=mysqli_num_rows($result);
	if ($num_rows>0)
	{
		 $row = mysqli_fetch_assoc($result);
		 $id_sysdesa12 = $row["id_sysdesa12"];
		 return $id_sysdesa12;
	}else{
	    return 0; //NO SE ENCONTRÓ AL VACUNADOR CON EL DNI OBTENIDO COMO PARÁMETRO
	}
	
}
	
//echo json_encode(array('usuario' => $usuario));
//echo  json_encode(array('usuario' => $usuario), JSON_UNESCAPED_UNICODE);
echo  json_encode(array('usuario' => $usuario));

?>