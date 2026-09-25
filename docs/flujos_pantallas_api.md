# Flujos App Vacunación Formosa

**Host:** `https://dh.formosa.gob.ar/modulos/webservice/php/`
**Convención API:** `codigo_mensaje "0"` = ERROR · `"1"` = ÉXITO

---

## Navegación entre pantallas

```mermaid
flowchart LR
    A([Inicio]) --> L[LoginBody]
    L -->|registrador OK| V[VacunadorPage]
    V -->|equipo listo| B[BusquedaBeneficiario]
    B -->|beneficiario OK| VA[VacunasPage]
    VA -->|8 pasos completos| C[ConfirmarDatos]
    VA -->|cancelar| B
    C -->|OK o cancelar| B
    B -->|salir| L
    V -->|salir| L
```

---

## PANTALLA 1 — LoginBody

El registrador escanea su DNI. La app lee el código de barras, extrae el número de documento y lo manda a la API para validar si el usuario tiene permiso.

```mermaid
sequenceDiagram
    actor U as Registrador
    participant APP as App
    participant API as API
    participant RAM as Memoria

    U->>APP: Escanea código de barras del DNI
    APP->>APP: Lee el número de documento del código escaneado
    APP->>API: GET version_2_0/wserv_login.php
    Note over APP,API: Manda: flxcore03_dni = número de documento leído

    API-->>APP: Responde con usuario[0]
    Note over API,APP: Devuelve: id_flxcore03, flxcore03_dni, flxcore03_nombre, rela_sysofic01, sysofic01_descripcion, codigo_mensaje, mensaje

    alt flxcore03_dni viene vacío - usuario no existe o sin permiso
        APP-->>U: Diálogo de error usando el campo mensaje del response
    else sysofic01_descripcion viene null - sin establecimiento asignado
        APP-->>U: Diálogo Datos incompletos en el servidor
    else Respuesta válida
        APP->>RAM: registradorService guarda id_flxcore03, flxcore03_dni, flxcore03_nombre, rela_sysofic01, sysofic01_descripcion
        APP-->>U: Navega a VacunadorPage
    end
```

---

## PANTALLA 2 — VacunadorPage

Configura el equipo de trabajo. Al entrar carga los establecimientos disponibles para el registrador. Permite elegir si el registrador es también el vacunador o asignar uno diferente. Tiene opción de marcar si es vacunación en terreno.

### Al entrar — carga establecimientos del registrador

```mermaid
sequenceDiagram
    participant APP as App
    participant API as API
    participant RAM as Memoria

    APP->>API: GET version_3_0/wserv_efector_registrador.php
    Note over APP,API: Manda: flxcore03_dni = registradorService.registrador.flxcore03_dni

    API-->>APP: Responde con usuario[] lista de establecimientos
    Note over API,APP: Devuelve por cada establecimiento: id_flxcore03, flxcore03_dni, flxcore03_nombre, rela_sysofic01, sysofic01_descripcion

    alt Lista vacía
        APP-->>APP: Muestra error No hay establecimientos disponibles con botón Reintentar
    else OK
        APP->>RAM: efectoresService guarda la lista completa de establecimientos
    end
```

### Si el usuario cambia de establecimiento — sin llamada a la API

```mermaid
sequenceDiagram
    actor U as Usuario
    participant APP as App
    participant RAM as Memoria

    U->>APP: Toca el ícono de hospital y elige un establecimiento de la lista
    APP->>RAM: registradorService actualiza rela_sysofic01 y sysofic01_descripcion con el establecimiento elegido
    Note over APP,RAM: No hay llamada a la API. Solo se actualiza en memoria.
```

### Switch mismo vacunador = SÍ — sin llamada a la API

