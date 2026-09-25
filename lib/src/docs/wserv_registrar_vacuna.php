<?php
include "../../../../lib/functions.php";
include "../../conexion/link_mysql.php";
include "../../../consultar_datos_renaper/libreria/library/Requests.php";

//include "../../../../lib/link_msq.php";
Requests::register_autoloader();

$insertvacunado = $_GET['insertvacunado'];
$insertvacunado = json_decode($insertvacunado, true);
$contador = 0;
$mensaje_notificacion = "";
$variable_validacion = true;
$mensajes = array();

mysqli_set_charset($conexion, "utf8");
//REALIZÓ LAS VALIDACIONES PARA ASEGURAR QUE TODOS LOS DATOS ESTÁN CORRECTOS PARA PODER HACER EL INSERT DEL/LOS REGISTROS
foreach ($insertvacunado as $value) {
   
	$id_flxcore03=$value['id_flxcore03']; //REGISTRADOR
	//$id_sysvacu03=$value['id_sysvacu03']; //CONFIGURACIÓN DE VACUNA (SE QUITÓ DE LA ÚLTIMA VERSIÓN)
	
	$id_sysvacu01=$value['id_sysvacu01']; //CONDICIÓN (SE AGREGÓ DE LA ÚLTIMA VERSIÓN)
	$id_sysvacu02=$value['id_sysvacu02']; //ESQUEMA (SE AGREGÓ DE LA ÚLTIMA VERSIÓN)
	$id_sysvacu04=$value['id_sysvacu04']; //VACUNA (SE AGREGÓ DE LA ÚLTIMA VERSIÓN)
	$id_sysvacu05=$value['id_sysvacu05']; //DÓSIS (SE AGREGÓ DE LA ÚLTIMA VERSIÓN)
	
	$fecha_aplicacion=$value['fecha_aplicacion']; //FECHA DE LA APLICACÓN (SE AGREGÓ DE LA ÚLTIMA VERSIÓN)
	
	$id_sysofic01=$value['id_sysofic01']; //EFECTOR
	$id_sysdesa12=$value['id_sysdesa12']; //VACUNADOR (ID O DNI EN CASO DE QUE REGISTRADOR Y VACUNADOR SEAN IGUALES)
	$vacunador_registrador=$value['vacunador_registrador']; //1 = VACUNADOR Y REGISTRADOR SON LA MISMA PERSONA
	$id_sysdesa18=$value['id_sysdesa18']; //LOTE DE LA VACUNA
	$sysdesa10_apellido=$value['sysdesa10_apellido']; // APELLIDO BENEFICIARIO
	$sysdesa10_nombre=$value['sysdesa10_nombre']; // NOMBRE BENEFICIARIO
	$sysdesa10_dni=$value['sysdesa10_dni']; // DNI BENEFICIARIO
	$sysdesa10_edad=$value['sysdesa10_edad']; // EDAD BENEFICIARIO
	$sysdesa10_fecha_nacimiento=$value['sysdesa10_fecha_nacimiento']; // FECHA DE NACIMIENTO BENEFICIARIO
	$sysdesa10_apellido_tutor=$value['sysdesa10_apellido_tutor']; // NOMBRE DEL TUTOR DEL BENEFICIARIO
	$sysdesa10_nombre_tutor=$value['sysdesa10_nombre_tutor']; // NOMBRE DEL TUTOR DEL BENEFICIARIO
	$sysdesa10_dni_tutor=$value['sysdesa10_dni_tutor']; // DNI DEL TUTOR DEL BENEFICIARIO
	$sysdesa10_sexo_tutor=$value['sysdesa10_sexo_tutor']; // SEXO DEL TUTOR DEL BENEFICIARIO
	$DNI = str_replace("M","",$sysdesa10_dni); // DNI BENEFICIARIO | LE QUITO LA M
	$DNI = str_replace("F","",$DNI); // DNI BENEFICIARIO | LE QUITO LA F
	$sysdesa10_sexo=$value['sysdesa10_sexo'];// // SEXO BENEFICIARIO
	$sysdesa10_nro_tramite=$value['sysdesa10_nro_tramite'];// // NRO DE TRÁMITE DEL BENEFICIARIO
	$sysdesa10_cadena_dni=$value['sysdesa10_cadena_dni'];//CADENA DNI DEL BENEDFICIARIO
	$sysdesa10_terreno=$value['sysdesa10_terreno'];//TERRENO
	
	$respuesta = agregar_aplicacion_vacuna($conexion, $id_flxcore03, $id_sysvacu01,$id_sysvacu02,$id_sysvacu04, 
	                               $id_sysvacu05, $fecha_aplicacion,
                                   $id_sysofic01, $id_sysdesa12,$vacunador_registrador, $id_sysdesa18, $sysdesa10_apellido, 
								   $sysdesa10_nombre, $sysdesa10_dni, $sysdesa10_edad, $sysdesa10_fecha_nacimiento, 
								   $sysdesa10_apellido_tutor, $sysdesa10_nombre_tutor, $sysdesa10_dni_tutor, $sysdesa10_sexo_tutor,
								   $sysdesa10_sexo, $sysdesa10_nro_tramite, $sysdesa10_cadena_dni, $sysdesa10_terreno);
	$mensaje_notificacion = explode("<->",$respuesta);
	$codigo_mensaje = trim($mensaje_notificacion[0]);
	$mensaje_error = trim($mensaje_notificacion[1]);
	$mensajes[] = array(
						'codigo_mensaje' => $codigo_mensaje,
						'mensaje' =>utf8_encode($mensaje_error),
					);
	//echo json_encode(array('mensajes' => $mensajes), JSON_UNESCAPED_UNICODE);
	echo json_encode(array('mensajes' => $mensajes)); 
}

