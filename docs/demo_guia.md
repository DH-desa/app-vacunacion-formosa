# Guía — Demo educativa de la app de Vacunación Formosa

Demo que corre la **misma app real** sin tocar el backend de producción
(`dh.formosa.gob.ar`). Todo el tráfico HTTP lo intercepta un backend falso
que responde con JSON que respeta las claves exactas que la app espera. Se
puede usar sin miedo, equivocarse y registrar vacunas: **cero impacto en BD**.

## Cómo correr la demo

Requisitos: **Android físico con depuración USB** y cámara (el escáner de DNI
usa la cámara real; no funciona en emulador).

```bash
flutter run -d <id-dispositivo> --flavor demo -t lib/demo/main_demo.dart
```

Sin `--flavor demo`, Gradle no sabe qué variante instalar (hay dos:
`demo` y `prod`, con `applicationId` distinto) y puede terminar
actualizando el APK equivocado en el teléfono — la app que abrís sigue
siendo la build vieja aunque la compilación haya "terminado bien". El
`-t` solo cambia el entry point (código), el `--flavor` cambia qué APK
se instala; hacen falta los dos juntos.

### Build por entorno (Android)

Hay dos flavors: `demo` y `prod`. Demo apunta al backend falso
(`lib/demo/main_demo.dart`) y se identifica visualmente como
"**DEMO Sistema Vacunación**". Prod impacta en la BD real. Los flavors usan
`applicationIdSuffix=".demo"` (id `com.mindh.vacunacion.demo` vs
`com.mindh.vacunacion`) y `versionNameSuffix="-demo"`, así conviven
instalados en el mismo teléfono.

Antes de buildear, regenerá los íconos con la config correspondiente
(ambos comandos sobreescriben `android/app/src/main/res/mipmap-*`):

```bash
# Producción (ícono normal, "Sistema Vacunación")
dart run flutter_launcher_icons
flutter build apk --flavor prod -t lib/main.dart

# Demo (ícono con badge DEMO, "DEMO Sistema Vacunación")
dart run flutter_launcher_icons -f flutter_launcher_icons-demo.yaml
flutter build apk --flavor demo -t lib/demo/main_demo.dart
```

Para volver a producción:

```bash
flutter run --flavor prod            # o flutter build apk --flavor prod
```

El flavor sigue haciendo falta aunque no uses `-t`: una vez que
`android/app/build.gradle` define `flavorDimensions`, Gradle ya no tiene un
default implícito, así que `flutter run`/`flutter build apk` sin `--flavor`
también quedan ambiguos en producción.

Sin `-t`, Flutter ejecuta `lib/main.dart`, que **no** interpone el backend
falso: la app habla con `dh.formosa.gob.ar` como siempre. La intercepción
vive exclusivamente en `lib/demo/main_demo.dart` (vía `http.runWithClient`),
no dentro de `MyApp`. Un APK de release normal (sin `-t`) no incluye el
entry point de demo en su árbol de ejecución.

---

## Cómo se ven las cosas en modo DEMO

La app se ve **idéntica a producción**: mismo flujo, mismos pantallazos, sin
botones extra, sin banners, sin panel de debug. La única diferencia es que
el backend responde con datos ficticios. El operador la usa como la real:
escanea DNIs, busca beneficiarios, completa los 8 pasos, registra.

Las validaciones de error se disparan solas con datos específicos del
catálogo de la demo (vacunas y DNIs designados), no con botones externos.

---

## DNI de muestra

Todos ficticios. El backend falso responde según el DNI con datos coherentes
(fecha de nacimiento alineada con la fecha de la demo: 2026-08-13) para que
el **Calendario Nacional 2026** clasifique a cada persona en la fila etaria
correcta y genere las vacunas pendientes correspondientes.

### Beneficiario (ingreso manual o escaneo)

