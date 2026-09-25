<?php
include "../../../consultar_datos_renaper/libreria/library/Requests.php";
//include "../../../../lib/renaper/Requests.php";
include "../../conexion/link_mysql.php";
//include "../../../../lib/link_msq.php";
include "../../../../lib/functions.php";
include "../../../../lib/nusoap/lib/nusoap.php";

ini_set("memory_limit","-1");
set_time_limit(0);
header("Cache-Control: no-cache, must-revalidate"); // HTTP/1.1

Requests::register_autoloader();
$client = new nusoap_client('https://ws.formosa.gob.ar/modulos/ws/php/ws_personas.php?wsdl', true);

$sysdesa10_sexo = $_GET['sysdesa10_sexo'];
if($sysdesa10_sexo == "M"){
  $sysdesa10_sexo_consultar = 2;
}else if($sysdesa10_sexo == "F"){
  $sysdesa10_sexo_consultar = 1;
}else{
  $sysdesa10_sexo_consultar = 0;
}
$DNI = $_GET['sysdesa10_dni'];

$sysdesa10_dni = str_replace("M","",$DNI);
$sysdesa10_dni_consultar = str_replace("F","",$sysdesa10_dni);
$sysdesa10_cadena_dni = $_GET['sysdesa10_cadena_dni'];

//mysqli_set_charset($conexion, "utf8");

$configuraciones = array();
$dosis_cacuna = array();

/*if($DNI != "" and $sysdesa10_sexo != ""){
                    $sysdesa10_nro_tramite= "";
					$fechaNacimiento= "";
					//$sysdesa10_sexo= "";
					$sysdesa10_apellido= "";
					$sysdesa10_nombre= "";
					$sysdesa10_dni= "";
					$sysdesa10_cuil= "";

					$sysdesa10_fecha_nacimiento="";
					$sysdesa10_edad = "";
					$sysdesa10_fecha_nacimiento_2="";
					$mensaje = "El ingreso manual de los datos (DNI y SEXO) está en mantenimiento.";
					$mensaje = utf8_encode($mensaje);
					$codigo_mensaje = 0;
					
					$beneficiario[] = array(
					'sysdesa10_apellido' => "$sysdesa10_apellido", //ID CONFIG VACUNA
					'sysdesa10_nombre' => "$sysdesa10_nombre", //ID CONFIG VACUNA
					'sysdesa10_cuil' => $sysdesa10_cuil,//condicion
					'sysdesa10_dni' => $sysdesa10_dni,//esquema
					'sysdesa10_sexo' => $sysdesa10_sexo,//esquema
					'sysdesa10_nro_tramite' => "$sysdesa10_nro_tramite",
					'sysdesa10_fecha_nacimiento' => $sysdesa10_fecha_nacimiento_2,//laboratorio
					'sysdesa10_edad' =>"$sysdesa10_edad",//laboratorio
					'sysdesa10_cadena_dni' =>"$sysdesa10_cadena_dni",//cadena_dni
					'foto_beneficiario' =>"$foto_beneficiario",//foto
					'codigo_mensaje' => "$codigo_mensaje",
		            'mensaje' => "$mensaje",
				);
				
				echo json_encode(array('beneficiario' => $beneficiario)); exit;
} */

