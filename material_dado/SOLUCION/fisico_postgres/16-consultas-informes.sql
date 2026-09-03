-- ============================================================================
--  16 · Los veinte informes
--
--  Los cuatro del enunciado van marcados con [ENUNCIADO]; los que pidio el
--  profesor Hugo Nelson en la reunion, con [REUNION].
-- ============================================================================

SET search_path TO catedras, public;

\pset pager off

-- ===========================================================================
\echo '=== I1 · Asistentes de una sesion - la pantalla del dia ==='
-- ===========================================================================
SELECT id_asis, asistente, programa, programa_nombre, vinculacion,
       to_char(registrado_en, 'HH24:MI:SS') AS hora, origen
  FROM v_asistencia_completa
 WHERE id_evento_asis = '000099001'
 ORDER BY registrado_en
 LIMIT 10;

-- ===========================================================================
\echo '=== I2 · [ENUNCIADO 1] Estadisticas por programa ==='
-- ===========================================================================
SELECT coalesce(programa, '(sin programa)') AS programa,
       coalesce(programa_nombre, 'Vinculacion que no exige programa') AS nombre,
       count(*)                                  AS asistencias,
       count(DISTINCT id_asistente)              AS personas,
       round(100.0 * count(*) / sum(count(*)) OVER (), 2) AS porcentaje
  FROM v_asistencia_completa
 GROUP BY programa, programa_nombre
 ORDER BY asistencias DESC
 LIMIT 15;

-- ===========================================================================
\echo '=== I3 · Estadisticas por facultad - con jerarquia recursiva ==='
-- ===========================================================================
WITH RECURSIVE arbol AS (
    SELECT id_facultad, nombre, fk_facultad_padre, id_facultad AS raiz, 0 AS nivel
      FROM facultad WHERE fk_facultad_padre IS NULL
    UNION ALL
    SELECT f.id_facultad, f.nombre, f.fk_facultad_padre, a.raiz, a.nivel + 1
      FROM facultad f JOIN arbol a ON f.fk_facultad_padre = a.id_facultad
)
SELECT repeat('  ', ar.nivel) || ar.nombre AS facultad,
       ar.nivel,
       count(v.id_registro) AS asistencias
  FROM arbol ar
  LEFT JOIN v_asistencia_completa v ON v.facultad = ar.id_facultad
 GROUP BY ar.id_facultad, ar.nombre, ar.nivel
 ORDER BY ar.nivel, asistencias DESC;

-- ===========================================================================
\echo '=== I4 · [ENUNCIADO 2] Internos contra externos ==='
-- ===========================================================================
SELECT CASE WHEN es_interno THEN 'Interno' ELSE 'Externo' END AS tipo,
       count(*)                     AS asistencias,
       count(DISTINCT id_asistente) AS personas,
       round(100.0 * count(*) / sum(count(*)) OVER (), 2) AS porcentaje
  FROM v_asistencia_completa
 GROUP BY es_interno
 ORDER BY es_interno DESC;

-- ===========================================================================
\echo '=== I5 · [REUNION] Externos por periodo - "cuantos en 2026-2" (56:16) ==='
-- ===========================================================================
SELECT periodo,
       count(*) FILTER (WHERE NOT es_interno) AS externos,
       count(*) FILTER (WHERE es_interno)     AS internos,
       count(*)                                AS total
  FROM v_asistencia_completa
 GROUP BY periodo
 ORDER BY periodo;

-- ===========================================================================
\echo '=== I6 · [ENUNCIADO 3] Evaluacion de las catedras ==='
-- ===========================================================================
SELECT catedra, numero_reunion, orden, left(enunciado, 45) AS pregunta,
       respuestas, promedio, minimo, maximo
  FROM v_evaluacion_sesion
 ORDER BY catedra, numero_reunion, orden;

-- ===========================================================================
\echo '=== I7 · [ENUNCIADO 4] EL ARCHIVO PLANO DEL ASIS - tres columnas ==='
-- ===========================================================================
SELECT * FROM fn_exportar_asis(
    (SELECT s.id_sesion FROM sesion s JOIN catedra c ON c.id_catedra = s.fk_catedra
      WHERE c.id_evento_asis = '000099001' AND s.fk_sede = 'SAN_BENITO'))
