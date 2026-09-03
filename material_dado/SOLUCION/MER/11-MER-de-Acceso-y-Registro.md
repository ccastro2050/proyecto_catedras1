# 11 · El MER de acceso y registro — las tres estructuras difíciles

Este es el centro de la carpeta. El acceso verificado por correo es lo que distingue este sistema del formulario anónimo de hoy, y concentra las tres estructuras que el resto del modelo no tiene.

---

## 1 · El flujo, y por qué cada entidad existe

```
  ADMINISTRADOR
       │ emite
       ▼
  ┌─────────────────┐   se difunde     ┌──────────┐
  │ ENLACE_REGISTRO │◄─── mediante ────│  SESION  │
  │  token · ventana│                  │ nº reunión│
  └────────┬────────┘                  └─────┬────┘
           │ ampara                          │ pertenece a
           ▼                                 ▼
  ┌─────────────────┐   solicita     ┌──────────────┐
  │  CLAVE_ACCESO   │◄───────────────│  ASISTENTE   │
  │ hash · enviado_a│                │ id_asis      │
  │ expira · usado  │                └──────┬───────┘
  └────────┬────────┘                       │
           │ habilita  (1,1)                │ se registra en
           ▼                                 ▼
  ┌────────────────────────────────────────────────┐
  │            REGISTRO_ASISTENCIA                  │
  │  instante · programa_snapshot · vinc_snapshot   │
  └────────┬───────────────────────────────┬────────┘
           │ es evaluado en                │ se migra en
           ▼                               ▼
  ┌──────────────────┐            ┌──────────────────┐
  │ RESPUESTA_ENCUESTA│───────────►│ DETALLE_MIGRACION│
  │      (0,1)        │  detalla   │  lo que se envió │
  └──────────────────┘   (1,N)     └──────────────────┘
```

**Cada flecha responde a una cita:**

| Flecha | Cita |
|---|---|
| Sesión → enlace | `1:06:53` — *«cuando es virtual enviamos el enlace; si es presencial, el QR»* |
| Asistente → clave | `58:07` — *«el sistema le envía una clave al correo electrónico»* |
| Clave → registro | `1:04:51` — *«yo me puedo registrar por cualquier persona, por eso tiene que ser con el correo»* |
| Registro → migración | `32:34` — *«la reunión consecutivo, el ID y el código del programa»* |

---

## 2 · Estructura difícil nº 1 — la instantánea que convive con su referencia

### El problema

`REGISTRO_ASISTENCIA` apunta a `PROGRAMA_ACADEMICO`. Y el asistente **también** tiene programas, en `PROGRAMA_ASISTENTE`. Parece redundancia. **No lo es**, y hay que poder explicar por qué en la sustentación.

### Por qué no es redundancia

Son dos hechos distintos:

| | `PROGRAMA_ASISTENTE` | `REGISTRO.fk_programa_snapshot` |
|---|---|---|
| Qué afirma | «Esta persona **está** matriculada en esto» | «Esta asistencia **se imputó** a esto» |
| Cuándo cambia | Cada semestre | **Nunca** |
| Si se borra | Se pierde la matrícula | **Se pierde la trazabilidad del archivo enviado al ASIS** |

El profesor Hugo Nelson lo dijo sin nombrarlo, en `50:14`:

> *«Las cátedras siempre le van a quedar a usted por el ID… Lo que pasa es que ahí el programa es importante porque después eso le da información a Registro de qué programas hizo el estudiante.»*

**«De qué programas hizo el estudiante»** es una afirmación sobre el pasado. Si el programa se lee siempre del vigente, un estudiante que cambia de carrera **reescribe su propio historial de asistencias**, y los informes por programa de semestres cerrados cambian solos.

### La prueba que lo decide

> Genere el archivo plano de una sesión de marzo. Guárdelo. En junio, el asistente cambia de programa. **Vuelva a generar el archivo de esa misma sesión de marzo.**
>
> - Con referencia viva: **sale distinto**. El archivo ya no reproduce lo que se envió al ASIS.
> - Con instantánea: **sale idéntico**.

