# Plan de migración de estado — única lógica de guardado

Ejecutor: Sonnet 4.6. Objetivo: reemplazar los ~20 mini-frameworks de estado escritos a
mano en `lib/src/presentation/state/` por **una sola primitiva** de estado observable, sin
perder funcionalidad. Cada dato pasa a ser un `Estado<T>`; guardar, observar y reiniciar
significan **una sola cosa** en todo el código.

## Reglas de trabajo (no negociables)

- No inventar ni asumir. Si un caso no encaja en las reglas de abajo, **frenar y preguntar**,
  no improvisar.
- No cambiar comportamiento visible: mismas pantallas, mismos datos, mismos flujos.
- Trabajar en **rebanadas verticales** (un service + sus consumidores) y, al terminar cada
  rebanada, correr `flutter analyze` y `flutter build apk --debug` (o `flutter run`). No pasar
  a la siguiente rebanada con analyze en rojo.
- Un commit por rebanada, mensaje `[REFACTOR estado] <service>`.
- Preservar los **nombres de getters y métodos públicos** de cada service (`beneficiario`,
  `cargarBeneficiario`, etc.) para no tocar las lecturas directas. Solo cambian: (a) el interior
  del service, (b) los `StreamBuilder` → `ValueListenableBuilder`.

## Contexto verificado del código actual

- Sin librería de estado (no hay provider/riverpod/bloc en `pubspec.yaml`). Todo son singletons
  globales `final xService = _XService();`.
- 3 mecanismos de notificación conviviendo: `ChangeNotifier` (`tema_app_service.dart:5`),
  `StreamController.broadcast` (18 services), y ninguno (`sesion_equipo_vacunacion_service.dart`).
- Doble fuente de verdad por service: el campo `_x` **y** el stream.
- Valor inicial incoherente entre archivos que hacen lo mismo: `vacunaslotes_service.dart:7` y
  `vacunas_dosis_service.dart:6` inicializan listas en `[]`; `perfilesvacunacion_service.dart:8`
  y `efectores_service.dart:8` las dejan en `null` y luego hacen `_lista!.isNotEmpty`
  (`perfilesvacunacion_service.dart:39`, `efectores_service.dart:24`) → **crash** si se consultan
  antes de cargar.
- Cargar/limpiar asimétrico: `vacunaslotes_service.dart:47 eliminarListaVacunasLotes` no limpia
  la búsqueda que `:41` sí alimentó.
- `dispose()` es letra muerta: los singletons son `final` de módulo, nunca se disponen.
- Consumo en UI: **20 `StreamBuilder`** (login 1, vacunador 3, busqueda 1, vacunas 15) + muchas
  lecturas directas `.propiedad` (no reactivas): `beneficiario` ×16, `registrador` ×12,
  `tutor` ×7, etc.

## Fase 0 — La primitiva única

Crear `lib/src/presentation/state/estado.dart`:

```dart
import 'package:flutter/foundation.dart';

/// Único contenedor de estado observable de la app.
/// - `value`: la única fuente de verdad (getter/setter de ValueNotifier).
/// - `reiniciar()`: vuelve al valor inicial. Mismo contrato para TODO estado.
/// Observar en UI con `ValueListenableBuilder`.
class Estado<T> extends ValueNotifier<T> {
  Estado(this._inicial) : super(_inicial);
  final T _inicial;
  void reiniciar() => value = _inicial;
}
```

Registro de sesión (mecanismo interno, NO un botón de UI). Sirve para que "reiniciar el estado
del ciclo corto" sea **una** llamada, no 30 métodos sueltos:

```dart
// lib/src/presentation/state/estado_sesion.dart
import 'estado.dart';

/// Estados que pertenecen al ciclo "por beneficiario": nacen y mueren con cada
/// persona atendida. Registrar acá cada Estado de ese ciclo (ver Fase 2).
final List<Estado> estadosPorBeneficiario = [];

/// Reinicia todo el ciclo corto de una. Se llama al iniciar un beneficiario nuevo.
void reiniciarCicloBeneficiario() {
  for (final e in estadosPorBeneficiario) {
    e.reiniciar();
  }
}
```

No agregar UI para esto. La invocación se decide en la Fase 3.

## Fase 1 — Migrar cada service a `Estado<T>`

Patrón mecánico por service. Ejemplo con `usuariobeneficiario_service.dart` (aplica igual al
resto):

**Antes** (resumen): campo `_beneficiario`, `StreamController.broadcast`, getter
`beneficiario`, getter `beneficiarioStream`, `cargarBeneficiario`, `eliminarBeneficiario`,
`existeBeneficiario`, `dispose`.

