# Contrato — Sesión de vacunación (ciclos de estado y flujo de carga)

Documento de estado vivo. Describe cómo funciona el flujo de carga de un registro
de vacunación y los ciclos de vida del estado en memoria. Todo lo afirmado está
verificado en código con cita `archivo:línea`. Lo no verificado se marca explícito.

Análisis de origen: 2026-07-03, rama `actualizacion2026`.

---

## Los tres ciclos de vida del estado

El estado en memoria vive en singletons `Estado<T>` (`lib/src/presentation/state/`).
Se agrupa en tres ciclos, de mayor a menor duración:

| Ciclo | Nace | Muere | Contiene |
|-------|------|-------|----------|
| **Largo (cuenta/equipo)** | Login / pantalla «Equipo de trabajo» | Logout manual (`drawer_page.dart:110`) | tema, enviroment, vacunador, registrador, efectores, `sesionEquipoVacunacionService` (enTerreno), cantidadVacunados (`estado_sesion.dart:30-32`) |
| **Persona (`estadosPorPersona`)** | Al cargar un beneficiario | Al buscar otro beneficiario — `reiniciarCicloBeneficiario()` | beneficiario, edad y fecha nac. del PDF417, tutor, situación (condición gestacional + personal de salud), historial de dosis (notificaciones), perfil de vacunación elegido, **vacunas registradas en la visita** (`estado_sesion.dart:19-34`) |
| **Vacuna (`estadosPorVacuna`)** | Al iniciar la carga de una vacuna | Entre dosis de la misma persona — `reiniciarCicloVacuna()` — y al cambiar de persona | lista de perfiles disponibles, vacunas, lotes, dosis, condiciones, esquemas, vacunas×perfil, insertRegistro, flags de loading (`estado_sesion.dart:35-58`) |

**Punto único de reinicio del ciclo persona**: `busquedabeneficiario_page.dart:41`
(`initState` de `BusquedaBeneficiario`). Ningún otro lugar llama
`reiniciarCicloBeneficiario()`.

**Punto único de reinicio del ciclo vacuna** (sin cambiar de persona):
`vacunas_page.dart`, `_registrarVacunacion()`, botón «Sí, otra vacuna».

La «sesión de vacunación» (cargar la persona una vez, registrar varias vacunas)
está implementada como: ciclo persona + pregunta post-registro
«¿Aplicar otra vacuna a la misma persona?» (`vacunas_page.dart`, `_registrarVacunacion()`).

---

## Flujo de carga completo

### 1. Entrada del beneficiario — dos vías

**Vía escaneo** (`_modoEscaneo`, `busquedabeneficiario_page.dart:205`):

1. `EscanerDni` lee el PDF417 y parsea localmente apellido, nombre, DNI, sexo,
   trámite y — según formato de tarjeta — edad y fecha de nacimiento
   (`escanerdni_widget.dart:544-559`).
2. Llama al back `obtenerDatosBeneficiario(codigodebarras, dni, sexo)`
   (`escanerdni_widget.dart:497-498`).
3. Fusiona nombre/apellido de la API con los del escaneo si la API viene corrupta
   (`escanerdni_widget.dart:487-493`).
4. `cargarBeneficiario(...)` guarda el beneficiario **más** edad y fecha nac. del
   PDF417 como fuentes propias (`escanerdni_widget.dart:507-511`,
   `usuariobeneficiario_service.dart:21-31`).
5. `validarNotificaciones` carga el historial de dosis aplicadas
   (`escanerdni_widget.dart:514-520`).
6. Control vuelve a `BusquedaBeneficiario` vía `onBeneficiarioCargado`
   (`escanerdni_widget.dart:523-527`): muestra resumen solo-lectura, bloque
   Situación y botón Continuar (`busquedabeneficiario_page.dart:223-247`).
7. «Continuar» guarda la situación en el service y navega a `VacunasPage`
   (`busquedabeneficiario_page.dart:315-325`).

**Vía manual** (`_modoManual`, `busquedabeneficiario_page.dart:328`):

1. Operador escribe DNI (≥7 dígitos) y elige sexo; sin default, elección
   obligatoria — «Verificar datos» no avanza sin sexo elegido
   (`formulario_documento_widget.dart:77`, `176-179`).
