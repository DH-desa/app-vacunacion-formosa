<?php

//include "../../conexion/link_mysql.php";
include "../../../../lib/link_msq.php";
include "../../../../lib/functions.php";

$vacunas_configuradas = array();

$id_sysvacu12 = $_GET['id_sysvacu12'];
$sysdesa10_sexo = $_GET['sysdesa10_sexo'];
$DNI = $_GET['sysdesa10_dni'];
$sysdesa10_dni = str_replace("M","",$DNI);
$sysdesa10_dni_consultar = str_replace("F","",$sysdesa10_dni);

if($sysdesa10_sexo!="" and $DNI !="" and $id_sysvacu12 !=""){
        
		//PRIMERO VOY A VERIFICAR SI EL BENEFICIARIO TIENE VACUNAS APLICADAS #########################################################
		$qr_validar_vacunas="SELECT id_sysvacu04, sysvacu05_orden, sysvacu03_tiempo_interdosis,
		                     sysdesa10_fecha_aplicacion, rela_sysvacu11, sysvacu05_orden_numerico
		                     FROM sys_desa_10_cab_nomivac
							 left outer join sys_vacu_03_rel_vacuna on id_sysvacu03=rela_sysvacu03
							 left outer join sys_vacu_05_cab_dosis on id_sysvacu05=rela_sysvacu05
							 inner join sys_vacu_04_cab_vacuna on id_sysvacu04=rela_sysvacu04
							 where sysdesa10_dni = '$sysdesa10_dni' and sysdesa10_sexo = '$sysdesa10_sexo'
							 order by id_sysvacu04 ASC";
							 
			$result_validar_vacunas = flex_query($qr_validar_vacunas,$link_msq);
			$num_rows_validar_vacunas = flex_num_rows($result_validar_vacunas);
			$contador_dosis = 0;
			$id_sysvacu04_anterior = 0;
			//$tabla44_fecha_descarte=date("Y-m-d",strtotime($tabla44_fecha_alta."+ 14 days"));
			if ($num_rows_validar_vacunas>0)
			{
				while ($row_validar_vacunas = flex_fetch_assoc($result_validar_vacunas)){
				        $sysvacu05_orden = $row_validar_vacunas["sysvacu05_orden"];
						$id_vacuna = $row_validar_vacunas["id_sysvacu04"];
						$rela_sysvacu11 = $row_validar_vacunas["rela_sysvacu11"];
						$orden_numerico = $row_validar_vacunas["sysvacu05_orden_numerico"];
						$sysvacu03_tiempo_interdosis = $row_validar_vacunas["sysvacu03_tiempo_interdosis"];
						$sysdesa10_fecha_aplicacion=$row_validar_vacunas["sysdesa10_fecha_aplicacion"];
						$sysdesa10_fecha_aplicacion=date("d-m-Y",strtotime($sysdesa10_fecha_aplicacion));
						 
						//DE ACUERDO A LA FECHA DE APLICACIÓN Y 
						//LA CANTIDAD DE DÍAS ENTRE DOSIS SACO LA FECHA MÍNIMA PAR ALA PRÓXIMA DOSIS						
						if($sysvacu03_tiempo_interdosis !=0){
						    $fecha_limite=date("Y-m-d",strtotime($sysdesa10_fecha_aplicacion."+ ". $sysvacu03_tiempo_interdosis ." days"));
						}
						
						if($rela_sysvacu11 == 1 and $orden_numerico == 1){
						   //$id_vacuna = $row_validar_vacunas["id_sysvacu04"];
						   $p1er_vacuna_aplicada = $row_validar_vacunas["id_sysvacu04"];
						   //CUENTO LA CANTIDAD DE DÓSIS CONFIGURADAS SOLO DE LA PRIMER VACUNA APLICADA
						   $cantidad_dosis = obtener_cantidad_dosis_vacuna($link_msq, $p1er_vacuna_aplicada);
						}
						
						if($rela_sysvacu11 == 1 and $orden_numerico == 2){
						   $s2da_vacuna_aplicada = $row_validar_vacunas["id_sysvacu04"];
						}
							
						//$cantidad_dosis = obtener_cantidad_dosis_vacuna($link_msq, $id_vacuna);
							
						//NO VA A TENER EN CUENTA LAS DOSIS QUE SEAN PARA LA ANTIGRIPAL
						/*if($id_vacuna != 8 and  $id_vacuna != 9 and  $id_vacuna != 10 and  $id_vacuna != 11 
					          and  $id_vacuna != 12){
							    $contador_dosis = $contador_dosis + 1;
						} */ 
						
						//if($rela_sysvacu11 != 2){ //TIPO DE VACUNA: ANTIGRIPAL
						if($rela_sysvacu11 == 1){ //TIPO DE VACUNA: COVID 19
							    $contador_dosis = $contador_dosis + 1;
						}
						
				}	
		   }
		   
		      // BUSCO LAS VACUNAS POR EL PERIL########################################################################
		      //$where_vacunas = devolver_vacunas_por_perfil($link_msq, $id_sysvacu12); //comentado 21032022
			  $where_vacunas = devolver_vacunas_por_perfil($link_msq,$id_sysvacu12,$p1er_vacuna_aplicada,$s2da_vacuna_aplicada);
				if($where_vacunas != ""){
					$where_vacunas_perfil = " and " .  $where_vacunas;
				}
		      // ######################################################################################################
			  
		        
		      /*  if($contador_dosis == 2){ //TIENE LAS DOS DÓSIS DEL MISMO TIPO DE VACUNA
				   $in_not = "where id_sysvacu04  NOT IN (". $id_vacuna . ")";
				//}else if($contador_dosis == 1){ //TIENE UNA SOLA DÓSIS DEL MISMO TIPO DE VACUNA
				}else if($contador_dosis == 1 and $rela_sysvacu11 == 1){ //TIENE UNA SOLA DÓSIS DEL MISMO TIPO DE VACUNA
					 //COMBINACIONES ###################################################################################
					 $in_not = devolver_combinaciones($id_vacuna);
				}*/else{
				   $in_not = "";
				   $where_vacunas_perfil = "";
				} 
        //=========================================================================================================
		//DEVUELVO LAS VACUNAS DE ACUERDO A LAS DOSIS QUE TIENE APLICADO O NO EL BENEFICIARIO
		$qr_edu="SELECT id_sysvacu03,id_sysvacu04, sysvacu04_nombre, sysvacu05_nombre FROM sys_vacu_03_rel_vacuna 
		left outer join sys_vacu_05_cab_dosis on id_sysvacu05=rela_sysvacu05
		inner join sys_vacu_04_cab_vacuna on id_sysvacu04=rela_sysvacu04
		$in_not $where_vacunas_perfil
		group by id_sysvacu04"; 
		
			$result_edu = flex_query($qr_edu,$link_msq);
			$num_rows = flex_num_rows($result_edu);
			if ($num_rows>0)
			{
				while ($row = flex_fetch_assoc($result_edu)){
					 $vacunas_configuradas[] = array(
						'id_sysvacu04' => $row["id_sysvacu04"], //ID VACUNA
						'sysvacu04_nombre' => utf8_encode($row['sysvacu04_nombre']) ,//nombre VACUNA,
						'codigo_mensaje' => '',
						'mensaje' =>'',
					);
				}	
		   }else{
		   
		        $mensaje = "No se encontraron vacunas";
				$vacunas_configuradas[] = array(
					'id_sysvacu04' => '', //ID CONFIG VACUNA
					'sysvacu04_nombre' => '',//nombre VACUNA
					'codigo_mensaje' => '0',
					'mensaje' =>utf8_decode($mensaje),
				);
		      
		   }

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
			 if($id_sysvacu12==""){
				   $campo_vacio .= "ID DEL PERFIL DEL REGISTRADOR";
				   $campo_vacio .= ",";
			 }
			 
			 
			  $campos =substr($campo_vacio, 0, -1);
			 
		      $mensaje = "No pueden haber campos vacíos. Campos Vacios: $campos";
				$vacunas_configuradas[] = array(
					'id_sysvacu04' => '', //ID CONFIG VACUNA
					'sysvacu04_nombre' => '',//nombre VACUNA
					'codigo_mensaje' => '0',
					'mensaje' =>utf8_decode($mensaje),
				);
}