if($sysdesa10_cadena_dni != ""){
	
	$string_1= str_replace("[", "",$sysdesa10_cadena_dni);
	$string_2= str_replace("", "",$string_1);
	//$string_3= str_replace("UNIDAD", "",$string_2);
	//$string_4= str_replace("ARGENTINA", "",$string_3);
	$campos = explode(",", $string_2);
	$fecha_minima = "";
    $iteracion = 0;
	$encontre_apellido = 0;
	$encontre_nombre = 0;
	$encontre_sexo = 0;
	$encontre_dni = 0;
	foreach ($campos as $valor) {
        
		$iteracion = $iteracion + 1;
		$valor = trim($valor);
		$longitud_string = strlen($valor);
		
		//============================================================================================
		//APELLIDO
		if($encontre_apellido == 0 and $longitud_string > 2 and  is_string($valor)){
		     $valor_apellido = str_replace(array('0','1', '2', '3', '4', '5', '6', '7', '8', '9'),"",$valor);
			 $valor_apellido = trim($valor_apellido);
			 $longitud_valor = strlen($valor_apellido);
			 if($longitud_valor > 2){
			    $sysdesa10_apellido = $valor_apellido;
			     $encontre_apellido = 1;
			 }
		     
		}
		//======================================================================================
		//NOMBRE
		if($encontre_nombre == 0 and $longitud_string > 2 and  is_string($valor)){
			 
			 $valor_nombre = str_replace(array('0','1', '2', '3', '4', '5', '6', '7', '8', '9'),"",$valor);
			 $valor_nombre = trim($valor_nombre);
			 $longitud_valor = strlen($valor_nombre);
			 if($longitud_valor > 2 and $valor_nombre != $sysdesa10_apellido){
			    $sysdesa10_nombre = $valor_nombre;
			     $encontre_nombre = 1;
			 }
		}
		//======================================================================================
		
		$findme_sexo   = 'M';
		$findme_sexo_2   = 'F';
		$pos_sexo_masculino = strpos($valor, $findme_sexo);
		$pos_sexo_femenino = strpos($valor, $findme_sexo_2);
           //SEXO
				

						if ($pos_sexo_masculino !== false or $pos_sexo_femenino !== false) {
						   $valor_sexo = str_replace(array('0','1', '2', '3', '4', '5', '6', '7', '8', '9'),"",$valor);
						   $longitud_valor = strlen($valor_sexo);
						   if($longitud_valor == 1 and $encontre_sexo == 0){
						        $sysdesa10_sexo = $valor_sexo;
								$encontre_sexo = 1;
						   }
								
						}
		//======================================================================================
           //DNI
				if(($longitud_string >  7 and $longitud_string <=  9)){
				           $string_valor= str_replace("M", "",$valor);
	                       $string_valor_2= str_replace("F", "",$string_valor);
						   $longitud_valor = strlen($string_valor_2);
						   if( is_numeric($string_valor_2) and ($longitud_valor == 7 or $longitud_valor == 8)){
						        $sysdesa10_dni = $string_valor_2;
						        $encontre_dni = 1;
						   }
						        
						
				}
		//=======================================================================================
		$findme_fecha_nacimiento   = '/';
		$findme_fecha_nacimiento_2   = '-';
		$pos_fecha_nacimiento = strpos($valor, $findme_fecha_nacimiento);
		$pos_fecha_nacimiento_2 = strpos($valor, $findme_fecha_nacimiento_2);
		//======================================================================================
         //FECHA DE NACIMIENTO
		if ($pos_fecha_nacimiento !== false or $pos_fecha_nacimiento_2 !== false) {
			$fecha= str_replace("/", "-",$valor);
			$campos_fecha = explode("-", $fecha);

           
			if (is_numeric($campos_fecha[0]) and is_numeric($campos_fecha[1]) and is_numeric($campos_fecha[2])) {

				$fecha_minima = fecha_minima($fecha_minima, $fecha); 
				$sysdesa10_fecha_nacimiento_2=date("Y-m-d",strtotime($fecha_minima));
			}

		} 
		//=======================================================================================

	}
	
	if($sysdesa10_sexo == "M"){
		  $sysdesa10_sexo_consultar = 2;
		  $sysdesa10_sexo_consultar_opuesto = 1;
		  $sysdesa10_sexo_consultar_opuesto_string = "F";
		}else if($sysdesa10_sexo == "F"){
		  $sysdesa10_sexo_consultar = 1;
		  $sysdesa10_sexo_consultar_opuesto = 2;
		   $sysdesa10_sexo_consultar_opuesto_string = "M";
		}else{
		  $sysdesa10_sexo_consultar = 0;
		}
	
    /*$json_datos_personales = obtener_datos_personales($sysdesa10_dni, $sysdesa10_sexo_consultar);
    if($json_datos_personales !=NULL){
          $foto_beneficiario= ($json_datos_personales['foto']);
	}else{
	      $foto_beneficiario= "";
	} */
	
	 $foto_beneficiario= "";
	 
	/*if($json_datos_personales != NULL){ //ENCONTRÉ A LA PERSONA CON EL DNI Y SEXO ENCONTRADO EN LA CADENA DEL DNI
	                $foto_beneficiario= ($json_datos_personales['foto']);
		            $sysdesa10_nro_tramite= ($json_datos_personales['idtramiteprincipal']);
					$fechaNacimiento= ($json_datos_personales['fechaNacimiento']);
					$sysdesa10_sexo= ($json_datos_personales['sexo']);
					$sysdesa10_apellido= ($json_datos_personales['apellido']);
					$sysdesa10_nombre= ($json_datos_personales['nombres']);
					$sysdesa10_dni= ($json_datos_personales['numeroDocumento']);
					$sysdesa10_cuil= ($json_datos_personales['cuil']);
					
					$sysdesa10_fecha_nacimiento=date("d-m-Y",strtotime($fechaNacimiento));
					$sysdesa10_edad = busca_edad($sysdesa10_fecha_nacimiento);
					$sysdesa10_fecha_nacimiento_2=date("d-m-Y",strtotime($fechaNacimiento));
					$mensaje = "";
		 
	}else{ //SI ES QUE NO LO ENCUENTRO VOY A PROBAR CON EL SEXO OPUESTO
	
	     $json_datos_personales = obtener_datos_personales($sysdesa10_dni, $sysdesa10_sexo_consultar_opuesto);
		 if($json_datos_personales != NULL){ //encontré a la persona con el sexo opuesto
		            $foto_beneficiario= ($json_datos_personales['foto']);
		            $sysdesa10_nro_tramite= ($json_datos_personales['idtramiteprincipal']);
					$fechaNacimiento= ($json_datos_personales['fechaNacimiento']);
					$sysdesa10_sexo= ($json_datos_personales['sexo']);
					$sysdesa10_apellido= ($json_datos_personales['apellido']);
					$sysdesa10_nombre= ($json_datos_personales['nombres']);
					$sysdesa10_dni= ($json_datos_personales['numeroDocumento']);
					$sysdesa10_cuil= ($json_datos_personales['cuil']);
					
					$sysdesa10_fecha_nacimiento=date("d-m-Y",strtotime($fechaNacimiento));
					$sysdesa10_edad = busca_edad($sysdesa10_fecha_nacimiento);
					$sysdesa10_fecha_nacimiento_2=date("d-m-Y",strtotime($fechaNacimiento));
					$mensaje = "";
		 }else{ //NO ENCONTRÉ A LA PEROSNA CON EL SEXO OPUESTO
		            $foto_beneficiario= "";
		            $sysdesa10_nro_tramite= "";
					$fechaNacimiento= "";
					//$sysdesa10_sexo= "";
					$sysdesa10_apellido= "";
					$sysdesa10_nombre= "";
					//$sysdesa10_dni= "";
					$sysdesa10_cuil= "";

					$sysdesa10_fecha_nacimiento="";
					$sysdesa10_edad = "";
					$sysdesa10_fecha_nacimiento_2="";
					$mensaje = "No se encontraron coincidencias con el DNI ($sysdesa10_dni) y el sexo ($sysdesa10_sexo | 
					            $sysdesa10_sexo_consultar_opuesto_string) enviados en la cadena del DNI. ";
					$mensaje = utf8_encode($mensaje);
					$codigo_mensaje = 0;
		 }
	     
	}  */
	
	$sysdesa10_edad = busca_edad($fecha_minima); 
	
}else if($DNI != "" and $sysdesa10_sexo != ""){

             //CONSULTA A RENAPER ####################################################################################
            $json_datos_personales = obtener_datos_personales($sysdesa10_dni_consultar, $sysdesa10_sexo_consultar);
			if($json_datos_personales != NULL){    
			        //$responseData_2 = json_decode($json_datos_personales, TRUE); 
					
					if($json_datos_personales['httpStatus'] == "INTERNAL_SERVER_ERROR" ){
					
					    $sysdesa10_nro_tramite= "";
						$fechaNacimiento= "";
						//$sysdesa10_sexo= "";
						$sysdesa10_apellido= "";
						$sysdesa10_nombre= "";
						$sysdesa10_dni= "";
						$sysdesa10_cuil= "";

						$sysdesa10_fecha_nacimiento="";
						$sysdesa10_edad = "";
						$sysdesa10_fecha_nacimiento_2="";
						$mensaje = "Hubo un error interno al buscar el DNI ($DNI) y el sexo ($sysdesa10_sexo) enviados.";
						$mensaje = utf8_encode($mensaje);
						$codigo_mensaje = 0;
					
					}else{
					
					$sysdesa10_nro_tramite= ($json_datos_personales['idtramiteprincipal']);
					$fechaNacimiento= ($json_datos_personales['fechaNacimiento']);
					$sysdesa10_sexo= ($json_datos_personales['sexo']);
					$sysdesa10_apellido= ($json_datos_personales['apellido']);
					$sysdesa10_nombre= ($json_datos_personales['nombres']);
					$sysdesa10_dni= ($json_datos_personales['numeroDocumento']);
					$sysdesa10_cuil= ($json_datos_personales['cuil']);
					//$foto_beneficiario = ($json_datos_personales['foto']); //COMENTADO 21102021
					$foto_beneficiario = "";

					$sysdesa10_fecha_nacimiento=date("d-m-Y",strtotime($fechaNacimiento));
					$sysdesa10_edad = busca_edad($sysdesa10_fecha_nacimiento);
					$sysdesa10_fecha_nacimiento_2=date("d-m-Y",strtotime($fechaNacimiento));
					$mensaje = "";
					
					
					}
					
			}else{
			        $sysdesa10_nro_tramite= "";
					$fechaNacimiento= "";
					//$sysdesa10_sexo= "";
					$sysdesa10_apellido= "";
					$sysdesa10_nombre= "";
					$sysdesa10_dni= "";
					$sysdesa10_cuil= "";

					$sysdesa10_fecha_nacimiento="";
					$sysdesa10_edad = "";
					$sysdesa10_fecha_nacimiento_2="";
					$mensaje = "No se encontraron coincidencias con el DNI ($DNI) y sexo ($sysdesa10_sexo) enviados.";
					$mensaje = utf8_encode($mensaje);
					$codigo_mensaje = 0;
			} 
			
			  //CONSULTA A RECURSO LOCAL ####################################################################################
			  /*$json_datos_personales = obtener_datos_personales_sys_pers_03_sip_consexterna($client, $sysdesa10_dni_consultar, $sysdesa10_sexo);
			  			  
			  
			  if($json_datos_personales != ""){ 
			        $sipcomp05_apenom= ($json_datos_personales['SIPCOMP05_APENOM']);
					
					$sipcomp05_fnac= trim($json_datos_personales['SIPCOMP05_FNAC']);
					$sysdesa10_dni= trim($json_datos_personales['SIPCOMP05_NRODOC']); 
					$sysdesa10_cuil= trim($json_datos_personales['SIPCOMP05_CUIL']);
					$sysdesa10_fecha_nacimiento_2= str_replace ("/", "-", $sipcomp05_fnac); 
					$foto_beneficiario = "";
					$sysdesa10_edad = busca_edad($sysdesa10_fecha_nacimiento_2);

					$split_sipcomp05_apenom=explode(" ",$sipcomp05_apenom);
					$sysdesa10_apellido=utf8_encode($split_sipcomp05_apenom[0]);
					
					$split_sipcomp05_apenom=explode(" ",$sipcomp05_apenom);
					$sipcomp05_nombres=$split_sipcomp05_apenom[1]." ".$split_sipcomp05_apenom[2]." ".$split_sipcomp05_apenom[3];
					$socusua05_apellido= ($sipcomp05_apellidos);
					$sysdesa10_nombre= ($sipcomp05_nombres);
					
					$mensaje = "";
			  }else{
			     
					  $sysdesa10_nro_tramite= "";
					  $fechaNacimiento= "";
					  //$sysdesa10_sexo= "";
					  $sysdesa10_apellido= "";
					  $sysdesa10_nombre= "";
					  $sysdesa10_dni= "";
					  $sysdesa10_cuil= "";

					  $sysdesa10_fecha_nacimiento="";
					  $sysdesa10_edad = "";
					  $sysdesa10_fecha_nacimiento_2="";
					  $mensaje = "No se encontraron coincidencias con el DNI ($DNI) y sexo ($sysdesa10_sexo) enviados.";
					  $mensaje = utf8_encode($mensaje);
					  $codigo_mensaje = 0;
			  }*/ 
			  //#########################################################################################################
			               
}else{
                   $campo_vacio = "";
			 
			  if($DNI==""){
				   $campo_vacio .= "DNI";
				   $campo_vacio .= ",";
			 }

			 if($sysdesa10_sexo==""){
				   $campo_vacio .= "SEXO";
				   $campo_vacio .= ",";
			 }
			 
			  $campos =substr($campo_vacio, 0, -1);
		      $mensaje = "No pueden haber campos vacíos. Campos Vacios: $campos";
			  $codigo_mensaje = 0;
}
 
 $beneficiario[] = array(
					'sysdesa10_apellido' => "$sysdesa10_apellido", //ID CONFIG VACUNA
					'sysdesa10_nombre' => "$sysdesa10_nombre", //ID CONFIG VACUNA
					'sysdesa10_cuil' => $sysdesa10_cuil,//condicion
					'sysdesa10_dni' => $sysdesa10_dni,//esquema
					'sysdesa10_sexo' => $sysdesa10_sexo,//esquema
					'sysdesa10_nro_tramite' => "$sysdesa10_nro_tramite",
					'sysdesa10_fecha_nacimiento' => $sysdesa10_fecha_nacimiento_2,//laboratorio
					'sysdesa10_edad' =>"$sysdesa10_edad",//laboratorio
					'sysdesa10_cadena_dni' =>"$sysdesa10_cadena_dni",//cadena_dni
					'foto_beneficiario' =>"$foto_beneficiario",//foto
					'codigo_mensaje' => "$codigo_mensaje",
		            'mensaje' => "$mensaje",
				);