2. Bloque Situación visible; condición gestacional solo si sexo = F; al cambiar
   a sexo ≠ F la condición se anula (`formulario_documento_widget.dart:83-89`).
3. «Verificar datos» guarda la situación en el service **antes** de consultar el
   padrón (`formulario_documento_widget.dart:176-187`).
4. Diálogo de confirmación DNI+sexo (`busquedabeneficiario_page.dart:343-368`).
5. Back responde persona con `sysdesa10_edad` y `sysdesa10_fecha_nacimiento`;
   si `codigo_mensaje == '0'` frena con error (`busquedabeneficiario_page.dart:392`).
6. Carga notificaciones (`busquedabeneficiario_page.dart:378-390`) y navega a
   `VacunasPage` (`busquedabeneficiario_page.dart:447-454`).

### 2. Determinación de edad y tutor

Prioridad de fuente de edad (`vacunas_page.dart:2330-2344`):

1. Edad en años del PDF417 escaneado.
2. `sysdesa10_edad` de la API (parseo tolerante: `edad_beneficiario.dart:11-22`,
   ignora valores > 120).
3. Edad calculada desde `sysdesa10_fecha_nacimiento`
   (`edad_beneficiario.dart:26-56`).

Regla tutor: menor de 18 **o edad no parseable** → panel tutor obligatorio
(`vacunas_page.dart:2342`: sin dato de edad se exige tutor — conservador).
El tutor se valida contra el back (`escanerdni_widget.dart:459-484`). Un
beneficiario nuevo limpia el tutor anterior (`usuariobeneficiario_service.dart:27`).

### 3. Clasificador calendario 2026 (modo prueba)

`clasificarBeneficiarioActual()` (`calendario_2026.dart:160-184`) es función pura
derivada: fecha nac. (PDF417 > API) o edad en años (PDF417 > API), más situación.
Devuelve filas del calendario + flag `edadIndeterminada`. La matriz es
transcripción literal de `docs/calendario_nacional_vacunacion_2026.md`
(`calendario_2026.dart:196-286`).

**Puramente informativo, en bottom sheet** (`_mostrarCalendarioSheet()`,
ícono en el `AppBar`, `Icons.calendar_month_outlined`): antes vivía siempre
expandido en el medio del flujo vertical de `VacunasPage` y era el bloque
más alto de la pantalla, empujando el formulario. No hay ninguna otra
vista que repita esta clasificación: el sheet es la única fuente.

Situación editable sin re-buscar: `_bloqueSituacionInline()` (`vacunas_page.dart`),
reusa `SituacionBeneficiario` contra `situacionBeneficiarioService`
directamente. Vive dentro del bottom sheet de detalle del beneficiario
(`_mostrarDetalleBeneficiarioSheet()`, ver sección 4) — no en una tarjeta
aparte del scroll.

### 4. Layout de `VacunasPage` — banner fijo + sheet único + barra de acciones fija

Reescrito dos veces: primero se agregaron banners y sheets fijos sin
retirar la tarjeta de beneficiario del scroll (`containerBeneficiario()`),
lo que terminó **triplicando** la identidad (banner + tarjeta + sheet) y
duplicando el calendario (chips en la tarjeta + sheet). Ese error quedó
documentado como incoherencia #9 y fue corregido eliminando la tarjeta:
ahora hay una sola fuente por dato, no una copia por pantalla.

- **`_bannerIdentidad()`**: fuera del `SingleChildScrollView` (en un `Column`
  con `Expanded` alrededor del scroll), una línea fija con nombre · DNI (+
  «MENOR» si `_beneficiarioRequierePanelTutor()`). Tocar abre
  `_mostrarDetalleBeneficiarioSheet()` — **único** lugar con el detalle
  completo del beneficiario y la situación editable. No existe ninguna otra
  tarjeta de beneficiario en `VacunasPage`.
