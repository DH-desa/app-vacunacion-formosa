# Contexto de Endpoints PHP — Sistema de Vacunación

Este documento describe línea por línea qué hace cada endpoint PHP del sistema de vacunación legacy.
El sistema mobile apunta directamente a estos archivos PHP. La web admin solo gestiona versiones de la app.

---

## Convenciones generales

- Todos los endpoints reciben parámetros vía **GET**.
- Responden JSON. La clave raíz varía por endpoint.
- `codigo_mensaje = ''` → éxito; `codigo_mensaje = '0'` → error.
- Hay dos conexiones a BD usadas a lo largo del código:
  - `$conexion` → MySQL directo (`link_mysql.php`) — usado en producción para la mayoría de endpoints.
  - `$link_msq` → wrapper abstracto `flex_*` (`link_msq.php`) — usado en login y algunos endpoints de perfil/vacunas (conexión alternativa, probablemente SQL Server o MSSQL).
- Las funciones `flex_query`, `flex_num_rows`, `flex_fetch_assoc` son wrappers definidos en `lib/functions.php` que envuelven la conexión `$link_msq`.

---

## Tablas clave del modelo de datos

| Tabla | Descripción |
|---|---|
| `flx_core_03_arb_usuarios` | Usuarios registradores del sistema |
| `sys_vacu_07_det_registrador_efector` | Relación registrador ↔ efector (establecimiento) |
| `sys_ofic_01_cab_establecimientos` | Efectores / establecimientos de salud |
| `sys_vacu_12_cab_perfil` | Perfiles de vacunación |
| `sys_vacu_14_det_perfil_registrador` | Relación registrador ↔ perfil |
| `sys_vacu_13_rel_perfil_vacuna` | Relación perfil ↔ vacunas habilitadas |
| `sys_vacu_04_cab_vacuna` | Catálogo de vacunas |
| `sys_vacu_01_cab_condicion_aplicacion` | Condiciones de aplicación (Campaña, Rutina, etc.) |
| `sys_vacu_02_cab_esquema` | Esquemas de vacunación |
| `sys_vacu_05_cab_dosis` | Dosis (1ra, 2da, Refuerzo, Dosis Anual, etc.) |
| `sys_vacu_03_rel_vacuna` | Configuración: combina vacuna + condición + esquema + dosis |
| `sys_vacu_11_tipo_vacuna` | Tipo de vacuna (1=COVID, 2=Antigripal, 3=Otras, 4=Otras2) |
| `sys_desa_10_cab_nomivac` | Registro principal de aplicaciones de vacunas (producción) |
| `sys_desa_99_cab_nomivac_pruebas` | Tabla de pruebas/desarrollo (no se usa en producción) |
| `sys_desa_12_vacunador` | Vacunadores habilitados |
| `sys_desa_06_cab_personas` | Personas (vinculada a vacunadores) |
| `sys_desa_13_tipo_vacunador` | Tipo de vacunador |
| `sys_desa_18_cab_lotes` | Lotes de vacunas con stock |
| `sys_vacu_27_det_movimientos_lotes` | Movimientos/descuentos de stock de lotes |
| `sys_appl_01_cab_versiones` | Versiones de la aplicación mobile |
| `sys_info_01_cab_informes` | Log de notificaciones enviadas a SISA |
| `sys_info_03_cab_auditoria` | Auditoría de inserciones fallidas en SISA |
| `seg_publ_12_det_cambios_relacion_covid` | Historial de resultados COVID (para validar positivos) |
| `seg_publ_01_cab_personas` | Personas del módulo de seguridad pública |

---

## 1. `wserv_login.php`

**Parámetro GET:** `flxcore03_dni`
**Respuesta:** `{ "usuario": [ {...} ] }`

**Flujo línea por línea:**
1. Incluye `functions.php` y `link_msq.php` (conexión alternativa).
2. Lee `$_GET['flxcore03_dni']`.
3. `str_replace(".","",$flxcore03_dni)` → elimina puntos del DNI (ej. "25.123.456" → "25123456").
4. `trim()` → elimina espacios.
5. Si el DNI no está vacío:
   - Consulta `flx_core_03_arb_usuarios` buscando el DNI con `flxcore03_estado=1` (activo).
   - Si hay resultado: obtiene `id_flxcore03`.
   - Consulta `sys_vacu_07_det_registrador_efector` JOIN `sys_ofic_01_cab_establecimientos` para obtener el efector asignado al registrador (solo el primero, `flex_fetch_assoc` sin loop).
   - Retorna: `id_flxcore03`, `flxcore03_dni`, `flxcore03_nombre` (utf8_encode), `rela_sysofic01` (ID del efector), `sysofic01_descripcion` (nombre del efector), `codigo_mensaje=''`, `mensaje=''`.
   - Si no existe: retorna campos vacíos y `codigo_mensaje='0'` con mensaje "No hay registradores con el DNI ingresado".