//===========================================================================================================

function obtener_datos_personales_sys_pers_03_sip_consexterna($client, $dni, $sexo ){
            $err = $client->getError();
			if ($err)
			{
				//echo "2<@>El número de DNI ingresado no se encuentra cargado en el sistema";	
				//exit;
				return "";
			}

			$param = array('syspers03_dni' => $dni,'syspers03_sexo' => $sexo); 
			$result = $client->call('sys_pers_03_sip_consexterna', array('input_personas' => $param));			
			// Check for a fault
			if ($client->fault) 
			{
				//echo "0<@>El servidor de personas no funciona (falla).";	
				//exit;
				return "";
			}
			else
	        {
				if ($result!=""){ return $result; }else{ return "";	}
	        }			
}

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
   //===========================================================================================
}

function fecha_minima($fecha_1, $fecha_2){   
		  
	if($fecha_1 == "" and $fecha_2 != ""){
		$fecha_1 = new DateTime('01-01-2025');
		$fecha_2 = new DateTime($fecha_2);
	}else{
		$fecha_1 = new DateTime($fecha_1);
		$fecha_2 = new DateTime($fecha_2);
	}

	$fecha_minima = min($fecha_1,$fecha_2)->format('d-m-Y');
	return $fecha_minima;
}

function busca_edad($fecha_nacimiento){
	
	$dia=date("d");
	$mes=date("m");
	$ano=date("Y");

	$dianaz=date("d",strtotime($fecha_nacimiento));
	$mesnaz=date("m",strtotime($fecha_nacimiento));
	$anonaz=date("Y",strtotime($fecha_nacimiento));

	//si el mes es el mismo pero el día inferior aun no ha cumplido años, le quitaremos un año al actual
	if (($mesnaz == $mes) && ($dianaz > $dia)) { $ano=($ano-1); }

	//si el mes es superior al actual tampoco habrá cumplido años, por eso le quitamos un año al actual
	if ($mesnaz > $mes) { $ano=($ano-1); }

	//ya no habría mas condiciones, ahora simplemente restamos los años y mostramos el resultado como su edad
	$edad=($ano-$anonaz);

	return $edad;
}
   
echo json_encode(array('beneficiario' => $beneficiario));
?>