El ASIS ya recibió la primera versión. Si el sistema no puede reproducirla, ninguna diferencia se puede depurar.

### Por qué no es un atributo derivado

Un derivado se recalcula y **da lo mismo**. Una instantánea se recalcula y **da otra cosa**. Es la diferencia entre `nombre_asis` —que siempre serán los mismos 30 caracteres— y el programa de una asistencia.

### Alternativas evaluadas

| Alternativa | Por qué no |
|---|---|
| Leer siempre el programa vigente | Reescribe el historial. Es el problema |
| Guardar solo el texto del código, sin clave foránea | Pierde la integridad: podría quedar un código que no existe |
| Versionar `PROGRAMA_ASISTENTE` con vigencias y consultar «a fecha» | **Es correcto y más puro**, pero exige un `JOIN` con rango de fechas en la consulta más frecuente del sistema, y el archivo plano se vuelve caro. **Se acepta como alternativa legítima si se justifica** |

---

## 3 · Estructura difícil nº 2 — la regla condicional entre atributos

Dos reglas del modelo no son «este campo es obligatorio» sino **«este campo es obligatorio dependiendo del valor de otro»**. Ninguna clave foránea las expresa.

### 3.1 · El programa, obligatorio salvo excepción

De `41:16`, el profesor Hugo Nelson:

> *«Para el tema de Rutas de Paz sí sería una excepción: ellos entrarían sin programa, pero solo ellos.»*

La regla completa es:

> **`fk_programa_snapshot` debe estar lleno si y solo si el tipo de vinculación exige programa.**

Y hay tres formas de escribirla:

| Forma | Cómo se ve | Veredicto |
|---|---|---|
| **A ·** Dejarlo simplemente opcional | `fk_programa` nullable, sin más | **Insuficiente.** Permite un estudiante sin programa, que es lo que rompe el archivo plano |
| **B ·** Restricción con la lista escrita | `CHECK (vinculacion = 'RUTAS_PAZ' OR programa IS NOT NULL)` | **Frágil.** «Solo ellos» hoy; mañana hay otra población y toca `ALTER TABLE` en producción |
| **C ·** Atributo del catálogo | `TIPO_VINCULACION.exige_programa` + restricción que lo consulta | **La elegida.** Habilitar una excepción es un `UPDATE` de una fila |

**La lección general:** cuando el usuario experto dice *«solo ellos»*, está describiendo el estado de hoy, no una ley. Lo que hay que modelar es **la categoría de la excepción**, no la excepción.

### 3.2 · El tipo de pregunta decide dónde va la respuesta

`RESPUESTA_ITEM` tiene tres atributos de valor —numérico, texto y opción— y **exactamente uno** debe estar lleno, según el tipo de la pregunta.

| Tipo de pregunta | Se llena |
|---|---|
| Escala 1-5 | `valor_numerico` |
| Sí/no | `valor_numerico` (0 o 1) |
| Texto libre | `valor_texto` |
| Opción única o múltiple | `fk_opcion` |

Los tres vacíos, o dos llenos, es **dato corrupto**, no un caso opcional.

| Alternativa | Por qué no |
|---|---|
| Tres columnas nullables sin restricción | Corrupción silenciosa. Los promedios saldrían mal sin avisar |
| Una sola columna de texto con todo dentro | Un promedio exigiría convertir texto a número en cada consulta. Y un texto no convertible rompe el informe 3 |
| **Especialización supertipo/subtipo** — una tabla por tipo de respuesta | **Es la solución ortodoxa y se acepta.** Cuesta tres tablas y una unión en cada consulta |
| **Tres columnas con restricción condicional** | **La elegida.** Una tabla, y la regla se hace cumplir |

---

## 4 · Estructura difícil nº 3 — la participación mínima de uno

### El enunciado

Tres afirmaciones del modelo tienen la forma **«debe haber al menos uno»**:

1. Toda encuesta respondida tiene **al menos un** ítem (R29).
2. Toda pregunta **obligatoria** de la encuesta tiene respuesta.
3. Todo lote de migración lleva **al menos un** detalle.

### Por qué ninguna clave foránea las garantiza

