# Informe — corrección de los registros con QR y hallazgo sobre la fecha de aplicación

Fecha: 21/09/2026. Base: `desarrollo_humano`, producción.
Todas las cifras de este informe salen de consultas de sólo lectura ejecutadas por el
administrador del IDE. Las escrituras las corrió el usuario desde DBeaver.
Lo no verificado está en la última sección, marcado como tal.

## 1. Qué se corrigió

El QR del DNI 2026 se parseaba como si fuera PDF417: el número de documento quedaba
guardado en la columna `sysdesa10_sexo` y la fecha de nacimiento en `1969-12-31`.
NOMIVAC rechazaba esos envíos por sexo inválido.

Estado al empezar, con filtro `sysdesa10_cadena_dni LIKE '%eyJ%' AND sysdesa10_estado = 2`:

| | Filas | Documentos |
|---|---|---|
| Total rechazadas | 184 | 73 |
| Con el defecto presente (`sysdesa10_sexo = sysdesa10_dni`) | 174 | 71 |
| Ya corregidas en la sesión anterior, aún rechazadas | 10 | 2 |

Se corrigieron **69 documentos / 169 filas**, con una sentencia `UPDATE` por documento
(sexo, fecha de nacimiento, edad recalculada y enlace a la persona). Se usó una sentencia
por documento porque las versiones masivas con `UNION ALL` y con `CASE` daban
`SQL Error [1064]` en el cliente; la causa de ese error **no se determinó**, y la misma
consulta parseaba bien del lado del servidor.

Quedaron fuera **2 documentos / 5 filas**:

- uno con 4 filas, excluido porque el padrón provincial y RENAPER se contradicen sobre su identidad;
- uno con 1 fila, al que nunca se le resolvió la identidad.

### Cambio respecto del plan previsto

El plan traía 5 `INSERT` en `sys_desa_06_cab_personas` para documentos supuestamente
ausentes del padrón. **No se ejecutó ninguno**: los cinco ya existían en producción, con
el sexo correcto y tipo de documento 1. Correrlos habría duplicado personas.

También se corrigió el alcance: el plan hablaba de 70 documentos / 170 filas; el número
real es **69 / 169**. El documento sobrante nunca tuvo identidad resuelta.

### Verificación posterior

```sql
SELECT ... FROM desarrollo_humano.sys_desa_10_cab_nomivac
WHERE sysdesa10_sexo = sysdesa10_dni GROUP BY sysdesa10_estado;
→ estado 2 : 5 filas , 2 docs
```

El filtro va sobre la tabla entera, sin restringir por QR ni por estado: los únicos
registros con el defecto son los 2 excluidos a propósito. **No apareció ninguno nuevo.**

## 2. Cuánto se informó a NOMIVAC

El usuario informó los registros manualmente, uno por uno.

| | Filas | Documentos |
|---|---|---|
| Conjunto QR en estado 2, antes | 184 | 73 |
| Conjunto QR en estado 2, después | 20 | 6 |
| **Aceptadas** | **164** | |

La cuenta cierra: 184 = 164 aceptadas + 15 corregidas pero aún rechazadas + 5 sin corregir.

### Las 15 que siguen rechazadas

Cuatro documentos quedaron en estado 2 pese a tener sexo, fecha de nacimiento y enlace a
persona correctos: dos venían rechazados desde la sesión anterior (9 y 1 filas) y dos se
corrigieron ahora (4 y 1 filas). **La causa no está determinada.** Descarta la hipótesis de
"no se reenviaron": el fenómeno se repite con registros corregidos hoy.

## 3. Duplicados: no se generaron

Riesgo conocido: reenviar un registro que ya tiene un gemelo aceptado duplica la dosis en
el registro nacional. Clasificación de las 164 aceptadas, con el criterio de
`estado_2026-09-18.md` (gemelo = misma persona, misma configuración de vacuna):

| | Filas | Resultado |
|---|---|---|
| A. Gemelo aceptado el mismo día, efector y lote | 32 | **NOMIVAC unificó las 32** |
| B. Gemelo aceptado en otro día | 13 | criterio clínico |
| C. Sin gemelo aceptado | 119 | faltaban de verdad |

La unificación no se dedujo del comportamiento histórico: se verificó registro por registro
en `sys_info_01_cab_informes`. Cada envío devolvió `OK ... idSniAplicacion: <n>`, y en los
32 pares ese número coincide con el que ya tenía el gemelo. Cero duplicados.

De las 13 de la categoría B, doce tienen entre 30 y 1073 días de diferencia con su gemelo
(dosis posteriores normales). **Una tiene un día de diferencia** —misma persona, misma
vacuna, días consecutivos— y conviene revisarla.

### Nota metodológica

`sysdesa10_fecha_aplicacion` es un **datetime con hora**. Comparar el valor completo hace
que dos registros del mismo día nunca coincidan, y produce un falso "0 duplicados". Para
agrupar por día hay que usar `DATE(...)`. El primer cálculo de este informe salió mal por
ese motivo y se rehizo.

## 4. Hallazgo aparte: el servidor acepta fechas de aplicación futuras

### El caso

Un registro (`id_sysdesa10 = 7298616`) tiene fecha de aplicación **28/09/2026**, posterior
al día de hoy. Se creó el **04/09/2026** y ya nació con esa fecha: las dos peticiones a
NOMIVAC de ese día (ids 8548335 y 8548380, 08:55 y 08:59) llevan
`fechaAplicacion => 28-09-2026`. **No fue modificado después.**