**Después:**

```dart
class _BeneficiariorService {
  final beneficiarioEstado = Estado<Beneficiario?>(null);
  final edadEstado = Estado<String?>(null);
  final fechaNacEstado = Estado<String?>(null);

  // Getters públicos SE MANTIENEN (lecturas directas no cambian):
  Beneficiario? get beneficiario => beneficiarioEstado.value;
  String? get edadAniosDesdePdf417Escaneado => edadEstado.value;
  String? get fechaNacimientoDesdePdf417Escaneado => fechaNacEstado.value;
  bool get existeBeneficiario => beneficiarioEstado.value != null;

  void cargarBeneficiario(Beneficiario? b, {String? edadAniosDesdePdf417Escaneado,
      String? fechaNacimientoDesdePdf417Escaneado}) {
    tutorService.reiniciar();               // antes: tutorService.eliminarTutor()
    edadEstado.value = edadAniosDesdePdf417Escaneado;
    fechaNacEstado.value = fechaNacimientoDesdePdf417Escaneado;
    beneficiarioEstado.value = b;
  }

  void reiniciar() {                         // reemplaza eliminarBeneficiario()
    beneficiarioEstado.reiniciar();
    edadEstado.reiniciar();
    fechaNacEstado.reiniciar();
  }
}
final beneficiarioService = _BeneficiariorService();
```

Reglas de conversión por service:

1. Cada campo `_x` (valor único, lista, o lista-de-búsqueda) → un `final xEstado = Estado<T>(inicial)`.
   - **Valor inicial correcto y uniforme:** objetos nullable → `null`; listas → `[]` (arregla el
     crash de `perfiles`/`efectores`); bools de loading → su default actual en
     `loadingLogin_service.dart:4-11`.
2. Getters de valor (`beneficiario`, `listaVacunasDosis`, `enTerreno`, …) → delegan a
   `xEstado.value`. **Mantener el nombre.**
3. Getters `existeX` → `xEstado.value != null` (objetos) o `.isNotEmpty` (listas). Mantener nombre.
4. Métodos `cargarX` / `buscarX` / `establecerX` / `agregarX` → setean `xEstado.value = ...`.
   Mantener nombre y firma.
5. Métodos de borrado (`eliminarX`, `eliminarListaX`, `eliminarBusquedaX`, `reiniciar`) → **un solo**
   método `reiniciar()` que llama `.reiniciar()` de todos los `Estado` del service. Esto arregla la
   asimetría (la búsqueda vuelve a vacío junto con la lista). Ver "Ajuste de consumidores" para
   renombrar las llamadas.
6. Borrar `StreamController`, los getters `xStream`, y `dispose()`. Ya no existen.
7. Exponer, donde haya `StreamBuilder` consumidor, el propio `Estado` (ya es `ValueListenable<T>`).
   No hace falta getter extra: `beneficiarioService.beneficiarioEstado` sirve como `valueListenable`.

Casos especiales verificados:

- `insertregistro_service.dart:8` usa `StreamController<InsertRegistros>` **non-nullable** → el
  `Estado` debe ser `Estado<InsertRegistros?>(null)`. `agregarFecha` (`:23`) muta el objeto y
  reasigna: `_registroEstado.value = _registroEstado.value!..fecha_aplicacion = ...` (o reasignar
  copia). Verificar que `InsertRegistros` no sea inmutable antes; si lo es, preguntar.
- `loadingLogin_service.dart`: 9 flags → 9 `Estado<bool>` con los mismos nombres de getter
  (`getLoadingDosisState`, etc.) y de método (`cargarDosis`, etc.). **No consolidar en un modelo
  único ahora** (YAGNI; se puede después). `loadingMensaje` → `Estado<String>('')`.
  // ponytail: 9 Estado<bool> en vez de un modelo de carga; consolidar si molesta.
- `tema_app_service.dart` y `enviroment_service.dart`: son del **ciclo largo** (app/login), NO
  registrar en `estadosPorBeneficiario`. `tema` ya es `ChangeNotifier` con persistencia en
  `SharedPreferences` — se puede dejar como está o migrarlo a `Estado` manteniendo la persistencia;
  si se migra, la escritura a prefs va en un listener, no perder `inicializar()`/`establecerModo`.
- `sesion_equipo_vacunacion_service.dart`: ya tiene `reiniciar()`. Migrar `_enTerreno` a
  `Estado<bool>(true)`; su `reiniciar()` queda alineado con el contrato.
