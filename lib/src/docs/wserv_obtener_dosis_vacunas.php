<?php

include "../../conexion/link_mysql.php";
include "../../../../lib/functions.php";

$id_sysvacu01 = $_GET['id_sysvacu01'];
$id_sysvacu02 = $_GET['id_sysvacu02'];
$id_sysvacu04 = $_GET['id_sysvacu04'];
mysqli_set_charset($conexion, "utf8mb4"); 
$dosis_vacunas = array();
if($id_sysvacu04!="" and $id_sysvacu01!="" and $id_sysvacu02!=""){

$qr_dosis="SELECT * FROM sys_vacu_03_rel_vacuna
	JOIN sys_vacu_01_cab_condicion_aplicacion ON id_sysvacu01=rela_sysvacu01
	JOIN sys_vacu_04_cab_vacuna on id_sysvacu04=rela_sysvacu04
	JOIN sys_vacu_05_cab_dosis on id_sysvacu05=rela_sysvacu05
	JOIN sys_vacu_02_cab_esquema on id_sysvacu02=rela_sysvacu02
	WHERE rela_sysvacu04=$id_sysvacu04 and rela_sysvacu01=$id_sysvacu01 and rela_sysvacu02=$id_sysvacu02
	AND sysvacu03_estado = 1";

	//echo $qr_esquema;

	$result_dosis = mysqli_query($conexion,$qr_dosis);
	$num_rows = mysqli_num_rows($result_dosis);	
	if ($num_rows>0)
	{		
		while ($row = mysqli_fetch_assoc($result_dosis)){

				 $dosis_vacunas[] = array(
					'id_sysvacu05' => $row["id_sysvacu05"], //ID DOSIS
					'sysvacu05_nombre' => ($row['sysvacu05_nombre']),//NOMBRE DOSIS
					'sysvacu05_orden' => $row['sysvacu05_orden'],//ORDEN DOSIS
					'sysvacu05_cod_sisa' => $row["sysvacu05_cod_sisa"],//CODIGO SISA DOSIS
					'sysvacu05_esquema' => ($row["sysvacu05_esquema"]),//ESQUEMA DOSIS
					'sysvacu05_orden_numerico' => $row["sysvacu05_orden_numerico"],//ORDEN NUMERICO DOSIS
					'codigo_mensaje' => '',
					'mensaje' =>'',
				);

		}
	
   }else{
		  $dosis_vacunas[] = array(
					'id_sysvacu05' => '', //ID CONFIG VACUNA
					'sysvacu05_nombre' => '',//condicion
					'sysvacu05_orden' => '',//esquema
					'sysvacu05_cod_sisa' => '',//esquema
					'sysvacu05_esquema' => '',//laboratorio
					'sysvacu05_orden_numerico' => '',//laboratorio
					'codigo_mensaje' => '0',
					'mensaje' =>'No se encontraron Dosis para la vacuna seleccionada',
				);
   }
}else{
 $mensaje = "No se recibió el ID de vacuna";
 $dosis_vacunas[] = array(
				'id_sysvacu05' => '', //ID CONFIG VACUNA
				'sysvacu05_nombre' => '',//condicion
				'sysvacu05_orden' => '',//esquema
				'sysvacu05_cod_sisa' => '',//esquema
				'sysvacu05_esquema' => '',//laboratorio
				'sysvacu05_orden_numerico' => '',//laboratorio
				'codigo_mensaje' => '0',
				'mensaje' => utf8_encode($mensaje),
			);

}
   
//echo json_encode(array('dosis_vacunas' => $dosis_vacunas), JSON_UNESCAPED_UNICODE);  
echo json_encode(array('dosis_vacunas' => $dosis_vacunas));

?>