```mermaid
sequenceDiagram
    actor U as Usuario
    participant APP as App
    participant RAM as Memoria

    U->>APP: Deja el switch en SÍ y presiona Siguiente
    APP->>RAM: vacunadorService guarda un Vacunador construido con los datos del registrador
    Note over APP,RAM: id_sysdesa12 = registrador.flxcore03_dni
    Note over APP,RAM: sysdesa06_nombre = registrador.flxcore03_nombre
    Note over APP,RAM: sysdesa06_nro_documento = registrador.flxcore03_dni
    Note over APP,RAM: No hay llamada a la API.
    APP-->>U: Navega a BusquedaBeneficiario
```

### Switch mismo vacunador = NO — valida al vacunador por DNI

```mermaid
sequenceDiagram
    actor U as Usuario
    participant APP as App
    participant API as API
    participant RAM as Memoria

    U->>APP: Escanea el DNI del vacunador o lo ingresa manualmente
    APP->>API: GET version_3_0/wserv_vacunador.php
    Note over APP,API: Manda: sysdesa06_nro_documento = DNI del vacunador

    API-->>APP: Responde con vacunador[0]
    Note over API,APP: Devuelve: id_sysdesa12, sysdesa06_nro_documento, sysdesa06_nombre, codigo_mensaje, mensaje

    alt codigo_mensaje == 0
        APP-->>U: Diálogo de error usando el campo mensaje del response
    else Error de red
        APP-->>U: Diálogo Error de conexión
    else OK
        APP->>RAM: vacunadorService guarda id_sysdesa12, sysdesa06_nro_documento, sysdesa06_nombre
        APP-->>U: Snackbar Vacunador asignado correctamente
        U->>APP: Presiona Siguiente
        APP-->>U: Navega a BusquedaBeneficiario
    end
```

### Switch en terreno — sin llamada a la API

```mermaid
sequenceDiagram
    actor U as Usuario
    participant APP as App
    participant RAM as Memoria

    U->>APP: Cambia el switch en terreno
    APP->>RAM: sesionEquipoVacunacionService guarda el valor true o false
    Note over APP,RAM: Este valor se usa al final en el POST como vacunacion_en_terreno con valor 1 o 0
```

---

## PANTALLA 3 — BusquedaBeneficiario

Busca al beneficiario que va a recibir la vacuna. Se puede buscar escaneando su DNI o ingresando el número manualmente. También carga cuántas vacunas aplicó el vacunador hoy.

### Al entrar — contador de vacunas del vacunador

```mermaid
sequenceDiagram
    participant APP as App
    participant API as API
    participant RAM as Memoria

    Note over APP: Solo se ejecuta si hay un vacunador asignado

    APP->>API: GET version_3_0/wserv_cantidad_vacunas_registradas.php
    Note over APP,API: Manda: id_sysdesa12 = vacunadorService.vacunador.id_sysdesa12
    Note over APP,API: Manda: vacunador_registrador = 1 si registrador y vacunador son la misma persona, sino 0

    API-->>APP: Responde con usuario[0]
    Note over API,APP: Devuelve: cantidad_aplicaciones

    APP->>RAM: cantidadVacunasService guarda cantidad_aplicaciones y la muestra en pantalla
```

### Búsqueda del beneficiario por escaneo de DNI

```mermaid
sequenceDiagram
    actor U as Usuario
    participant APP as App
    participant API as API
    participant RAM as Memoria

    U->>APP: Presiona Escanear documento y apunta la cámara al DNI
    APP->>APP: Lee el código de barras y extrae número de documento y sexo
    APP->>API: GET version_3_0/wserv_obtener_datos_beneficiario.php
    Note over APP,API: Manda: sysdesa10_cadena_dni = cadena completa leída del código de barras
    Note over APP,API: Manda: sysdesa10_dni = número de documento extraído
    Note over APP,API: Manda: sysdesa10_sexo = M o F extraído del código de barras

    API-->>APP: Responde con beneficiario[0]
    Note over API,APP: Devuelve: sysdesa10_apellido, sysdesa10_nombre, sysdesa10_cuil, sysdesa10_dni, sysdesa10_sexo, sysdesa10_nro_tramite, sysdesa10_fecha_nacimiento, sysdesa10_edad, sysdesa10_cadena_dni, foto_beneficiario, codigo_mensaje, mensaje

    alt codigo_mensaje == 0
        APP-->>U: Diálogo de error usando el campo mensaje del response
    else OK
        APP->>RAM: beneficiarioService guarda todos los campos del response
        Note over APP,RAM: También guarda la edad calculada en años desde el código de barras si estaba disponible
    end
```

