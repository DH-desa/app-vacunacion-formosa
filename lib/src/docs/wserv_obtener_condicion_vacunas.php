<?php

include "../../conexion/link_mysql.php";
include "../../../../lib/functions.php";

$id_sysvacu04 = $_GET['id_sysvacu04'];
$sysdesa10_edad = $_GET['sysdesa10_edad'];

//$edad=$sysdesa10_edad;

/* $mensaje = $sysdesa10_edad;
 $condicion_vacunas[] = array(
				'id_sysvacu01' => '', //ID CONFIG VACUNA
				'sysvacu01_codigo' => '',//condicion
				'sysvacu01_descripcion' => '',//esquema
				'sysvacu01_orden' => '',//esquema
				'sysvacu01_abreviatura' => '',//laboratorio
				'codigo_mensaje' => '0',
				'mensaje' => utf8_encode($mensaje),
			);
			
echo json_encode(array('condicion_vacunas' => $condicion_vacunas));*/
			
			
//$id_sysvacu01 = $_GET['id_sysvacu01'];

//print_r($_SESSION);

//$edad_cero=intval($sysdesa10_edad)/365;

//$edad_cero=intval($edad_cero);
//echo intval($sysdesa10_edad);

//echo $id_sysvacu01, " --- ";

mysqli_set_charset($conexion, "utf8mb4"); 
$condicion_vacunas = array();
if($id_sysvacu04!="" and $sysdesa10_edad!=""){

	/*if($sysdesa10_edad > 0){
		if($id_sysvacu04==42 or $id_sysvacu04==57){ //vacuna ipv salk o triple viral
			if ($sysdesa10_edad < 6){
				//$sysdesa10_edad = 395; se comenta el 13/12 por nueva cfg de vacuna triple viral
				if($id_sysvacu04==47 or $id_sysvacu04==53 or $id_sysvacu04==54){ //neumococo o rotavirus
					$sysdesa10_edad = 42;
				}
				else{
					$sysdesa10_edad = 437; //edad para triple viral o ipv salk
				}
			}
			else{
				$sysdesa10_edad = $sysdesa10_edad * 365;
			}
			//$sysdesa10_edad = 395;
		}
		else{
			$sysdesa10_edad = $sysdesa10_edad * 365;
		}
		
	}
	else{
		if($id_sysvacu04==42 or $id_sysvacu04==57){ //vacuna ipv salk o triple viral
			//$sysdesa10_edad = 395; se comenta el 13/12 por nueva cfg de vacuna triple viral
			$sysdesa10_edad = 437;
		}
		else if($id_sysvacu04==47 or $id_sysvacu04==53 or $id_sysvacu04==54){ //neumococo o rotavirus
			$sysdesa10_edad = 42;
		}
		else{
			$sysdesa10_edad = 365;
		}
		
	}*/
	
	//$tripleViralOIpv = [42, 57]; // Vacuna IPV Salk o Triple Viral
	//$neumococoORotavirus = [47, 53, 54]; // Vacuna Neumococo o Rotavirus
	
	if ($sysdesa10_edad == 0) {
		
		//echo "entra aca lse";
		switch (true) {
			case in_array($id_sysvacu04, [42, 57]): // IPV Salk o Triple Viral
				$sysdesa10_edad = 437;
				$edadConsulta = $sysdesa10_edad;
				break;

			case $id_sysvacu04 == 45:
				$edadConsulta = 56;
				break;

			case in_array($id_sysvacu04, [47, 53, 54]): // Neumococo o Rotavirus
				$sysdesa10_edad = 42;
				$edadConsulta = $sysdesa10_edad;
				break;

			case in_array($id_sysvacu04, [64, 8, 9]): // Moderna, Antigripal Trivalente Pediátrica o Antigripal Trivalente Adultos
				$edadConsulta = 180;
				break;

			case $id_sysvacu04 == 51: // Quíntuple
				$edadConsulta = 42;
				break;

			case $id_sysvacu04 == 55:
				$edadConsulta = 60;
				break;

			default:
				$edadConsulta = 0;
		}

		$where = "AND $edadConsulta BETWEEN sysvacu03_limite_min_dosis AND sysvacu03_limite_max_dosis";

	} else {
		if (in_array($id_sysvacu04, [42, 57])) { // IPV Salk o Triple Viral
			if ($edad_cero < 6) {
				//echo "entra aca if";
				$sysdesa10_edad = 437;
			} else {
				//echo "entra aca else";
				$sysdesa10_edad *= 365;
			}
		} else {
			//echo "entra aca otro else";
			$sysdesa10_edad *= 365;
		}
		
		$where = "AND ($sysdesa10_edad BETWEEN sysvacu03_limite_min_dosis AND sysvacu03_limite_max_dosis OR
					   0 BETWEEN sysvacu03_limite_min_dosis AND sysvacu03_limite_max_dosis)";
	}

