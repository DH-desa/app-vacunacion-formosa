<?php

//include "../../../consultar_datos_renaper/libreria/library/Requests.php";
include "../../../../lib/renaper/Requests.php";
include "../../conexion/link_mysql.php";
//include "../../../../lib/link_msq.php";
include "../../../../lib/functions.php";

ini_set("memory_limit","-1");
set_time_limit(0);
header("Cache-Control: no-cache, must-revalidate"); // HTTP/1.1
mysqli_set_charset($conexion, "utf8");

$sysdesa10_sexo = $_GET['sysdesa10_sexo'];
$sysdesa10_dni = $_GET['sysdesa10_dni'];

//mysqli_set_charset($conexion, "utf8");

$aplicaciones_beneficiario = array();

 //VOY A BUSCAR TODAS LAS VACUNAS QUE SE APLICÓ EL BENEFICIARIO
 //PARA VALIDAR EL TIEMPO ENTRE DOSIS
 if($sysdesa10_dni != "" and $sysdesa10_sexo != ""){
          //echo "sysdesa10_dni $sysdesa10_dni | sysdesa10_sexo $sysdesa10_sexo     ";
		 $qr_validar_vacunas="SELECT id_sysdesa10,sysvacu04_nombre, sysvacu05_nombre, sysdesa10_fecha_aplicacion, 
						DATEDIFF(NOW(),sysdesa10_fecha_aplicacion) as dias_transcurridos,
						sysvacu03_tiempo_interdosis, id_sysvacu04, sysdesa18_lote
						FROM sys_desa_10_cab_nomivac
						left outer join sys_vacu_03_rel_vacuna on id_sysvacu03=rela_sysvacu03
						left outer join sys_vacu_05_cab_dosis on id_sysvacu05=rela_sysvacu05
						inner join sys_vacu_04_cab_vacuna on id_sysvacu04=rela_sysvacu04
						inner join sys_desa_18_cab_lotes on id_sysdesa18=rela_sysdesa18
						where sysdesa10_dni = '$sysdesa10_dni' and sysdesa10_sexo = '$sysdesa10_sexo'
						order by sysdesa10_fecha_aplicacion DESC";
							 
	//$result_validar_vacunas = flex_query($qr_validar_vacunas,$link_msq);
	$result_validar_vacunas = mysqli_query($conexion,$qr_validar_vacunas);
	$num_rows_validar_vacunas = mysqli_num_rows($result_validar_vacunas);
	//$num_rows_validar_vacunas = flex_num_rows($result_validar_vacunas);
    $id_anterior = 0;
   if ($num_rows_validar_vacunas>0)
			{
				while ($row_validar_vacunas = mysqli_fetch_assoc($result_validar_vacunas)){
				//while ($row_validar_vacunas = flex_fetch_assoc($result_validar_vacunas)){
				        $id_vacu=$row_validar_vacunas["id_sysdesa10"];
						 $fecha=$row_validar_vacunas["sysdesa10_fecha_aplicacion"];
						  $fecha_array=explode(" ",$fecha);
						  $sysdesa10_fecha_aplicacion=viewDate($fecha_array[0]);
                          $id_sysvacu04 = $row_validar_vacunas["id_sysvacu04"];
						  //echo " id_sysvacu04 $id_sysvacu04 ||  ";
						  /*if($id_anterior == $id_sysvacu04){
						     continue;
						  }else{
						      $id_anterior = $id_sysvacu04;
						  } */
						  
						  $fecha_3=$row_validar_vacunas["proxima_dosis"]; 
						  $fecha_array_3=explode(" ",$fecha_3);
						  $fecha_proxima_dosis=viewDate($fecha_array_3[0]);

						  $dias_transcurridos=$row_validar_vacunas["dias_transcurridos"];
						  $faltan_dias_proxima_aplicacion=$row_validar_vacunas["faltan_dias_proxima_aplicacion"];

						  if($faltan_dias_proxima_aplicacion<0){
							$faltan_dias_proxima_aplicacion=0;
						  }	
						  $sysvacu03_tiempo_interdosis=$row_validar_vacunas["sysvacu03_tiempo_interdosis"];
						  
						    $fecha_aplicacion=date("d-m-Y",strtotime($fecha));
						//DE ACUERDO A LA FECHA DE APLICACIÓN Y LA CANTIDAD DE DÍAS ENTRE DOSIS SACO LA FECHA MÍNIMA PAR ALA PRÓXIMA DOSIS
						if($sysvacu03_tiempo_interdosis !=0){
						    $fecha_limite=date("Y-m-d",strtotime($sysdesa10_fecha_aplicacion."+ ". $sysvacu03_tiempo_interdosis ." days"));
							$fecha_proxima_dosis=date("d-m-Y",strtotime($fecha_limite));
						}
						
						$sysvacu04_nombre =  $row_validar_vacunas["sysvacu04_nombre"];
						$sysvacu05_nombre =  $row_validar_vacunas["sysvacu05_nombre"]; 
							$sysdesa18_lote =  $row_validar_vacunas["sysdesa18_lote"];
						
						 $aplicaciones_beneficiario[] = array(
							//'id_sysvacu04' => $row_validar_vacunas["id_sysvacu04"], //ID DE LA VACUNA
							'sysvacu04_nombre' => "$sysvacu04_nombre", //NOMBRE DE LA VACUNA
							'sysvacu05_nombre' => "$sysvacu05_nombre", //DOSIS
							'sysdesa10_fecha_aplicacion' => "$fecha_aplicacion", //FECHA DE APLICACION
							'fecha_proxima_dosis' => "$fecha_proxima_dosis", //FECHA  MÍNIMA PARA APLICAR LA SEGUNDA DOSIS
							'dias_transcurridos' => "$dias_transcurridos", //CANTIDAD DE DÍAS QUE TRANSCURRIERON DESDE LA FECHA DE APLICACIÓN
							'sysvacu03_tiempo_interdosis' =>"$sysvacu03_tiempo_interdosis", //Tiempo entre dosis para la vacuna 
							'sysdesa18_lote' =>"$sysdesa18_lote", //lote
							'codigo_mensaje' => "1",
						    'mensaje' => "",
						);
				}
				
		   }else{
		         $mensaje_error = "No se encontraron registros sobre este beneficiario";
			     //$mensaje_error=utf8_encode($mensaje_error);
				  $aplicaciones_beneficiario[] = array(
								'sysvacu04_nombre' => "", //NOMBRE DE LA VACUNA
								'sysvacu05_nombre' => "", //DOSIS
								'sysdesa10_fecha_aplicacion' => "", //FECHA DE APLICACION
								'fecha_proxima_dosis' => "", //FECHA  MÍNIMA PARA APLICAR LA SEGUNDA DOSIS
								'dias_transcurridos' => "", //CANTIDAD DE DÍAS QUE TRANSCURRIERON DESDE LA FECHA DE APLICACIÓN
								'sysvacu03_tiempo_interdosis' =>"" , //Tiempo entre dosis para la vacuna
								'codigo_mensaje' => "0",
								'mensaje' => "$mensaje_error"
							);
		   
		   }
								
     
 }else{
 
	         $campo_vacio = "";

			  if($sysdesa10_dni==""){
				   $campo_vacio .= "DNI";
				   $campo_vacio .= ",";
			 }

			 if($sysdesa10_sexo==""){
				   $campo_vacio .= "SEXO";
				   $campo_vacio .= ",";
			 }
			
			 $campos =substr($campo_vacio, 0, -1);
			 
		$mensaje = "No pueden haber campos vacíos. Campos Vacios: $campos";
		//$mensaje = utf8_encode($mensaje);
				  $aplicaciones_beneficiario[] = array(
								'sysvacu04_nombre' => "", //NOMBRE DE LA VACUNA
								'sysvacu05_nombre' => "", //DOSIS
								'sysdesa10_fecha_aplicacion' => "", //FECHA DE APLICACION
								'fecha_proxima_dosis' => "", //FECHA  MÍNIMA PARA APLICAR LA SEGUNDA DOSIS
								'dias_transcurridos' => "", //CANTIDAD DE DÍAS QUE TRANSCURRIERON DESDE LA FECHA DE APLICACIÓN
								'sysvacu03_tiempo_interdosis' =>"" , //Tiempo entre dosis para la vacuna
								'codigo_mensaje' => "0",
								'mensaje' =>"$mensaje",
							);
     
 }
 
 //echo  json_encode(array('aplicaciones_beneficiario' => $aplicaciones_beneficiario), JSON_UNESCAPED_UNICODE);
 echo  json_encode(array('aplicaciones_beneficiario' => $aplicaciones_beneficiario));

?>