### Búsqueda del beneficiario modo manual

```mermaid
sequenceDiagram
    actor U as Usuario
    participant APP as App
    participant API as API
    participant RAM as Memoria

    U->>APP: Ingresa el número de documento sin puntos y elige sexo M o F
    U->>APP: Presiona Verificar datos
    APP->>API: GET version_3_0/wserv_obtener_datos_beneficiario.php
    Note over APP,API: Manda: sysdesa10_cadena_dni = vacío porque no hubo escaneo
    Note over APP,API: Manda: sysdesa10_dni = número ingresado por el usuario
    Note over APP,API: Manda: sysdesa10_sexo = M o F elegido por el usuario

    API-->>APP: Responde con beneficiario[0]
    Note over API,APP: Devuelve: sysdesa10_apellido, sysdesa10_nombre, sysdesa10_cuil, sysdesa10_dni, sysdesa10_sexo, sysdesa10_nro_tramite, sysdesa10_fecha_nacimiento, sysdesa10_edad, sysdesa10_cadena_dni, foto_beneficiario, codigo_mensaje, mensaje

    alt codigo_mensaje == 0
        APP-->>U: Diálogo de error usando el campo mensaje del response
    else OK
        APP->>RAM: beneficiarioService guarda todos los campos del response
    end
```

### Historial de dosis del beneficiario — se ejecuta después de encontrarlo

```mermaid
sequenceDiagram
    participant APP as App
    participant API as API
    participant RAM as Memoria

    APP->>API: GET version_3_0/obtener_aplicaciones_beneficiario.php
    Note over APP,API: Manda: sysdesa10_dni = DNI del beneficiario recién encontrado
    Note over APP,API: Manda: sysdesa10_sexo = sexo del beneficiario

    API-->>APP: Responde con aplicaciones_beneficiario[]
    Note over API,APP: Devuelve por cada dosis previa: sysvacu04_nombre, sysvacu05_nombre, sysdesa10_fecha_aplicacion, fecha_proxima_dosis, dias_transcurridos, sysdesa18_lote, sysvacu03_tiempo_interdosis, codigo_mensaje, mensaje

    alt codigo_mensaje == 1 hay dosis registradas
        APP->>RAM: notificacionesDosisService guarda la lista completa de dosis anteriores
    else cualquier otro valor sin dosis registradas
        APP->>RAM: notificacionesDosisService guarda un objeto vacío
    end

    APP-->>APP: Navega a VacunasPage
```

---

## PANTALLA 4 — VacunasPage

Selección paso a paso de la vacuna a aplicar. Cada elección del usuario dispara una llamada a la API para cargar las opciones del siguiente paso.

### Al entrar — carga los perfiles de vacunación

```mermaid
sequenceDiagram
    participant APP as App
    participant API as API
    participant RAM as Memoria

    APP->>API: GET version_3_0/wserv_obtener_perfil_vacunacion.php
    Note over APP,API: Manda: rela_flxcore03 = registradorService.registrador.id_flxcore03

    API-->>APP: Responde con perfiles_vacunacion[]
    Note over API,APP: Devuelve por cada perfil: id_sysvacu12, sysvacu12_descripcion, codigo_mensaje, mensaje

    alt Lista vacía o error del servidor
        APP-->>APP: Muestra el campo mensaje del response con botón Reintentar carga
    else OK
        APP->>RAM: perfilesVacunacionService guarda la lista de perfiles
    end
```