- **`_mostrarDetalleBeneficiarioSheet()`**: detalle completo
  (`_filasDetalleBeneficiario`) + situación editable (`_bloqueSituacionInline()`,
  incluye condición gestacional y el switch «Personal de salud» — antes vivía
  en la tarjeta eliminada). Nota de alcance: el switch «Personal de salud» no
  filtra el catálogo de vacunas del paso 2 (`obtenerVacunasxPerfilesProviders`
  no recibe ese parámetro); solo alimenta el calendario informativo y el
  campo `es_personal_salud` del registro. Bajarlo de la tarjeta protagonista
  a este sheet reduce su jerarquía visual a lo que realmente hace.
- **`_bannerAlertaTutor()`**: también fijo, visible solo si
  `_beneficiarioRequierePanelTutor()` y no hay tutor cargado. Tocar
  scrollea hasta `containerTutor()` (`Scrollable.ensureVisible` sobre
  `_tutorSectionKey`) en vez de obligar a bajar a ciegas.
- **`_barraAccionesFija()`** (`bottomNavigationBar` del `Scaffold`): «Cancelar»
  siempre visible + la acción de avance del paso actual, cuando ese paso
  tiene una (paso 6 Fecha → `_cargarLotesYAvanzar`; paso 8 Confirmar →
  `_alPresionarContinuarRegistro` → `_registrarVacunacion`). El segundo slot
  se reserva siempre con `Visibility(maintainSize: true)` aunque no haya
  acción, para que la barra no cambie de alto ni de ancho entre pasos. Los
  demás pasos (Perfil, Vacuna, Condición, Esquema, Dosis, Lote) avanzan solo
  con tocar una opción de la lista, sin botón propio.
- **`_seccionVacunasVisita()`**: línea compacta («N aplicadas en esta
  visita»); tocarla abre el mismo bottom sheet de historial
  (`_mostrarHistorialDosis()`, botón del `AppBar`).

### 5. Registro — wizard de 8 pasos

`containerPasos()` (`vacunas_page.dart`):
1 Perfil · 2 Vacuna · 3 Condición · 4 Esquema · 5 Dosis · 6 Fecha · 7 Lote · 8 Verificar.

- Cascada dependiente: cambiar una selección anula todas las de aguas abajo.
- Header del panel (`VacunasPanelFlujo`, `vacunas_ui_helpers.dart`): badge
  «PASO X DE 8» + `Wrap` de chips compactos **solo de los pasos ya
  completados** (`_ChipCompacto`) — antes una grilla fija de 6 chips de
  56dp en 3 filas, siempre renderizada aunque todo dijera «—». Tocar un
  chip vuelve a ese paso: guard real es `numeroPaso <= pasoActual ||
  tieneValor` en `_ChipCompacto`/`onIrAPaso` (el `VacunasFlujoStepper` con
  guard `n <= pasoActual` que citaba esta sección antes era código muerto,
  eliminado).
- «Cancelar registro» (`_mostrarDialogoCancelarRegistro`, `vacunas_page.dart`,
  disparado desde la barra fija): tres destinos — «Volver» (cierra el
  diálogo), «Salir y buscar otra persona» (`BusquedaBeneficiario`, pierde la
  persona) y «Descartar esta vacuna» (`reiniciarCicloVacuna()` +
  `VacunasPage`, conserva beneficiario/tutor).
- **Perfil heredado dentro de la visita**: si ya hay perfil elegido en una
  vacuna anterior de la misma persona (`perfilesVacunacionService`, ciclo
  persona), `_heredarPerfilDeLaVisita()` lo reutiliza y arranca directo en
  paso 2 (`vacunas_page.dart`, `initState`). Para cambiarlo: volver a paso 1
  con el chip del header y elegir otro perfil ahí.
- Fecha de aplicación: default hoy, `firstDate` del picker = fecha de
  nacimiento del beneficiario si es posterior a 2021, si no 2021
  (`_fechaNacimientoBeneficiario()`). El botón «Continuar» de este paso vive
  en la barra fija, no dentro del contenido del paso.
- Paso 8 valida completitud (`_validarDatosRegistro`) y arma
  `InsertRegistros` (`_construirRegistro`). La condición gestacional se
  descarta si `sysdesa10_sexo != 'F'`.
