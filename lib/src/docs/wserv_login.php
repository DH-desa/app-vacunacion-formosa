<?php
include "../../../../lib/functions.php";
include "../../../consultar_datos_renaper/libreria/library/Requests.php";
//include "../../conexion/link_mysql.php";
include "../../../../lib/link_msq.php";

$flxcore03_dni = $_GET['flxcore03_dni'];

 $flxcore03_dni = str_replace(".","",$flxcore03_dni);
$usuario = array();
// mysqli_set_charset($conexion, "utf8mb4");
$flxcore03_dni=trim($flxcore03_dni);
if($flxcore03_dni !=""){

			$qr_usuario="SELECT id_flxcore03,flxcore03_dni, flxcore03_nombre FROM flx_core_03_arb_usuarios  WHERE flxcore03_dni='$flxcore03_dni'
		and flxcore03_estado=1";

			//$result = mysqli_query($conexion, $qr_usuario);
			$result = flex_query($qr_usuario,$link_msq);
			//$num_rows=mysqli_num_rows($result);
            $num_rows = flex_num_rows($result);
		if ($num_rows>0)
		{    
			 //$row = mysqli_fetch_assoc($result);
             $row = flex_fetch_assoc($result);
			 //$flxcore03_nombre = $row['flxcore03_nombre'];
			 //$flxcore03_nombre = $conexion->real_escape_string($flxcore03_nombre);
              $id_flxcore03=$row["id_flxcore03"];
             
             $qr_efector="SELECT rela_sysofic01,sysofic01_descripcion FROM sys_vacu_07_det_registrador_efector 
							inner join sys_ofic_01_cab_establecimientos on id_sysofic01=rela_sysofic01
							WHERE rela_flxcore03=$id_flxcore03 and sysvacu07_activo=1";
							//$result_efector = mysqli_query($conexion, $qr_efector);
							$result_efector = flex_query($qr_efector,$link_msq);
							//$num_rows_efector=mysqli_num_rows($result_efector);
							 $num_rows_efector = flex_num_rows($result_efector);
							if ($num_rows_efector>0)
							{    
								// $row_efector = mysqli_fetch_assoc($result_efector);
								 $row_efector = flex_fetch_assoc($result_efector);
								 $rela_sysofic01=$row_efector["rela_sysofic01"];
								 $sysofic01_descripcion=$row_efector["sysofic01_descripcion"];
							}
							
							
			 $usuario[] = array(
				'id_flxcore03' => $row["id_flxcore03"],
				'flxcore03_dni' => $row['flxcore03_dni'],
				'flxcore03_nombre' => utf8_encode($row['flxcore03_nombre']),
				'rela_sysofic01' => $rela_sysofic01,
		        'sysofic01_descripcion' => utf8_encode($sysofic01_descripcion),
				'codigo_mensaje' => '',
				'mensaje' =>'',
			);

		}else{
		   $usuario[] = array(
				'id_flxcore03' => "",
				'flxcore03_dni' => "",
				'flxcore03_nombre' => "",
				'rela_sysofic01' => "",
		        'sysofic01_descripcion' => "",
				'codigo_mensaje' => '0',
				'mensaje' =>'No hay registradores con el DNI ingresado',
			);

		}
}else{
     $mensaje = "DNI vacío. Debe ingresar este dato.";
     $usuario[] = array(
				'id_flxcore03' => "",
				'flxcore03_dni' => "",
				'flxcore03_nombre' => "",
				'rela_sysofic01' => "",
		        'sysofic01_descripcion' => "",
				'codigo_mensaje' => '0',
				'mensaje' =>utf8_encode($mensaje),
			);

}

echo  json_encode(array('usuario' => $usuario));

?>