### Paso 1 — Usuario elige un perfil → carga las vacunas de ese perfil

```mermaid
sequenceDiagram
    actor U as Usuario
    participant APP as App
    participant API as API
    participant RAM as Memoria

    U->>APP: Toca un perfil de la lista
    APP->>APP: Limpia la selección de vacuna y los lotes acumulados

    APP->>API: GET version_3_0/wserv_obtener_vacunas_configuradas.php
    Note over APP,API: Manda: id_sysvacu12 = id del perfil elegido
    Note over APP,API: Manda: sysdesa10_dni = beneficiarioService.beneficiario.sysdesa10_dni
    Note over APP,API: Manda: sysdesa10_sexo = beneficiarioService.beneficiario.sysdesa10_sexo

    API-->>APP: Responde con vacunas_configuradas[]
    Note over API,APP: Devuelve por cada vacuna: id_sysvacu04, sysvacu04_nombre, codigo_mensaje, mensaje

    alt codigo_mensaje == 0
        APP-->>U: Diálogo de error usando el campo mensaje del response
    else OK
        APP->>RAM: vacunasxPerfilService guarda la lista de vacunas disponibles
        APP-->>U: Muestra el Paso 2 con la lista de vacunas
    end
```

### Paso 2 — Usuario elige una vacuna → carga las condiciones

```mermaid
sequenceDiagram
    actor U as Usuario
    participant APP as App
    participant API as API
    participant RAM as Memoria

    U->>APP: Toca una vacuna de la lista
    APP->>APP: Limpia las selecciones de condicion esquema dosis lote
    APP->>APP: Determina la edad a mandar: primero intenta la edad del código de barras del DNI, si no la edad que devolvió la API del beneficiario, si no manda vacío

    APP->>API: GET version_3_0/wserv_obtener_condicion_vacunas.php
    Note over APP,API: Manda: id_sysvacu04 = id de la vacuna elegida
    Note over APP,API: Manda: sysdesa10_edad = edad determinada según la lógica de arriba

    API-->>APP: Responde con condicion_vacunas[]
    Note over API,APP: Devuelve por cada condición: id_sysvacu04, id_sysvacu01, sysvacu01_descripcion, codigo_mensaje, mensaje

    alt codigo_mensaje == 0
        APP-->>U: Diálogo de error usando el campo mensaje del response
    else OK
        APP->>RAM: vacunasCondicionService guarda la lista de condiciones disponibles
        APP-->>U: Muestra el Paso 3 con la lista de condiciones
    end
```

### Paso 3 — Usuario elige una condición → carga los esquemas

```mermaid
sequenceDiagram
    actor U as Usuario
    participant APP as App
    participant API as API
    participant RAM as Memoria

    U->>APP: Toca una condición de la lista
    APP->>APP: Limpia las selecciones de esquema dosis lote

    APP->>API: GET version_3_0/wserv_obtener_esquema_vacunas.php
    Note over APP,API: Manda: id_sysvacu04 = id de la vacuna elegida en el Paso 2
    Note over APP,API: Manda: id_sysvacu01 = id de la condición elegida

    API-->>APP: Responde con esquema_vacunas[]
    Note over API,APP: Devuelve por cada esquema: id_sysvacu04, id_sysvacu01, id_sysvacu02, sysvacu02_descripcion, codigo_mensaje, mensaje

    alt codigo_mensaje == 0
        APP-->>U: Diálogo de error usando el campo mensaje del response
    else OK
        APP->>RAM: vacunasEsquemaService guarda la lista de esquemas disponibles
        APP-->>U: Muestra el Paso 4 con la lista de esquemas
    end
```

### Paso 4 — Usuario elige un esquema → carga las dosis