> **Una clave foránea garantiza que *lo que se inserte exista*, no que *se inserte algo*.**

La clave foránea de `RESPUESTA_ITEM` hacia `RESPUESTA_ENCUESTA` impide que exista un ítem huérfano. **No impide que exista una cabecera sin ningún ítem.** Es el lado contrario de la relación, y no tiene mecanismo declarativo en SQL.

La segunda es todavía más dura: no es «al menos uno», es **«uno por cada pregunta marcada obligatoria»**, y eso depende del contenido de otra tabla que además cambia con cada versión de la encuesta.

### Cómo se resuelven

| Regla | Mecanismo | Dónde |
|---|---|---|
| Encuesta con al menos un ítem | **Procedimiento** que crea cabecera e ítems en una sola transacción | `11-funciones-procedimientos.sql` |
| Preguntas obligatorias respondidas | **Procedimiento de cierre** que valida contra el catálogo antes de marcar `completa` | idem |
| Lote con al menos un detalle | **Procedimiento** de generación del archivo | idem |
| Verificación | **Consultas de control** que deben devolver cero | `16-consultas-informes.sql` |

> **Que no sea declarativa no significa que se pueda omitir.** Significa que hay que **declararla aquí** para que quien revise no la busque como restricción y concluya que se olvidó — y que hay que **medirla**, porque lo que no es declarativo se degrada.

---

## 5 · La decisión abierta: quién entra y quién no

El §3.1 del plan recoge un conflicto entre cuatro citas de la reunión, y **el modelo lo deja explícito en vez de esconderlo**.

| Cita | Dice |
|---|---|
| `26:46` el profesor Hugo Nelson | *«Para poder inscribir la cátedra en ASIS, cualquier persona debe estar registrada en ASIS con ID»* |
| `55:52` el profesor Carlos Castro | *«Solo los que estén en esa tabla pueden ingresar al sistema. Si no, no pueden ingresar»* |
| `43:37` el profesor Hugo Nelson | *«Si son externos… eso lo podemos depurar antes de pasarlo»* |
| `56:16` el profesor Hugo Nelson | *«Que nos genere un registro de externos… que sí podamos descargar cuántos externos han ingresado en 2026-2»* |

**Las dos primeras dicen que sin ID no se entra. Las dos últimas piden contar externos.** No pueden ser ciertas a la vez si el externo nunca entra.

### Lo que hace el modelo mientras se decide

Implementa la **salida C**: `id_asis` es opcional y `es_externo` lo marca. Eso permite las cuatro citas a la vez, cuesta una columna, y **no cierra ninguna puerta**:

- Si se confirma la **salida A** —crear ID en el ASIS a todo externo—, basta con volver `id_asis` obligatorio. Ningún dato se pierde.
- Si se confirma la **salida C**, ya está hecho.

> **Está marcado como revisable en el modelo, no resuelto en silencio.** Es la primera pregunta del §12 del plan y hay que llevarla a la reunión.

---

## 6 · Lo que este subsistema garantiza y lo que no

**Garantiza:**

- Que nadie se registre dos veces en la misma sesión.
- Que nadie se registre fuera de la ventana horaria.
- Que todo registro tenga detrás una clave enviada a un correo concreto, con su hora.
- Que quede constancia de a qué correo salió y si era institucional.
- Que el archivo enviado al ASIS sea reproducible meses después.

**No garantiza** —y hay que decirlo:

- Que la persona que digitó la clave sea la dueña del correo. El profesor Carlos Castro lo reconoció en `1:05:18`: *«esa trampa se puede hacer»*, cuando el profesor Hugo Nelson señaló que basta con pedirle el código a alguien por teléfono.

**Es un riesgo aceptado explícitamente por la dirección técnica**, no un descuido del modelo. Se mitiga con la ventana horaria corta y se vigila con el informe de embudo. Si algún día se quisiera cerrar, el modelo ya tiene dónde: `enlace_registro` admite un destinatario nominal, y ahí el enlace deja de ser público.

---

**Anterior:** [10 · Diagramas](10-Diagramas-MER.md) · **Siguiente nivel:** [`../MR/`](../MR/)