- **Advertencia de duplicado** (no bloquea): `_vacunaDosisYaAplicada()`
  compara vacuna+dosis por nombre contra el historial del back
  (`notificacionesDosisService.listaDosisAplicadas`) y contra lo ya
  registrado en la visita (`insertRegistroService.visitaRegistros`). Si
  coincide, diálogo «Vacuna ya registrada» con «Continuar igual» / «Volver»
  antes de registrar.

### 6. Confirmación y envío — fusionado en el paso 8

Antes existía una pantalla aparte (`ConfirmarDatos`, «Revisión final») que
repetía el mismo resumen de vacuna/dosis/lote que ya mostraba el paso 8
(«Revisar selección») y las mismas tarjetas de beneficiario/tutor que el
banner y el sheet de detalle ya mostraban — dos revisiones idénticas
seguidas. Se eliminó esa pantalla: el paso 8 (`containerVerificar()`,
título «Confirmar y registrar») es ahora la pantalla de confirmación y
registro en sí misma. El botón «Registrar» de la barra fija dispara
`_registrarVacunacion()` (`vacunas_page.dart`), que:

1. `insertRegistroService.cargarRegistro(_construirRegistro())`.
2. POST `sistemaRepository.insertRegistroProd()`, con overlay de carga
   (`_overlayRegistrando()`) mientras `_registrando == true`.
3. Si `codigo_mensaje == '0'`: error, diálogo «Reintentar» (queda en el
   paso 8, no se pierde la selección).
4. Si no: éxito. Se suma a `insertRegistroService.visitaRegistrosEstado`
   («vacunas de esta visita», ciclo persona) y se pregunta «¿Aplicar otra
   vacuna a la misma persona?».
   - «Sí, otra vacuna» → `_refrescarHistorialDosis()` (recarga
     `notificacionesDosisService` para que la vacuna recién aplicada
     aparezca en el historial) → `reiniciarCicloVacuna()` → `VacunasPage`
     (misma persona).
   - «No, finalizar» → `BusquedaBeneficiario` → reinicio total del ciclo
     persona.

Convención `codigo_mensaje` (verificada en llamadas, no en el PHP):
- Beneficiario: `'0'` = error/no encontrado (`busquedabeneficiario_page.dart:392`).
- Notificaciones: `'1'` = hay dosis (`busquedabeneficiario_page.dart:386`).
- Insert: `'0'` = error, reintentar (`vacunas_page.dart`, `_registrarVacunacion`).

«Vacunas de esta visita»: una sola fuente de UI (`_seccionVacunasVisita()`
en `VacunasPage`, línea compacta que abre el sheet de historial). Antes se
mostraba una segunda vez, como lista completa, en `ConfirmarDatos` — esa
pantalla ya no existe.

---

## Campos del registro enviados al back

`InsertRegistros.toJson()` (`insertregistros_models.dart:86-114`). Campos en
modo prueba / pendientes de confirmación del back:

| Campo | Valores | Estado back |
|-------|---------|-------------|
| `vacunacion_en_terreno` | `'1'` terreno / `'0'` fijo | Se envía; persistencia depende del PHP (`insertregistros_models.dart:63-64`) |
| `condicion_gestacional_beneficiario` | `'embarazada'` \| `'puerpera'` \| null | Nombre de campo sin confirmar (`insertregistros_models.dart:71`) |
| `es_personal_salud` | `'1'` / `'0'` | Nombre de campo sin confirmar (`insertregistros_models.dart:73`) |
| `vacunador_registrador` | `'1'` si `registrador.flxcore03_dni == vacunador.id_sysdesa12` | Contrato no verificado: compara DNI contra id (`vacunas_page.dart:2584-2588`) |

---

## Piezas en modo prueba

- Bloque Situación (condición gestacional + personal de salud):
  `situacion_beneficiario_widget.dart`, `situacionbeneficiario_service.dart`.
- Clasificador y matriz calendario 2026: `calendario_2026.dart`,
  test en `test/calendario_2026_test.dart`.
- Umbrales edad↔situación: sin definir; se definen cuando el back confirme campos.
- Modalidad en terreno: switch en «Equipo de trabajo»
  (`vacunador_page.dart:514-527`), default `false` (establecimiento fijo)
  (`sesion_equipo_vacunacion_service.dart:7-8`), reset solo en logout manual.