| DNI | Persona | Edad | Calendario 2026 (pendientes) |
|---|---|---|---|
| `11111112` | Mateo Gómez, M | Recién nacido | BCG, Hepatitis B |
| `11111113` | Sofía Ruiz, F | 6 meses | Neumococo 3ra, Quíntuple 3ra, Antigripal |
| `11111114` | Diego López, M | 12 meses | Neumococo refuerzo, Antigripal, Hepatitis A, Triple Viral 1ra |
| `11111115` | Valentina Martínez, F | 15 meses | Quíntuple refuerzo, Meningococo refuerzo, Antigripal, Triple Viral 2da, Varicela 1ra |
| `11111116` | Bruno Pérez, M | 18 meses | Antigripal |
| `11111117` | Emma Sánchez, F | 5 años (2021) | IPV refuerzo, Triple Viral 2da, Varicela 2da, Triple Bacteriana Celular 2do refuerzo |
| `11111118` | Tomás Torres, M | 11 años (2015) | Meningococo, Triple Bacteriana Acelular, VPH, Fiebre Amarilla |
| `11111119` | Camila Acosta, F | 15 años | Triple Viral, Fiebre Hemorrágica Argentina |
| `11111120` | Juan Díaz, M | 36 años | Hepatitis B, Neumococo, Antigripal, Triple Viral, Doble Bacteriana, FHA |
| `22222222` | Carla Romero, F, embarazada | 31 años | Antigripal, Triple Bacteriana Acelular, VSR (+ filas adulto) |
| `33333333` | Laura Vega, F, puérpera | 33 años | Antigripal, Triple Viral (+ filas adulto) |
| `44444444` | Roberto Castro, M, personal de salud | 38 años | Antigripal, Triple Viral, Triple Bacteriana Acelular (+ filas adulto) |
| `11111111` | Lucía Fernández, F | 35 años | Igual que adulto genérico (compatibilidad) |
| `99999999` | No encontrado | — | "No se encontró el beneficiario" |

**Vacunador**: cualquier DNI OK · `30000002` inválido.

Las pendientes se generan dinámicamente: al cargar un beneficiario, la app
recibe las vacunas que le corresponden según su edad, sexo y condición
(embarazada/puérpera/personal de salud), igual que haría el backend real con
el Calendario Nacional 2026.

---

## Matriz de validaciones (todas alcanzables por input)

| # | Pantalla | Validación | Cómo se dispara | Mensaje esperado |
|---|---|---|---|---|
| 1 | Escáner | Cámara no disponible | Revocar permiso de cámara y escanear | "No se pudo abrir la cámara" + pop automático |
| 2 | Búsqueda beneficiario | DNI incompleto | Ingreso manual: 6 dígitos, "Verificar datos" | "Datos incompletos — D.N.I. de al menos 7 dígitos y sexo indicados." |
| 3 | Búsqueda beneficiario | Sexo obligatorio | Ingreso manual: DNI ≥7, sin elegir sexo, "Verificar" | "Datos incompletos — ...y sexo indicados." |
| 4 | Búsqueda beneficiario | No encontrado | Ingreso manual DNI `99999999` + sexo, confirmar | "No se pudo continuar — No se encontró el beneficiario..." |
| 5 | Búsqueda beneficiario | Menor → tutor obligatorio | Ingreso/escaneo DNI pediátrico (`11111112`–`11111116`) → entrar a VacunasPage | Banner "Menor de edad: falta cargar el tutor" |
| 6 | Equipo de trabajo | Vacunador inválido | Switch "mismo vacunador" NO → DNI `30000002` | "No se pudo validar el vacunador — El DNI no corresponde..." |
| 7 | Vacunas paso 6 | Sin lotes | Elegir vacuna **Fiebre Hemorrágica Argentina** (36) → elegir fecha → Continuar | "Sin lotes disponibles" + Cambiar vacuna / Cambiar dosis |
| 8 | Vacunas paso 6 | Error lotes | Elegir vacuna **Fiebre Amarilla** (35) → elegir fecha → Continuar | "No se pudieron cargar los lotes" + Reintentar / Cambiar vacuna |
| 9 | Vacunas paso 8 | Faltan datos | Antes de completar todos los pasos → "Registrar" | "Faltan datos para continuar" (específico: vacuna/condición/esquema/dosis/lote/tutor) |
| 10 | Vacunas paso 8 | Vacuna ya registrada | Registrar "Hepatitis B / 1ra Dosis" (ya figura en historial) | "Vacuna ya registrada — ¿Continuar igual?" |
| 11 | Registro (paso 8) | POST fallido | Completar todo el flujo con **Fiebre Amarilla** (35) → Registrar | "Atención — No se pudo registrar..." + Reintentar |
| 12 | Cualquiera | Sin conexión | Activar **modo avión** en el teléfono → cualquier acción con API | "Sin conexión" / "Error de conexión" |

### Vacunas que disparan errores (catálogo designado)

| Vacuna | id | Comportamiento en la demo |
|---|---|---|
| Fiebre Hemorrágica Argentina | 36 | Lotes vacíos → "Sin lotes disponibles" (paso 6) |
| Fiebre Amarilla | 35 | Lotes con error `codigo_mensaje '0'` (paso 6) + POST falla al registrar (paso 8) |