- `changelog_app_service.dart`: NO es estado, es un loader de asset. **No tocar.**

## Fase 2 — Clasificar ciclo largo vs ciclo corto

Registrar en `estadosPorBeneficiario` (Fase 0) únicamente los `Estado` que deben limpiarse al
pasar de un beneficiario al siguiente:

- **Ciclo corto (registrar):** beneficiario, tutor, perfilesVacunacion (single + lista),
  vacunasConfiguracion, vacunasLotes, vacunasDosis, vacunasCondicion, vacunasEsquema,
  vacunasxPerfil, notificacionesDosis, insertRegistro, y los flags de carga de
  `loadingLogin` asociados a la carga por-beneficiario (`loadingVerificar`, `loadingDosis`,
  `loadingEsquema`, `loadingCondicion`, `cargaPerfil`, `cargaLotes`).
- **Ciclo largo (NO registrar):** tema, enviroment, vacunador, registrador, efectores,
  sesionEquipoVacunacion, cantidadVacunados.

Si alguna clasificación es dudosa (ej: `efectores`, `cantidadVacunados`), **preguntar** antes de
registrar; no adivinar.

## Fase 3 — Punto único de reinicio del ciclo corto

Reemplazar las listas manuales de borrado dispersas por **una** llamada a
`reiniciarCicloBeneficiario()` en el único lugar donde arranca un beneficiario nuevo.

Callsites de borrado manual actuales a eliminar/reemplazar:
- `vacunas_page.dart:213-218` (bloque de 5 `eliminar*`)
- `confirmaciondatos_page.dart:525-530` (bloque de 5 `eliminar*`)
- `vacunas_page.dart:937` (`tutorService.eliminarTutor`)

Verificar en el código si el arranque de un beneficiario nuevo es siempre `BusquedaBeneficiario`
(hay `pushAndRemoveUntil` hacia esa página en `vacunas_page.dart:220`, `:2614`,
`confirmaciondatos_page.dart:532`). Si es único punto de entrada, poner
`reiniciarCicloBeneficiario()` en `initState` de `BusquedaBeneficiario`. **Antes de moverlo ahí,
confirmar con el usuario que no hay otra entrada** (ej. escaneo directo desde drawer). No asumir.

## Fase 4 — Migrar los 20 `StreamBuilder` a `ValueListenableBuilder`

Localizar todos con `grep -rn "stream:" lib/src/pages lib/src/widgets`. Conversión:

```dart
// Antes
StreamBuilder<T>(
  stream: xService.datoStream,
  builder: (context, snapshot) {
    final dato = snapshot.data;            // T?
    if (!snapshot.hasData) { ... }
    ...
  },
)
// Después
ValueListenableBuilder<T>(
  valueListenable: xService.datoEstado,
  builder: (context, dato, _) {           // dato ya es el valor actual, sincrónico
    ...
  },
)
```

Traducción de semántica del snapshot (cuidado, es la parte delicada):
- `snapshot.data` → `dato` (el valor). Ya no es "puede no haber llegado": `Estado` siempre tiene
  valor inicial.
- `snapshot.hasData` (objetos nullable) → `dato != null`.
- `snapshot.hasData` (listas) → normalmente el chequeo real que interesa es `dato.isNotEmpty`;
  revisar cada builder y traducir a la condición equivalente. **No copiar a ciegas.**
- `snapshot.connectionState == waiting` → con `Estado` no hay estado "waiting" (el valor inicial ya
  está). Si un builder mostraba spinner en `waiting`, ese spinner ahora depende del flag de loading
  correspondiente (`loadingLogin`), que ya se consume por separado en varios de estos casos.
  Revisar caso por caso; si un builder mezclaba loading con datos en el mismo snapshot, **preguntar**.

Callsites conocidos (confirmar cada uno al abrir el archivo):

