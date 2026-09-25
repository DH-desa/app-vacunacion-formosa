<?php
include "../../../../lib/functions.php";
include "../../conexion/link_mysql.php";

$flxcore03_dni = $_GET['flxcore03_dni'];
//$flxcore03_dni ='36355149';

$usuario = array();

 //mysql_set_charset('utf8',$conexion);
 mysqli_set_charset($conexion, "utf8mb4");
 //$conexion -> set_charset("utf8");
 
$qr_usuario="SELECT id_flxcore03,flxcore03_dni, flxcore03_nombre FROM flx_core_03_arb_usuarios  WHERE flxcore03_dni='$flxcore03_dni'
and flxcore03_estado=1";
$result = mysqli_query($conexion, $qr_usuario);
$num_rows=mysqli_num_rows($result);
if ($num_rows>0)
{    

	 $row = mysqli_fetch_assoc($result);
	 $id_flxcore03=$row["id_flxcore03"];

	 
	$qr_efector="SELECT rela_sysofic01,sysofic01_descripcion FROM sys_vacu_07_det_registrador_efector 
	inner join sys_ofic_01_cab_establecimientos on id_sysofic01=rela_sysofic01
	WHERE rela_flxcore03=$id_flxcore03 and sysvacu07_activo=1
	ORDER BY sysvacu07_fecha_alta DESC, sysvacu07_principal DESC";
	$result_efector = mysqli_query($conexion, $qr_efector);
	$num_rows_efector=mysqli_num_rows($result_efector);
	if ($num_rows_efector>0)
	{    
		
		 while ( $row_efector = mysqli_fetch_assoc($result_efector)){
		      $rela_sysofic01=$row_efector["rela_sysofic01"];
		      $sysofic01_descripcion=$row_efector["sysofic01_descripcion"];
			  
			  $usuario[] = array(
					'id_flxcore03' => $row["id_flxcore03"],
					'flxcore03_dni' => $row['flxcore03_dni'],
					'flxcore03_nombre' => $row['flxcore03_nombre'],
					'rela_sysofic01' => $rela_sysofic01,
					'sysofic01_descripcion' => $sysofic01_descripcion,

				);
	
		 } 
		
	}	 


}else{
   $usuario[] = array(
        'id_flxcore03' => "",
        'flxcore03_dni' => "",
        'flxcore03_nombre' => "",
		'rela_sysofic01' => "",
		'sysofic01_descripcion' => "",
    );
	
}	

//echo json_encode(array('usuario' => $usuario));
echo  json_encode(array('usuario' => $usuario), JSON_UNESCAPED_UNICODE);

?>