---

## Incoherencias conocidas

Detalle, impacto y orden de resolución: `docs/plan_mejora_sesion_vacunacion.md`.
Tachadas: ya resueltas (Fases 1-8 del plan, completo).

1. ~~Historial de dosis en `estadosPorVacuna`: se borraba al elegir «otra
   vacuna, misma persona» aunque es dato de la persona.~~ Resuelto Fase 1
   (movido a `estadosPorPersona`) + Fase 2 (se refresca tras cada registro).
2. ~~Escáner no valida `codigo_mensaje == '0'` del beneficiario.~~ Resuelto
   Fase 3.1.
3. ~~Situación fijada con sexo declarado, sin revalidar contra sexo del
   back.~~ Resuelto Fase 3.2 (`_construirRegistro` descarta condición si
   `sysdesa10_sexo != 'F'`).
4. ~~Situación no editable después de la búsqueda.~~ Resuelto Fase 7.2
   (`_seccionSituacionEditable()` en `VacunasPage`, reusa
   `SituacionBeneficiario` contra `situacionBeneficiarioService`).
5. ~~Etiqueta de sexo con fallback «Femenino» ante sexo desconocido, con
   bloque condición oculto.~~ Resuelto Fase 7.5 (M/F/X muestran su etiqueta,
   cualquier otro valor muestra «Sin dato»).
6. ~~Perfil se re-consulta y re-selecciona en cada vacuna de la misma
   persona.~~ Resuelto Fase 4 (perfil en ciclo persona, heredado entre
   vacunas de la visita).
7. ~~`enTerreno`: doble escritura.~~ Resuelto Fase 8.1 (queda solo el
   on-change del switch, se quitó la del `dispose`).
8. ~~Sin validación de duplicado vacuna+dosis dentro de la visita.~~ Resuelto
   Fase 6 (advertencia, no bloqueo). Fecha aplicación ≥ fecha nacimiento:
   resuelto Fase 3.3. Tutor ≠ beneficiario / tutor mayor de edad: pendiente,
   sin fase asignada.
9. ~~El formulario (lo importante de la pantalla) quedaba debajo de bloques
   informativos siempre expandidos: el calendario completo (bloque más alto
   de la página) y, por error propio al aplicar las Fases 5 y 7.2, la
   situación editable y "vacunas de la visita" también sin colapsar. La
   acción de avance del paso 8 exigía scrollear todo eso.~~ Resuelto: ver
   «Layout de `VacunasPage`» arriba — calendario a bottom sheet, situación
   dentro de `containerBeneficiario` (colapsable), visita a una línea,
   acciones de avance a barra fija.
10. ~~Patrón sistémico: cada pantalla nueva del flujo repetía desde cero un
    dato que otra pantalla ya mostraba, en vez de reutilizar una única
    fuente. Encontrado en cuatro dominios a la vez: identidad del
    beneficiario (banner + tarjeta + sheet + `ConfirmarDatos`, hasta 4
    veces), resumen de la vacuna elegida (chips del header + paso 8 +
    `ConfirmarDatos`, 3 veces), «vacunas de esta visita» (línea + sheet +
    `ConfirmarDatos`, 3 veces, con dos fuentes de datos paralelas
    reconciliadas por nombre) y calendario/situación (chips + sheet, 2
    veces). Causa: cada capa nueva se copió del layout anterior en vez de
    reusarlo. Esto fue lo que introdujo la incoherencia #9 (la propia
    corrección anterior).~~ Resuelto: se eliminó `containerBeneficiario()`
    (dejó una sola fuente para identidad y situación: banner + sheet); se
    eliminó `ConfirmarDatos` fusionando la confirmación y el registro en el
    paso 8 (dejó una sola fuente para el resumen de vacuna y para «vacunas
    de esta visita»). De paso, se corrigió un bug de correctitud encontrado
    en el camino: `containerPerfiles()`/`_heredarPerfilDeLaVisita()`
    indexaban `tempLista[0]` sin chequear que `obtenerVacunasxPerfilesProviders`
    puede devolver `0` (`int`, sin vacunas configuradas para el perfil) en
    vez de una `List` — crash potencial, ahora con guardia de tipo.
