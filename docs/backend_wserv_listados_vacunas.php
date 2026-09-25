<?php

include "../../conexion/link_mysql.php";
include "../../../../lib/functions.php";

ini_set("memory_limit","-1");
set_time_limit(0);
header("Cache-Control: no-cache, must-revalidate");
mysqli_set_charset($conexion, "utf8");

// Variables que recibo
$sysdesa10_sexo = $_GET['sysdesa10_sexo'];
$sysdesa10_dni = $_GET['sysdesa10_dni'];
$sysdesa10_edad = $_GET['sysdesa10_edad']; // En dias
$embarazada = $_GET['embarazada'];
$puerpera = $_GET['puerpera'];
$personal_salud = $_GET['personal_salud'];

// BUSCAMOS TODAS LAS VACUNAS QUE TIENE APLICADAS

$aplicaciones_beneficiario = array(); // Array de vacunas aplicadas
$vacunas_aplicadas_indexadas = array(); // Indice id_sysvacu04_id_sysvacu05 => true, para descartar pendientes ya aplicadas

if ($sysdesa10_dni != "" && $sysdesa10_sexo != "") {

    $qr_vacunas_aplicadas = "
        SELECT
            id_sysdesa10,
            id_sysvacu04,
            d.id_sysvacu05,
            sysvacu04_nombre,
            sysvacu05_nombre,
            sysdesa10_fecha_aplicacion
        FROM sys_desa_10_cab_nomivac n
        INNER JOIN sys_vacu_03_rel_vacuna rv
            ON rv.id_sysvacu03 = n.rela_sysvacu03
        LEFT JOIN sys_vacu_05_cab_dosis d
            ON d.id_sysvacu05 = rv.rela_sysvacu05
        INNER JOIN sys_vacu_04_cab_vacuna v
            ON v.id_sysvacu04 = rv.rela_sysvacu04
        WHERE
            n.sysdesa10_dni = '$sysdesa10_dni'
            AND n.sysdesa10_sexo = '$sysdesa10_sexo'
            AND sysvacu03_valida_rango = true

        ORDER BY
            n.sysdesa10_fecha_aplicacion,
            v.sysvacu04_nombre,
            d.sysvacu05_nombre";

    $result_vacunas_aplicadas = mysqli_query($conexion, $qr_vacunas_aplicadas);
    $num_rows_vacunas_aplicadas = mysqli_num_rows($result_vacunas_aplicadas);

    if ($num_rows_vacunas_aplicadas > 0) {

        while ($row_vacunas_aplicadas = mysqli_fetch_assoc($result_vacunas_aplicadas)) {

            $id_sysdesa10 = $row_vacunas_aplicadas["id_sysdesa10"];
            $id_sysvacu04 = $row_vacunas_aplicadas["id_sysvacu04"];
            $id_sysvacu05 = $row_vacunas_aplicadas["id_sysvacu05"];
            $sysvacu04_nombre = $row_vacunas_aplicadas["sysvacu04_nombre"];
            $sysvacu05_nombre = $row_vacunas_aplicadas["sysvacu05_nombre"];
            $sysdesa10_fecha_aplicacion = viewDate($row_vacunas_aplicadas["sysdesa10_fecha_aplicacion"]);

            $aplicaciones_beneficiario[] = array(

                'id_sysdesa10' => $id_sysdesa10,
                'id_sysvacu04' => $id_sysvacu04,
                'sysvacu04_nombre' => $sysvacu04_nombre,
                'sysvacu05_nombre' => $sysvacu05_nombre,
                'sysdesa10_fecha_aplicacion' => $sysdesa10_fecha_aplicacion,
                'codigo_mensaje' => "",
                'mensaje' => ""

            );

            $vacunas_aplicadas_indexadas[$id_sysvacu04 . '_' . $id_sysvacu05] = true;

        }

    } else {

        $mensaje_error = "No se encontraron registros sobre este beneficiario";

        $aplicaciones_beneficiario[] = array(

            'id_sysdesa10' => "",
            'id_sysvacu04' => "",
            'sysvacu04_nombre' => "",
            'sysvacu05_nombre' => "",
            'sysdesa10_fecha_aplicacion' => "",
            'codigo_mensaje' => "0",
            'mensaje' => $mensaje_error

        );

    }

} else {

    $aplicaciones_beneficiario[] = array(

        'id_sysdesa10' => "",
        'id_sysvacu04' => "",
        'sysvacu04_nombre' => "",
        'sysvacu05_nombre' => "",
        'sysdesa10_fecha_aplicacion' => "",
        'codigo_mensaje' => "0",
        'mensaje' => "Debe enviar DNI, sexo y campana."

    );

}

