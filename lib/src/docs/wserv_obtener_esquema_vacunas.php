<?php
include "../../conexion/link_mysql.php";
include "../../../../lib/functions.php";

$id_sysvacu04 = $_GET['id_sysvacu04'];
$id_sysvacu01 = $_GET['id_sysvacu01'];

mysqli_set_charset($conexion, "utf8mb4"); 
$esquema_vacunas = array();
if($id_sysvacu04!="" and $id_sysvacu01!=""){

/*$qr_esquema="SELECT * FROM sys_vacu_03_rel_vacuna
	JOIN sys_vacu_01_cab_condicion_aplicacion ON id_sysvacu01=rela_sysvacu01
	JOIN sys_vacu_04_cab_vacuna on id_sysvacu04=rela_sysvacu04
	JOIN sys_vacu_05_cab_dosis on id_sysvacu05=rela_sysvacu05
	JOIN sys_vacu_02_cab_esquema on id_sysvacu02=rela_sysvacu02
	WHERE rela_sysvacu04=$id_sysvacu04 and rela_sysvacu01=$id_sysvacu01
	AND sysvacu03_estado = 1"; */
	
$qr_esquema="SELECT * FROM sys_vacu_03_rel_vacuna
	JOIN sys_vacu_01_cab_condicion_aplicacion ON id_sysvacu01=rela_sysvacu01
	JOIN sys_vacu_04_cab_vacuna on id_sysvacu04=rela_sysvacu04
	JOIN sys_vacu_05_cab_dosis on id_sysvacu05=rela_sysvacu05
	JOIN sys_vacu_02_cab_esquema on id_sysvacu02=rela_sysvacu02
	WHERE rela_sysvacu04=$id_sysvacu04 and rela_sysvacu01=$id_sysvacu01
	AND sysvacu03_estado = 1
	GROUP BY id_sysvacu02";

	//echo $qr_esquema;

	$result_esquema = mysqli_query($conexion,$qr_esquema);
	$num_rows = mysqli_num_rows($result_esquema);	
	if ($num_rows>0)
	{		
		while ($row = mysqli_fetch_assoc($result_esquema)){

				 $esquema_vacunas[] = array(
					'id_sysvacu02' => $row["id_sysvacu02"], //ID ESQUEMA
					'sysvacu02_codigo' => $row['sysvacu02_codigo'],//CODIGO ESQUEMA
					'sysvacu02_descripcion' => ($row['sysvacu02_descripcion']),//DESCRIPCION ESQUEMA
					'sysvacu02_limite_min' => $row["sysvacu02_limite_min"],//LIMITE MINIMO ESQUEMA
					'sysvacu02_limite_max' => $row["sysvacu02_limite_max"],//LIMITE MAXIMO ESQUEMA
					'codigo_mensaje' => '',
					'mensaje' =>'',
				);

		}
	
   }else{
		  $esquema_vacunas[] = array(
					'id_sysvacu02' => '', //ID CONFIG VACUNA
					'sysvacu02_codigo' => '',//condicion
					'sysvacu02_descripcion' => '',//esquema
					'sysvacu02_limite_min' => '',//esquema
					'sysvacu02_limite_max' => '',//laboratorio
					'codigo_mensaje' => '0',
					'mensaje' =>'No se encontraron Esquemas para la vacuna seleccionada',
				);
   }
}else{
 $mensaje = "No se recibió el ID de vacuna";
 $esquema_vacunas[] = array(
				'id_sysvacu02' => '', //ID CONFIG VACUNA
				'sysvacu02_codigo' => '',//condicion
				'sysvacu02_descripcion' => '',//esquema
				'sysvacu02_limite_min' => '',//esquema
				'sysvacu02_limite_max' => '',//laboratorio
				'codigo_mensaje' => '0',
				'mensaje' => utf8_encode($mensaje),
			);

}
   
//echo json_encode(array('esquema_vacunas' => $esquema_vacunas), JSON_UNESCAPED_UNICODE);
echo json_encode(array('esquema_vacunas' => $esquema_vacunas));

?>