LIMIT 8;

\echo '--- comprobacion: EXACTAMENTE 3 columnas y ningun espacio sobrante ---'
SELECT count(*) AS filas,
       count(*) FILTER (WHERE id_asis <> trim(id_asis))   AS id_con_espacios,
       count(*) FILTER (WHERE programa <> trim(programa)) AS programa_con_espacios
  FROM fn_exportar_asis(
    (SELECT s.id_sesion FROM sesion s JOIN catedra c ON c.id_catedra = s.fk_catedra
      WHERE c.id_evento_asis = '000099001' AND s.fk_sede = 'SAN_BENITO'));

-- ===========================================================================
\echo '=== I8 · [REUNION] Siguiente numero de reunion - el paso 2 del manual ==='
-- ===========================================================================
SELECT c.id_evento_asis, left(c.nombre, 40) AS catedra,
       max(s.numero_reunion)                    AS ultima_reunion,
       fn_siguiente_reunion(c.id_evento_asis)   AS siguiente
  FROM catedra c JOIN sesion s ON s.fk_catedra = c.id_catedra
 GROUP BY c.id_evento_asis, c.nombre
 ORDER BY ultima_reunion DESC
 LIMIT 5;

-- ===========================================================================
\echo '=== I9 · Las tres puertas de acceso resuelven a la misma persona ==='
-- ===========================================================================
WITH uno AS (
    SELECT a.id_asis, a.correo_institucional::text AS correo, d.numero AS documento
      FROM asistente a JOIN documento_asistente d ON d.fk_asistente = a.id_asistente
     WHERE a.id_asis IS NOT NULL AND d.vigente
     LIMIT 1)
SELECT 'por codigo'    AS via, id_asis    AS valor, fn_resolver_asistente(id_asis)    AS resuelve FROM uno
UNION ALL SELECT 'por correo',    correo,    fn_resolver_asistente(correo)    FROM uno
UNION ALL SELECT 'por documento', documento, fn_resolver_asistente(documento) FROM uno
UNION ALL SELECT 'con prefijo ID:', 'ID:' || id_asis, fn_resolver_asistente('ID:' || id_asis) FROM uno;

-- ===========================================================================
\echo '=== I10 · Registrados que NO se pueden migrar - cola del gestor ==='
-- ===========================================================================
SELECT id_evento_asis, left(catedra, 35) AS catedra, numero_reunion,
       registros, sin_id_asis, sin_programa, externos, migrables
  FROM v_pendiente_migracion
 ORDER BY registros DESC
 LIMIT 10;

-- ===========================================================================
\echo '=== I11 · H10 · personas con mas de un documento - deben ser 707 ==='
-- ===========================================================================
SELECT count(*) AS personas_con_varios_documentos
  FROM (SELECT fk_asistente FROM documento_asistente
         GROUP BY fk_asistente HAVING count(*) > 1) q;

-- ===========================================================================
\echo '=== I12 · Tasa de respuesta de la encuesta por sesion ==='
-- ===========================================================================
SELECT left(catedra, 35) AS catedra, numero_reunion,
       registros, encuestas,
       CASE WHEN registros > 0
            THEN round(100.0 * encuestas / registros, 1) END AS tasa_respuesta
  FROM v_embudo_registro
 WHERE registros > 0
 ORDER BY registros DESC
 LIMIT 10;

-- ===========================================================================
\echo '=== I13 · Embudo completo - enlaces, claves, registros, encuestas ==='
-- ===========================================================================
SELECT left(catedra, 30) AS catedra, numero_reunion,
       enlaces, claves_enviadas, claves_usadas, registros, encuestas
  FROM v_embudo_registro
 WHERE claves_enviadas > 0
 ORDER BY registros DESC;

-- ===========================================================================
\echo '=== I14 · [REUNION] Asistencia por sede y modalidad (1:03:33) ==='
-- ===========================================================================
SELECT sede, modalidad, count(*) AS asistencias, count(DISTINCT id_asistente) AS personas
  FROM v_asistencia_completa
 GROUP BY sede, modalidad
 ORDER BY asistencias DESC;

