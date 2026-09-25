# Revisión de `version_5_0` — qué hace cada webservice y contra qué tablas

Leído del IDE de FLEX (fuente 124, `modulos/webservice/php/version_5_0`) el 18/09/2026,
con la skill `flex-ide`. Los 15 archivos se bajaron completos y se analizaron sin los
comentarios, para mirar solo el código que corre. El esquema de cada tabla se consultó
con `flex.sh campos`, no se dedujo de las consultas.

Base de datos: `link_mysql.php` conecta a **`10.10.0.170`, base `desarrollo_humano`**
(coincide con `SERVIDOR/docs/ARQUITECTURA.md`). Las credenciales están en texto plano
en ese include.

**Sin verificar:** `lib/link_msq.php` (la otra conexión, usada por 4 endpoints) está
fuera de esta fuente del IDE y no pude leerlo. No sé si apunta a la misma base.

## Tabla resumen

| Webservice | Entradas | Tablas que lee | Escribe |
|---|---|---|---|
| `wserv_efector_registrador.php` | `flxcore03_dni` | `flx_core_03_arb_usuarios`, `sys_vacu_07_det_registrador_efector`, `sys_ofic_01_cab_establecimientos` | — |
| `wserv_login.php` | `flxcore03_dni` | las mismas | — |
| `wserv_vacunador.php` | `sysdesa06_nro_documento` | `sys_desa_12_vacunador`, `sys_desa_06_cab_personas`, `sys_desa_13_tipo_vacunador` | — |
| `wserv_obtener_perfil_vacunacion.php` | `rela_flxcore03` | `sys_vacu_14_det_perfil_registrador`, `sys_vacu_12_cab_perfil` | — |
| `wserv_obtener_vacunas_configuradas.php` | `id_sysvacu12`, `sysdesa10_dni`, `sysdesa10_sexo` | `sys_vacu_13_rel_perfil_vacuna`, `sys_vacu_03_rel_vacuna`, `sys_vacu_04_cab_vacuna`, `sys_vacu_05_cab_dosis`, `sys_desa_10_cab_nomivac` | — |
| `wserv_obtener_condicion_vacunas.php` | `id_sysvacu04`, `sysdesa10_edad` | `sys_vacu_03_rel_vacuna`, `sys_vacu_01_cab_condicion_aplicacion`, `sys_vacu_04_cab_vacuna` | — |
| `wserv_obtener_esquema_vacunas.php` | `id_sysvacu04`, `id_sysvacu01` | las de configuración (`sys_vacu_01/02/03/04/05`) | — |
| `wserv_obtener_dosis_vacunas.php` | `+ id_sysvacu02` | ídem | — |
| `wserv_obtener_lotes_vacunas.php` | `id_sysvacu04` | `sys_desa_18_cab_lotes` | — |
| `wserv_listados_vacunas.php` | `sysdesa10_dni`, `sysdesa10_sexo`, `sysdesa10_edad`, `embarazada`, `puerpera`, `personal_salud` | `sys_desa_10_cab_nomivac`, `sys_vacu_30_rango_etario_vacunas`, `sys_vacu_01/02/03/04/05` | — |
| `obtener_aplicaciones_beneficiario.php` | `sysdesa10_dni`, `sysdesa10_sexo` | `sys_desa_10_cab_nomivac`, `sys_vacu_03/04/05`, `sys_desa_18_cab_lotes` | — |
| `wserv_cantidad_vacunas_registradas.php` | `id_sysdesa12`, `vacunador_registrador` | `sys_desa_10_cab_nomivac`, `sys_desa_12_vacunador` | — |
| `wserv_versiones_app.php` | `sysappl01_nombre`, `sysappl01_version` | `sys_appl_01_cab_versiones` | — |
| `wserv_obtener_datos_beneficiario.php` | `sysdesa10_cadena_dni`, `sysdesa10_dni`, `sysdesa10_sexo` | **ninguna** | — |
| `wserv_registrar_vacuna.php` | `insertvacunado` (JSON) | 18 tablas | **6 escrituras** |

## Detalle por endpoint

### Identidad del personal

- **`wserv_efector_registrador.php`** busca el usuario por DNI con `flxcore03_estado=1`
  y devuelve **una fila por efector activo** (`sysvacu07_activo=1`), ordenados por fecha
  de alta y `sysvacu07_principal`. La app usa el primero.
- **`wserv_login.php`** hace la misma consulta con la otra conexión y devuelve un solo
  efector. **La app no lo usa**: `urlLogin` apunta a `wserv_efector_registrador.php`.
- **`wserv_vacunador.php`** busca en `sys_desa_12_vacunador` por documento con
  `sysdesa12_habilitado=1`. Devuelve `mensaje: "1"` cuando encuentra, que la app no lee
  como mensaje sino como marca.

### Configuración de vacunas

- **`wserv_obtener_perfil_vacunacion.php`** devuelve los perfiles asignados al
  registrador (`sysvacu14_activo=1`).