```mermaid
sequenceDiagram
    actor U as Usuario
    participant APP as App
    participant API as API
    participant RAM as Memoria

    U->>APP: Toca un esquema de la lista
    APP->>APP: Limpia las selecciones de dosis y lote

    APP->>API: GET version_3_0/wserv_obtener_dosis_vacunas.php
    Note over APP,API: Manda: id_sysvacu04 = id de la vacuna elegida en el Paso 2
    Note over APP,API: Manda: id_sysvacu01 = id de la condición elegida en el Paso 3
    Note over APP,API: Manda: id_sysvacu02 = id del esquema elegido

    API-->>APP: Responde con dosis_vacunas[]
    Note over API,APP: Devuelve por cada dosis: id_sysvacu04, id_sysvacu01, id_sysvacu02, id_sysvacu05, sysvacu05_nombre, codigo_mensaje, mensaje

    alt codigo_mensaje == 0
        APP-->>U: Diálogo de error usando el campo mensaje del response
    else OK
        APP->>RAM: vacunasDosisService guarda la lista de dosis disponibles
        APP-->>U: Muestra el Paso 5 con la lista de dosis
    end
```

### Paso 5 — Usuario elige una dosis — sin llamada a la API

```mermaid
sequenceDiagram
    actor U as Usuario
    participant APP as App

    U->>APP: Toca una dosis de la lista
    APP->>APP: Guarda la dosis elegida y limpia la selección de lote
    APP-->>U: Muestra el Paso 6 con el selector de fecha
```

### Paso 6 — Usuario elige la fecha → carga los lotes

```mermaid
sequenceDiagram
    actor U as Usuario
    participant APP as App
    participant API as API
    participant RAM as Memoria

    U->>APP: Elige la fecha de aplicación en el calendario desde 2021 hasta hoy
    APP->>APP: Guarda la fecha elegida
    U->>APP: Presiona Continuar

    APP->>API: GET version_3_0/wserv_obtener_lotes_vacunas.php
    Note over APP,API: Manda: id_sysvacu04 = id de la vacuna elegida en el Paso 2

    API-->>APP: Responde con lotes_vacunas[]
    Note over API,APP: Devuelve por cada lote: id_sysdesa18, sysdesa18_lote, sysdesa18_cantidad_actual, sysdesa18_fecha_vencimiento, sysvacu02_descripcion, codigo_mensaje, mensaje

    alt Lista vacía sin lotes registrados
        APP-->>U: Diálogo Sin lotes con botón Cambiar vacuna que vuelve al Paso 2 y botón Cambiar dosis que cierra el diálogo
    else codigo_mensaje == 0
        APP-->>U: Diálogo de error con el campo mensaje y botón Cambiar vacuna que vuelve al Paso 2 y botón Reintentar que cierra el diálogo
    else Error de red
        APP-->>U: Diálogo Error de conexión con botón Cambiar vacuna que vuelve al Paso 2 y botón Cerrar
    else OK
        APP->>RAM: vacunasLotesService guarda la lista de lotes disponibles
        APP-->>U: Muestra el Paso 7 con la lista de lotes
    end
```

### Paso 7 — Usuario elige un lote — sin llamada a la API

```mermaid
sequenceDiagram
    actor U as Usuario
    participant APP as App

    U->>APP: Toca un lote de la lista
    APP->>APP: Guarda el lote elegido
    APP-->>U: Muestra el Paso 8 con el resumen de toda la selección
```

### Paso 7 alternativo — Sin lotes en pantalla

```mermaid
sequenceDiagram
    actor U as Usuario
    participant APP as App

    APP-->>U: Muestra panel Sin lotes disponibles con botón Cambiar dosis que vuelve al Paso 5 y botón Cambiar vacuna que vuelve al Paso 2
```

### Paso 8 — Resumen y armado del registro — sin llamada a la API

