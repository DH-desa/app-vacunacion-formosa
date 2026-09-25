# Hallazgos del backend `version_5_0` (16/09/2026)

Investigación hecha durante la implementación de la lectura del QR del DNI 2026.
El código PHP se leyó del IDE de FLEX (`ide.formosa.gob.ar`, fuente 124,
`modulos/webservice/php/version_5_0`) y coincide línea por línea con las copias de
`DH/flex-lectura/`. Las pruebas contra los servicios se hicieron con datos reales de
dos documentos, en modo escaneo. Para repetirlas, ver la skill `flex-ide`.

> Todo lo de este documento se verificó ejecutando, salvo lo marcado como "leído en el código".

## 1. `wserv_obtener_datos_beneficiario.php` tiene dos vías

| | Vía escaneo (`sysdesa10_cadena_dni` con contenido) | Vía manual (cadena vacía + DNI + sexo) |
|---|---|---|
| Consulta a RENAPER | **No.** El bloque está comentado (líneas 178-238) | Sí (línea 245) |
| Separador de la cadena | `,` (línea 75), pero la app manda `@` | — |
| Nombre y apellido | Basura: la cadena entera sin dígitos | De RENAPER |
| Fecha de nacimiento | `null` | Correcta, con año de 4 dígitos |
| Edad | **Siempre `56`** (es `busca_edad("")`) | Correcta |
| `codigo_mensaje` | Siempre `''`, nunca avisa un error | `'0'` si no encuentra |

La app **siempre manda la cadena cuando escanea** (`escanerdni_widget.dart`), tanto
con PDF417 como con QR. El QR no cambia de vía: entra en la misma que el PDF417.

## 2. El QR del DNI 2026

Lectura real: `tramite@apellido@nombre@dni@ejemplar@fNac@fEmision@jwt`, 8 campos.

- **No trae el sexo.** Lo carga el operador.
- **La fecha viene con año de 2 dígitos** (`07/02/80`), lo que abre la ambigüedad de siglo.
- **El JWT solo contiene `{"id_tramite":"..."}`**, con firma RS256 de 256 bytes.
  No sirve para resolver el siglo ni para validar el sexo.

## 3. Validación del sexo: qué detecta cada fuente

| Consulta | Sexo correcto | Sexo equivocado | Sexo `X` | Sin sexo |
|---|---|---|---|---|
| RENAPER (vía manual) | Datos + fecha de 4 dígitos | `codigo_mensaje '0'` | Basura: fecha `31-12-1969`, edad 56, **sin avisar** | — |
| Recurso local `ws_personas.php` (plan B2, hoy comentado) | Datos + fecha + CUIL, en ~0,1 s | `nil` (no encuentra) | `nil` | `nil` |
| Vía escaneo | Devuelve el sexo que se le mandó | Igual | Igual | Igual |

**Ninguna de las dos fuentes devuelve el sexo a partir del DNI solo.** Confirman un
sexo, no lo informan.

El bloque B2 tal como está escrito parte `SIPCOMP05_APENOM` por espacios y toma la
primera palabra como apellido: con "CACERES MIRANDA EMILIANO NAHUEL" guarda apellido
`CACERES`. El servicio devuelve `SIPCOMP05_APELLIDO` y `SIPCOMP05_NOMBRE` separados,
pero el bloque no los usa.

## 4. Qué pasa cuando RENAPER se cae

Simulado con una copia de prueba que apunta el federador a destinos que no responden.

| Caída | Consulta de datos | Registro de vacuna |
|---|---|---|
| Vía escaneo, con RENAPER caído | **Funciona igual** (no lo consulta) | **Falla**: el registro sí consulta a RENAPER |
| Login del federador sin red | Texto plano, no JSON | Texto plano, no JSON |
| RENAPER sin red | `Fatal error` de PHP (HTML) | `Fatal error` de PHP |
| RENAPER sin respuesta | `Fatal error` a los 10,2 s | Ídem |
| RENAPER responde con error | **JSON con apariencia de éxito**: fecha `31-12-1969`, edad 56 | Registra con fecha `1969-12-31` |
| Recurso local caído (B2) | `'0'` "No se encontraron coincidencias", igual que sexo equivocado | — |

La app trata las respuestas que no son JSON como "Sin conexión"
(`beneficiario_providers.dart:34-40`). El caso peligroso es el de RENAPER
respondiendo con error: pasa como éxito.

## 5. `wserv_registrar_vacuna.php`: efectos por registro

Verificado con una copia de prueba seca que captura las escrituras sin ejecutarlas.

1. `INSERT` en `sys_desa_99_cab_nomivac_pruebas` (tabla de **pruebas**; el `INSERT` a
   producción está comentado).
2. `UPDATE` de stock en `sys_desa_18_cab_lotes` y `INSERT` de movimiento: **tablas reales**.
3. `POST` a NOMIVAC nacional (`apisalud.msal.gob.ar/nomivacAplicacion/v1/aplicaciones/alta/`).
4. `UPDATE sys_desa_10_cab_nomivac SET sysdesa10_estado=… WHERE id_sysdesa10=<id del
   INSERT en la tabla de pruebas>`. **El id pertenece a otra tabla** (leído en el código:
   puede cambiar el estado de un registro real ajeno).
5. `INSERT` de informe y, según el caso, de auditoría.

Qué se guardaría hoy, en modo escaneo:

| Caso | Edad guardada | Fecha de nacimiento | Lo que recibe NOMIVAC |
|---|---|---|---|
| QR o PDF417, sexo correcto | **56** | La completa RENAPER en el chequeo de fallecidos | Fecha correcta |
| QR con **sexo equivocado** | 56 | `0000-00-00` | sexo equivocado y `fechaNacimiento: null` |
| RENAPER responde con error | 56 | `1969-12-31` | `31-12-1969` |
| RENAPER sin red o sin respuesta | — | — | No registra: `Fatal error` |

La app manda al registro la edad y la fecha **que devolvió el API**, no las del
escaneo (`vacunas_page.dart:3512-3515`).

## 6. Pendientes

- **Rechazos de SISA/NOMIVAC**: los payloads inválidos de arriba son candidatos, pero
  hay que leer las respuestas guardadas en `sys_info_01_cab_informes` para confirmarlo.
- Probar el recurso local con alguien que no esté en el padrón de Formosa.
- La app muestra la fecha del QR tal cual (`07/02/80`) en la ficha (`vacunas_page.dart:1088`).
- Credenciales escritas en el código de los PHP (federador y NOMIVAC).