6. Si DNI vacío: retorna error "DNI vacío. Debe ingresar este dato."

**Nota importante:** Solo devuelve el primer efector del registrador. `wserv_efector_registrador.php` devuelve todos.

---

## 2. `wserv_efector_registrador.php`

**Parámetro GET:** `flxcore03_dni`
**Respuesta:** `{ "usuario": [ {...}, {...} ] }` (array con todos los efectores)

**Flujo línea por línea:**
1. Incluye `functions.php` y `link_mysql.php` (conexión MySQL directa).
2. Lee `$_GET['flxcore03_dni']`.
3. Consulta `flx_core_03_arb_usuarios` con `flxcore03_estado=1`.
4. Si existe, obtiene `id_flxcore03`.
5. Consulta `sys_vacu_07_det_registrador_efector` JOIN establecimientos con `sysvacu07_activo=1`, ordenado por `sysvacu07_fecha_alta DESC, sysvacu07_principal DESC`.
6. Itera con `while` → devuelve **todos** los efectores del registrador, uno por fila en el array.
7. Cada item: `id_flxcore03`, `flxcore03_dni`, `flxcore03_nombre`, `rela_sysofic01`, `sysofic01_descripcion`.
8. Si el usuario no existe: devuelve array con campos vacíos (sin `codigo_mensaje`).

**Diferencia con wserv_login.php:** Este devuelve todos los efectores en loop; el login solo devuelve el primero y también usa `link_msq`.

---

## 3. `wserv_obtener_perfil_vacunacion.php`

**Parámetro GET:** `rela_flxcore03` (ID del registrador)
**Respuesta:** `{ "perfiles_vacunacion": [ {...} ] }`

**Flujo línea por línea:**
1. Incluye `link_msq.php` y `functions.php`.
2. Lee `$_GET['rela_flxcore03']`.
3. Si no está vacío:
   - Consulta `sys_vacu_14_det_perfil_registrador` LEFT JOIN `sys_vacu_12_cab_perfil` donde `rela_flxcore03=$rela_flxcore03` y `sysvacu14_activo=1`, ordenado por descripción ASC.
   - Itera todos los resultados con `while`.
   - Cada item: `id_sysvacu12` (ID perfil), `sysvacu12_descripcion` (utf8_encode), `codigo_mensaje=''`, `mensaje=''`.
   - Sin resultados: error "EL registrador no posee perfil asignado." (usa `utf8_decode` en el mensaje de error — inconsistencia).
4. Si vacío: error "No pueden haber campos vacíos. Campos Vacios: ID DEL REGISTRADOR".

---

## 4. `wserv_obtener_vacunas_configuradas.php`

**Parámetros GET:** `id_sysvacu12` (ID perfil), `sysdesa10_sexo`, `sysdesa10_dni`
**Respuesta:** `{ "vacunas_configuradas": [ {...} ] }`

**Flujo línea por línea:**
1. Incluye `link_msq.php` y `functions.php`.
2. Lee los tres parámetros. Al DNI le quita "M" y "F" (prefijos de sexo que puede venir en la cadena del DNI).
3. Si todos los campos están presentes:
   - **Paso 1 — Verificar vacunas aplicadas:** Consulta `sys_desa_10_cab_nomivac` JOIN vacuna, dosis, config, para el DNI y sexo del beneficiario. Cuenta dosis de tipo COVID (`rela_sysvacu11=1`). Registra la primera vacuna aplicada (`$p1er_vacuna_aplicada`, orden_numerico=1) y la segunda (`$s2da_vacuna_aplicada`, orden_numerico=2).
   - **Paso 2 — Devolver vacunas por perfil:** Llama `devolver_vacunas_por_perfil()`:
     - Consulta `sys_vacu_13_rel_perfil_vacuna` JOIN `sys_vacu_04_cab_vacuna` donde `rela_sysvacu12=$id_sysvacu12` y `sysvacu13_activo=1`.
     - Construye lista de IDs de vacunas (`IN (...)`) habilitadas para el perfil.
     - Si el perfil es el 1 (COVID): agrega combinaciones posibles de segundas y terceras dosis según la primera vacuna aplicada (ver funciones de combinaciones).
     - Excepción: si la primera vacuna es Cansino (id=15) y tiene segunda dosis, excluye Sinopharm (id=4).
   - **Paso 3 — Query final:** Consulta `sys_vacu_03_rel_vacuna` JOIN vacuna, dosis con el filtro `WHERE id_sysvacu04 IN (...)`, agrupado por `id_sysvacu04`.
   - Devuelve: `id_sysvacu04`, `sysvacu04_nombre` (utf8_encode), `codigo_mensaje`, `mensaje`.