function agregar_aplicacion_vacuna($conexion, $id_flxcore03, $id_sysvacu01,$id_sysvacu02,$id_sysvacu04, 
	                               $id_sysvacu05, $fecha_aplicacion,
                                   $id_sysofic01, $id_sysdesa12,$vacunador_registrador, $id_sysdesa18, $sysdesa10_apellido, 
								   $sysdesa10_nombre, $sysdesa10_dni, $sysdesa10_edad, $sysdesa10_fecha_nacimiento, 
								   $sysdesa10_apellido_tutor, $sysdesa10_nombre_tutor, $sysdesa10_dni_tutor, $sysdesa10_sexo_tutor,
								   $sysdesa10_sexo, $sysdesa10_nro_tramite, $sysdesa10_cadena_dni, $sysdesa10_terreno){
								   
					
	
	
	//SE AGREGÓ EL 01092022 10:50							   
	if($sysdesa10_terreno == "" ){
           $sysdesa10_terreno = 0; //HOSPITAL, SALA, CENTRO DE SALUD;
	}					   
								   
	$sysdesa10_apellido_verificar=Quitar_Espacios($sysdesa10_apellido);
	if(trim($sysdesa10_apellido_verificar) == ""){         
	        $mensaje = "El Apellido del beneficiario no puede estar vacío.";
			return "0 <-> Error: $mensaje";			
	}else{
	    $sysdesa10_apellido = str_replace("'"," ",$sysdesa10_apellido);
	}
	
	
	$sysdesa10_nombre_verificar=Quitar_Espacios($sysdesa10_nombre);
	if(trim($sysdesa10_nombre_verificar) == ""){
	        $mensaje = "El Nombre del beneficiario no puede estar vacío.";
		    return "0 <-> Error: $mensaje";
	}else{
	    $sysdesa10_nombre = str_replace("'"," ",$sysdesa10_nombre);
	}
	
	$sysdesa10_dni_verificar=Quitar_Espacios($sysdesa10_dni);
	if(trim($sysdesa10_dni_verificar) == ""){
	        $mensaje = "El DNI del beneficiario no puede estar vacío.";
            return "0 <-> Error: $mensaje";
	}
	
	if(trim($sysdesa10_sexo) == ""){
	        $mensaje = "El SEXO del beneficiario no puede estar vacío.";
			//$mensaje = utf8_encode($mensaje);
            return "0 <-> Error: $mensaje" ;
	}
	
	if($sysdesa10_fecha_nacimiento == ""){
	       $sysdesa10_fecha_nacimiento = "0000-00-00";
	}else{
	    $sysdesa10_fecha_nacimiento=date("Y-m-d",strtotime($sysdesa10_fecha_nacimiento));
		$sysdesa10_fecha_nacimiento_cadena_dni=date("d-m-Y",strtotime($sysdesa10_fecha_nacimiento));
	}
	
	if(trim($sysdesa10_edad) == ""){
          return "0 <-> Error: La EDAD del beneficiario no puede estar vacío.";
	}else{ //SI EL BENEFICIARIO ES MENOR DE EDAD DEBE CARGRSE LOS DATOS DEL TUTOR 
			if($sysdesa10_edad < 18){
			   if(trim($sysdesa10_apellido_tutor) == ""){
						return "0 <-> Error: El beneficiario es menor de Edad. Debe cargarse el apellido del tutor";
				}else{
				   $sysdesa10_apellido_tutor = str_replace("'"," ",$sysdesa10_apellido_tutor);
				}
			
			   if(trim($sysdesa10_nombre_tutor) == ""){
						return "0 <-> Error: El beneficiario es menor de Edad. Debe cargarse el nombre del tutor";
				}else{
				   $sysdesa10_nombre_tutor = str_replace("'"," ",$sysdesa10_nombre_tutor);
				}
			   
			    if(trim($sysdesa10_dni_tutor) == ""){
						return "0 <-> Error: El beneficiario es menor de Edad. Debe cargarse el DNI del tutor";
				}  
				
				if(trim($sysdesa10_sexo_tutor) == ""){
						return "0 <-> Error: El beneficiario es menor de Edad. Debe cargarse el sexo del tutor";
				}
			}
	}
	
	if($id_flxcore03 == "" or $id_flxcore03 == 0){
          return "0 <-> Error: ID del registrador no puede estar vacío.";
	}
	
	/*if($id_sysvacu03 == "" or $id_sysvacu03 == 0){
          return "0 <-> Error: ID de la Configuracion no puede estar vacío.";
	}*/
	
	if($id_sysvacu01 == "" or $id_sysvacu01 == 0){
          return "0 <-> Error: ID de la Condición no puede estar vacío.";
	}
	
	if($id_sysvacu02 == "" or $id_sysvacu02 == 0){
          return "0 <-> Error: ID del Esquema no puede estar vacío.";
	} 
	
	if($id_sysvacu04 == "" or $id_sysvacu04 == 0){
          return "0 <-> Error: ID de la vacuna no puede estar vacío.";
	}
	
	if($id_sysvacu05 == "" or $id_sysvacu05 == 0){
          return "0 <-> Error: ID de la Dósis no puede estar vacío.";
	}
	
	if($id_sysofic01 == "" or $id_sysofic01 == 0){
          return "0 <-> Error: ID del Efector no puede estar vacío.";
	}
	
	if($id_sysdesa12 == "" or $id_sysdesa12 == 0){
           return "0 <-> Error: ID del Vacunador no puede estar vacío.";
	}else{
	   //VOY A CONSULTAR SI VACUNADOR Y REGISTRADOR SON L AMISMA PERSONA
	   if($vacunador_registrador == 1){ //id_sysdesa12 es un dni
	       $id_vacunador = obtener_datos_vacunador($conexion, $id_sysdesa12);
		   if($id_vacunador == 0){
		       return "0 <-> Error: No se encontró al vacunador con el DNI ($id_sysdesa12) del cargador enviado";
		   }else{
		     $id_sysdesa12 = $id_vacunador;
		   }
		   
	   }
	}
	
	if($id_sysdesa18 == "" or $id_sysdesa18 == 0){
             return "0 <-> Error: El ID del Lote no puede estar vacío.";
	}		
	
	if($fecha_aplicacion == "" or $fecha_aplicacion == "0000-00-00"  or $fecha_aplicacion == "00-00-0000"){
          return "0 <-> Error: No se recibió la Fecha de Aplicación.";
	}else{
	       $sysdesa10_fecha_aplicacion=date("Y-m-d",strtotime($fecha_aplicacion));
		   $fecha_enviar_sisa = date("d-m-Y",strtotime($sysdesa10_fecha_aplicacion));
		   $fecha_aplicacion_insert=$sysdesa10_fecha_aplicacion . " " . date('H:i:s');
	}
	
	// ACA ESTABA DESCUENTO DE LOTE
	
	//OBTENGO EL ID DE LA CONFIGURACIÓN ###########################################################################
	$qr_consulta_configuracion="SELECT id_sysvacu03,rela_sysvacu11 FROM sys_vacu_03_rel_vacuna
								join sys_vacu_04_cab_vacuna on id_sysvacu04=rela_sysvacu04
								where rela_sysvacu01=$id_sysvacu01 and rela_sysvacu02=$id_sysvacu02
								and rela_sysvacu04=$id_sysvacu04 and rela_sysvacu05=$id_sysvacu05";
	$result_consulta_configuracion = mysqli_query($conexion,$qr_consulta_configuracion);
	$num_rows_consulta_configuracion = mysqli_num_rows($result_consulta_configuracion);	
	if($num_rows_consulta_configuracion > 0){
	
		$row_consulta_configuracion = mysqli_fetch_assoc($result_consulta_configuracion);
	    $id_sysvacu03=$row_consulta_configuracion["id_sysvacu03"]; //CONFIGURACIÓN
		$rela_sysvacu11_cfg=$row_consulta_configuracion["rela_sysvacu11"]; //TIPO VACUNA
	
	}else{
	
	  return "0 <-> Error: No se encontró la configuración con la condición, esquema, vacuna ni dósis seleccionada";
	  
	}

	
	
	//VALIDO QUE EL BENEFICIARIO NO HAYA DADO POSITIVO A COVID EN LOS ÚLTIMOS 90DÍAS
	/*$qr_consulta_validar_positivo="SELECT id_syssgho10 , syssgho10_apellido , syssgho10_nombre,syssgho10_documento, 
	                               syssgho10_fechaCargaResultado, syssgho10_resultado,
                                   DATEDIFF(NOW(),syssgho10_fechaCargaResultado) as dias_transcurridos
                                   FROM sys_sgho_10_cab_pacientes_hisopados
                                   where syssgho10_resultadoID = 5 and syssgho10_sexo = '$sysdesa10_sexo' 
						           and syssgho10_documento = '$sysdesa10_dni' ORDER BY id_syssgho10 DESC limit 1"; */
								   
   $qr_consulta_validar_positivo="SELECT id_segpubl01 , segpubl01_apellido , segpubl01_nombre,segpubl01_dni, segpubl01_sexo, 
									segpubl12_fecha_toma_muestra,
									DATEDIFF(NOW(),segpubl12_fecha_toma_muestra) as dias_transcurridos, segpubl02_nombre
									FROM seg_publ_12_det_cambios_relacion_covid
									inner join seg_publ_01_cab_personas on id_segpubl01 = rela_segpubl01
									inner join seg_publ_02_cab_relacion_covid on id_segpubl02 = rela_segpubl02
									where rela_segpubl02=1 and segpubl01_sexo = '$sysdesa10_sexo' 
									and segpubl01_dni = '$sysdesa10_dni' order by segpubl12_fecha_toma_muestra DESC LIMIT 1";
								   
								   
	$result_consulta_validar_positivo = mysqli_query($conexion,$qr_consulta_validar_positivo);
	$num_rows_consulta_validar_positivo = mysqli_num_rows($result_consulta_validar_positivo);	
	if ($num_rows_consulta_validar_positivo>0){
	    $row_consulta_validar_positivo = mysqli_fetch_assoc($result_consulta_validar_positivo);
		$dias_transcurridos=$row_consulta_validar_positivo["dias_transcurridos"];
		$segpubl01_apellido=$row_consulta_validar_positivo["segpubl01_apellido"];
		$segpubl01_nombre=$row_consulta_validar_positivo["segpubl01_nombre"];
		$segpubl01_dni=$row_consulta_validar_positivo["segpubl01_dni"];
		$segpubl12_fecha_toma_muestra=viewDateTime($row_consulta_validar_positivo["segpubl12_fecha_toma_muestra"]);
		
		if($row_consulta_validar_positivo["segpubl12_fecha_toma_muestra"] != "" and 
				     $row_consulta_validar_positivo["dias_transcurridos"] != ""){
		  //if($dias_transcurridos <= 90){
	      if($dias_transcurridos <= 21 and $rela_sysvacu11_cfg==1){ // 30/07/2021 10:12
		    return ("0 <-> Error: El/La ciudadano/a $segpubl01_apellido $segpubl01_nombre - DNI: $segpubl01_dni posee un resultado DETECTABLE 
			a COVID-19 cargado el $segpubl12_fecha_toma_muestra ( hace $dias_transcurridos días)");
		  }
		}
        
	}
	
	//VOY A VALIDAR QUE EL CIUDADANO NO FIGURE COMO FALLECIDO #########################################################
	if($sysdesa10_sexo == "M"){
		  $sysdesa10_sexo_consultar = 2;
		}else if($sysdesa10_sexo == "F"){
		  $sysdesa10_sexo_consultar = 1;
		}else{
		  $sysdesa10_sexo_consultar = 0;
		}
	 //COMENTADO 26102021 0752
	 $json_datos_personales = obtener_datos_personales($sysdesa10_dni, $sysdesa10_sexo_consultar);
	 
	 if($json_datos_personales != ""){
	     $descripcionError= trim($json_datos_personales['descripcionError']);
		 $apellido= utf8_decode($json_datos_personales['apellido']);
		 $nombres= utf8_decode($json_datos_personales['nombres']);
		 $fechaf= ($json_datos_personales['fechaf']);
		 $fechaNacimiento= $json_datos_personales['fechaNacimiento'];
		 $sysdesa10_fecha_nacimiento=date("Y-m-d",strtotime($fechaNacimiento));
         $sysdesa10_fecha_nacimiento_cadena_dni=date("d-m-Y",strtotime($fechaNacimiento));
		 //$error_1 = "SIN DNI DIGITAL VIGENTE";
		 //$error_2 = "SIN TARJETA REIMPRESA"; 
		 
		 $campos_fecha = explode("-", $fechaf);
		 
		 if (is_numeric($campos_fecha[0]) and is_numeric($campos_fecha[1]) and is_numeric($campos_fecha[2])) {
		      $fecha_fallecimiento=date("d-m-Y",strtotime($fechaf));
			  $mensaje = "El/La Ciudadano/a $apellido $nombres - DNI: $sysdesa10_dni figura como fallecido/a desde el $fecha_fallecimiento.";
              return "0 <-> Error: $mensaje";
		}
		
	} 
	//####################################################################################################
	  
	 //##########################################################################
	 //DESARROLLO !!!!!!!!!!!!!!
	$qr_consulta_validar="SELECT id_sysdesa10 FROM sys_desa_99_cab_nomivac_pruebas where sysdesa10_dni = '$sysdesa10_dni' 
    and rela_sysvacu03=$id_sysvacu03";  
	
	 //PRODUCCION !!!!!!!!!!!!!!!!!!!
	/*$qr_consulta_validar="SELECT id_sysdesa10, rela_sysvacu11, sysvacu05_orden_numerico,sysvacu05_nombre,id_sysvacu04,
	DATEDIFF(NOW(),sysdesa10_fecha_aplicacion) as dias_transcurridos FROM sys_desa_10_cab_nomivac
	inner join sys_vacu_03_rel_vacuna on id_sysvacu03=rela_sysvacu03
	inner join sys_vacu_04_cab_vacuna on id_sysvacu04=rela_sysvacu04
	inner join sys_vacu_05_cab_dosis on id_sysvacu05=rela_sysvacu05
	inner join sys_vacu_11_tipo_vacuna on id_sysvacu11=rela_sysvacu11
	where sysdesa10_dni = '$sysdesa10_dni' 
	and sysdesa10_sexo = '$sysdesa10_sexo' and rela_sysvacu03=$id_sysvacu03";	*/
	
	 
	$result_consulta_validar = mysqli_query($conexion,$qr_consulta_validar);
	$row_consulta_validar = mysqli_fetch_assoc($result_consulta_validar);
	$num_rows_consulta_validar = mysqli_num_rows($result_consulta_validar);	
	
	$rela_sysvacu11 = $row_consulta_validar["rela_sysvacu11"];
	$sysvacu05_orden_numerico = $row_consulta_validar["sysvacu05_orden_numerico"];
	$dosis = $row_consulta_validar["sysvacu05_nombre"];
	$vac = $row_consulta_validar["id_sysvacu04"];
	$dias_aplicacion=$row_consulta_validar["dias_transcurridos"];
	
	
	
	if ($num_rows_consulta_validar>0){
	    if($rela_sysvacu11 == 1){
			if ($dosis != "Refuerzo"){
				$mensaje = "Ya se encuentra registrada la persona con el DNI ingresado y la configuración seleccionada.";
        		return "0 <-> Error: $mensaje";	
			}
			else{				
				if($dias_aplicacion < 120){
					$faltan_dias = 120 - $dias_aplicacion;
					$mensaje = "Error: Faltan $faltan_dias dias para aplicar la siguiente dosis.";
        			return "0 <-> Error: $mensaje";
				}	
			}			
		}else if ($rela_sysvacu11 == 4){ //OTRAS VACUNAS, AGREGADO PROVISORIAMENTE PARA DENGUE 11-10-24
			if ($vac == 78){
				$mensaje = "Ya se encuentra registrada la persona con el DNI ingresado y la configuración seleccionada.";
        		return "0 <-> Error: $mensaje";	
			}
			else{
				;
			}
		}
		else{
				
			$fecha_aplicacion_validacion=date("Y-m-d 00:00:00",strtotime($fecha_aplicacion));

			$qr_validar_mismo_dia="SELECT count(1) cantidad FROM sys_desa_10_cab_nomivac c
										WHERE
										CAST(`sysdesa10_fecha_aplicacion` AS DATE)=CAST('$fecha_aplicacion_validacion' AS DATE)
										AND c.sysdesa10_dni='$sysdesa10_dni'
										AND c.sysdesa10_sexo='$sysdesa10_sexo'
										AND c.rela_sysvacu03 IN(
											SELECT id_sysvacu03 FROM `sys_vacu_03_rel_vacuna`
											WHERE rela_sysvacu04=( SELECT rela_sysvacu04 FROM sys_vacu_03_rel_vacuna
												WHERE id_sysvacu03=$id_sysvacu03 LIMIT 1
											)
										)";

			$result_validar_mismo_dia = mysqli_query($conexion,$qr_validar_mismo_dia);
			//$num_rows_mismo_dia = mysqli_num_rows($result_validar_mismo_dia);
			$row_validar_vacuna_2 = mysqli_fetch_assoc($result_validar_mismo_dia);
			$cantidad = intval($row_validar_vacuna_2["cantidad"]);
			
			if ($cantidad > 0){
				if ($sysdesa10_edad > 0){
					return "0 <-> Error: No se puede aplicar la misma dosis en menos de 24 hrs";
				}
				else{
					;
				}
			}else{
				if( ($rela_sysvacu11==3 or $rela_sysvacu11==4) and $dosis!="Dosis Anual" and $edad > 0){
					
					if ($dosis!="Refuerzo"){
						$mensaje = "Ya se encuentra registrada la persona con el DNI ingresado y la configuración seleccionada.";
        				return "0 <-> Error: $mensaje";
					}										
				}else{
					;
				}
			}
		} //comentado para probar dosis del dia 20-09-23
	}else{	 		
		//OBTENGO EL ID DE LA VACUNA
	    $qr_consulta_validar_2="SELECT rela_sysvacu04,rela_sysvacu01,sysvacu05_orden_numerico,sysvacu05_nombre,id_sysvacu11 FROM sys_vacu_03_rel_vacuna
								inner join sys_vacu_01_cab_condicion_aplicacion on id_sysvacu01=rela_sysvacu01
								inner join sys_vacu_04_cab_vacuna on id_sysvacu04=rela_sysvacu04
								inner join sys_vacu_05_cab_dosis on id_sysvacu05=rela_sysvacu05
								inner join sys_vacu_11_tipo_vacuna on id_sysvacu11=rela_sysvacu11
								where id_sysvacu03=$id_sysvacu03";
	                         $result_consulta_validar_2 = mysqli_query($conexion,$qr_consulta_validar_2);
	                         //$num_rows_consulta_validar_2 = mysqli_num_rows($result_consulta_validar_2);	
							 $row_consulta_validar_2 = mysqli_fetch_assoc($result_consulta_validar_2);
							 $rela_sysvacu01=$row_consulta_validar_2["rela_sysvacu01"];
							 $rela_sysvacu04=$row_consulta_validar_2["rela_sysvacu04"];
							 $sysvacu05_orden_numerico=$row_consulta_validar_2["sysvacu05_orden_numerico"];
							 $sysvacu05_nombre=$row_consulta_validar_2["sysvacu05_nombre"];
							 $id_sysvacu11=$row_consulta_validar_2["id_sysvacu11"];
							 
							 
	           //CONTROLO LAS DOSIS APLICADAS POR LA VACUNA, DNI Y SEXO DEL BENEFICIARIO
			   //############################ PRODUUCCIÓN ###############################
			   //PRODUCCIÓN
			   /*$qr_validar_vacunas="SELECT id_sysdesa10,sysvacu04_nombre, sysvacu05_nombre, sysdesa10_fecha_aplicacion, 
								DATEDIFF(NOW(),sysdesa10_fecha_aplicacion) as dias_transcurridos,
								sysvacu03_tiempo_interdosis, id_sysvacu04, sysvacu05_orden_numerico, rela_sysvacu11
								FROM sys_desa_10_cab_nomivac
								left outer join sys_vacu_03_rel_vacuna on id_sysvacu03=rela_sysvacu03
								inner join sys_vacu_04_cab_vacuna on id_sysvacu04=rela_sysvacu04
								left outer join sys_vacu_05_cab_dosis on id_sysvacu05=rela_sysvacu05
								inner join sys_vacu_11_tipo_vacuna on id_sysvacu11=rela_sysvacu11
								where sysdesa10_dni = '$sysdesa10_dni' and sysdesa10_sexo = '$sysdesa10_sexo'
								and rela_sysvacu11=$id_sysvacu11 -- and rela_sysvacu03=$id_sysvacu03
								order by id_sysvacu04 ASC";*/
				//DESARROLLO			
			    $qr_validar_vacunas="SELECT id_sysdesa10,sysvacu04_nombre, sysvacu05_nombre, sysdesa10_fecha_aplicacion, 
								DATEDIFF(NOW(),sysdesa10_fecha_aplicacion) as dias_transcurridos,
								sysvacu03_tiempo_interdosis, id_sysvacu04, sysvacu05_orden_numerico
								FROM sys_desa_99_cab_nomivac_pruebas
								left outer join sys_vacu_03_rel_vacuna on id_sysvacu03=rela_sysvacu03
								left outer join sys_vacu_05_cab_dosis on id_sysvacu05=rela_sysvacu05
								inner join sys_vacu_04_cab_vacuna on id_sysvacu04=rela_sysvacu04
								where sysdesa10_dni = '$sysdesa10_dni' and sysdesa10_sexo = '$sysdesa10_sexo'
								order by id_sysvacu04 ASC"; 

			$result_validar_vacunas = mysqli_query($conexion,$qr_validar_vacunas);
			//$num_rows = mysqli_num_rows($result_edu);
			$num_rows_validar_vacunas = mysqli_num_rows($result_validar_vacunas);
			$id_anterior = 0;
		   if ($num_rows_validar_vacunas>0){
                    while ($row_validar_vacunas = mysqli_fetch_assoc($result_validar_vacunas)){
					
				//while ($row_validar_vacunas = flex_fetch_assoc($result_validar_vacunas)){
				          $fecha=$row_validar_vacunas["sysdesa10_fecha_aplicacion"];
						  $fecha_array=explode(" ",$fecha);
						  $sysdesa10_fecha_aplicacion=viewDate($fecha_array[0]);
                          $id_sysvacu04 = $row_validar_vacunas["id_sysvacu04"]; 
						  $sysvacu05_orden_numerico_validar = $row_validar_vacunas["sysvacu05_orden_numerico"];
						  $sysvacu05_nombre_validar = $row_validar_vacunas["sysvacu05_nombre"];
						  $rela_sysvacu11_validar = $row_validar_vacunas["rela_sysvacu11"];
						  
						  $dias_aplicacion = $row_validar_vacunas["dias_transcurridos"];	
						  
						  if($sysvacu05_orden_numerico_validar == $sysvacu05_orden_numerico){						  		
						  
						  		//if ($rela_sysvacu04 == 57 or $rela_sysvacu04 == 42 or $id_sysvacu11 != 1 or $sysvacu05_nombre == "Refuerzo"){ //triple viral y ipv salk o condicion es distinta de covid	--------> se comenta el 09022024 por doble carga de registros
								if ($sysvacu05_nombre == "Refuerzo"){
									if ($dias_aplicacion < 120 and $id_sysvacu11==1){
										$faltan_dias = 120 - $dias_aplicacion;
										$mensaje = "Error: Faltan $faltan_dias dias para aplicar la siguiente dosis.";
        								return "0 <-> Error: $mensaje";
									}else{
										continue; 
									}									
								}
								else{
									if ($id_sysvacu11 != 1){
										if ($rela_sysvacu04==78){
											return "0 <-> Error: Ya se encuentra registrada esta dosis para la vacuna seleccionada.";
										}else{
											continue;
										}										
									}else{
										return "0 <-> Error: Ya se encuentra registrada esta dosis para la vacuna seleccionada.";
									}									
								}
						  		//if ($id_sysvacu11 == 1 and $rela_sysvacu11_validar == 1){ //vacuna covid								
								//}
								//else{
									//continue;
								//}
						  }
						  

						  if($id_anterior == $id_sysvacu04){
						     continue;
						  }else{
						      $id_anterior = $id_sysvacu04;
						  }
						  
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
						//DE ACUERDO A LA FECHA DE APLICACIÓN Y LA CANTIDAD DE DÍAS ENTRE DOSIS SACO LA FECHA MÍNIMA PARA LA PRÓXIMA DOSIS
						
						if($sysvacu03_tiempo_interdosis !=0){
						    $fecha_limite=date("Y-m-d",strtotime($sysdesa10_fecha_aplicacion."+ ". $sysvacu03_tiempo_interdosis ." days"));
							$fecha_proxima_dosis=date("d-m-Y",strtotime($fecha_limite));
						}
						
						
						/*if($id_sysvacu11 == $rela_sysvacu11_validar){ // comentado 24052022 facu
							if($dias_transcurridos < $sysvacu03_tiempo_interdosis){
							   $faltan_dias = $sysvacu03_tiempo_interdosis - $dias_transcurridos;
							   return "0 <-> Error: Faltan $faltan_dias para aplicar la siguiente dosis";
							}
						}*/
						
						if($id_sysvacu11 == $rela_sysvacu11_validar){
						
							$qr_validar_vacunas_orden="SELECT id_sysdesa10,sysvacu04_nombre, sysvacu05_nombre, sysdesa10_fecha_aplicacion, 
								DATEDIFF(NOW(),sysdesa10_fecha_aplicacion) as dias_transcurridos,
								sysvacu03_tiempo_interdosis, id_sysvacu04, sysvacu05_orden_numerico,rela_sysvacu11
								FROM sys_desa_10_cab_nomivac
								left outer join sys_vacu_03_rel_vacuna on id_sysvacu03=rela_sysvacu03
								left outer join sys_vacu_04_cab_vacuna on id_sysvacu04=rela_sysvacu04
								left outer join sys_vacu_05_cab_dosis on id_sysvacu05=rela_sysvacu05
								left outer join sys_vacu_11_tipo_vacuna on id_sysvacu11=rela_sysvacu11
								where sysdesa10_dni = '$sysdesa10_dni' and sysdesa10_sexo = '$sysdesa10_sexo'
								and rela_sysvacu11=$id_sysvacu11
								order by sysvacu05_orden_numerico DESC LIMIT 1";
								
							$result_validar_vacunas_orden = mysqli_query($conexion,$qr_validar_vacunas_orden);
							$num_rows_validar_vacunas_orden = mysqli_num_rows($result_validar_vacunas_orden);
							
						  	if ($num_rows_validar_vacunas_orden>0){
                    			$row_validar_vacunas_orden = mysqli_fetch_assoc($result_validar_vacunas_orden);
								$sysvacu05_orden_numerico_validar_interdosis = $row_validar_vacunas_orden["sysvacu05_orden_numerico"];
								$dias_transcurridos_validar_interdosis = $row_validar_vacunas_orden["dias_transcurridos"];
							}
							
							/*echo $dias_transcurridos;
							echo " ----- ";
							echo $sysvacu03_tiempo_interdosis;*/
							
							if ($id_sysvacu11 == 1){ //Vacunas COVID = 1
								if (($sysvacu05_orden_numerico == 2) and ($sysvacu05_orden_numerico_validar_interdosis == 1)){
									if($dias_transcurridos_validar_interdosis < 28){
										$faltan_dias = 28 - $dias_transcurridos_validar_interdosis;
										return "0 <-> Error: Faltan $faltan_dias dias para aplicar la siguiente dosis";
									}
								}

								else if (($sysvacu05_orden_numerico == 3 or $sysvacu05_orden_numerico == 6) and ($sysvacu05_orden_numerico_validar_interdosis == 2)){								

									if($dias_transcurridos_validar_interdosis < 90){
										$faltan_dias = 90 - $dias_transcurridos_validar_interdosis;
										return "0 <-> Error: Faltan $faltan_dias dias para aplicar la siguiente dosis";
									}
								}

								else if (($sysvacu05_orden_numerico == 4 or $sysvacu05_orden_numerico == 6) and ($sysvacu05_orden_numerico_validar_interdosis == 3)){

									if($dias_transcurridos_validar_interdosis < 120){
										$faltan_dias = 120 - $dias_transcurridos_validar_interdosis;
										return "0 <-> Error: Faltan $faltan_dias dias para aplicar la siguiente dosis";
									}
								}

								else if (($sysvacu05_orden_numerico == 5 or $sysvacu05_orden_numerico == 6) and ($sysvacu05_orden_numerico_validar_interdosis == 4)){

									if($dias_transcurridos_validar_interdosis < 120){
										$faltan_dias = 120 - $dias_transcurridos_validar_interdosis;
										return "0 <-> Error: Faltan $faltan_dias dias para aplicar la siguiente dosis";
									}
								}
								
								else if (($sysvacu05_orden_numerico == 6) and ($sysvacu05_orden_numerico_validar_interdosis == 5)){

									if($dias_transcurridos_validar_interdosis < 120){
										$faltan_dias = 120 - $dias_transcurridos_validar_interdosis;
										return "0 <-> Error: Faltan $faltan_dias dias para aplicar la siguiente dosis";
									}
								}

								/*else if($dias_transcurridos < $sysvacu03_tiempo_interdosis){
									$faltan_dias = $sysvacu03_tiempo_interdosis - $dias_transcurridos;
									return "0 <-> Error: Faltan $faltan_dias dias para aplicar la siguiente dosis";
								}
								if ($rela_sysvacu04 == 2){
									if($dias_transcurridos < 183){
									   $faltan_dias = 183 - $dias_transcurridos;
									   return "0 <-> Error: Faltan $faltan_dias dias para aplicar la siguiente dosis";
									}
								}*/
								
								else{
									if($sysvacu03_tiempo_interdosis>0){
										if($dias_transcurridos_validar_interdosis < $sysvacu03_tiempo_interdosis){
										   $faltan_dias = $sysvacu03_tiempo_interdosis - $dias_transcurridos;
										   return "0 <-> Error: Faltan $faltan_dias dias para aplicar la siguiente dosis";
										}
									}
								}
								if($sysvacu05_nombre=="Refuerzo"){
									if($dias_transcurridos_validar_interdosis < 120){
										$faltan_dias = 120 - $dias_transcurridos_validar_interdosis;
										return "0 <-> Error: Faltan $faltan_dias dias para aplicar la siguiente dosis";
									}
								}
							}
						}	
				}
		   }
	   
	}
	
								
	
	   $sysdesa10_fecha_alta=date('Y-m-d');
	   //$sysdesa10_fecha_aplicacion=date('Y-m-d H:i:s');
	   	   
	   if($sysdesa10_cadena_dni != ""){
	   
	       $cadena_dni = str_replace(array(",", ".", ":", "(", ")", "|","'")," ",$sysdesa10_cadena_dni);
		   $cadena_dni = utf8_encode($cadena_dni);
	       //$cadena_dni = str_replace("'"," ",$sysdesa10_cadena_dni);
	   }
	   
	   if($fecha_aplicacion_insert != "" and $id_sysdesa18 != ""){
			$qr_lotes_vencidos="select * from sys_desa_18_cab_lotes where id_sysdesa18=$id_sysdesa18";
			
			$result_validar_lotes_vencidos = mysqli_query($conexion,$qr_lotes_vencidos);
			$num_rows_validar_lotes_vencidos = mysqli_num_rows($result_validar_lotes_vencidos);
			
			if ($num_rows_validar_lotes_vencidos>0){
				$row_validar_lotes_vencidos = mysqli_fetch_assoc($result_validar_lotes_vencidos);
				$sysdesa18_lote = $row_validar_lotes_vencidos["sysdesa18_lote"];
				$sysdesa18_fecha_vencimiento = viewDate(($row_validar_lotes_vencidos["sysdesa18_fecha_vencimiento"]));
			}

			$fecha_aplicacion_validar_lote=date("d-m-Y H:i:s",strtotime($fecha_aplicacion_insert));

			$sysdesa18_fecha_vencimiento=$sysdesa18_fecha_vencimiento . " " . date('23:59:59');
			
			$fecha_aplicacion_validar_lote=strtotime($fecha_aplicacion_validar_lote);
			$sysdesa18_fecha_vencimiento=strtotime($sysdesa18_fecha_vencimiento);
			
			//echo $sysdesa18_fecha_vencimiento;sysdesa18_fecha_vencimiento sysdesa10_fecha_aplicacion

			if ($fecha_aplicacion_validar_lote > $sysdesa18_fecha_vencimiento){
				return "0 <-> Error: El lote seleccionado ($sysdesa18_lote) está vencido para esta Fecha de Aplicación";
			}
		}
	  
	   //$sysdesa10_fecha_nacimiento = 
	   //$sysdesa10_fecha_nacimiento=viewDate($sysdesa10_fecha_nacimiento);
	   
	   /*if ($id_flxcore03==3168 or $id_flxcore03==683){
	   		 $qr2="
			VALUES 
			(
			$id_flxcore03,
			$id_sysvacu03,
			$id_sysofic01,
			$id_sysdesa12,
			'$fecha_aplicacion_insert',
			$id_sysdesa18,
			'$sysdesa10_fecha_alta',
			'$sysdesa10_apellido',
			'$sysdesa10_nombre',
			'$sysdesa10_dni',
			'$sysdesa10_sexo',
			$sysdesa10_edad,
			'$sysdesa10_fecha_nacimiento',
			'$sysdesa10_nro_tramite',
			'$cadena_dni',
			'$sysdesa10_apellido_tutor',
			'$sysdesa10_nombre_tutor',
			'$sysdesa10_dni_tutor',
			'$sysdesa10_sexo_tutor',
			$sysdesa10_terreno
			)";
			
			$query_error= Quitar_Espacios($qr2);
	   		return "$query_error";
	   }*/
	  
	   //############################# PRODUCCIÓN #####################################
	   /*$qr1="INSERT INTO sys_desa_10_cab_nomivac
			(
			rela_flxcore03,
			rela_sysvacu03, 
			rela_sysofic01,
			rela_sysdesa12,
			sysdesa10_fecha_aplicacion,
			rela_sysdesa18,
			sysdesa10_fecha_alta,
			sysdesa10_apellido,
			sysdesa10_nombre,
			sysdesa10_dni,
			sysdesa10_sexo,
			sysdesa10_edad,
			sysdesa10_fecha_nacimiento,
			sysdesa10_nro_tramite,
			sysdesa10_cadena_dni,
			sysdesa10_apellido_tutor,
			sysdesa10_nombre_tutor,
			sysdesa10_dni_tutor,
			sysdesa10_sexo_tutor,
			sysdesa10_terreno
			) 
			VALUES 
			(
			$id_flxcore03,
			$id_sysvacu03,
			$id_sysofic01,
			$id_sysdesa12,
			'$fecha_aplicacion_insert',
			$id_sysdesa18,
			'$sysdesa10_fecha_alta',
			'$sysdesa10_apellido',
			'$sysdesa10_nombre',
			'$sysdesa10_dni',
			'$sysdesa10_sexo',
			$sysdesa10_edad,
			'$sysdesa10_fecha_nacimiento',
			'$sysdesa10_nro_tramite',
			'$cadena_dni',
			'$sysdesa10_apellido_tutor',
			'$sysdesa10_nombre_tutor',
			'$sysdesa10_dni_tutor',
			'$sysdesa10_sexo_tutor',
			$sysdesa10_terreno
			)";*/
		  //=====================================================
		  //DESARROLLO
		  $qr1="INSERT INTO sys_desa_99_cab_nomivac_pruebas
			(
			rela_flxcore03,
			rela_sysvacu03,
			rela_sysofic01,
			rela_sysdesa12,
			sysdesa10_fecha_aplicacion,
			rela_sysdesa18,
			sysdesa10_fecha_alta,
			sysdesa10_apellido,
			sysdesa10_nombre,
			sysdesa10_dni,
			sysdesa10_sexo,
			sysdesa10_edad,
			sysdesa10_fecha_nacimiento,
			sysdesa10_nro_tramite,
			sysdesa10_cadena_dni,
			sysdesa10_apellido_tutor,
			sysdesa10_nombre_tutor,
			sysdesa10_dni_tutor,
			sysdesa10_sexo_tutor
			) 
			VALUES 
			(
			$id_flxcore03,
			$id_sysvacu03,
			$id_sysofic01,
			$id_sysdesa12,
			'$fecha_aplicacion_insert',
			$id_sysdesa18,
			'$sysdesa10_fecha_alta',
			'$sysdesa10_apellido',
			'$sysdesa10_nombre',
			'$sysdesa10_dni',
			'$sysdesa10_sexo',
			$sysdesa10_edad,
			'$sysdesa10_fecha_nacimiento',
			'$sysdesa10_nro_tramite',
			'$sysdesa10_cadena_dni',
			'$sysdesa10_apellido_tutor',
			'$sysdesa10_nombre_tutor',
			'$sysdesa10_dni_tutor',
			'$sysdesa10_sexo_tutor'
			)
			";
			
		 $resultI =mysqli_query($conexion,$qr1);
		 
		 //SE AGREGA 20-05-2024
	if($id_sysdesa18!=""){
		$qr_lote="select sysdesa18_lote from sys_desa_18_cab_lotes
		where id_sysdesa18=$id_sysdesa18";
		
		$result_lote = mysqli_query($conexion,$qr_lote);	
		$row_lote = mysqli_fetch_assoc($result_lote);
		
		$lote_descripcion=$row_lote["sysdesa18_lote"];
		
		
		//DESCEUNTO DE LOTE
		$qr_stock_lotes="select id_sysdesa18, sysdesa18_cantidad_actual from sys_desa_18_cab_lotes
			inner join sys_ofic_01_cab_establecimientos on id_sysofic01=rela_sysofic01_dh
			where sysdesa18_lote='$lote_descripcion' and rela_sysofic01_dh=$id_sysofic01 and sysdesa18_inicial = 1
			and sysdesa18_cantidad_actual > 0";
			
		$result_stock_lotes = mysqli_query($conexion,$qr_stock_lotes);
		$num_rows_stock_lotes = mysqli_num_rows($result_stock_lotes);

		if ($num_rows_stock_lotes > 0){

			$row_validar_stock_lotes = mysqli_fetch_assoc($result_stock_lotes);				

			$id_sysdesa18_inicial = $row_validar_stock_lotes["id_sysdesa18"];
			
			$sysdesa18_cantidad_actual = $row_validar_stock_lotes["sysdesa18_cantidad_actual"];
			
			if ($id_sysvacu04==8 && $sysdesa10_edad > 2){ //VACUNA ANTIGRIPAL PEDIATRICA APLICADA A MAYORES DE EDAD DEBE DESCONTAR DOBLE
				$cantidad_resta=intval($sysdesa18_cantidad_actual) - 2;
				$sysvacu27_cantidad=2;
			}else{
				$cantidad_resta=intval($sysdesa18_cantidad_actual) - 1;
				$sysvacu27_cantidad=1;
			}			

			$id_sysdesa18=$row_validar_stock_lotes["id_sysdesa18"];
			
			//Facu 07-05-2024 -> se agrega porque empieza a funcionar el descuento de stock a partir del 20-05-2024
			$fecha_19_mayo = date("Y-m-d",strtotime('2024-05-19')); 
			$fecha_aplicacion_validacion = date("Y-m-d", strtotime($fecha_aplicacion));			

			//if( $fecha_aplicacion_validacion > $fecha_19_mayo ){
				//actualizo el stock
				$sql_stock="UPDATE sys_desa_18_cab_lotes 
							SET sysdesa18_cantidad_actual=$cantidad_resta
							WHERE id_sysdesa18=$id_sysdesa18_inicial";

				$result_stock =mysqli_query($conexion,$sql_stock); 

				if (!$result_stock>0) // si se deseas arrojar un error >>>

				{
					$query_error= Quitar_Espacios($sql_stock);
					return "0 <-> Error: Hubo un error al descontar el lote - $query_error";		
				}else{
					$fecha_actual=date("Y-m-d H:i:s");
						
					$qr_insert="INSERT INTO sys_vacu_27_det_movimientos_lotes
								SET rela_sysdesa18=$id_sysdesa18_inicial,
								rela_flxcore03=$id_flxcore03,
								rela_sysofic01_origen=$id_sysofic01,
								rela_sysauto35=1,
								rela_sysauto36=8,
								sysvacu27_fecha_modi='$fecha_actual',
								sysvacu27_cantidad_actual=($sysdesa18_cantidad_actual-1),
								sysvacu27_cantidad=$sysvacu27_cantidad,
								sysvacu27_observacion='APP VACUNA'";


					$result_insert=mysqli_query($conexion,$qr_insert);
					if (!$result_insert>0) // si se deseas arrojar un error >>>

					{
						$query_error= Quitar_Espacios($qr_insert);
						return "0 <-> Error: Hubo un error al actualizar el stock del lote - $query_error";		
					}
				}
			//}
		}
		else{
			$query_error= Quitar_Espacios($qr_stock_lotes);
			return "0 <-> Error: No hay stock disponible para el lote seleccionado.";	
		}
	}
	//$resultI = flex_query($qr1,$link_msq);
	
	
	
	if (!$resultI>0) 
	{
	     $query_error= Quitar_Espacios($qr1);
		 return "0 <-> Error: No pudo guardarse el registro. Comunicarse con los Administradores - $query_error";
		 
	}else{
			  
	   $id_sysdesa10 = mysqli_insert_id($conexion); //RECUPERO EL ID DEL REGISTRO GUARDADO
	   $id_sysdesa10_auditoria=$id_sysdesa10;
	   $mensaje_respuesta = "Registro guardado correctamente.";	   
	  
	   		//PRODUCCIÓN
		   $respuesta_sisa = informar_sisa($conexion,$id_sysdesa10, $id_sysvacu03, $id_sysdesa18, $id_sysofic01,
										   $sysdesa10_dni, $sysdesa10_sexo,$sysdesa10_apellido, $sysdesa10_nombre,
										   $sysdesa10_fecha_nacimiento_cadena_dni,$fecha_enviar_sisa); 
		   $respuesta_sisa = 1;

		   if($respuesta_sisa != 1){
			   $mensaje_respuesta .=" Pero no pudo notificarse a SISA"; 

			   //GUARDO LA CONSULTA DE INSERCIÓN DL REGISTRO DE VACUNA EN LA BASE
				$respuesta_auditoria=auditoria($conexion,$id_sysdesa10_auditoria, $qr1);	
				//$mensaje_respuesta .=" | respuesta_auditoria $respuesta_auditoria |";  

			   return "1 <-> ". $mensaje_respuesta;
			}
	  		
	}
	return $mensaje_respuesta;
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

function informar_sisa($conexion,$id_sysdesa10, $id_sysvacu03, $id_sysdesa18, $id_sysofic01,
                       $sysdesa10_dni, $sysdesa10_sexo, $sysdesa10_apellido, $sysdesa10_nombre,
					   $sysdesa10_fecha_nacimiento_cadena_dni,$fecha_enviar_sisa){

		if($id_sysofic01 == ""){ return 0; }
		
		if($id_sysdesa10 == ""){ return 0; }
		
		if($id_sysvacu03 == "" or $id_sysvacu03 == 0){ return 0; }
		
		if($id_sysdesa18 == "" or $id_sysdesa18 == 0){ return 0; }
			
$qr_consulta_1="SELECT sysofic01_codigo_sisa,id_sysofic01 FROM sys_ofic_01_cab_establecimientos where id_sysofic01 = $id_sysofic01";
	$result_consulta_1 = mysqli_query($conexion,$qr_consulta_1);
	$num_rows_consulta_1 = mysqli_num_rows($result_consulta_1);	
	if ($num_rows_consulta_1>0){
	 
	 $row_consulta_1 = mysqli_fetch_assoc($result_consulta_1);
	  //$id_sysofic01=$row_consulta_1['id_sysofic01'];
	  $sysofic01_codigo_sisa=$row_consulta_1['sysofic01_codigo_sisa'];
	}else{
	    return 0; //no se encontró el código del efector
	}
	
	$qr_consulta_2="SELECT sysvacu01_codigo,sysvacu02_codigo, 
						sysvacu03_orden, sysvacu04_codigo FROM sys_vacu_03_rel_vacuna 
						inner join sys_vacu_01_cab_condicion_aplicacion on id_sysvacu01=rela_sysvacu01
						inner join sys_vacu_02_cab_esquema on id_sysvacu02=rela_sysvacu02
						inner join sys_vacu_05_cab_dosis on id_sysvacu05=rela_sysvacu05 
						inner join sys_vacu_04_cab_vacuna on id_sysvacu04=rela_sysvacu04
						where id_sysvacu03 = $id_sysvacu03";
	$result_consulta_2 = mysqli_query($conexion,$qr_consulta_2);
	$num_rows_consulta_2 = mysqli_num_rows($result_consulta_2);	
	if ($num_rows_consulta_2>0){
			$row_consulta_2 = mysqli_fetch_assoc($result_consulta_2);
			$sysvacu01_codigo=$row_consulta_2['sysvacu01_codigo'];
			$sysvacu02_codigo=$row_consulta_2['sysvacu02_codigo'];
			$sysvacu04_codigo=$row_consulta_2['sysvacu04_codigo'];
			$sysvacu03_orden=$row_consulta_2['sysvacu03_orden'];
	}else{
	  return 0; //no se encontró los datos de configuración 
	}
	
	$qr_consulta_3="SELECT sysdesa18_lote FROM sys_desa_18_cab_lotes where id_sysdesa18 = $id_sysdesa18";
	$result_consulta_3 = mysqli_query($conexion,$qr_consulta_3);
	$num_rows_consulta_3 = mysqli_num_rows($result_consulta_3);	
	if ($num_rows_consulta_3>0){
	    $row_consulta_3 = mysqli_fetch_assoc($result_consulta_3);
	    $sysdesa18_lote=$row_consulta_3['sysdesa18_lote'];
    }else{
	   return 0; //no se encontró el lote
	}
	
	//voy a obtener el departamento
	$qr_codigo="select sysdesa14_codigo from sys_ofic_01_cab_establecimientos 
        inner join sys_desa_27_cab_localidades on id_sysdesa27=rela_sysdesa27 
		inner join sys_desa_14_cab_departamento on id_sysdesa14=rela_sysdesa14
		where id_sysofic01=$id_sysofic01";
		//$result_codigo = flex_query($qr_codigo,$link_msq);
		$result_codigo = mysqli_query($conexion,$qr_codigo);
	    $num_rows_consulta_codigo = mysqli_num_rows($result_codigo);	
		if($num_rows_consulta_codigo > 0)
		{
		    $row_codigo = mysqli_fetch_assoc($result_codigo);
			$sysdesa14_codigo=$row_codigo["sysdesa14_codigo"];
		}
	
	    //SI LLEGA A ESTA LINEA EL PROCESO SIGUIENTE ES REALIZAR LA PETICIÓN PARA NOTIFICAR A SISA
		//$fechaAplicacion=date('d-m-Y');
		$fechaAplicacion=$fecha_enviar_sisa;
		
		$postData = array(
			'ciudadano' => array('tipoDocumento' => 1,
								 'numeroDocumento' => $sysdesa10_dni,
								 'sexo' =>  $sysdesa10_sexo, 
								 'apellido' => $sysdesa10_apellido,
								 'nombre' => $sysdesa10_nombre,
								 'fechaNacimiento' =>$sysdesa10_fecha_nacimiento_cadena_dni,
								 'pais' => 200,
								 'provincia' => 9,
								 'departamento' => $sysdesa14_codigo,
								),
			'aplicacionVacuna' => array('establecimiento' => $sysofic01_codigo_sisa, 
										'fechaAplicacion' => $fechaAplicacion, 
										'lote' => $sysdesa18_lote,
										'esquema' => $sysvacu02_codigo, 
										'condicionAplicacion' => $sysvacu01_codigo, 
										'vacuna' => $sysvacu04_codigo,
										'ordenDosis' => $sysvacu03_orden		
									   )
		);
		
		//SE UTILIZA PARA INSERTAR EN LA BASE 
		$peticion="array(
			'ciudadano' => array('tipoDocumento' => 1,
								 'numeroDocumento' => $sysdesa10_dni,
								 'sexo' =>  $sysdesa10_sexo, 
								 'apellido' => $sysdesa10_apellido,
								 'nombre' => $sysdesa10_nombre,
								 'fechaNacimiento' =>$sysdesa10_fecha_nacimiento_cadena_dni,
								 'pais' => 200,
								 'provincia' => 9,
								 'departamento' => $sysdesa14_codigo,
								),
			'aplicacionVacuna' => array('establecimiento' => $sysofic01_codigo_sisa, 
										'fechaAplicacion' => $fechaAplicacion, 
										'lote' => $sysdesa18_lote,
										'esquema' => $sysvacu02_codigo, 
										'condicionAplicacion' => $sysvacu01_codigo, 
										'vacuna' => $sysvacu04_codigo,
										'ordenDosis' => $sysvacu03_orden		
									   ))";
									   
	    $headerss = array('Accept' => 'application/json', 
                  'Content-Type' => 'application/json',
                  'APP_ID' => 'bc3de063',
				  'APP_KEY' => '61342dbd6a87cdd3410ab91f4e0db718');
	   $url_post="https://apisalud.msal.gob.ar/nomivacAplicacion/v1/aplicaciones/alta/";
       $request_post = Requests::post($url_post, $headerss,json_encode($postData)); 
       $json_request_post=	$request_post->body;
		
		// Decode the response
		$responseData = json_decode($json_request_post, TRUE);
		$resultado= ($responseData['resultado']);
		$description= ($responseData['description']);
		
		$timestamp= ($responseData['timestamp']);
		$idSniAplicacion= ($responseData['idSniAplicacion']);
		$findme   = 'Ya existe';
		$pos = strpos($description, $findme);
		if($resultado == "OK"){	
			$sql_update="UPDATE sys_desa_10_cab_nomivac SET sysdesa10_estado=1 WHERE id_sysdesa10=$id_sysdesa10"; 
			$sysinfo01_estado=1;
			
			$response_2 = " $resultado - timestamp: $timestamp - idSniAplicacion: $idSniAplicacion"; 
		    $res = str_replace("'"," ",$response_2);
			
		}else if ($resultado  == 'ERROR_DATOS' and $pos !== false) {
			$sql_update="UPDATE sys_desa_10_cab_nomivac SET sysdesa10_estado=1 WHERE id_sysdesa10=$id_sysdesa10"; 
			$sysinfo01_estado=1;
			
			$response_2 = " $resultado - description: $description"; 
		    $res = str_replace("'"," ",$response_2);
		
		}else{
			$sql_update="UPDATE sys_desa_10_cab_nomivac SET sysdesa10_estado=2 WHERE id_sysdesa10=$id_sysdesa10"; 
			$sysinfo01_estado=2;
			
			$response_2 = " $resultado - description: $description"; 
		    $res = str_replace("'"," ",$response_2);
		}
		//$result=flex_query($sql,$link_msq);
		$result_update =mysqli_query($conexion,$sql_update);
		if (!$result_update>0) // si se deseas arrojar un error >>>
		{
			return 0; //no pudo actualizarse el estado del informe al registro de vacuna		
		}
		
		$sysinfo01_fecha=date('Y-m-d');
		$sysinfo01_hora=date('H:i:s');
		
		//$response_2 = " $resultado - description: $description"; 
		//$res = str_replace("'"," ",$response_2);
		
		//$res = str_replace("'"," ",$json_request_post);
		
		$sysinfo01_peticion = str_replace("'"," ",$peticion);
		$sysinfo01_peticion=Quitar_Espacios($sysinfo01_peticion);
		$sql_informe="INSERT INTO sys_info_01_cab_informes
						(
						sysinfo01_respuesta,
						rela_sysdesa10,
						sysinfo01_fecha,
						sysinfo01_hora,
						sysinfo01_estado,
						sysinfo01_peticion
						) 
						VALUES 
						(
						'$res',
						$id_sysdesa10,
						'$sysinfo01_fecha',
						'$sysinfo01_hora',
						$sysinfo01_estado,
						'$sysinfo01_peticion'
						)";
						
		$result_informe =mysqli_query($conexion,$sql_informe);
		if (!$result_informe>0) 
		{
			return 0; //HUBO UN ERROR AL INTENTAR INSERTAR LA NOTIFICACION EN LA BASE
		}
		
		if($resultado == "OK"){	
		    return 1; //SE GUARDÓ Y SE NOTIFICÓ CORRECTAMENTE
		}else if($resultado  == 'ERROR_DATOS' and $pos !== false){
		    return 1; //SE GUARDÓ Y SE NOTIFICÓ CORRECTAMENTE
		}else{
		    return 0; //SE GUARDÓ CORRECTAMENTE PERO NO SE NOTIFICÓ CON RESPUESTA OK
		}
		//===========================================================0
}

function auditoria($conexion,$id_sysdesa10, $query_sysdesa10){
	
	$sysinfo03_query = str_replace("'","",$query_sysdesa10);
	$query=Quitar_Espacios($sysinfo03_query);
	$sysinfo03_fecha=date('Y-m-d');
	$sysinfo03_hora=date('H:i:s');
	
	//PRODUCCIÓN
	/*$qr_auditoria="INSERT INTO sys_info_03_cab_auditoria
					(
					sysinfo03_fecha,
					sysinfo03_hora,
					rela_sysdesa10,
					sysinfo03_query
					) 
					VALUES 
					(
					'$sysinfo03_fecha',
					'$sysinfo03_hora',
					$id_sysdesa10,
					'$query')";*/
					
	//DESARROLLO				
	$qr_auditoria="INSERT INTO sys_info_09_cab_auditoria
					(
					sysinfo03_fecha,
					sysinfo03_hora,
					rela_sysdesa10,
					sysinfo03_query
					) 
					VALUES 
					(
					'$sysinfo03_fecha',
					'$sysinfo03_hora',
					$id_sysdesa10,
					'$query')";
	$result_auditoria =mysqli_query($conexion,$qr_auditoria);
	if (!$result_auditoria>0) 
	{
		return $qr_auditoria;
	}
	else
	{
		//$id = $resultI -> insert_id;
		//$id = $conexion -> insert_id;
		//$id = mysqli_insert_id($conexion);
		return 1;
	}
}

//FUNCION UTILIZADA PARA OBTENER LOS DATOS PERSONALES DE LA PERSONA
function obtener_datos_personales($sysdesa10_dni, $sysdesa10_sexo ){
      //=========================================================================================
		   //LOGUEO PARA OBTENER EL TOKEN
		   $postData = array(
						   'nombre' => 'FAQAEgIaHQ0fCl4JBh4RBh1PFQoCDBwAEQ==',
							'clave' => 'URU9A10MRRhBPxEzNypIWEs=',
							'codDominio' => 'DOMINIOSINAUTORIZACIONDEALTA',
					);
			
			// Setup cURL
			$ch = curl_init('https://federador.msal.gob.ar/masterfile-federacion-service/api/usuarios/aplicacion/login');

			curl_setopt_array($ch, array(
				CURLOPT_POST => TRUE,
				CURLOPT_RETURNTRANSFER => TRUE,
				CURLOPT_HTTPHEADER => array(
					'Content-Type: application/json'
				),
				CURLOPT_POSTFIELDS => json_encode($postData)
			));

			// Send the request
			$response = curl_exec($ch);
			// Check for errors
			if($response === FALSE){
				print_r($response);
				die(curl_error($ch));
			}

			// Decode the response
			$responseData = json_decode($response, TRUE);
			$token= ($responseData['token']);
           //==========================================================================================
		   //UNA VEZ OBTENIDO EL TOKEN HAGO LA PETICIÓN
		   $headers = array('Accept' => 'application/json',
                 'token' => $token,
                 'codDominio' => 'DOMINIOSINAUTORIZACIONDEALTA');
			//$options = array('auth' => array('user', 'pass'));
			$url_peticion = 'https://federador.msal.gob.ar/masterfile-federacion-service/api/personas/renaper?nroDocumento='.$sysdesa10_dni.'&idSexo='.$sysdesa10_sexo;
			$request_1 = Requests::get($url_peticion, $headers);
			$json_request=	$request_1->body;
			$responseData_2 = json_decode($json_request, TRUE);
			return $responseData_2;		
}

function Quitar_Espacios($Frase)
{
	return preg_replace("/\s+/", " ", trim($Frase));
}
?>