NOMIVAC lo rechazó con: `ERROR_DATOS - La fecha de aplicación debe ser menor o igual al día de hoy`.

### La causa: la regla existe en un solo lado

La restricción "no futuro" está **únicamente en el navegador**. En
`ver_registro_vacunas_abm_v2.php` (IDE id 335186):

```php
línea 351 (rama update):  $dateMax="dateMax:'+0D',";
línea 438 (rama add):     $dateMax="dateMax:'+0D',";
```

y se inyecta en la definición del campo `sysdesa10_fecha_aplicacion` (línea 1035).

Del lado del servidor **no hay ningún control**. El formulario declara su validador en la
línea 29 del mismo archivo:

```php
$urlValidator="modulos/registro_vacunas/php/urlValida.php";
```

`urlValida.php` tiene 206 líneas y ocho cortes por error. Ninguno compara la fecha contra
hoy: su único control de fechas es que el lote no esté vencido (líneas 176-189). La única
comparación contra una fecha fija, en la línea 151, está **comentada**.

Conclusión: si el tope del navegador no actúa, el valor entra a la base sin que nada más lo
mire. **NOMIVAC fue la única capa que lo detectó.**

### Efecto secundario en la edición

Como el tope no puede representar una fecha fuera de rango, al abrir ese registro el
formulario de edición muestra **hoy, sin hora**, en vez del valor guardado. La grilla
muestra el valor real. **Guardar desde ese formulario pisaría la fecha con la del día.**

### Magnitud

Filas con `DATE(sysdesa10_fecha_aplicacion) > sysdesa10_fecha_alta`, algo imposible porque
la vacuna no puede aplicarse después de que se cargue el registro:

- **311 filas, 247 personas**, entre 2020 y 2026, en 124 registradores y 51 efectores.
- 202 aceptadas por NOMIVAC, 109 rechazadas.
- Sólo **1** tiene fecha posterior a hoy; las otras 310 tienen fechas pasadas y NOMIVAC no las objeta.
- `sysdesa10_fecha_alta` sí es la fecha de creación: no hay ningún informe anterior a ella, y 250 de las 311 se informaron el mismo día del alta.
- La tasa es prácticamente igual por las dos vías de carga: 0,024 % por el app, 0,018 % por la web. **No es un defecto de una sola vía.**

### Las dos vías de carga

Sirve para atribuir un registro sin suponer. En `sys_desa_10_cab_nomivac`, dos columnas se
comportan como firma del `INSERT` que creó cada fila, y nunca se mezclan:

| Firma | Vía | Filas en 2026 |
|---|---|---|
| `sysdesa10_cadena_dni` y `sysdesa10_terreno` **ambas NULL** | módulo web | 253.958 |
| ambas con valor | app móvil | 66.066 |

Una cadena de documento escaneada sólo la produce el app, y esas filas siempre tienen
`terreno` puesto. `terreno` por sí solo no sirve: su `DEFAULT` es NULL.

### Descartado

Los tres archivos de edición masiva del módulo **no tocan** la fecha de aplicación:

- `onSubmit_ActDatos.php`: `SET` fijo con apellido, nombre, dni, fecha de nacimiento y sexo.
- `onSubmit_ActDatos_v2.php`: `SET rela_sysdesa06` y nada más.
- `actualizar_datos_multiples.php`: `SET` dinámico, pero armado sólo con efector, configuración y lote (líneas 22-39).

### Dónde iría el arreglo

En `urlValida.php`: es el único punto por el que pasa todo guardado del formulario, y hoy
no mira la fecha.

## 5. Sin verificar y sin hacer

- **Por qué siguen rechazadas las 15 filas de 4 documentos** con datos correctos.
- **Cómo el navegador llegó a enviar 28-09-2026 con el tope puesto.** Se revisaron las tres plantillas del formulario: el único código que escribe ese campo lo vacía, y la asignación de la fecha de hoy está dentro de `if (esAdd)`. No se encontró código que escriba una fecha futura. La hipótesis de que el operador haya tipeado la fecha en vez de elegirla del calendario —`maxDate` limita el calendario, no el texto tipeado— **no se verificó**.
- **Los 2 documentos excluidos** (5 filas): uno necesita resolver la contradicción entre padrón y RENAPER, el otro necesita que se le resuelva la identidad.
- **La fila de categoría B con un día de diferencia**, posible duplicado real.
- **Las 109 filas rechazadas** del conjunto de fechas imposibles: no se analizaron.
- No se pudo auditar quién cargó qué: `sys_info_09_cab_auditoria` tiene 70 filas, todas de 2022, y `agregar_control()` sólo se llama en las ramas de error.

## 6. Incidente operativo

Durante la investigación se lanzaron contra producción tres consultas con subconsulta
correlacionada sobre `sys_desa_10_cab_nomivac` sin filtro que restringiera. Superaron el
tiempo de espera del cliente y siguieron corriendo en el servidor. Inmediatamente después,
el IDE dejó de responder por completo durante unos minutos: el TCP conectaba al instante y
el HTTP devolvía 0 bytes, incluso para un `SELECT 1`. Se recuperó solo.

**No está probado que las consultas lo hayan causado**, sólo que coincidieron en el tiempo.
Todo lo ejecutado fue de lectura; el administrador del IDE bloquea escrituras en producción
por diseño. Para adelante: acotar por fecha o por clave cualquier consulta sobre esta tabla,
que tiene más de 1,3 millones de filas sólo en 2021.