```mermaid
sequenceDiagram
    actor U as Usuario
    participant APP as App
    participant RAM as Memoria

    APP-->>U: Muestra resumen con perfil vacuna condición esquema dosis fecha y lote elegidos
    Note over APP,U: Cada fila tiene un botón Cambiar que vuelve al paso correspondiente

    U->>APP: Presiona Continuar a confirmación

    APP->>APP: Valida que todos los datos obligatorios estén completos
    Note over APP: Verifica: beneficiario con DNI, vacuna, condición, esquema, dosis, lote
    Note over APP: Si el beneficiario es menor de edad también verifica que haya tutor cargado

    alt Falta algún dato obligatorio
        APP-->>U: Diálogo indicando qué falta completar
    else Todo completo
        APP->>RAM: insertRegistroService guarda el objeto con todos los datos del registro
        Note over APP,RAM: id_flxcore03 del registrador
        Note over APP,RAM: id_sysdesa12 del vacunador
        Note over APP,RAM: id_sysofic01 del establecimiento
        Note over APP,RAM: id_sysdesa18 del lote
        Note over APP,RAM: id_sysvacu04 de la vacuna
        Note over APP,RAM: id_sysvacu01 de la condición
        Note over APP,RAM: id_sysvacu02 del esquema
        Note over APP,RAM: id_sysvacu05 de la dosis
        Note over APP,RAM: sysdesa10_nombre sysdesa10_apellido sysdesa10_dni sysdesa10_sexo sysdesa10_edad sysdesa10_fecha_nacimiento sysdesa10_nro_tramite sysdesa10_cadena_dni del beneficiario
        Note over APP,RAM: vacunador_registrador = 1 si registrador y vacunador son la misma persona sino 0
        Note over APP,RAM: vacunacion_en_terreno = 1 o 0 según el switch de VacunadorPage
        Note over APP,RAM: fecha_aplicacion = fecha elegida en el Paso 6
        Note over APP,RAM: sysdesa10_apellido_tutor sysdesa10_nombre_tutor sysdesa10_dni_tutor sysdesa10_sexo_tutor del tutor o cadenas vacías si no hay tutor
        APP-->>U: Navega a ConfirmarDatos
    end
```

### Si el beneficiario es menor de edad — carga del tutor

```mermaid
sequenceDiagram
    actor U as Usuario
    participant APP as App
    participant API as API
    participant RAM as Memoria

    APP->>APP: Determina si el beneficiario es menor de edad
    Note over APP: Usa la edad del código de barras del DNI si existe, si no la edad del response de la API, si no la fecha de nacimiento del response

    alt Mayor de edad
        APP-->>APP: No muestra el panel de tutor
    else Menor de edad o edad desconocida
        APP-->>U: Muestra panel de tutor obligatorio

        alt Usuario escanea el DNI del tutor
            U->>APP: Escanea el código de barras del DNI del tutor
            APP->>API: GET version_3_0/wserv_obtener_datos_beneficiario.php
            Note over APP,API: Manda: sysdesa10_cadena_dni = cadena completa del código de barras del tutor
            Note over APP,API: Manda: sysdesa10_dni = número de documento del tutor extraído del escaneo
            Note over APP,API: Manda: sysdesa10_sexo = sexo del tutor extraído del escaneo
        else Usuario ingresa el DNI del tutor manualmente
            U->>APP: Ingresa el número de documento del tutor y elige sexo
            APP->>API: GET version_3_0/wserv_obtener_datos_beneficiario.php
            Note over APP,API: Manda: sysdesa10_cadena_dni = vacío porque no hubo escaneo
            Note over APP,API: Manda: sysdesa10_dni = número ingresado manualmente
            Note over APP,API: Manda: sysdesa10_sexo = M o F elegido por el usuario
        end

        API-->>APP: Responde con beneficiario[0]
        Note over API,APP: Devuelve: sysdesa10_apellido, sysdesa10_nombre, sysdesa10_dni, sysdesa10_sexo, codigo_mensaje, mensaje

        alt codigo_mensaje == 0
            APP-->>U: Diálogo No se pudo validar al tutor con el campo mensaje del response
        else Error de red
            APP-->>U: Diálogo Sin conexión
        else OK
            APP->>RAM: tutorService guarda apellido nombre dni sexo del tutor
            APP-->>U: Muestra la tarjeta del tutor cargado en pantalla
        end
    end
```

