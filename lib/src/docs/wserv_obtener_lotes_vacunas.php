<?php

include "../../conexion/link_mysql.php";
include "../../../../lib/functions.php";

$id_sysvacu04 = $_GET['id_sysvacu04'];

mysqli_set_charset($conexion, "utf8mb4"); 
$lotes_vacunas = array();
if($id_sysvacu04!=""){

$qr_edu="select * from sys_desa_18_cab_lotes
	where rela_sysvacu04=$id_sysvacu04 and (sysdesa18_externo = 0 or sysdesa18_externo is null)
	and sysdesa18_inicial=1
	GROUP BY sysdesa18_lote"; 

/*$qr_edu="SELECT id_sysdesa18,sysdesa18_lote,sysdesa18_fecha_vencimiento, 
sysdesa18_cantidad_actual FROM sys_desa_18_cab_lotes 
where id_sysdesa18 = 7"; */

	$result_edu = mysqli_query($conexion,$qr_edu);
	$num_rows = mysqli_num_rows($result_edu);	
	if ($num_rows>0)
	{
		while ($row = mysqli_fetch_assoc($result_edu)){

				 $lotes_vacunas[] = array(
					'id_sysdesa18' => $row["id_sysdesa18"], //ID LOTE
					'sysdesa18_lote' => $row['sysdesa18_lote'],//DESCRIPCIÓN LOTE
					'sysdesa18_cantidad_actual' => $row['sysdesa18_cantidad_actual'],//STOCK ACTUAL DEL LOTE
					'sysdesa18_fecha_vencimiento' => viewDate($row["sysdesa18_fecha_vencimiento"]),//VENCIENTO
					'codigo_mensaje' => '',
					'mensaje' =>'',
				);

		}
	
   }else{
		  $lotes_vacunas[] = array(
					'id_sysdesa18' => '', //ID CONFIG VACUNA
					'sysdesa18_lote' => '',//condicion
					'sysvacu02_descripcion' => '',//esquema
					'sysdesa18_cantidad_actual' => '',//esquema
					'sysdesa18_fecha_vencimiento' => '',//laboratorio
					'codigo_mensaje' => '0',
					'mensaje' =>'No se encontraron Lotes para la vacuna seleccionada',
				);
   }
}else{
 $mensaje = "No se recibió el ID de vacuna";
 $lotes_vacunas[] = array(
				'id_sysdesa18' => '', //ID CONFIG VACUNA
				'sysdesa18_lote' => '',//condicion
				'sysvacu02_descripcion' => '',//esquema
				'sysdesa18_cantidad_actual' => '',//esquema
				'sysdesa18_fecha_vencimiento' => '',//laboratorio
				'codigo_mensaje' => '0',
				'mensaje' => utf8_decode($mensaje),
			);

}
   
echo json_encode(array('lotes_vacunas' => $lotes_vacunas), JSON_UNESCAPED_UNICODE);

?>