El resto de las vacunas del catálogo 2026 (BCG, Hepatitis B, Antigripal,
COVID-19, etc.) funcionan como happy path completo de 8 pasos.

---

## Validaciones no alcanzables en la demo

| Validación | Por qué |
|---|---|
| Login: "No se pudo iniciar sesión" (no autorizado) | El login es solo escaneo; no hay formulario manual de DNI del registrador. Un DNI real escaneado siempre llega válido al fake. |
| Login: "Datos incompletos en el servidor" (sin efector) | Ídem: no hay path de input que devuelva `sysofic01_descripcion = null` sin un DNI designado, y escanear un DNI propio siempre llega OK. |
| Login: "Actualice la aplicación" | Código muerto: `validarVersionNuevaVersion` está definido pero no se invoca; `versionApp` se hardcodea en `'Ok'` al iniciar y nunca cambia. |
| Vacunas paso 1: lista de perfiles vacía | Los perfiles dependen del registrador logueado, que siempre llega OK. Sin UI para inyectar un error por input. |

Estas validaciones **sí** son demostrables en modo `'DEV'` (con el botón DESA
del login y el DevOverlay), que es el entorno de desarrollo puro, no la demo
educativa. En modo `'DEMO'` quedan fuera del alcance.

---

## Cómo desactivar las validaciones de la demo (happy path completo)

Si querés grabar una demo de corrido o probar el flujo de 8 pasos sin
trabarzos por validaciones de error, hay dos formas:

### 1. Toggle global (recomendado)

`lib/demo/demo_fake_http_client.dart` tiene una constante que apaga todas las
validaciones de la matriz de arriba en un solo cambio:

```dart
const bool kDemoValidations = true;   // cambialo a false para happy path
```

Con `kDemoValidations = false`:

- Los DNIs designados a fallar (`30000000`, `30000001`, `30000002`, `99999999`)
  caen al branch de éxito.
- La vacuna 36 (FHA) devuelve lotes en vez de lista vacía.
- La vacuna 35 (Fiebre Amarilla) devuelve lotes OK y el POST de registro
  devuelve éxito.

Cero impacto en producción: la constante vive en el backend falso, no en
`MyApp`. Un APK con `--flavor prod` no incluye este archivo en su
compilación.

### 2. Por validación individual (más fino)

Si querés mantener algunas validaciones pero quitar otras, editá la
condición específica en `lib/demo/demo_fake_http_client.dart`:

| Validación | DNI / Vacuna | Líneas | Cómo desactivarla |
|---|---|---|---|
| Login: sin permisos | `30000000` | ~592 | Borrar `kDemoValidations &&` |
| Login: sin efector | `30000001` | ~602 | Borrar `kDemoValidations &&` |
| Vacunador inválido | `30000002` | ~641 | Borrar `kDemoValidations &&` |
| Beneficiario no encontrado | `99999999` | ~109 | Borrar `kDemoValidations &&` |
| Lotes vacíos | Vacuna 36 (FHA) | ~728 | Borrar `kDemoValidations &&` |
| Error lotes | Vacuna 35 (FA) | ~730 | Borrar `kDemoValidations &&` |
| Registro falla | Vacuna 35 (FA) | ~748 | Borrar `kDemoValidations &&` |

Las líneas son aproximadas: si modificaste el archivo pueden haber
corrido. Buscá por el DNI o el id de vacuna (`"35"`, `"36"`).

---

## Catálogo de vacunas de la demo

18 vacunas del Calendario Nacional 2026, cada una con condiciones, esquemas,
dosis y lotes coherentes. La vía **Pendientes** (4 pasos) en VacunasPage
muestra las vacunas que corresponden al beneficiario según edad, sexo y
condición, generadas dinámicamente por el backend falso.

---

## Archivos relacionados

- `lib/demo/main_demo.dart` — entry point de la demo (entorno `'DEMO'`).
- `lib/demo/demo_fake_http_client.dart` — backend falso con calendario 2026
  y constante `kDemoValidations` para el toggle de validaciones.
- `flutter_launcher_icons-demo.yaml` — config del icono con badge "DEMO".
- `assets/logo/logo_demo.png` — logo con badge "DEMO" generado.

Ningún codepath de producción se modifica: el entorno `'DEMO'` es distinto
de `'DEV'` y `'PROD'`. El botón DESA y el DevOverlay solo se montan en
`'DEV'`; en `'DEMO'` la app se ve igual que en `'PROD'`.