function devolver_vacunas_por_perfil($link_msq, $id_perfil_vacunacion,$p1er_vacuna_aplicada,$s2da_vacuna_aplicada){

	$qr_vacunas_perfil="SELECT rela_sysvacu04 FROM sys_vacu_13_rel_perfil_vacuna
		   inner join sys_vacu_04_cab_vacuna on id_sysvacu04=rela_sysvacu04
		   where rela_sysvacu12 = $id_perfil_vacunacion and sysvacu13_activo = 1
		   order by sysvacu04_nombre ASC";
	
						
	$in = "";		
	$result_vacunas_perfil = flex_query($qr_vacunas_perfil,$link_msq);
	$num_rows_vacunas_perfil = flex_num_rows($result_vacunas_perfil);
	if ($num_rows_vacunas_perfil>0)
	{
		while ($row_vacunas_perfil = flex_fetch_assoc($result_vacunas_perfil)){
			$in .= $row_vacunas_perfil["rela_sysvacu04"] . ",";
		}
		//echo $in;
		
		if($id_sysvacu12 == 1){
			if($p1er_vacuna_aplicada > 0 and $s2da_vacuna_aplicada == 0){ //PRIMER DÓSIS
				$in .= devolver_combinaciones_segundas_dosis($p1er_vacuna_aplicada);
			}

			if($p1er_vacuna_aplicada > 0 and $s2da_vacuna_aplicada > 0){ //SEGUNDA DÓSIS
				$in .= devolver_combinaciones_terceras_dosis($p1er_vacuna_aplicada, $s2da_vacuna_aplicada);
			}
		}
	
		$where_vacunas =" id_sysvacu04 IN (" . substr($in, 0, -1) . ")";

		if($p1er_vacuna_aplicada > 0 and $s2da_vacuna_aplicada > 0 and $p1er_vacuna_aplicada == 15){ ////15 = Cansino Ad5 nCoV	 
			//TODAS MENOS 4 = Sinopharm Vacuna SARSCOV 2 Inactivada 
			$where_vacunas .= " AND id_sysvacu04  NOT IN  (4)"; 
		}
		
	
	}else{
       $where_vacunas = "";
	}
	
	return $where_vacunas;
}