// VAMOS A TRABAJAR EN EL ARREGLO DE LAS VACUNAS QUE DEBERIA TENER APLICADAS

// Buscamos todos los rangos etarios que correspondan a la edad que recibimos

$rango_etario = array();
$vacunas_esperadas = array();

if ($sysdesa10_edad != "") {

    $qr_rangos_etarios = "SELECT
                            id_sysvacu30,
                            sysvacu30_nombre,
                            sysvacu30_edad_min_cobertura,
                            sysvacu30_edad_max_cobertura
                       FROM sys_vacu_30_rango_etario_vacunas
                       WHERE sysvacu30_edad_min_cobertura <= $sysdesa10_edad
                       ORDER BY sysvacu30_edad_min_cobertura ASC";

    $result_rangos_etarios = mysqli_query($conexion, $qr_rangos_etarios);

    if (!$result_rangos_etarios) {
        die("Error en consulta de rangos: " . mysqli_error($conexion));
    }

    while ($row_rango = mysqli_fetch_assoc($result_rangos_etarios)) {

        $rango_etario[] = $row_rango['id_sysvacu30'];
    }
}

// Buscamos todas las vacunas que correspondan a los rangos etarios que obtuvimos

if (count($rango_etario) > 0) {

    $rangos = implode(',', $rango_etario);

    $qr_vacunas_por_rango = "SELECT
                                rv.rela_sysvacu01,
                                c.sysvacu01_descripcion,
								rv.sysvacu03_limite_min_dosis,
								rv.sysvacu03_limite_max_dosis,
                                rv.rela_sysvacu02,
                                e.sysvacu02_descripcion,
                                rv.rela_sysvacu04,
                                v.sysvacu04_nombre,
                                rv.rela_sysvacu05,
                                d.sysvacu05_nombre
                              FROM sys_vacu_03_rel_vacuna rv
                              LEFT JOIN sys_vacu_01_cab_condicion_aplicacion c
                                  ON c.id_sysvacu01 = rv.rela_sysvacu01
                              LEFT JOIN sys_vacu_02_cab_esquema e
                                  ON e.id_sysvacu02 = rv.rela_sysvacu02
                              LEFT JOIN sys_vacu_04_cab_vacuna v
                                  ON v.id_sysvacu04 = rv.rela_sysvacu04
                              LEFT JOIN sys_vacu_05_cab_dosis d
                                  ON d.id_sysvacu05 = rv.rela_sysvacu05
                              WHERE rv.rela_sysvacu30 IN ($rangos)
                                AND rv.sysvacu03_valida_rango = 1";

    $result_vacunas_por_rango = mysqli_query($conexion, $qr_vacunas_por_rango);

    if (!$result_vacunas_por_rango) {
        die("Error en consulta de vacunas por rango: " . mysqli_error($conexion));
    }

    while ($row_vacuna = mysqli_fetch_assoc($result_vacunas_por_rango)) {
	
	$aplicacion_dentro_limite = (
			$sysdesa10_edad >= $row_vacuna['sysvacu03_limite_min_dosis'] &&
			$sysdesa10_edad <= $row_vacuna['sysvacu03_limite_max_dosis']
		) ? 1 : 0;

        $vacunas_esperadas[] = array(
			'rela_sysvacu01' => $row_vacuna['rela_sysvacu01'],
			'sysvacu01_descripcion' => $row_vacuna['sysvacu01_descripcion'],
			'rela_sysvacu02' => $row_vacuna['rela_sysvacu02'],
			'sysvacu02_descripcion' => $row_vacuna['sysvacu02_descripcion'],
			'rela_sysvacu04' => $row_vacuna['rela_sysvacu04'],
			'sysvacu04_nombre' => $row_vacuna['sysvacu04_nombre'],
			'rela_sysvacu05' => $row_vacuna['rela_sysvacu05'],
			'sysvacu05_nombre' => $row_vacuna['sysvacu05_nombre'],
			'aplicacion_dentro_limite' => $aplicacion_dentro_limite
		);

    }
} 

// VACUNAS POR CONDICIONES ESPECIALES

$condiciones = array();