-- ===========================================================================
\echo '=== I15 · Fidelizacion - quien asiste a mas de una catedra ==='
-- ===========================================================================
SELECT id_asis, asistente, count(DISTINCT id_evento_asis) AS catedras_distintas,
       count(*) AS asistencias
  FROM v_asistencia_completa
 GROUP BY id_asis, asistente
HAVING count(DISTINCT id_evento_asis) >= 1
 ORDER BY catedras_distintas DESC, asistencias DESC
 LIMIT 5;

-- ===========================================================================
\echo '=== I16 · Catedras con sesiones sin migrar - deuda operativa ==='
-- ===========================================================================
SELECT count(*) AS sesiones_con_registros_sin_migrar
  FROM v_pendiente_migracion WHERE migrables > 0;

-- ===========================================================================
\echo '=== I17 · CONTROL de RN-15 - registros fuera de ventana. DEBE SER 0 ==='
-- ===========================================================================
SELECT count(*) AS registros_fuera_de_ventana FROM v_control_ventana;

-- ===========================================================================
\echo '=== I18 · [REUNION] Claves a correo NO institucional (55:32) ==='
-- ===========================================================================
SELECT es_correo_institucional,
       count(*)                              AS claves,
       count(*) FILTER (WHERE usado_en IS NOT NULL) AS usadas,
       count(DISTINCT fk_asistente)          AS personas
  FROM clave_acceso
 GROUP BY es_correo_institucional
 ORDER BY es_correo_institucional DESC;

\echo '--- a que dominios se esta enviando ---'
SELECT split_part(enviado_a::text, '@', 2) AS dominio, count(*) AS envios
  FROM clave_acceso GROUP BY 1 ORDER BY 2 DESC LIMIT 5;

-- ===========================================================================
\echo '=== I19 · TRAZABILIDAD COMPLETA de un registro ==='
-- ===========================================================================
SELECT r.id_registro,
       a.id_asis,
       to_char(k.generado_en, 'HH24:MI:SS')   AS clave_generada,
       k.enviado_a                            AS clave_enviada_a,
       k.es_correo_institucional              AS institucional,
       to_char(k.usado_en, 'HH24:MI:SS')      AS clave_usada,
       to_char(r.registrado_en, 'HH24:MI:SS') AS registrado,
       r.fk_programa_snapshot                 AS programa_instantanea,
       lm.nombre_archivo,
       lm.instancia_proceso_asis,
       lm.fk_estado_proceso                   AS estado_asis,
       dm.resultado
  FROM registro_asistencia r
  JOIN asistente a         ON a.id_asistente = r.fk_asistente
  LEFT JOIN clave_acceso k ON k.id_clave     = r.fk_clave
  LEFT JOIN detalle_migracion dm ON dm.fk_registro = r.id_registro
  LEFT JOIN lote_migracion lm ON lm.id_lote_migracion = dm.fk_lote_migracion
 ORDER BY r.id_registro
 LIMIT 3;

-- ===========================================================================
\echo '=== I20 · Jerarquia de dependencias - consulta recursiva ==='
-- ===========================================================================
WITH RECURSIVE arbol AS (
    SELECT id_dependencia, nombre, fk_dependencia_padre, 0 AS nivel,
           nombre::text AS ruta
      FROM dependencia WHERE fk_dependencia_padre IS NULL
    UNION ALL
    SELECT d.id_dependencia, d.nombre, d.fk_dependencia_padre, a.nivel + 1,
           a.ruta || ' > ' || d.nombre
      FROM dependencia d JOIN arbol a ON d.fk_dependencia_padre = a.id_dependencia
)
SELECT repeat('  ', nivel) || nombre AS dependencia, nivel,
       (SELECT count(*) FROM catedra c WHERE c.fk_dependencia = arbol.id_dependencia) AS catedras
  FROM arbol
 ORDER BY ruta;

\echo ''
\echo '16 · Los 20 informes ejecutados'
