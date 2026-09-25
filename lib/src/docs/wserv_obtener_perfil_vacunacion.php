<?php
//include "../../conexion/link_mysql.php";
include "../../../../lib/link_msq.php";
include "../../../../lib/functions.php";

$perfiles_vacunacion = array();

$rela_flxcore03 = $_GET['rela_flxcore03'];

if($rela_flxcore03!="" ){	   
        //=========================================================================================================
		$qr_edu="SELECT sysvacu12_descripcion, id_sysvacu12  FROM sys_vacu_14_det_perfil_registrador
				 left outer join sys_vacu_12_cab_perfil on id_sysvacu12=rela_sysvacu12
				 where rela_flxcore03 = $rela_flxcore03 and sysvacu14_activo = 1
				 order by sysvacu12_descripcion ASC";
		
		//echo "qr_edu $qr_edu";
			$result_edu = flex_query($qr_edu,$link_msq);
			$num_rows = flex_num_rows($result_edu);
			if ($num_rows>0)
			{
				while ($row = flex_fetch_assoc($result_edu)){
					 $perfiles_vacunacion[] = array(
						'id_sysvacu12' => $row["id_sysvacu12"], //ID PERFIL DE VACUNACIÓN
						'sysvacu12_descripcion' => utf8_encode($row['sysvacu12_descripcion']) ,//nombre DEL PERFIL DE VACUNACIÓN,
						'codigo_mensaje' => '',
						'mensaje' =>'',
					);
				}	
		   }else{
		       $mensaje = "EL registrador no posee perfil asignado.";
				$perfiles_vacunacion[] = array(
					'id_sysvacu12' => '', //ID CONFIG VACUNA
					'sysvacu12_descripcion' => '',//nombre VACUNA
					'codigo_mensaje' => '0',
					'mensaje' =>utf8_decode($mensaje),
				);
		   }

}else{
			 
		      $mensaje = "No pueden haber campos vacíos. Campos Vacios: ID DEL REGISTRADOR";
				$perfiles_vacunacion[] = array(
					'id_sysvacu12' => '', //ID CONFIG VACUNA
					'sysvacu12_descripcion' => '',//nombre VACUNA
					'codigo_mensaje' => '0',
					'mensaje' =>utf8_decode($mensaje),
				);
}

echo json_encode(array('perfiles_vacunacion' => $perfiles_vacunacion));
?>