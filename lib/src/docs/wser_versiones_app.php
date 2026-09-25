<?php

include "../../conexion/link_mysql.php";
include "../../../../lib/link_msq.php";
include "../../../../lib/functions.php";

//$sysdesa06_nro_documento = $_GET['sysdesa06_nro_documento'];
//$sysdesa06_cuil = $_GET['sysdesa06_cuil'];
 $sysappl01_nombre = $_GET['sysappl01_nombre'];
 $sysappl01_version  = $_GET['sysappl01_version'];
// echo " sysappl01_nombre $sysappl01_nombre || sysappl01_nombre $sysappl01_nombre";
$versiones = array();
mysqli_set_charset($conexion, "utf8mb4");

//PRODUCCIÓN
$qr_versiones="SELECT id_sysappl01,sysappl01_nombre, sysappl01_version, sysappl01_fecha_actualizacion FROM sys_appl_01_cab_versiones
WHERE sysappl01_nombre = '$sysappl01_nombre' and sysappl01_version = '$sysappl01_version' and  sysappl01_estado=1"; 

//DESARROLLO
/*$qr_versiones="SELECT id_sysappl01,sysappl01_nombre, sysappl01_version, sysappl01_fecha_actualizacion FROM sys_appl_01_cab_versiones
WHERE id_sysappl01 = 5";*/

    $result = mysqli_query($conexion, $qr_versiones);
	//$result = flex_query($qr_versiones,$link_msq);
	$num_rows=mysqli_num_rows($result);
	//$num_rows = flex_num_rows($result);
if ($num_rows>0)
{
	 $row = mysqli_fetch_assoc($result);
	 //$row = flex_fetch_assoc($result);
	 $versiones[] = array(
        'id_sysappl01' => $row["id_sysappl01"],
        'sysappl01_nombre' => $row['sysappl01_nombre'],
		'sysappl01_version' => $row['sysappl01_version'],
        'sysappl01_fecha_actualizacion' => viewDate($row["sysappl01_fecha_actualizacion"]),
		'codigo_mensaje' => '',
	    'mensaje' =>'',
    );

}else{
$mensaje = "No se encontraron coincidencias con la APP ($sysappl01_nombre) y versión ($sysappl01_version) enviados. ";
   $versiones[] = array(
       'id_sysappl01' => "",
        'sysappl01_nombre' => "",
		'sysappl01_version' => "",
        'sysappl01_fecha_actualizacion' => "" ,
		'codigo_mensaje' => '0',
		'mensaje' => utf8_decode($mensaje),
    );
	
}	

//echo json_encode(array('versiones' => $versiones), JSON_UNESCAPED_UNICODE);
echo json_encode(array('versiones' => $versiones));

?>