4. Si falta algún campo: indica cuáles están vacíos.

**Función `devolver_combinaciones_segundas_dosis($p1er_vacuna_aplicada)`:**
Define qué vacunas son compatibles para la 2da dosis según la 1ra:
- Covishield (3) → AstraZeneca (5)
- Sputnik V (1) → Sputnik V (1), AstraZeneca (5), Moderna (13)
- AstraZeneca (5) → AstraZeneca (5), Moderna (13), Pfizer (14)
- Pfizer (14) → Pfizer (14), Moderna (13)
- Moderna (13) → Moderna (13), Pfizer (14)
- Antigripales (8,9,10,11,12) → sin combinación adicional
- Resto → misma vacuna

**Función `devolver_combinaciones_terceras_dosis($p1er, $s2da)`:**
Para 3ra dosis:
- Sputnik (1) → Sputnik, AstraZeneca, Cansino, Moderna, Pfizer
- AstraZeneca (5) → AstraZeneca, Sputnik, Moderna, Pfizer, Cansino
- Sinopharm (4) → Sinopharm, Sputnik, AstraZeneca, Cansino, Moderna, Pfizer
- Cansino (15) → todas menos Sinopharm (se maneja aparte)
- Pfizer (14) → Pfizer, Moderna
- Moderna (13) → Moderna, Pfizer

---

## 5. `wserv_obtener_condicion_vacunas.php`

**Parámetros GET:** `id_sysvacu04` (ID vacuna), `sysdesa10_edad` (edad en años)
**Respuesta:** `{ "condicion_vacunas": [ {...} ] }`

**Flujo línea por línea:**
1. Incluye `link_mysql.php` y `functions.php`.
2. Lee `id_sysvacu04` y `sysdesa10_edad`.
3. Si ambos presentes:
   - **Caso edad = 0** (recién nacido/no informada): aplica un `switch` con valores fijos de edad en días para consultar:
     - IPV Salk o Triple Viral (id 42, 57) → 437 días
     - Vacuna id 45 → 56 días
     - Neumococo o Rotavirus (id 47, 53, 54) → 42 días
     - Moderna, Antigripal Trivalente Pediátrica, Antigripal Adultos (id 64, 8, 9) → 180 días
     - Quíntuple (id 51) → 42 días
     - Vacuna id 55 → 60 días
     - Default → 0 días
     - Cláusula WHERE: `$edadConsulta BETWEEN sysvacu03_limite_min_dosis AND sysvacu03_limite_max_dosis`
   - **Caso edad > 0**: convierte edad en días (`* 365`), excepto IPV Salk / Triple Viral si la edad es < 6 años → usa 437 días fijos.
     - Cláusula WHERE: `($sysdesa10_edad BETWEEN min AND max OR 0 BETWEEN min AND max)` — incluye configs sin rango de edad.
   - Query: `sys_vacu_03_rel_vacuna` JOIN condición, vacuna → filtra por `id_sysvacu04`, rango de edad, `sysvacu03_estado=1`, agrupado por `id_sysvacu01`.
   - Devuelve: `id_sysvacu01`, `sysvacu01_codigo`, `sysvacu01_descripcion`, `sysvacu01_orden`, `sysvacu01_abreviatura`.
4. Si falta algún campo: error genérico "No se recibió el ID de vacuna".

---

## 6. `wserv_obtener_esquema_vacunas.php`

**Parámetros GET:** `id_sysvacu04` (vacuna), `id_sysvacu01` (condición)
**Respuesta:** `{ "esquema_vacunas": [ {...} ] }`

**Flujo línea por línea:**
1. Incluye `link_mysql.php` y `functions.php`. Charset `utf8mb4`.
2. Requiere ambos parámetros no vacíos.
3. Consulta `sys_vacu_03_rel_vacuna` JOIN condición, vacuna, dosis, esquema → filtra por `id_sysvacu04`, `id_sysvacu01`, `sysvacu03_estado=1`, agrupado por `id_sysvacu02`.
4. Devuelve: `id_sysvacu02`, `sysvacu02_codigo`, `sysvacu02_descripcion`, `sysvacu02_limite_min` (mínimo edad esquema), `sysvacu02_limite_max` (máximo edad esquema).
5. Sin resultados: error "No se encontraron Esquemas para la vacuna seleccionada".
6. Sin parámetros: error "No se recibió el ID de vacuna".

---

## 7. `wserv_obtener_dosis_vacunas.php`

**Parámetros GET:** `id_sysvacu04` (vacuna), `id_sysvacu01` (condición), `id_sysvacu02` (esquema)
**Respuesta:** `{ "dosis_vacunas": [ {...} ] }`

