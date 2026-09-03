# Lista de chequeo de requisitos — Versión 1

> **Versión 1** ([mapa](../0_mapa_versiones.md)) · Rige la
> [constitución](../../1_constitution.md).
>
> | Documento | Contenido |
> |---|---|
> | [2_spec.md](2_spec.md) | QUÉ construir y los criterios de aceptación |
> | [3_plan.md](3_plan.md) | CÓMO: el stack, las capas y sus decisiones |
> | [4_research.md](4_research.md) | Las decisiones, con lo que se descartó |
> | [5_data_model.md](5_data_model.md) | La tabla, sus datos y quién escribe qué |
> | [6_contracts.md](6_contracts.md) | Los endpoints y las pantallas |
> | [7_quickstart.md](7_quickstart.md) | Arranque y smoke test |
> | [8_tasks.md](8_tasks.md) | El orden de construcción por fases |
> | [9_checklist.md](9_checklist.md) | La compuerta 3: se firma ANTES de programar |
> | [GUIA_IA1.md](GUIA_IA1.md) | Construirla con ayuda de una IA |

---

> **La compuerta 3** del método. Esta lista revisa **la ESPECIFICACIÓN, no el
> código**: se corre cuando los documentos 2 a 8 están escritos y **ANTES** de
> programar la primera línea.

## Cómo se usa

- **Las casillas las marca una persona.** Una IA puede ayudar a evaluar y a
  señalar dudas, pero **no puede auto-aprobarse**: quien firma es quien
  responde por la versión.
- Se marca `[x]` solo cuando el criterio se cumple **hoy, en el documento** —
  no "cuando lo arregle".
- **Con una sola casilla en rojo no se escribe código.**
- Trabaja bien en pareja: un estudiante revisa la spec del otro.

---

## A. Claridad — ¿dice UNA sola cosa?

- [ ] Ningún requisito usa palabras sin definir: *rápido, amigable, correcto,
      adecuado, robusto*.
- [ ] No queda ningún marcador `[NECESITA ACLARACIÓN: …]` sin resolver.
- [ ] Cada RF explica UNA cosa.

## B. Alcance — ¿se sabe qué NO se hace?

- [ ] El "NO incluye" de [2_spec §2](2_spec.md) es explícito.
- [ ] Las otras 36 tablas quedan fuera, dichas por su nombre.
- [ ] Está dicho que la carga masiva **no se ejecuta**, y por qué.

## C. Verificabilidad — ¿se puede EJECUTAR cada criterio?

- [ ] Cada criterio de aceptación dice con qué se comprueba.
- [ ] El criterio 4 (el opcional nulo) se comprueba **mirando la base**, no
      creyéndole a la API.
- [ ] El criterio 7 (borrado lógico) comprueba que **la fila sigue ahí**.
- [ ] El criterio 8 (apagar la API) está escrito como un paso reproducible.
- [ ] El criterio 9 dice **explícitamente** que la prueba no referencia el
      paquete del motor.

## D. Coherencia con la constitución

- [ ] El chequeo de [3_plan §5](3_plan.md) está completo, artículo por
      artículo.
- [ ] Ningún artículo tuvo que cambiarse para que esta versión quepa.
- [ ] La excepción del Artículo 7 (secretos a la vista) está **declarada**, no
      escondida.

## E. Trazabilidad

- [ ] Cada RF tiene al menos un criterio que lo cubre.
- [ ] Cada endpoint y cada pantalla de [6_contracts](6_contracts.md) sale de
      un RF.
- [ ] Cada fase de [8_tasks](8_tasks.md) termina en una verificación.
- [ ] Cada clarificación de [2_spec §6](2_spec.md) dice **dónde quedó**.

## F. Las decisiones tienen razón, no gusto

- [ ] Cada decisión de [4_research](4_research.md) dice qué se descartó y por
      qué.
- [ ] La decisión de poner **el front en otro lenguaje** dice qué se gana y
      qué cuesta.
- [ ] La decisión de que **el nombre único lo defienda la base** explica por
      qué comprobarlo en la API no funcionaría.

## G. Propia de esta versión: los datos personales

> Esta sección existe porque el material original traía datos de quince mil
> personas, y esa es la clase de cosa que no se puede dejar a la memoria de
> nadie.

- [ ] **Está escrito, en la constitución, que el repositorio no lleva datos de
      personas reales.**
- [ ] La cabecera de `db/init.sql` dice **qué se quitó, cuánto era y por qué**.
- [ ] Está dicho que se quitaron **los datos, no el mecanismo**.
- [ ] Está dicho por qué **"anonimizar" no era una opción** (ver
      [D3](4_research.md)).
- [ ] Los datos hipotéticos son **evidentemente inventados**: nombres de
      ejemplo, códigos en rangos reservados.
- [ ] Alguien **buscó en el repositorio** —no solo en la base— que no queden
      archivos con datos reales.

## H. Propia de este proyecto: back y front EN PARALELO

> Esta sección existe porque este repositorio es el **piloto** de esa
> estrategia ([Artículo 1.1](../../1_constitution.md)), y una estrategia que
> solo está declarada no cambia nada.

- [ ] **Cada requisito funcional tiene sus dos bloques**, `En la API` y
      `En la pantalla`. Si alguno tiene uno vacío, está justificado en su sitio.
- [ ] **Cada fase de [8_tasks](8_tasks.md) que tenga pantalla se verifica en
      el navegador**, y su verificación lo dice.
- [ ] Los criterios de aceptación indican **por qué vía** se comprueba cada
      uno, y los que tienen pantalla no se comprueban solo con `curl`.
- [ ] Está dicho, en algún documento, que **una versión no está cerrada si la
      API responde y la pantalla no**.

## I. Propia de este proyecto: la identidad visual

- [ ] Los valores del manual están en un archivo **aparte** de los estilos
      propios, para que sean una restricción y no una preferencia.
- [ ] Está dicho **por qué no hay archivo de logosímbolo** en el repositorio.
- [ ] Está dicho **en qué versión se evalúa** la imagen corporativa completa,
      y por qué no es esta.

---

## Todo lo que rige el proyecto está en el spec kit

> La última comprobación, y la que resume el método: **si una regla no está en
> un documento del spec kit, no está especificada** — por más que "todo el
> mundo la sepa".

- [ ] Las **historias de usuario** están en el spec kit
      ([`0_historias_de_usuario.md`](../../0_historias_de_usuario.md)), no
      sueltas en la raíz.
- [ ] La **identidad visual** está en la constitución (Artículo 9.1), no solo
      en el README ni solo en un `.css`.
- [ ] La regla de los **datos personales** está en la constitución
      (Artículo 8), no solo en la cabecera de un `.sql`.
- [ ] La **estrategia de versionado** está en la constitución (Artículo 1.1) y
      razonada en el [mapa](../0_mapa_versiones.md).
- [ ] Cada requisito **cita la historia** de la que sale, y cada historia dice
      **en qué versión** entra: la trazabilidad va en los dos sentidos.

---

## Firma

Cuando todas las casillas estén en verde:

```
Revisada por: ______________________     Fecha: ____________
```

**Sin esta firma no se escribe código.**
