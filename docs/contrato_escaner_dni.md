# Contrato — Componente EscanerDni

## Descripción

`EscanerDni` es un widget botón que abre la cámara, lee el código de barras PDF417
del DNI argentino y, según el `tipoEscaneo`, ejecuta una acción contra la API
o actualiza el estado local del servicio correspondiente.

---

## Formato del DNI argentino — PDF417

El DNI argentino **solo usa PDF417**. No hay QR ni Code128 en ninguna versión emitida.

### Tarjeta nueva (plástico, desde 2009/2012) — código en el **frente**

Campos separados por `@`. **8 campos** base; con CUIL parcial **9 campos**.

| Índice | Campo | Ejemplo |
|--------|-------|---------|
| `[0]` | Número de trámite | `00123456789` |
| `[1]` | Apellido/s | `GARCIA` |
| `[2]` | Nombre/s | `JUAN PABLO` |
| `[3]` | Sexo | `M` · `F` · `X` |
| `[4]` | Número de DNI | `12345678` |
| `[5]` | Ejemplar | `A` |
| `[6]` | Fecha de nacimiento | `15/06/1990` |
| `[7]` | Fecha de emisión | `10/03/2022` |
| `[8]` | CUIL parcial (opcional) | `203` |

### Tarjeta anterior (cartón, pre-2009) — código en el **reverso**

**16 o 17 campos** separados por `@`.

| Índice | Campo |
|--------|-------|
| `[1]` | Número de DNI |
| `[4]` | Apellido |
| `[5]` | Nombre |
| `[7]` | Fecha de nacimiento |
| `[8]` | Sexo |
| `[9]` | Fecha de emisión |
| `[12]` | Fecha de vencimiento |

### Restricciones de codificación

- Sin tildes ni ñ. Renaper usa sustituciones: `NUÑEZ → NUXXEZ`, `AGÜERO → AGUXXERO`.
- Encoding: ISO-8859-1 (Latin-1). El plugin puede entregar el texto como UTF-8; el
  widget resuelve el encoding mediante `decodificarCadenaPdf417Argentino`.
- Género válido: `M`, `F`, `X` (no binario, habilitado por Renaper desde 2021).

---

## API pública del widget

```dart
EscanerDni(
  tipoEscaneo,   // String — ver valores válidos abajo
  textoBoton,    // String — etiqueta del botón
  anchoValor,    // double? — alto del botón (default 40)
  largoValor,    // double? — ancho del botón (default ∞)
  iconBool,      // bool?  — mostrar ícono de código de barras (default true)
)
```

---

## Valores válidos de `tipoEscaneo`

### `'Registrador'`

**Precondición:** la pantalla de login está activa.

**Flujo:**
1. Lee PDF417 → extrae DNI.
2. Llama `usuariosProviers.validarUsuariosNuevo(dni)`.
3. Si `flxcore03_dni == ''` → muestra error.
4. Si `sysofic01_descripcion == null` → muestra error de datos incompletos.
5. Si `datosdecargaprovider.versionApp != 'Ok'` → obliga actualizar.
6. Si todo OK → carga `registradorService` y navega a `VacunadorPage` (elimina stack).

**Postcondición exitosa:** `registradorService` cargado; usuario en `VacunadorPage`.

**Servicio que toca:** `registradorService`, `loadingLoginService`.

---

### `'Vacunador'`

**Precondición:** `VacunadorPage` activa; registrador ya validado.

**Flujo:**
1. Lee PDF417 → extrae DNI.
2. Llama `vacunadorProviders.validarVacunador(dni)`.
3. Si `codigo_mensaje == '0'` → muestra error.
4. Si OK → carga `vacunadorService`; muestra SnackBar de confirmación.

**Postcondición exitosa:** `vacunadorService` cargado; usuario permanece en `VacunadorPage`.

**Servicio que toca:** `vacunadorService`, `loadingLoginService`.

---

### `'Beneficiario'`

**Precondición:** `BusquedaBeneficiario` activa; registrador y vacunador validados.

**Diferencia de UX:** antes de salir de la cámara se muestra un panel de confirmación
in-camera con DNI y sexo; el operador debe confirmar antes de consultar la API.

**Flujo:**
1. Lee PDF417 → extrae DNI, sexo, nombre, apellido, fecha nac.
2. Panel de confirmación (solo este tipo lo tiene).
3. Muestra loading sobre la pantalla anterior (dialog no dismissible).
4. Llama `beneficiarioProviders.obtenerDatosBeneficiario(codigodebarras, dni, sexo)`.
5. Llama `notificacionesProvider.validarNotificaciones(dni, sexo)`.
6. Si OK → carga `beneficiarioService` y `notificacionesDosisService`; navega a `VacunasPage` (elimina stack).
7. Si error → cierra loading; muestra dialog de red.

**Postcondición exitosa:** `beneficiarioService` cargado; usuario en `VacunasPage`.

**Servicio que toca:** `beneficiarioService`, `notificacionesDosisService`, `loadingLoginService`.

---

### `'Tutor'`

**Precondición:** `VacunasPage` activa; beneficiario principal ya cargado.

**Flujo:**
1. Lee PDF417 → extrae DNI, sexo, nombre, apellido.
2. Llama `beneficiarioProviders.obtenerDatosBeneficiario(codigodebarras, dni, sexo)`.
3. Si `codigo_mensaje == '0'` → lanza Exception con el mensaje del servidor.
4. Si OK → carga `tutorService`; muestra SnackBar de confirmación.

**Postcondición exitosa:** `tutorService` cargado; usuario permanece en `VacunasPage`.

**Servicio que toca:** `tutorService`, `loadingLoginService`.

---

## Comportamiento del escáner (pantalla de cámara)

| Parámetro | Valor | Razón |
|-----------|-------|-------|
| Formato | `Format.pdf417` | El DNI argentino no usa otros formatos |
| Resolución | `ResolutionPreset.high` | PDF417 requiere resolución suficiente |
| `tryHarder` | `false` | PDF417 impreso en plástico no necesita multipaso |
| `tryDownscale` | `true` | Ayuda en documentos lejanos sin costo notorio |
| `tryInverted` | `true` | Algunos PDF417 argentinos leen mejor en negativo |
| `scanDelay` | `240 ms` | Balance entre intentos y frames movidos |
| `cropPercent` | `1.0` | El PDF417 puede ocupar todo el encuadre |

El marco visual es solo guía. La decodificación usa todo el encuadre (`cropPercent 1.0`).

---

## Invariantes

- Si `dniPersona == null` tras el parseo (formato no reconocido), **ningún tipo** llama a la API.
- Cancelar la cámara (back o pop null) no modifica ningún servicio.
- El género puede ser `M`, `F` o `X`; el widget lo pasa tal cual a la API.
  Si la API no soporta `X`, el manejo corresponde al servidor, no al widget.
- Encoding del payload: si el plugin entrega texto corrupto (mojibake), se reintenta
  con Latin-1 sobre `rawBytes` antes de aceptar la cadena.

---

## Errores conocidos y límites

| Caso | Comportamiento |
|------|---------------|
| Cámara no disponible / sin permiso | Dialog informativo + pop automático |
| Formato de DNI no reconocido | Dialog de error; no llama a la API |
| Error de red en validación | Dialog "Sin conexión" |
| DNI con ñ/tildes | Recibe versión sin tilde (ej. `NUXXEZ`); la API resuelve el nombre real |
| DNI género X | Se extrae y pasa `'X'` a la API |