**Flujo línea por línea:**
1. Incluye `link_mysql.php` y `functions.php`. Charset `utf8mb4`.
2. Requiere los tres parámetros no vacíos.
3. Consulta `sys_vacu_03_rel_vacuna` JOIN condición, vacuna, dosis, esquema → filtra por los tres IDs y `sysvacu03_estado=1`. Sin GROUP BY → devuelve todas las dosis disponibles.
4. Devuelve por cada dosis: `id_sysvacu05`, `sysvacu05_nombre`, `sysvacu05_orden`, `sysvacu05_cod_sisa`, `sysvacu05_esquema`, `sysvacu05_orden_numerico`.
5. Sin resultados: error "No se encontraron Dosis para la vacuna seleccionada".

---

## 8. `wserv_obtener_lotes_vacunas.php`

**Parámetro GET:** `id_sysvacu04`
**Respuesta:** `{ "lotes_vacunas": [ {...} ] }`

**Flujo línea por línea:**
1. Incluye `link_mysql.php` y `functions.php`. Charset `utf8mb4`.
2. Si `id_sysvacu04` no vacío:
   - Consulta `sys_desa_18_cab_lotes` donde `rela_sysvacu04=$id_sysvacu04`, `sysdesa18_externo=0 OR NULL` (no es lote externo), `sysdesa18_inicial=1` (lote original, no re-distribución), agrupado por `sysdesa18_lote`.
   - Devuelve: `id_sysdesa18`, `sysdesa18_lote` (nombre/código del lote), `sysdesa18_cantidad_actual` (stock actual), `sysdesa18_fecha_vencimiento` (formateado con `viewDate()`).
3. Sin resultados: error "No se encontraron Lotes para la vacuna seleccionada".
4. Sin parámetro: error "No se recibió el ID de vacuna".

---

## 9. `wserv_vacunador.php`

**Parámetro GET:** `sysdesa06_nro_documento` (DNI del vacunador)
**Respuesta:** `{ "vacunador": [ {...} ] }`

**Flujo línea por línea:**
1. Incluye `link_mysql.php` y `functions.php`. Charset `utf8mb4`.
2. Si DNI no vacío:
   - Consulta `sys_desa_12_vacunador` LEFT JOIN `sys_desa_06_cab_personas` LEFT JOIN `sys_desa_13_tipo_vacunador` donde `sysdesa06_nro_documento=$dni` y `sysdesa12_habilitado=1`.
   - `CONCAT(apellido, ' ', nombre)` como alias `nombre`.
   - Si existe: devuelve `id_sysdesa12`, `sysdesa06_nro_documento`, `sysdesa06_nombre` (apellido nombre), `codigo_mensaje=""`, `mensaje="1"` (atípico: usa "1" como mensaje en lugar de código).
   - Si no existe: `codigo_mensaje="0"`, `mensaje="No hay registros"`.
3. Si vacío: `codigo_mensaje="0"`, `mensaje="No se recibió el número de documento"`.

**Nota:** Cuando `vacunador_registrador=1` en el registro de vacuna, el registrador actúa también como vacunador. En ese caso se busca por DNI usando `obtener_datos_vacunador()`.

---

## 10. `wserv_cantidad_vacunas_registradas.php`

**Parámetros GET:** `id_sysdesa12` (ID o DNI del vacunador), `vacunador_registrador` (1 si registrador = vacunador)
**Respuesta:** `{ "usuario": [ {...} ] }`

**Flujo línea por línea:**
1. Incluye `functions.php` y `link_mysql.php`. Charset `utf8`.
2. Lee `id_sysdesa12` y `vacunador_registrador`. Hace `trim()`.
3. Si `id_sysdesa12` no vacío:
   - Si `vacunador_registrador==1`: llama `obtener_datos_vacunador($conexion, $id_sysdesa12)` que busca por DNI en `sys_desa_12_vacunador` y devuelve el ID real.
   - Sino: usa el ID directamente.
   - Obtiene la fecha actual (`date('Y-m-d')`).
   - Consulta `sys_desa_10_cab_nomivac` contando registros donde `rela_sysdesa12=$id_vacunador` y `sysdesa10_fecha_alta = hoy`.
   - Devuelve: `id_sysdesa12`, `cantidad_aplicaciones`.
4. Si vacío: error "DNI o ID del Vacunador Vacío."

**Función `obtener_datos_vacunador($conexion, $dni)`:** Busca en `sys_desa_12_vacunador` JOIN personas JOIN tipo_vacunador por `sysdesa06_nro_documento=$dni` y `sysdesa12_habilitado=1`. Devuelve `id_sysdesa12` o 0.

---

## 11. `obtener_aplicaciones_beneficiario.php`

**Parámetros GET:** `sysdesa10_dni`, `sysdesa10_sexo`
**Respuesta:** `{ "aplicaciones_beneficiario": [ {...} ] }`