| Archivo:línea | stream actual | Estado destino | tipo |
|---|---|---|---|
| busquedabeneficiario_page.dart:404 | cantidadvacunadosStream | cantidadVacunadosEstado | CantidadVacunados? |
| login_page.dart:218 | loadingStateStream | loadingEstado | bool |
| vacunador_page.dart:347 | registradorStream | registradorEstado | Usuarios? |
| vacunador_page.dart:847 | listaEfectoresStream | listaEfectoresEstado | List<Efectores> |
| vacunas_page.dart:331 | listaDosisAplicadasStream | listaDosisAplicadasEstado | List<NotificacionesDosis> |
| vacunas_page.dart:964 | tutorStream | tutorEstado | Tutor? |
| vacunas_page.dart:1061 | listaPerfilesVacunacionStream | listaPerfilesEstado | List<PerfilesVacunacion> |
| vacunas_page.dart:1264 | cargaPerfilStateStream | cargaPerfilEstado | bool |
| vacunas_page.dart:1269 | listaVacunasxPerfilesStream | listaVacunasxPerfilEstado | List |
| vacunas_page.dart:1419 | loadingCondicionStateStream | loadingCondicionEstado | bool |
| vacunas_page.dart:1424 | listaVacunasCondicionesStream | listaCondicionEstado | List |
| vacunas_page.dart:1483 | (búsqueda condicion, multilínea) | busquedaCondicionEstado | List |
| vacunas_page.dart:1582 | loadingEsquemaStateStream | loadingEsquemaEstado | bool |
| vacunas_page.dart:1587 | listavacunasEsquemaesStream | listaEsquemaEstado | List |
| vacunas_page.dart:1739 | loadingDosisStateStream | loadingDosisEstado | bool |
| vacunas_page.dart:1744 | listaVacunasDosisStream | listaDosisEstado | List |
| vacunas_page.dart:1986 | listaVacunasLotesStream | listaLotesEstado | List |
| vacunas_page.dart:1326, :1644 | (resolver al abrir) | — | — |

`vacunador_page.dart:46` es un comentario, no un `StreamBuilder`. Ignorar.

## Fase 5 — Ajuste de consumidores de métodos de borrado

Reemplazar cada llamada a los viejos métodos de borrado por `reiniciar()` del service (o por
`reiniciarCicloBeneficiario()` en el punto único de Fase 3):
- `vacunasxPerfilService.eliminarListaVacunasxPerfil`, `perfilesVacunacionService.eliminarListaPerfiles`,
  `vacunasConfiguracionService.eliminarListaVacunasConfiguracion`,
  `vacunasLotesService.eliminarListaVacunasLotes`, `notificacionesDosisService.eliminarListaDosis`,
  `tutorService.eliminarTutor`, `usuarioregistrador`/`usuariovacunador` `eliminar*`.

Buscar todos con: `grep -rnE "\.(eliminar|reiniciar)[A-Za-z]*\(" lib/src/pages lib/src/widgets`.

## Orden de ejecución (rebanadas)

1. Fase 0 (primitiva + registro). Compila, no cambia nada. Commit.
2. `sesion_equipo_vacunacion_service` (el más chico, sin stream) — valida el patrón. Commit.
3. `tutor_service` + su `StreamBuilder` (vacunas_page:964) y llamadas `eliminarTutor`. Commit.
4. `usuariobeneficiario_service` (depende de tutor). Commit.
5. `usuarioregistrador_service` + StreamBuilder vacunador:347. Commit.
6. `usuariovacunador_service`. Commit.
7. `efectores_service` + StreamBuilder vacunador:847. Commit.
8. Cada service de vacunas (`perfiles`, `configuracion`, `lotes`, `dosis`, `condicion`, `esquema`,
   `xperfiles`) + sus StreamBuilder en vacunas_page. Una rebanada por service. Commit c/u.
9. `notificacionesdosis_service` + StreamBuilder vacunas_page:331. Commit.
10. `insertregistro_service` (caso non-null). Commit.
11. `vacunadoscant`/`vacunascant` + StreamBuilder busqueda:404. Commit.
12. `loadingLogin_service` (9 flags) + StreamBuilders login:218, vacunas (varios). Commit.
13. Fase 2 (registrar ciclo corto) + Fase 3 (punto único de reinicio). Commit.
14. Fase 5 (limpiar callsites de borrado restantes). Commit.
15. Borrar `enviroment`/`tema` solo si se decide migrarlos (ver Fase 1 casos especiales); si no,
    dejarlos.

## Verificación final

- `flutter analyze` sin errores.
- `flutter build apk --debug` OK.
- Prueba manual del flujo completo: login → equipo → buscar beneficiario A → cargar perfiles/lotes
  → vacunar → volver a buscar → beneficiario B **arranca limpio** (sin datos de A). Este es el
  criterio de "no perder funcionalidad" + "el estado se limpia solo".

## Qué NO hacer

- No agregar dependencias (provider/riverpod/bloc). `Estado` es `ValueNotifier`, nativo.
- No agregar botón de "reiniciar sesión" en la UI.
- No consolidar `loadingLogin` en un modelo grande en esta migración.
- No tocar `changelog_app_service` (no es estado).
- Ante cualquier builder que mezcle loading + datos, o clasificación de ciclo dudosa: **preguntar.**