### Usuario cancela en VacunasPage

```mermaid
sequenceDiagram
    actor U as Usuario
    participant APP as App
    participant RAM as Memoria

    U->>APP: Presiona Cancelar registro y confirma el diálogo
    APP->>RAM: Limpia vacunasxPerfilService perfilesVacunacionService vacunasConfiguracionService vacunasLotesService notificacionesDosisService
    Note over APP,RAM: insertRegistroService no se limpia porque aún no fue construido en este punto
    APP-->>U: Navega a BusquedaBeneficiario
```

---

## PANTALLA 5 — ConfirmarDatos

Muestra el resumen completo antes de enviarlo. El usuario confirma y se ejecuta el único POST de toda la app.

### Lo que muestra la pantalla

```mermaid
sequenceDiagram
    participant APP as App
    participant RAM as Memoria

    APP->>RAM: Lee el registro guardado en insertRegistroService
    Note over APP,RAM: Muestra: vacuna condición esquema dosis lote
    Note over APP,RAM: Muestra: nombre apellido dni del beneficiario
    Note over APP,RAM: Muestra tarjeta del tutor solo si tiene DNI cargado
```

### Usuario confirma — POST al servidor

```mermaid
sequenceDiagram
    actor U as Usuario
    participant APP as App
    participant API as API
    participant RAM as Memoria

    U->>APP: Presiona Registrar vacunación

    APP->>API: POST version_4_0/wserv_registrar_vacuna.php
    Note over APP,API: Header: Content-Type = application/x-www-form-urlencoded charset UTF-8
    Note over APP,API: Query param insertvacunado = JSON serializado como array de un elemento con los campos del registro
    Note over APP,API: id_flxcore03, id_sysvacu04, id_sysofic01, id_sysdesa18, id_sysdesa12
    Note over APP,API: id_sysvacu01, id_sysvacu02, id_sysvacu05
    Note over APP,API: sysdesa10_nombre, sysdesa10_apellido, sysdesa10_dni, sysdesa10_sexo
    Note over APP,API: sysdesa10_nro_tramite, sysdesa10_cadena_dni, sysdesa10_edad, sysdesa10_fecha_nacimiento
    Note over APP,API: vacunador_registrador, vacunacion_en_terreno, fecha_aplicacion
    Note over APP,API: sysdesa10_apellido_tutor, sysdesa10_nombre_tutor, sysdesa10_dni_tutor, sysdesa10_sexo_tutor
    Note over APP,API: ATENCIÓN — el back lee sysdesa10_terreno pero la app envía vacunacion_en_terreno — el campo no se guarda en BD

    API-->>APP: Responde con mensajes[0]
    Note over API,APP: Devuelve: codigo_mensaje, mensaje

    alt codigo_mensaje == 0
        APP-->>U: Diálogo de error con el campo mensaje del response y botón Reintentar que cierra el diálogo
    else Error de red
        APP-->>U: Diálogo No se pudo registrar. Revise la conexión
    else OK
        APP-->>U: Diálogo de éxito con el campo mensaje del response
        APP-->>U: Navega a BusquedaBeneficiario
    end
```

### Usuario cancela

```mermaid
sequenceDiagram
    actor U as Usuario
    participant APP as App
    participant RAM as Memoria

    U->>APP: Presiona Cancelar registro y confirma el diálogo
    APP->>RAM: Limpia vacunasxPerfilService perfilesVacunacionService vacunasConfiguracionService vacunasLotesService notificacionesDosisService insertRegistroService
    APP-->>U: Navega a BusquedaBeneficiario
```