function devolver_combinaciones_segundas_dosis($p1er_vacuna_aplicada){

	 if($p1er_vacuna_aplicada == 3 ){ //3 = COVISHIELD ChAdOx1nCoV COVID 19
					 
		 //$in = " AND id_sysvacu04  = 5"; //5 = AstraZeneca ChAdOx1 S recombinante
		 $in = "5,"; //5 = AstraZeneca ChAdOx1 S recombinante

	 }else if($p1er_vacuna_aplicada == 1 ){ //1 = SPUTNIK V
         //5 = AstraZeneca ChAdOx1 S recombinante, 13= Moderna ARNm
		 //$in = " AND id_sysvacu04  IN ($p1er_vacuna_aplicada,5,13)"; 
		 $in = "$p1er_vacuna_aplicada,5,13,"; 

	 }else if($p1er_vacuna_aplicada == 5 ){ //5 = AstraZeneca ChAdOx1 S recombinante

		 //$in = " AND id_sysvacu04  IN ($p1er_vacuna_aplicada,13,14)"; // 13= Moderna ARNm, 14 = Pfizer BioNTech Comirnaty
		 $in = "$p1er_vacuna_aplicada,13,14,";

	 } else if($p1er_vacuna_aplicada == 14 ){ //14 = Pfizer BioNTech Comirnaty

		 //$in = " AND id_sysvacu04  IN ($p1er_vacuna_aplicada,13)"; // 13= Moderna ARNm
		 $in = "$p1er_vacuna_aplicada,13,"; // 13= Moderna ARNm

	 }else if($p1er_vacuna_aplicada == 13 ){ //13 = Moderna ARNm

		 $in = " AND id_sysvacu04  IN ($p1er_vacuna_aplicada,14)"; // 14= Pfizer BioNTech Comirnaty 
		 $in = "$p1er_vacuna_aplicada,14,";

	 }else if($p1er_vacuna_aplicada == 14 ){ //14 = Pfizer BioNTech Comirnaty 

		 //$in = " AND id_sysvacu04  IN ($p1er_vacuna_aplicada,13)"; // 13= Moderna ARNm
		 $in = "$p1er_vacuna_aplicada,13,";

	 } else if($p1er_vacuna_aplicada == 8 or  $p1er_vacuna_aplicada == 9 or  $p1er_vacuna_aplicada == 10 or  $p1er_vacuna_aplicada == 11 
			   or  $p1er_vacuna_aplicada == 12){ //ANTIGRIPALES

		// $in = " AND id_sysvacu04  NOT IN (8,9,10,11,12)"; //QUE NO APAREZCAN LAS ANTIGRIPALES */
		// $in = " AND id_sysvacu04  NOT IN (8,9,10,11,12)";
	 }else{
		// $in = " AND id_sysvacu04  = $p1er_vacuna_aplicada"; //QUE SOLO APAREZCA LA VACUNA QUE TIENE  APLICADA.
		$in = "$p1er_vacuna_aplicada,";
		 
	 }
	
	return $in;
}