//$sysdesa10_edad = $sysdesa10_edad * 365;

/*$qr_condicion="SELECT id_sysdesa18,sysdesa18_lote,sysdesa18_fecha_vencimiento, 
sysdesa18_cantidad_actual FROM sys_desa_18_cab_lotes 
where rela_sysvacu04 = $id_sysvacu04 and sysdesa18_publicar = 1"; */

    /*$qr_condicion="select * from sys_vacu_03_rel_vacuna
	join sys_vacu_01_cab_condicion_aplicacion on id_sysvacu01=rela_sysvacu01
	join sys_vacu_04_cab_vacuna on id_sysvacu04=rela_sysvacu04
	where rela_sysvacu04=$id_sysvacu04
	AND $sysdesa10_edad BETWEEN sysvacu03_limite_min_dosis AND sysvacu03_limite_max_dosis
	AND sysvacu03_estado = 1"; */
	
	$qr_condicion="select id_sysvacu01,sysvacu01_codigo,
	sysvacu01_descripcion,sysvacu01_orden,sysvacu01_abreviatura from sys_vacu_03_rel_vacuna
	inner join sys_vacu_01_cab_condicion_aplicacion on id_sysvacu01=rela_sysvacu01
	inner join sys_vacu_04_cab_vacuna on id_sysvacu04=rela_sysvacu04
	where rela_sysvacu04=$id_sysvacu04
	$where
	AND sysvacu03_estado = 1 group by id_sysvacu01";
	
	//echo $qr_condicion;
	//exit; 
	
	//if ($_SESSION["session_id_flxcore03"]==683){
		//echo $qr_condicion;
		//exit;
	//}

/*$qr_edu="SELECT id_sysdesa18,sysdesa18_lote,sysdesa18_fecha_vencimiento, 
sysdesa18_cantidad_actual FROM sys_desa_18_cab_lotes 
where id_sysdesa18 = 7"; */

	$result_condicion = mysqli_query($conexion,$qr_condicion);
	$num_rows = mysqli_num_rows($result_condicion);	
	if ($num_rows>0)
	{		
		while ($row = mysqli_fetch_assoc($result_condicion)){

				 $condicion_vacunas[] = array(
					'id_sysvacu01' => $row["id_sysvacu01"], //ID CONDICION
					'sysvacu01_codigo' => $row['sysvacu01_codigo'],//CODIGO CONDICION
					'sysvacu01_descripcion' => ($row['sysvacu01_descripcion']),//DESCRIPCION CONDICION
					'sysvacu01_orden' => $row["sysvacu01_orden"],//ORDEN CONDICION
					'sysvacu01_abreviatura' => $row["sysvacu01_abreviatura"],//ABREVIATURA CONDICION
					'codigo_mensaje' => '',
					'mensaje' =>'',
				);

		}
	
   }else{
		  $condicion_vacunas[] = array(
					'id_sysvacu01' => '', //ID CONFIG VACUNA
					'sysvacu01_codigo' => '',//condicion
					'sysvacu01_descripcion' => '',//esquema
					'sysvacu01_orden' => '',//esquema
					'sysvacu01_abreviatura' => '',//laboratorio
					'codigo_mensaje' => '0',
					'mensaje' =>'No se encontraron Condiciones de Aplicacion para la vacuna seleccionada',
				);
   }
}else{
 $mensaje = "No se recibió el ID de vacuna";
 $condicion_vacunas[] = array(
				'id_sysvacu01' => '', //ID CONFIG VACUNA
				'sysvacu01_codigo' => '',//condicion
				'sysvacu01_descripcion' => '',//esquema
				'sysvacu01_orden' => '',//esquema
				'sysvacu01_abreviatura' => '',//laboratorio
				'codigo_mensaje' => '0',
				'mensaje' => utf8_encode($mensaje),
			);

}

//return "0 <-> Error: El beneficiario es menor de Edad. Debe cargarse el nombre del tutor";
   
//echo json_encode(array('condicion_vacunas' => $condicion_vacunas), JSON_UNESCAPED_UNICODE);
echo json_encode(array('condicion_vacunas' => $condicion_vacunas));

?>