**Flujo línea por línea:**
1. Incluye `Requests.php` (renaper), `link_mysql.php`, `functions.php`.
2. `ini_set("memory_limit","-1")` y `set_time_limit(0)` → sin límite de memoria ni tiempo.
3. `header("Cache-Control: no-cache")`.
4. Si DNI y sexo no vacíos:
   - Consulta `sys_desa_10_cab_nomivac` JOIN config, dosis, vacuna, lotes → filtra por DNI y sexo, ordenado por `sysdesa10_fecha_aplicacion DESC`.
   - Por cada aplicación:
     - Formatea fecha: `viewDate($fecha_array[0])` (solo fecha sin hora).
     - Calcula fecha próxima dosis: si `sysvacu03_tiempo_interdosis != 0`, suma esa cantidad de días a la fecha de aplicación.
     - Devuelve: `sysvacu04_nombre`, `sysvacu05_nombre` (dosis), `sysdesa10_fecha_aplicacion` (formateada), `fecha_proxima_dosis`, `dias_transcurridos`, `sysvacu03_tiempo_interdosis`, `sysdesa18_lote`, `codigo_mensaje="1"`.
   - Sin resultados: `codigo_mensaje="0"`, `mensaje="No se encontraron registros sobre este beneficiario"`.
5. Si falta DNI o sexo: lista qué campos están vacíos.

---

## 12. `wserv_obtener_datos_beneficiario.php`

**Parámetros GET:** `sysdesa10_dni`, `sysdesa10_sexo`, `sysdesa10_cadena_dni` (cadena raw del lector de DNI)
**Respuesta:** `{ "beneficiario": [ {...} ] }`

Este endpoint tiene **dos flujos** según el parámetro recibido:

### Flujo A — Con `sysdesa10_cadena_dni` (lectura de chip/código de barras del DNI):
1. Limpia la cadena: quita `[`, intenta parsear campos separados por comas.
2. Itera cada campo buscando:
   - **Apellido:** primer campo alfanumérico con longitud > 2, sin dígitos.
   - **Nombre:** segundo campo alfanumérico con longitud > 2, sin dígitos, distinto del apellido.
   - **Sexo:** campo que contiene "M" o "F" y tiene longitud exacta de 1 después de quitar dígitos.
   - **DNI:** campo numérico de 7 u 8 dígitos (después de quitar M/F).
   - **Fecha de nacimiento:** campo que contiene "/" o "-" con tres partes numéricas. Si hay varias fechas, toma la **mínima** (función `fecha_minima()`).
3. Con la fecha de nacimiento mínima calcula la edad con `busca_edad()`.
4. La foto del beneficiario se establece como cadena vacía (el llamado a RENAPER está comentado).
5. No consulta RENAPER en este flujo.

### Flujo B — Con `sysdesa10_dni` y `sysdesa10_sexo` (ingreso manual):
1. Convierte sexo: "M"→2, "F"→1, otro→0.
2. Limpia el DNI quitando "M" y "F".
3. Llama `obtener_datos_personales($dni, $sexo_numerico)`:
   - Hace POST a `https://federador.msal.gob.ar/masterfile-federacion-service/api/usuarios/aplicacion/login` con credenciales fijas (ofuscadas en base64).
   - Obtiene token JWT.
   - Hace GET a `https://federador.msal.gob.ar/masterfile-federacion-service/api/personas/renaper?nroDocumento=...&idSexo=...`.
   - Devuelve el JSON completo de RENAPER.
4. Si la respuesta es `INTERNAL_SERVER_ERROR`: devuelve error.
5. Si hay respuesta válida: extrae `idtramiteprincipal`, `fechaNacimiento`, `sexo`, `apellido`, `nombres`, `numeroDocumento`, `cuil`. Calcula edad y formatea fecha.
6. Si no hay respuesta: error con DNI y sexo enviados.

### Respuesta final (ambos flujos):
`sysdesa10_apellido`, `sysdesa10_nombre`, `sysdesa10_cuil`, `sysdesa10_dni`, `sysdesa10_sexo`, `sysdesa10_nro_tramite`, `sysdesa10_fecha_nacimiento` (formato d-m-Y), `sysdesa10_edad`, `sysdesa10_cadena_dni`, `foto_beneficiario` (siempre vacío actualmente), `codigo_mensaje`, `mensaje`.

**Función `busca_edad($fecha_nacimiento)`:** Calcula edad en años a partir de una fecha en formato "d-m-Y" o "Y-m-d", teniendo en cuenta si ya cumplió años en el año actual.

**Función `fecha_minima($f1, $f2)`:** Compara dos fechas y devuelve la menor. Si `$f1` es vacío usa 01-01-2025 como referencia inicial para comparar.

---

## 13. `wser_versiones_app.php`

**Parámetros GET:** `sysappl01_nombre` (nombre de la app), `sysappl01_version` (versión a verificar)
**Respuesta:** `{ "versiones": [ {...} ] }`