- **`wserv_obtener_vacunas_configuradas.php`** arma la lista de vacunas del perfil y le
  resta las ya aplicadas, con reglas de esquemas COVID escritas en el código como
  números de vacuna (`id_sysvacu04` 1, 3, 4, 5, 13, 14, 15). Corre sobre la conexión
  `link_msq`.
- **`wserv_obtener_condicion_vacunas.php`** convierte la edad a días (`edad * 365`) y
  filtra por `sysvacu03_limite_min_dosis`/`max`. Para edad 0 usa una tabla de casos
  especiales por vacuna. **Defecto:** en la rama de edad distinta de 0 usa la variable
  `$edad_cero`, que nunca se define.
- **`wserv_obtener_esquema_vacunas.php`** y **`wserv_obtener_dosis_vacunas.php`** son
  consultas directas sobre la configuración, con `sysvacu03_estado = 1`.
- **`wserv_obtener_lotes_vacunas.php`** devuelve lotes con `sysdesa18_inicial = 1`, no
  externos y no vencidos, agrupados por número de lote. **No filtra por efector**, y el
  registro sí exige que el lote tenga stock en el efector del registrador: por eso la app
  ofrece lotes con los que después el registro falla con "No hay stock disponible".

### Historial

- **`wserv_listados_vacunas.php`** es el más nuevo y el mejor escrito: arma la fecha de
  nacimiento desde la base si la tiene, resuelve rangos etarios con
  `sys_vacu_30_rango_etario_vacunas`, contempla equivalencias entre vacunas y agrega las
  condiciones (embarazada, puérpera, personal de salud).
- **`obtener_aplicaciones_beneficiario.php`** lista las aplicaciones del beneficiario.
  **Defecto:** lee `proxima_dosis` y `faltan_dias_proxima_aplicacion` de la fila, y esas
  columnas no están en el `SELECT`, así que siempre salen vacías.

### Datos del beneficiario

- **`wserv_obtener_datos_beneficiario.php`** no toca la base. Ya está documentado en
  `hallazgos_backend_version_5_0.md`: con la cadena del DNI no consulta a RENAPER y
  devuelve edad `56` fija; sin cadena consulta a RENAPER.

### Registro

**`wserv_registrar_vacuna.php`** (1219 líneas) recibe un JSON con la lista de
aplicaciones y, por cada una, corre unas 25 validaciones antes de guardar: campos
obligatorios, tutor si es menor de 18, existencia de la configuración vacuna/esquema/
dosis, COVID detectable en los últimos 21 días, misma dosis en el día, dosis ya
registrada, tiempo entre dosis, lote vencido y stock.

**Mezcla la tabla de pruebas con la de producción:**

| Consulta | Tabla |
|---|---|
| `$qr_consulta_validar` (dosis ya registrada) | `sys_desa_99_cab_nomivac_pruebas` |
| `$qr_validar_vacunas` (interdosis) | `sys_desa_99_cab_nomivac_pruebas` |
| `$qr_validar_mismo_dia` | `sys_desa_10_cab_nomivac` |
| `$qr_validar_vacunas_orden` | `sys_desa_10_cab_nomivac` |
| INSERT del registro | `sys_desa_99_cab_nomivac_pruebas` |
| UPDATE de estado tras NOMIVAC | `sys_desa_10_cab_nomivac` |

Es decir: **guarda en la tabla de pruebas, pero valida contra las dos y después
actualiza la de producción usando el id que devolvió la tabla de pruebas.**

Efectos por registro exitoso: INSERT del registro, UPDATE de stock del lote, INSERT del
movimiento de lote, POST a NOMIVAC nacional, UPDATE de estado e INSERT de informe (y
auditoría cuando NOMIVAC falla).

## Cosas comunes a casi todos

1. **SQL armado por concatenación** con los parámetros de la URL, sin `prepare`.
2. **Sin control de errores de conexión o de consulta**: si la consulta falla,
   `mysqli_num_rows` recibe `false` y el flujo sigue.
3. **`codigo_mensaje` no es consistente**: a veces `''`, a veces `'0'`, a veces
   `'Hola'` (en lotes), a veces el texto del mensaje.
4. **Codificación mezclada**: conviven `utf8_encode`, `utf8_decode` y texto sin
   convertir, sobre conexiones que a veces piden `utf8` y a veces `utf8mb4`.
5. **Credenciales en el código**: base de datos, federador RENAPER y NOMIVAC.
6. Dos conexiones distintas (`link_mysql.php` y `link_msq.php`) según el archivo.

## Preguntas abiertas

1. ¿A qué base apunta `lib/link_msq.php`?
2. ¿Por qué el registro de `version_5_0` escribe en `sys_desa_99_cab_nomivac_pruebas`?
   ¿Es una prueba en curso o quedó así?
3. `sysdesa18_inicial = 1` — ¿qué representa exactamente esa marca en los lotes?
4. Los ids de vacuna escritos en el código de `wserv_obtener_vacunas_configuradas.php`
   (esquemas COVID) — ¿siguen vigentes?