function devolver_combinaciones_terceras_dosis($p1er_vacuna_aplicada, $s2da_vacuna_aplicada){

	if($p1er_vacuna_aplicada == 1 ){ //1 = SPUTNIK V				 
	   // 5 = AstraZeneca ChAdOx1 S recombinantem,  15 = Cansino Ad5 nCoV, 13 = Moderna ARNm, 
	   //14= Pfizer BioNTech Comirnaty , 
	   //$in = " AND id_sysvacu04  IN (".$p1er_vacuna_aplicada.",5, 15, 13, 14)"; 
	    $in = "$p1er_vacuna_aplicada,5, 15, 13, 14,"; 
	}
	
	if($p1er_vacuna_aplicada == 5 ){ //5 = AstraZeneca ChAdOx1 S recombinantem			 
	   //1 = SPUTNIK V, 13 = Moderna ARNm, 14 = Pfizer BioNTech Comirnaty, 15 = Cansino Ad5 nCoV, 
	   //$in = " AND id_sysvacu04  IN (".$p1er_vacuna_aplicada.",1,13,14, 15)"; 
	   $in = "$p1er_vacuna_aplicada,1,13,14, 15,";
	}
	
	if($p1er_vacuna_aplicada == 4 ){ //4 = Sinopharm Vacuna SARSCOV 2 Inactivada			 
	   //1 = SPUTNIK V,5 = AstraZeneca ChAdOx1 S recombinantem,
	   //13 = Moderna ARNm, 14 = Pfizer BioNTech Comirnaty, 15 = Cansino Ad5 nCoV
	  // $in = " AND id_sysvacu04  IN (".$p1er_vacuna_aplicada.",1,5,15,13,14)"; 
	   $in = " $p1er_vacuna_aplicada,1,5,15,13,14,"; 
	}
	
	if($p1er_vacuna_aplicada == 15 ){ //15 = Cansino Ad5 nCoV	 
	   //TODAS MENOS 4 = Sinopharm Vacuna SARSCOV 2 Inactivada 
	   //$in = " AND id_sysvacu04  NOT IN  (4)"; 
	} 
	
	if($p1er_vacuna_aplicada == 14 ){ //14 = Pfizer BioNTech Comirnaty		 
	   //13 = Moderna ARNm,   
	  //$in = " AND id_sysvacu04  IN (".$p1er_vacuna_aplicada.",13)";
	   $in = "$p1er_vacuna_aplicada,13,";
	}
	
	if($p1er_vacuna_aplicada == 13 ){ //13 =  Moderna ARNm,		 
	   //14 = Pfizer BioNTech Comirnaty  
	   //$in = " AND id_sysvacu04  IN (".$p1er_vacuna_aplicada.",14)"; 
	   $in = "$p1er_vacuna_aplicada,14,"; 
	}
   
    return $in;
}

function obtener_cantidad_dosis_vacuna($link_msq, $id_vacuna){
  
     $qr_edu="SELECT * FROM sys_vacu_03_rel_vacuna 
		where rela_sysvacu04 = $id_vacuna
        group by rela_sysvacu05";
		
		//echo "qr_edu $qr_edu";
	    
		$result_edu = flex_query($qr_edu,$link_msq);
			//$num_rows = mysqli_num_rows($result_edu);
			$num_rows = flex_num_rows($result_edu);
			if ($num_rows>0)
			{
			    while ($row = flex_fetch_assoc($result_edu)){
				$cantidad_dosis = $cantidad_dosis + 1;
				}
			}else{
			   $cantidad_dosis = 0;
			}
			
			return $cantidad_dosis;

}

echo json_encode(array('vacunas_configuradas' => $vacunas_configuradas));
?>