**Flujo línea por línea:**
1. Incluye `link_mysql.php`, `link_msq.php`, `functions.php`. Charset `utf8mb4`.
2. Consulta `sys_appl_01_cab_versiones` donde `sysappl01_nombre=$nombre`, `sysappl01_version=$version`, `sysappl01_estado=1`.
3. Si existe: devuelve `id_sysappl01`, `sysappl01_nombre`, `sysappl01_version`, `sysappl01_fecha_actualizacion` (con `viewDate()`), `codigo_mensaje=''`.
4. Si no existe: `codigo_mensaje='0'` con mensaje indicando que no se encontró la combinación app/versión.

**Este es el único endpoint que la web admin gestiona activamente** (tabla `sys_appl_01_cab_versiones`).

---

## 14. `wserv_registrar_vacuna.php` ⚠️ El más complejo

**Parámetro GET:** `insertvacunado` (JSON codificado con array de objetos)
**Respuesta:** `{ "mensajes": [ {"codigo_mensaje": "...", "mensaje": "..."} ] }`

El JSON de entrada es un array. Por cada elemento llama a `agregar_aplicacion_vacuna()`.

### Campos del objeto en el array:
| Campo | Descripción |
|---|---|
| `id_flxcore03` | ID del registrador |
| `id_sysvacu01` | ID condición de aplicación |
| `id_sysvacu02` | ID esquema |
| `id_sysvacu04` | ID vacuna |
| `id_sysvacu05` | ID dosis |
| `fecha_aplicacion` | Fecha de aplicación |
| `id_sysofic01` | ID efector |
| `id_sysdesa12` | ID o DNI del vacunador |
| `vacunador_registrador` | 1 si registrador = vacunador |
| `id_sysdesa18` | ID lote de vacuna |
| `sysdesa10_apellido/nombre/dni/edad/fecha_nacimiento/sexo` | Datos del beneficiario |
| `sysdesa10_apellido/nombre/dni_tutor/sexo_tutor` | Datos del tutor (si es menor) |
| `sysdesa10_nro_tramite` | Número de trámite del DNI |
| `sysdesa10_cadena_dni` | Cadena raw del DNI |
| `sysdesa10_terreno` | 1 si es vacunación en terreno, 0 si es en establecimiento |

### `agregar_aplicacion_vacuna()` — Flujo detallado:

**Bloque 1 — Normalización inicial:**
- Si `sysdesa10_terreno` vacío → se establece en 0.
- `Quitar_Espacios()` quita espacios múltiples (regex `\s+` → espacio simple).
- Valida apellido, nombre, DNI, sexo: ninguno puede estar vacío.
- Si `sysdesa10_fecha_nacimiento` vacía → `"0000-00-00"`. Sino formatea a `Y-m-d` y también a `d-m-Y` para cadena del DNI.
- Si `sysdesa10_edad < 18`: valida que apellido_tutor, nombre_tutor, dni_tutor, sexo_tutor no estén vacíos.

**Bloque 2 — Validaciones de IDs:**
- `id_flxcore03`, `id_sysvacu01`, `id_sysvacu02`, `id_sysvacu04`, `id_sysvacu05`, `id_sysofic01` deben ser no vacíos y != 0.
- `id_sysdesa12`: si `vacunador_registrador==1` → busca por DNI con `obtener_datos_vacunador()`. Si no encuentra: error.
- `id_sysdesa18` no puede ser vacío.
- `fecha_aplicacion` no puede ser vacía ni "0000-00-00". Formatea a `Y-m-d` + hora actual para el INSERT.

**Bloque 3 — Descuento de stock (agregado 20-05-2024):**
1. Busca el nombre del lote (`sysdesa18_lote`) con el `id_sysdesa18`.
2. Busca el lote "inicial" (`sysdesa18_inicial=1`) del mismo nombre para el mismo efector (`rela_sysofic01_dh=$id_sysofic01`) con stock disponible (`sysdesa18_cantidad_actual > 0`).
3. Si no hay stock: error "No hay stock disponible para el lote seleccionado."
4. Si hay stock:
   - **Excepción:** Si `id_sysvacu04==8` (Antigripal Pediátrica) y el beneficiario tiene más de 2 años → descuenta 2 unidades en lugar de 1.
   - En todos los demás casos: descuenta 1.
   - `UPDATE sys_desa_18_cab_lotes SET sysdesa18_cantidad_actual=$cantidad_resta WHERE id_sysdesa18=$id_inicial`.
   - Si falla el UPDATE: error.
   - Si OK: inserta en `sys_vacu_27_det_movimientos_lotes` con `rela_sysauto35=1`, `rela_sysauto36=8`, `sysvacu27_observacion='APP VACUNA'`.
   - Si falla el INSERT en movimientos: error.