// Armo el arreglo de condiciones recibidas
if ($embarazada == "true") {
    $condiciones[] = 2;
}

if ($personal_salud == "true") {
    $condiciones[] = 4;
}

if ($puerpera == "true") {
    $condiciones[] = 5;
}

// Recorro cada condicion especial
foreach ($condiciones as $condicion) {

    $qr_vacunas_condicion = "SELECT
                                rv.rela_sysvacu01,
                                c.sysvacu01_descripcion,
                                rv.rela_sysvacu02,
                                e.sysvacu02_descripcion,
                                rv.rela_sysvacu04,
                                v.sysvacu04_nombre,
                                rv.rela_sysvacu05,
                                d.sysvacu05_nombre
                             FROM sys_vacu_03_rel_vacuna rv
                             LEFT JOIN sys_vacu_01_cab_condicion_aplicacion c
                                 ON c.id_sysvacu01 = rv.rela_sysvacu01
                             LEFT JOIN sys_vacu_02_cab_esquema e
                                 ON e.id_sysvacu02 = rv.rela_sysvacu02
                             LEFT JOIN sys_vacu_04_cab_vacuna v
                                 ON v.id_sysvacu04 = rv.rela_sysvacu04
                             LEFT JOIN sys_vacu_05_cab_dosis d
                                 ON d.id_sysvacu05 = rv.rela_sysvacu05
                             WHERE rv.rela_sysvacu01 = $condicion
                               AND rv.sysvacu03_valida_rango = 1";

    $result_vacunas_condicion = mysqli_query($conexion, $qr_vacunas_condicion);

    if (!$result_vacunas_condicion) {
        die("Error en consulta de vacunas por condicion: " . mysqli_error($conexion));
    }

    while ($row_condicion = mysqli_fetch_assoc($result_vacunas_condicion)) {

        $vacunas_esperadas[] = array(
            'rela_sysvacu01' => $row_condicion['rela_sysvacu01'],
            'sysvacu01_descripcion' => $row_condicion['sysvacu01_descripcion'],
            'rela_sysvacu02' => $row_condicion['rela_sysvacu02'],
            'sysvacu02_descripcion' => $row_condicion['sysvacu02_descripcion'],
            'rela_sysvacu04' => $row_condicion['rela_sysvacu04'],
            'sysvacu04_nombre' => $row_condicion['sysvacu04_nombre'],
            'rela_sysvacu05' => $row_condicion['rela_sysvacu05'],
            'sysvacu05_nombre' => $row_condicion['sysvacu05_nombre'],
			'aplicacion_dentro_limite' => null
        );

    }

}

// Eliminamos duplicados en caso que existan

$vacunas_esperadas_unicas = array();

foreach ($vacunas_esperadas as $vacuna) {

    $clave = $vacuna['rela_sysvacu04'] . '_' . $vacuna['rela_sysvacu05'];

    $vacunas_esperadas_unicas[$clave] = $vacuna;

}

// Reindexo el arreglo
$vacunas_esperadas = array_values($vacunas_esperadas_unicas);

// Sacamos las que ya tiene aplicadas

$vacunas_pendientes = array();

foreach ($vacunas_esperadas as $vacuna_esperada) {

    $clave = $vacuna_esperada['rela_sysvacu04'] . '_' . $vacuna_esperada['rela_sysvacu05'];

    if (!isset($vacunas_aplicadas_indexadas[$clave])) {

        $vacunas_pendientes[] = array(

            'rela_sysvacu01' => $vacuna_esperada['rela_sysvacu01'],
            'sysvacu01_descripcion' => $vacuna_esperada['sysvacu01_descripcion'],
            'rela_sysvacu02' => $vacuna_esperada['rela_sysvacu02'],
            'sysvacu02_descripcion' => $vacuna_esperada['sysvacu02_descripcion'],
            'rela_sysvacu04' => $vacuna_esperada['rela_sysvacu04'],
            'sysvacu04_nombre' => $vacuna_esperada['sysvacu04_nombre'],
            'rela_sysvacu05' => $vacuna_esperada['rela_sysvacu05'],
            'sysvacu05_nombre' => $vacuna_esperada['sysvacu05_nombre'],
			'aplicacion_dentro_limite' => $vacuna_esperada['aplicacion_dentro_limite']
        );

    }

}

echo json_encode(array(
    'vacunas_aplicadas' => $aplicaciones_beneficiario,
    'vacunas_pendientes' => $vacunas_pendientes
));