**Bloque 4 — Obtener configuración:**
- Consulta `sys_vacu_03_rel_vacuna` JOIN vacuna → donde `rela_sysvacu01`, `rela_sysvacu02`, `rela_sysvacu04`, `rela_sysvacu05` coinciden con los enviados.
- Obtiene `id_sysvacu03` (ID configuración) y `rela_sysvacu11` (tipo vacuna).
- Si no encuentra: error "No se encontró la configuración con la condición, esquema, vacuna ni dósis seleccionada".

**Bloque 5 — Validar COVID positivo:**
- Consulta `seg_publ_12_det_cambios_relacion_covid` JOIN personas, relación COVID → busca el último resultado COVID positivo (`rela_segpubl02=1`) del beneficiario por DNI y sexo.
- Si tiene resultado detectable hace menos de **21 días** Y el tipo de vacuna es COVID (`rela_sysvacu11_cfg==1`): error indicando que es positivo con fecha y días.

**Bloque 6 — Validar fallecido:**
- Convierte sexo: "M"→2, "F"→1.
- Llama `obtener_datos_personales($dni, $sexo_numerico)` → misma función que en wserv_obtener_datos_beneficiario, consulta a RENAPER vía federador.
- Si responde: extrae `fechaf` (fecha fallecimiento). Si los tres campos de la fecha son numéricos → la persona figura como fallecida → error.
- Si no responde: continúa.

**Bloque 7 — Validar dosis duplicada (rama: ya tiene esa configuración exacta):**
- Consulta `sys_desa_10_cab_nomivac` JOIN config, vacuna, dosis, tipo_vacuna → donde `sysdesa10_dni`, `sysdesa10_sexo`, `rela_sysvacu03=$id_sysvacu03`.
- **Si encuentra registros:**
  - Tipo COVID (`rela_sysvacu11==1`):
    - Si la dosis no es "Refuerzo": error "Ya se encuentra registrada la persona."
    - Si es "Refuerzo": verifica que hayan pasado >= 120 días desde la aplicación anterior.
  - Tipo "Otras" con dengue (`rela_sysvacu11==4`, `id_sysvacu04==78`): error duplicado.
  - Otras vacunas: valida que no se aplique la misma vacuna el mismo día (consulta si ya hay una aplicación el mismo día de la misma vacuna). Si hay y el beneficiario tiene edad > 0: error "No se puede aplicar la misma dosis en menos de 24 hrs".

**Bloque 7b — Validar dosis duplicada (rama: no tiene esa configuración pero puede tener dosis anteriores):**
- Obtiene datos de la configuración (`qr_consulta_validar_2`): vacuna, condición, orden de dosis, nombre de dosis, tipo de vacuna.
- Consulta todas las aplicaciones previas del beneficiario del mismo tipo de vacuna (`rela_sysvacu11`).
- Itera:
  - Si el orden de la dosis actual coincide con una ya aplicada:
    - Dosis "Refuerzo" de COVID: valida >= 120 días.
    - Vacuna Dengue (78) tipo 4: error duplicado.
    - Otras no-COVID: continúa (no bloquea).
    - COVID: error duplicado.
  - Controla inter-dosis para COVID:
    - Dosis 1→2: >= 28 días.
    - Dosis 2→3 o 2→6: >= 90 días.
    - Dosis 3→4 o 3→6: >= 120 días.
    - Dosis 4→5 o 4→6: >= 120 días.
    - Dosis 5→6: >= 120 días.
    - Refuerzo: >= 120 días.
    - Resto: usa `sysvacu03_tiempo_interdosis` configurado en BD.

**Bloque 8 — Validar lote vencido:**
- Busca el lote en `sys_desa_18_cab_lotes`.
- Compara `fecha_aplicacion_insert` (timestamp) con `sysdesa18_fecha_vencimiento + 23:59:59`.
- Si la fecha de aplicación es posterior al vencimiento: error "El lote seleccionado está vencido".

**Bloque 9 — INSERT principal:**
- Limpia `sysdesa10_cadena_dni`: reemplaza `,`, `.`, `:`, `(`, `)`, `|`, `'` por espacios y hace `utf8_encode`.
- `INSERT INTO sys_desa_10_cab_nomivac` con todos los campos del beneficiario, vacunador, registrador, efector, lote, fechas y datos del tutor.
- Si falla: error.
- Si OK: obtiene `id_sysdesa10` (insert_id).

**Bloque 10 — Notificar a SISA (actualmente desactivado):**
- Llama `informar_sisa()` pero **inmediatamente sobreescribe** `$respuesta_sisa = 1` → la notificación a SISA nunca falla desde el punto de vista del flujo principal.
- `informar_sisa()` internamente:
  1. Obtiene código SISA del efector.
  2. Obtiene código SISA de condición, esquema, vacuna y orden de dosis.
  3. Obtiene número del lote.
  4. Obtiene código de departamento del efector.
  5. Construye payload POST con datos del ciudadano y la aplicación.
  6. POST a `https://apisalud.msal.gob.ar/nomivacAplicacion/v1/aplicaciones/alta/` con headers `APP_ID` y `APP_KEY` fijos.
  7. Si respuesta `"OK"` o `ERROR_DATOS` con "Ya existe": marca `sysdesa10_estado=1` → notificado.
  8. Sino: marca `sysdesa10_estado=2` → pendiente de renotificación.
  9. Inserta en `sys_info_01_cab_informes` con la respuesta, petición y estado.
  10. Devuelve 1 si OK, 0 si falló.
- Si SISA falla (aunque nunca llega a ocurrir por el `$respuesta_sisa=1`): llama `auditoria()` que inserta la query en `sys_info_03_cab_auditoria`.

**Respuesta final:** `{ "mensajes": [{"codigo_mensaje": "1" o "0", "mensaje": "Registro guardado correctamente." o error}] }`

---

## 15. `wserv_obtener_configuraciones_vacuna.php`

Archivo vacío (1 línea). No implementado.

---

## Flujo completo de la app mobile (orden de llamadas)

```
1. wserv_login.php?flxcore03_dni=...
   → Autentica registrador, obtiene ID y efector

2. wserv_efector_registrador.php?flxcore03_dni=...
   → Obtiene todos los efectores del registrador (si tiene más de uno)

3. wserv_obtener_perfil_vacunacion.php?rela_flxcore03=...
   → Obtiene perfiles de vacunación del registrador

4. [Escaneo de DNI o ingreso manual del beneficiario]
   wserv_obtener_datos_beneficiario.php?sysdesa10_cadena_dni=... o ?sysdesa10_dni=...&sysdesa10_sexo=...
   → Obtiene datos del beneficiario (RENAPER o parseo de cadena)

5. obtener_aplicaciones_beneficiario.php?sysdesa10_dni=...&sysdesa10_sexo=...
   → Muestra historial de vacunas del beneficiario

6. wserv_obtener_vacunas_configuradas.php?id_sysvacu12=...&sysdesa10_sexo=...&sysdesa10_dni=...
   → Devuelve vacunas habilitadas para el perfil del registrador y compatibles con el historial

7. wserv_obtener_condicion_vacunas.php?id_sysvacu04=...&sysdesa10_edad=...
   → Devuelve condiciones de aplicación para la vacuna seleccionada

8. wserv_obtener_esquema_vacunas.php?id_sysvacu04=...&id_sysvacu01=...
   → Devuelve esquemas disponibles

9. wserv_obtener_dosis_vacunas.php?id_sysvacu04=...&id_sysvacu01=...&id_sysvacu02=...
   → Devuelve dosis disponibles

10. wserv_obtener_lotes_vacunas.php?id_sysvacu04=...
    → Devuelve lotes disponibles con stock

11. [Opcional] wserv_vacunador.php?sysdesa06_nro_documento=...
    → Si el vacunador es distinto del registrador, busca al vacunador por DNI

12. [Opcional] wserv_cantidad_vacunas_registradas.php?id_sysdesa12=...&vacunador_registrador=...
    → Muestra cuántas vacunas registró el vacunador hoy

13. wserv_registrar_vacuna.php?insertvacunado=[...]
    → Registra la aplicación con todas las validaciones

14. wser_versiones_app.php?sysappl01_nombre=...&sysappl01_version=...
    → Verifica si la versión de la app está vigente (puede llamarse al inicio)
```

---

## Notas de seguridad / deuda técnica

1. **SQL Injection:** Todos los endpoints construyen queries con concatenación directa de parámetros GET sin prepared statements. Ejemplo: `WHERE flxcore03_dni='$flxcore03_dni'`. Esto es una vulnerabilidad crítica en producción.
2. **Credenciales hardcoded:** `obtener_datos_personales()` tiene usuario y clave del federador MSAL en base64 en el código.
3. **APP_ID y APP_KEY de SISA** están hardcodeados en `informar_sisa()`.
4. **`$respuesta_sisa = 1`** en línea 877 de `wserv_registrar_vacuna.php` desactiva efectivamente la validación de respuesta de SISA.
5. **Inconsistencia de conexiones:** algunos endpoints usan `link_mysql.php` (mysqli directo) y otros `link_msq.php` (wrapper flex). El login usa `link_msq` y producción usa `link_mysql`.
6. **utf8_encode/utf8_decode mixtos:** hay inconsistencias entre endpoints (algunos encodean, otros decodifican) que pueden generar problemas de charset.
7. **Sin autenticación de endpoint:** cualquiera con acceso a la URL puede llamar los endpoints. No hay token/sesión en las llamadas.
