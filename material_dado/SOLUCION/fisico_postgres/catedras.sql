-- ==========================================================================
--  CATEDRAS ABIERTAS  ·  Universidad de San Buenaventura, Medellin
--  Base de datos completa, en UN SOLO script.
-- ==========================================================================
--
--  QUE HACE
--    Crea la base `catedras` desde cero: 37 tablas, 6 vistas, 22 rutinas,
--    7 disparadores, los catalogos, la carga real del ASIS, los indices,
--    los cuatro roles y las funciones envoltorio de la API.
--
--  COMO SE EJECUTA
--
--    cd SOLUCION/fisico_postgres
--    python preparar-datos.py          <- genera datos/*.csv desde los Excel
--    psql -U postgres -f catedras.sql
--
--    Debe ejecutarse DESDE esta carpeta: los \copy del bloque 13 buscan
--    datos/*.csv por ruta relativa.
--
--  SI SOLO QUIERE LA BASE YA CARGADA, sin reconstruirla, use el respaldo:
--    ApiCatedrasUsbmed/sql/backup/catedras.dump
--
--  TODO VA EN EL ESQUEMA `public`. No se crea un esquema aparte: la API,
--  las rutinas y pgAdmin apuntan todos ahi, y un esquema propio obligaba a
--  fijar el search_path en cada sesion y en cada rutina.
--
--  COMO ESTA ORGANIZADO
--    18 bloques numerados, cada uno con su cabecera. El orden NO es el de la
--    numeracion original: los disparadores van antes de los datos (la carga
--    los ejercita, que es como se comprueban) y los indices van al final (un
--    indice sobre una tabla vacia no dice nada).
--
--  Los informes NO estan aqui: son consultas, no construccion. Estan en
--  16-consultas-informes.sql.
-- ==========================================================================

\set ON_ERROR_STOP on
\timing on



-- ==========================================================================
--  1/18  ·  Base de datos, extensiones y esquema
--  fuente: 00-crear-bd.sql
-- ==========================================================================

\echo ''
\echo '>>> 1/18 · Base de datos, extensiones y esquema'

-- ============================================================================
--  00 · Base de datos, extensiones y esquema
--  Proyecto: Catedras Abiertas - Universidad de San Buenaventura, Medellin
--  Motor:    PostgreSQL 14 o superior
--
--  Ejecutar conectado a la base 'postgres':
--      psql -U postgres -f 00-crear-bd.sql
-- ============================================================================


-- Cortar las sesiones abiertas contra la base.
--
-- Sin esto, con pgAdmin abierto sobre `catedras` el DROP falla con
-- "la base de datos esta siendo utilizada por otros usuarios" y el script entero
-- se detiene en la primera linea. Es el tropiezo mas comun al reconstruir.
SELECT pg_terminate_backend(pid)
  FROM pg_stat_activity
 WHERE datname = 'catedras' AND pid <> pg_backend_pid();

-- La creacion de la base va fuera de transaccion.
DROP DATABASE IF EXISTS catedras;

CREATE DATABASE catedras
    WITH ENCODING  = 'UTF8'
         TEMPLATE  = template0
         LC_COLLATE = 'C'
         LC_CTYPE   = 'C';

COMMENT ON DATABASE catedras IS
    'Registro y control de asistencia a catedras abiertas. Sustituye el '
    'formulario anonimo y la migracion manual al ASIS.';

\connect catedras

-- ----------------------------------------------------------------------------
-- Extensiones
--
-- Cada una responde a una necesidad concreta del modelo; ninguna esta
-- por costumbre. Ver fisico_postgres/README.md, apartado 3.
-- ----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS pgcrypto;    -- hash de la clave de acceso (RN-18)
CREATE EXTENSION IF NOT EXISTS btree_gist;  -- EXCLUDE de ventanas solapadas (RN-36)
CREATE EXTENSION IF NOT EXISTS citext;      -- correos sin distinguir mayusculas (RN-06)
CREATE EXTENSION IF NOT EXISTS unaccent;    -- normalizacion de texto libre
CREATE EXTENSION IF NOT EXISTS pg_trgm;     -- emparejamiento difuso de programas

-- ----------------------------------------------------------------------------
-- Esquema
--
-- Todo va en `public`. Hubo una version con un esquema propio `catedras`, y se
-- abandono: obligaba a fijar el search_path en la cadena de conexion, en cada
-- sesion de pgAdmin y -- lo que de verdad dolio -- con un ALTER FUNCTION sobre
-- CADA UNA de las 22 rutinas, porque el `SET search_path` de un script NO queda
-- horneado en la funcion que se crea bajo el. Olvidar uno solo daba
-- "no existe la relacion registro_asistencia" sobre una tabla que si existia.
--
-- Lo que se pierde es poder revocar permisos sobre public de un golpe. Se
-- compensa en 17-usuarios-permisos.sql, que revoca objeto por objeto.
-- ----------------------------------------------------------------------------
COMMENT ON SCHEMA public IS
    'Todos los objetos del sistema de catedras abiertas.';

-- unaccent() debe ser inmutable para poder indexarla; se envuelve.
CREATE OR REPLACE FUNCTION public.fn_normalizar(p_texto text)
RETURNS text
LANGUAGE sql IMMUTABLE PARALLEL SAFE
AS $$
    SELECT lower(trim(regexp_replace(
               public.unaccent('public.unaccent', coalesce(p_texto, '')),
               '\s+', ' ', 'g')));
$$;

COMMENT ON FUNCTION public.fn_normalizar(text) IS
    'Baja a minusculas, quita tildes y colapsa espacios. Es la funcion con que '
    'se compara el texto libre de los formularios contra alias_programa. '
    'Es IMMUTABLE a proposito: si no, no se puede construir el indice GIN.';

SET search_path TO public;

\echo '00 · Base catedras creada, con 5 extensiones, sobre el esquema public'


-- ==========================================================================
--  2/18  ·  DDL · Bloque A · asistentes e identidad
--  fuente: 01-ddl-asistentes.sql
-- ==========================================================================

\echo ''
\echo '>>> 2/18 · DDL · Bloque A · asistentes e identidad'

-- ============================================================================
--  01 · DDL - Bloque A · Asistentes e identidad
--  Tablas: tipo_documento · asistente · documento_asistente
--          tipo_vinculacion · vinculacion_asistente · consentimiento_datos
--
--  Las claves foraneas se declaran en el script 08.
-- ============================================================================

SET search_path TO public;

-- ----------------------------------------------------------------------------
-- tipo_documento
-- ----------------------------------------------------------------------------
CREATE TABLE tipo_documento (
    id_tipo_documento  varchar(5)   NOT NULL,
    nombre             varchar(60)  NOT NULL,
    activo             boolean      NOT NULL DEFAULT true,

    CONSTRAINT pk_tipo_documento     PRIMARY KEY (id_tipo_documento),
    CONSTRAINT uq_tipo_documento_nom UNIQUE (nombre)
);

COMMENT ON TABLE tipo_documento IS
    'Clase de documento de identidad. Catalogo cerrado que elimina las mas de '
    'diez formas de escribir "cedula" que trae el formulario actual.';

-- ----------------------------------------------------------------------------
-- asistente
--
-- La entidad central. Conserva el nombre que le dio el usuario experto.
-- ----------------------------------------------------------------------------
CREATE TABLE asistente (
    id_asistente          bigint        GENERATED ALWAYS AS IDENTITY,
    id_asis               varchar(15),
    nombres               varchar(100)  NOT NULL,
    apellidos             varchar(100)  NOT NULL,
    nombre_completo_asis  varchar(200),
    correo_institucional  citext,
    correo_personal       citext,
    celular               varchar(20),
    es_externo            boolean       NOT NULL DEFAULT false,
    activo                boolean       NOT NULL DEFAULT true,
    creado_en             timestamptz   NOT NULL DEFAULT now(),
    fk_lote_carga         bigint,

    CONSTRAINT pk_asistente        PRIMARY KEY (id_asistente),
    CONSTRAINT uq_asistente_asis   UNIQUE (id_asis),
    CONSTRAINT uq_asistente_corinst UNIQUE (correo_institucional),

    -- RN-03 · dominio del id_asis, corregido contra el dato real
    CONSTRAINT chk_asistente_idasis
        CHECK (id_asis IS NULL OR id_asis ~ '^[0-9A-Za-z]{5,15}$'),

    -- RN-01 · el interno tiene id_asis; el externo, no
    CONSTRAINT chk_asistente_externo
        CHECK ( (es_externo = false AND id_asis IS NOT NULL)
             OR (es_externo = true) ),

    -- Todo asistente necesita al menos una via de contacto para la clave
    CONSTRAINT chk_asistente_correo
        CHECK (correo_institucional IS NOT NULL OR correo_personal IS NOT NULL),

    CONSTRAINT chk_asistente_cor_inst_fmt
        CHECK (correo_institucional IS NULL OR correo_institucional LIKE '%@%.%'),
    CONSTRAINT chk_asistente_cor_pers_fmt
        CHECK (correo_personal IS NULL OR correo_personal LIKE '%@%.%')
);

COMMENT ON TABLE asistente IS
    'Persona que asiste a las catedras abiertas, de forma presencial o virtual. '
    'Puede ser estudiante, docente, administrativo, egresado, participante de '
    'rutas de formacion o publico externo.';

COMMENT ON COLUMN asistente.id_asis IS
    'Codigo de identificacion en el sistema ASIS. CORREGIDO respecto del '
    'archivo original: es ALFANUMERICO de hasta 15 caracteres, no 10 digitos. '
    'El maestro real trae 9.553 filas de 11 caracteres y valores como 1000513C. '
    'NULO significa que es un externo que no esta en el ASIS - decision '
    'REVISABLE, ver §3.1 del plan.';

COMMENT ON COLUMN asistente.nombre_completo_asis IS
    'El nombre tal como llego del ASIS, sin transformar. Permite rehacer la '
    'particion en nombres y apellidos si resulta equivocada.';

COMMENT ON COLUMN asistente.correo_personal IS
    'No es un caso raro: los participantes de Rutas de Paz NO tienen correo '
    'institucional, y es su unica via para recibir la clave.';

-- ----------------------------------------------------------------------------
-- documento_asistente
--
-- Atributo multivaluado convertido en tabla: 707 personas del maestro real
-- tienen mas de un numero de documento.
-- ----------------------------------------------------------------------------
CREATE TABLE documento_asistente (
    id_documento       bigint      GENERATED ALWAYS AS IDENTITY,
    fk_asistente       bigint      NOT NULL,
    fk_tipo_documento  varchar(5)  NOT NULL,
    numero             varchar(20) NOT NULL,
    vigente            boolean     NOT NULL DEFAULT true,
    registrado_en      timestamptz NOT NULL DEFAULT now(),

    CONSTRAINT pk_documento_asistente PRIMARY KEY (id_documento),
    -- RN-04 · un documento identifica a lo sumo una persona (verificado: 0 casos)
    CONSTRAINT uq_documento_numero    UNIQUE (fk_tipo_documento, numero),
    CONSTRAINT chk_documento_numero   CHECK (numero ~ '^[0-9A-Za-z-]{4,20}$')
);

COMMENT ON TABLE documento_asistente IS
    'Numero de documento asociado a un asistente. Una persona puede tener '
    'varios a lo largo del tiempo; solo uno esta vigente (RN-05, indice '
    'parcial en el script 09). Sirve para resolver el ID cuando la persona '
    'no lo recuerda y digita la cedula.';

-- ----------------------------------------------------------------------------
-- tipo_vinculacion
--
-- Las dos columnas booleanas son el corazon de este catalogo: convierten
-- dos reglas del negocio en dato modificable con un UPDATE.
-- ----------------------------------------------------------------------------
CREATE TABLE tipo_vinculacion (
    id_tipo_vinculacion  varchar(15)  NOT NULL,
    nombre               varchar(60)  NOT NULL,
    es_interno           boolean      NOT NULL,
    exige_programa       boolean      NOT NULL DEFAULT true,
    activo               boolean      NOT NULL DEFAULT true,

    CONSTRAINT pk_tipo_vinculacion     PRIMARY KEY (id_tipo_vinculacion),
    CONSTRAINT uq_tipo_vinculacion_nom UNIQUE (nombre)
);

COMMENT ON COLUMN tipo_vinculacion.es_interno IS
    'Resuelve el informe 2 del enunciado - internos contra externos - con una '
    'agrupacion, en vez de un CASE de veinte lineas.';

COMMENT ON COLUMN tipo_vinculacion.exige_programa IS
    'FALSO en Rutas de Paz. Traduce la frase "ellos entrarian sin programa, '
    'pero solo ellos" (41:16) en un DATO. Habilitar una nueva excepcion es un '
    'UPDATE de una fila, no un ALTER TABLE en produccion.';

-- ----------------------------------------------------------------------------
-- vinculacion_asistente
--
-- Relacion N:M con atributos. fecha_ini ENTRA EN LA CLAVE PRIMARIA.
-- ----------------------------------------------------------------------------
CREATE TABLE vinculacion_asistente (
    fk_asistente         bigint      NOT NULL,
    fk_tipo_vinculacion  varchar(15) NOT NULL,
    fecha_ini            date        NOT NULL,
    fecha_fin            date,

    CONSTRAINT pk_vinculacion_asistente
        PRIMARY KEY (fk_asistente, fk_tipo_vinculacion, fecha_ini),
    CONSTRAINT chk_vinculacion_fechas
        CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_ini)
);

COMMENT ON TABLE vinculacion_asistente IS
    'Vinculacion institucional de una persona a lo largo del tiempo.';

COMMENT ON CONSTRAINT pk_vinculacion_asistente ON vinculacion_asistente IS
    'fecha_ini ENTRA EN LA CLAVE PRIMARIA. Sin ella, un egresado que se '
    'matricula en una maestria no podria volver a ser estudiante: el INSERT '
    'se rechazaria y el historico quedaria incompleto en silencio.';

-- ----------------------------------------------------------------------------
-- consentimiento_datos
-- ----------------------------------------------------------------------------
CREATE TABLE consentimiento_datos (
    id_consentimiento  bigint       GENERATED ALWAYS AS IDENTITY,
    fk_asistente       bigint       NOT NULL,
    version_politica   varchar(20)  NOT NULL,
    aceptado_en        timestamptz  NOT NULL DEFAULT now(),
    ip                 inet,
    canal              varchar(20)  NOT NULL DEFAULT 'WEB',

    CONSTRAINT pk_consentimiento     PRIMARY KEY (id_consentimiento),
    CONSTRAINT uq_consentimiento_ver UNIQUE (fk_asistente, version_politica),
    CONSTRAINT chk_consentimiento_canal
        CHECK (canal IN ('WEB', 'PRESENCIAL', 'CORREO', 'IMPORTADO'))
);

COMMENT ON TABLE consentimiento_datos IS
    'Ley 1581 de 2012. El sistema guarda documentos, nombres y correos '
    'personales de externos: el consentimiento es un HECHO que se registra, '
    'no un aviso en la pantalla.';

\echo '01 · Bloque A creado - 6 tablas'


-- ==========================================================================
--  3/18  ·  DDL · Bloque B · estructura academica
--  fuente: 02-ddl-academico.sql
-- ==========================================================================

\echo ''
\echo '>>> 3/18 · DDL · Bloque B · estructura academica'

-- ============================================================================
--  02 · DDL - Bloque B · Estructura academica
--  Tablas: facultad · programa_academico · periodo_academico
--          programa_asistente
-- ============================================================================

SET search_path TO public;

-- ----------------------------------------------------------------------------
-- facultad · relacion reflexiva -> arbol
-- ----------------------------------------------------------------------------
CREATE TABLE facultad (
    id_facultad         varchar(10)   NOT NULL,
    nombre              varchar(120)  NOT NULL,
    fk_facultad_padre   varchar(10),
    activo              boolean       NOT NULL DEFAULT true,

    CONSTRAINT pk_facultad        PRIMARY KEY (id_facultad),
    CONSTRAINT uq_facultad_nombre UNIQUE (nombre),
    -- Una facultad no puede ser su propia madre
    CONSTRAINT chk_facultad_padre CHECK (fk_facultad_padre <> id_facultad)
);

COMMENT ON TABLE facultad IS
    'Unidad academica que agrupa programas. La referencia reflexiva produce un '
    'ARBOL - cada nodo tiene un solo padre -, no un grafo. Por eso se resuelve '
    'con una columna en la misma tabla y se consulta con WITH RECURSIVE.';

-- ----------------------------------------------------------------------------
-- programa_academico · clave NATURAL
-- ----------------------------------------------------------------------------
CREATE TABLE programa_academico (
    codigo       varchar(5)    NOT NULL,
    nombre       varchar(150)  NOT NULL,
    fk_facultad  varchar(10),
    nivel        varchar(25)   NOT NULL DEFAULT 'PREGRADO',
    activo       boolean       NOT NULL DEFAULT true,

    CONSTRAINT pk_programa_academico PRIMARY KEY (codigo),
    -- El codigo NO es siempre M + 4 digitos: el maestro real trae MCDER (5)
    -- y MCCP (4). Es varchar y no char PORQUE char rellena con espacios, y
    -- 'MCCP ' saldria con un espacio final en el archivo plano - justo lo
    -- que el manual de migracion prohibe: "verificar que el archivo este
    -- limpio y que no se haya agregado ningun texto adicional".
    CONSTRAINT chk_programa_codigo   CHECK (codigo ~ '^[A-Z][0-9A-Z]{3,4}$'),
    CONSTRAINT chk_programa_nivel
        CHECK (nivel IN ('PREGRADO', 'ESPECIALIZACION', 'MAESTRIA',
                         'DOCTORADO', 'EDUCACION_CONTINUA', 'OTRO'))
);

COMMENT ON TABLE programa_academico IS
    'Programa academico. 105 codigos distintos en el maestro real: 103 con la '
    'forma M + 4 digitos, mas MCDER de 5 caracteres y MCCP de 4.';

COMMENT ON COLUMN programa_academico.codigo IS
    'CLAVE NATURAL a proposito: es el codigo que viaja al archivo plano del '
    'ASIS. Un identificador sustituto obligaria a un JOIN en la consulta mas '
    'critica del sistema, que es justamente la exportacion.';

-- ----------------------------------------------------------------------------
-- periodo_academico
-- ----------------------------------------------------------------------------
CREATE TABLE periodo_academico (
    id_periodo  char(6)  NOT NULL,
    fecha_ini   date     NOT NULL,
    fecha_fin   date     NOT NULL,
    activo      boolean  NOT NULL DEFAULT true,

    CONSTRAINT pk_periodo_academico PRIMARY KEY (id_periodo),
    CONSTRAINT chk_periodo_formato  CHECK (id_periodo ~ '^[0-9]{4}-[1-3]$'),
    CONSTRAINT chk_periodo_fechas   CHECK (fecha_fin > fecha_ini)
);

COMMENT ON TABLE periodo_academico IS
    'Periodo academico: 2026-1, 2026-2. Lo pidio el profesor Hugo Nelson por su '
    'nombre - "cuantas personas externas han ingresado en 2026-2" (56:16).';

-- ----------------------------------------------------------------------------
-- programa_asistente · N:M con atributos
-- ----------------------------------------------------------------------------
CREATE TABLE programa_asistente (
    fk_asistente  bigint    NOT NULL,
    fk_programa   varchar(5) NOT NULL,
    fk_periodo    char(6)   NOT NULL,
    estado        varchar(15) NOT NULL DEFAULT 'ACTIVO',

    CONSTRAINT pk_programa_asistente
        PRIMARY KEY (fk_asistente, fk_programa, fk_periodo),
    CONSTRAINT chk_programa_asistente_estado
        CHECK (estado IN ('ACTIVO', 'RETIRADO', 'GRADUADO', 'APLAZADO'))
);

COMMENT ON TABLE programa_asistente IS
    'Matricula de un asistente en un programa, por periodo. Es N:M por dato '
    'comprobado: en el maestro real el mismo ID aparece con varios codigos de '
    'programa. La clave de tres columnas absorbe los pares duplicados que trae '
    'el archivo del ASIS - hay pares repetidos hasta tres veces.';

\echo '02 · Bloque B creado - 4 tablas'


-- ==========================================================================
--  4/18  ·  DDL · Bloque C · catedras, sesiones y sedes
--  fuente: 03-ddl-catedras.sql
-- ==========================================================================

\echo ''
\echo '>>> 4/18 · DDL · Bloque C · catedras, sesiones y sedes'

-- ============================================================================
--  03 · DDL - Bloque C · Catedras, sesiones y sedes
--  Tablas: tipo_evento · sede · modalidad · dependencia
--          catedra · sesion · ponencia
-- ============================================================================

SET search_path TO public;

-- ----------------------------------------------------------------------------
-- tipo_evento · los 8 codigos reales del ASIS
-- ----------------------------------------------------------------------------
CREATE TABLE tipo_evento (
    id_tipo_evento  char(4)      NOT NULL,
    nombre          varchar(80)  NOT NULL,
    activo          boolean      NOT NULL DEFAULT true,

    CONSTRAINT pk_tipo_evento PRIMARY KEY (id_tipo_evento)
);

COMMENT ON TABLE tipo_evento IS
    'Clasificacion del evento en el ASIS. Ocho valores observados en las 5.711 '
    'filas reales: CAAB (5.449), DLLH (188), DEPR (44), SLDI (16), ARCU (5), '
    'MTG (5), DIIB (3), EIIC (1).';

-- ----------------------------------------------------------------------------
-- sede
-- ----------------------------------------------------------------------------
CREATE TABLE sede (
    id_sede     varchar(15)   NOT NULL,
    nombre      varchar(80)   NOT NULL,
    direccion   varchar(200),
    es_virtual  boolean       NOT NULL DEFAULT false,
    activo      boolean       NOT NULL DEFAULT true,

    CONSTRAINT pk_sede        PRIMARY KEY (id_sede),
    CONSTRAINT uq_sede_nombre UNIQUE (nombre)
);

COMMENT ON TABLE sede IS
    'Lugar fisico o virtual donde se dicta una sesion. Aparece porque "puede '
    'que una catedra este en San Benito, otra este virtual y otra este en '
    'Bello" (1:03:33): LA SEDE ES LO QUE DISTINGUE DOS CATEDRAS A LA MISMA '
    'HORA. Como texto libre en sesion, el informe por sede no se puede escribir.';

-- ----------------------------------------------------------------------------
-- modalidad · gobierna comportamiento, no es una etiqueta
-- ----------------------------------------------------------------------------
CREATE TABLE modalidad (
    id_modalidad    varchar(15)  NOT NULL,
    nombre          varchar(60)  NOT NULL,
    canal_difusion  varchar(10)  NOT NULL,
    activo          boolean      NOT NULL DEFAULT true,

    CONSTRAINT pk_modalidad          PRIMARY KEY (id_modalidad),
    CONSTRAINT chk_modalidad_canal   CHECK (canal_difusion IN ('QR', 'ENLACE', 'AMBOS'))
);

COMMENT ON COLUMN modalidad.canal_difusion IS
    'QR si es presencial, ENLACE si es virtual. Traduce la regla del profesor '
    'Hugo Nelson en 1:06:53: "cuando es virtual enviamos el enlace; si es '
    'presencial, el QR". Se hace cumplir en el script 10 (RN-13).';

-- ----------------------------------------------------------------------------
-- dependencia · reflexiva -> arbol
-- ----------------------------------------------------------------------------
CREATE TABLE dependencia (
    id_dependencia         varchar(15)   NOT NULL,
    nombre                 varchar(120)  NOT NULL,
    fk_dependencia_padre   varchar(15),
    activo                 boolean       NOT NULL DEFAULT true,

    CONSTRAINT pk_dependencia        PRIMARY KEY (id_dependencia),
    CONSTRAINT uq_dependencia_nombre UNIQUE (nombre),
    CONSTRAINT chk_dependencia_padre CHECK (fk_dependencia_padre <> id_dependencia)
);

-- ----------------------------------------------------------------------------
-- catedra
-- ----------------------------------------------------------------------------
CREATE TABLE catedra (
    id_catedra       bigint        GENERATED ALWAYS AS IDENTITY,
    id_evento_asis   char(9)       NOT NULL,
    nombre           varchar(200)  NOT NULL,
    nombre_asis      varchar(30)   GENERATED ALWAYS AS (left(nombre, 30)) STORED,
    fk_tipo_evento   char(4)       NOT NULL,
    fk_dependencia   varchar(15),
    activo           boolean       NOT NULL DEFAULT true,
    creado_en        timestamptz   NOT NULL DEFAULT now(),

    CONSTRAINT pk_catedra       PRIMARY KEY (id_catedra),
    CONSTRAINT uq_catedra_asis  UNIQUE (id_evento_asis),
    -- RN-09 · nueve caracteres, con ceros a la izquierda
    CONSTRAINT chk_catedra_asis CHECK (id_evento_asis ~ '^[0-9]{9}$')
);

COMMENT ON COLUMN catedra.id_evento_asis IS
    'Identificador del evento en el ASIS. char(9) CON CEROS A LA IZQUIERDA: '
    '000035392. Como entero se convierte en 35392 y deja de servir para la '
    'carga.';

COMMENT ON COLUMN catedra.nombre_asis IS
    'DERIVADO: los 30 primeros caracteres, que es lo que acepta el ASIS. El '
    'listado real trae nombres cortados a mitad de palabra - "REMOCION DE '
    'METALES PESADOS DE", "CURSO FORMATIVO LOGICO MATEMAT". Guardando el '
    'largo y derivando el corto, no se pierde informacion. Al reves, si.';

-- ----------------------------------------------------------------------------
-- sesion · ENTIDAD DEBIL de catedra
-- ----------------------------------------------------------------------------
CREATE TABLE sesion (
    id_sesion            bigint        GENERATED ALWAYS AS IDENTITY,
    fk_catedra           bigint        NOT NULL,
    numero_reunion       smallint      NOT NULL,
    numero_reunion_asis  smallint,
    titulo               varchar(200),
    inicio               timestamptz   NOT NULL,
    fin                  timestamptz   NOT NULL,
    fk_modalidad         varchar(15)   NOT NULL,
    fk_sede              varchar(15)   NOT NULL,
    fk_periodo           char(6)       NOT NULL,
    fk_encuesta          bigint,
    lugar                varchar(200),
    enlace_virtual       varchar(300),
    cupo                 integer,
    estado               varchar(15)   NOT NULL DEFAULT 'PROGRAMADA',
    creado_en            timestamptz   NOT NULL DEFAULT now(),

    CONSTRAINT pk_sesion PRIMARY KEY (id_sesion),
    -- RN-10 · el consecutivo por catedra. Verificado: el par es unico en las
    --         5.711 filas reales de USBME_LCONTROL_CATEDRAS
    CONSTRAINT uq_sesion_reunion  UNIQUE (fk_catedra, numero_reunion),
    CONSTRAINT chk_sesion_reunion CHECK (numero_reunion >= 1),
    -- RN-37
    CONSTRAINT chk_sesion_fechas  CHECK (fin > inicio),
    CONSTRAINT chk_sesion_cupo    CHECK (cupo IS NULL OR cupo > 0),
    CONSTRAINT chk_sesion_estado
        CHECK (estado IN ('PROGRAMADA', 'ABIERTA', 'CERRADA', 'MIGRADA'))
);

COMMENT ON TABLE sesion IS
    'Cada una de las reuniones en que se dicta una catedra. ENTIDAD DEBIL: la '
    '"reunion 3" no significa nada suelta, es la reunion 3 DE UN EVENTO.';

COMMENT ON COLUMN sesion.numero_reunion IS
    'El numero de reunion con que la sesion viaja al ASIS. Si no se indica, el '
    'disparador del script 10 PROPONE el maximo de la catedra mas uno - y eso '
    'elimina el paso 2 del manual para las catedras nuevas. Para las que ya '
    'existen en el ASIS, el valor bueno es numero_reunion_asis: el dato real '
    'demuestra que el ASIS no numera por evento desde 1.';

COMMENT ON COLUMN sesion.numero_reunion_asis IS
    'El numero de reunion segun el ASIS. DECISION RESUELTA POR EL DATO: el ASIS '
    'lleva un contador propio - de 5.481 eventos con una sola reunion, solo 588 '
    'tienen el numero 1, y los demas llegan hasta 4348. Cuando esta columna '
    'tiene valor, MANDA sobre numero_reunion.';

-- ----------------------------------------------------------------------------
-- ponencia · N:M con atributo
-- ----------------------------------------------------------------------------
CREATE TABLE ponencia (
    fk_sesion     bigint       NOT NULL,
    fk_asistente  bigint       NOT NULL,
    rol           varchar(15)  NOT NULL DEFAULT 'PONENTE',

    CONSTRAINT pk_ponencia  PRIMARY KEY (fk_sesion, fk_asistente, rol),
    CONSTRAINT chk_ponencia_rol
        CHECK (rol IN ('PONENTE', 'MODERADOR', 'INVITADO', 'ORGANIZADOR'))
);

\echo '03 · Bloque C creado - 7 tablas'


-- ==========================================================================
--  5/18  ·  DDL · Bloque D · acceso y registro
--  fuente: 04-ddl-registro.sql
-- ==========================================================================

\echo ''
\echo '>>> 5/18 · DDL · Bloque D · acceso y registro'

-- ============================================================================
--  04 · DDL - Bloque D · Acceso y registro · EL NUCLEO DEL MODELO
--  Tablas: enlace_registro · clave_acceso · registro_asistencia
--
--  Aqui estan la ventana como rango, el EXCLUDE de no solapamiento y las dos
--  columnas de instantanea que hacen reproducible el archivo del ASIS.
-- ============================================================================

SET search_path TO public;

-- ----------------------------------------------------------------------------
-- enlace_registro
--
-- El QR y la URL NO son dos entidades: son dos presentaciones del mismo token.
-- Separarlas duplicaria la ventana horaria y permitiria que se contradijeran.
-- ----------------------------------------------------------------------------
CREATE TABLE enlace_registro (
    id_enlace        bigint       GENERATED ALWAYS AS IDENTITY,
    fk_sesion        bigint       NOT NULL,
    token            uuid         NOT NULL DEFAULT gen_random_uuid(),
    url_publica      varchar(300) NOT NULL,
    ruta_imagen_qr   varchar(300),
    canal            varchar(10)  NOT NULL,
    ventana          tstzrange    NOT NULL,
    usos_maximos     integer,
    revocado_en      timestamptz,
    fk_usuario_crea  bigint,
    creado_en        timestamptz  NOT NULL DEFAULT now(),

    CONSTRAINT pk_enlace_registro PRIMARY KEY (id_enlace),
    -- RN-16 · el token es unico y no adivinable
    CONSTRAINT uq_enlace_token    UNIQUE (token),
    CONSTRAINT chk_enlace_canal   CHECK (canal IN ('QR', 'ENLACE')),
    CONSTRAINT chk_enlace_ventana CHECK (NOT isempty(ventana)
                                     AND lower(ventana) IS NOT NULL
                                     AND upper(ventana) IS NOT NULL),
    CONSTRAINT chk_enlace_usos    CHECK (usos_maximos IS NULL OR usos_maximos > 0),
    -- La ruta de la imagen debe ser RELATIVA
    CONSTRAINT chk_enlace_ruta_qr
        CHECK (ruta_imagen_qr IS NULL
               OR (ruta_imagen_qr !~ '^([A-Za-z]:|/|\\\\)')),

    -- RN-36 · dos enlaces de la MISMA sesion no pueden solaparse en el tiempo.
    --         Declarativo gracias a btree_gist. En otro motor esto seria un
    --         disparador con bloqueo explicito.
    CONSTRAINT ex_enlace_sin_solape
        EXCLUDE USING gist (fk_sesion WITH =, ventana WITH &&)
        WHERE (revocado_en IS NULL)
);

COMMENT ON TABLE enlace_registro IS
    'Punto de entrada al registro de una sesion, materializado como QR o como '
    'URL. El .docx exige que "el QR y URL no pueden ser reutilizables" y que '
    'tengan "hora de inicio y hora de cierre" configurables.';

COMMENT ON COLUMN enlace_registro.ventana IS
    'Apertura y cierre EN UN SOLO ATRIBUTO de rango. Con dos columnas sueltas, '
    'ni el EXCLUDE de RN-36 ni la contencion de RN-15 serian declarativos: '
    'los dos serian codigo que alguien tendria que mantener.';

COMMENT ON COLUMN enlace_registro.canal IS
    'QR o ENLACE. Debe concordar con la modalidad de la sesion (RN-13).';

COMMENT ON CONSTRAINT ex_enlace_sin_solape ON enlace_registro IS
    'RN-36. El WHERE hace que los enlaces revocados no estorben: se puede '
    'revocar uno y emitir otro para la misma franja.';

-- ----------------------------------------------------------------------------
-- clave_acceso
--
-- No es autenticacion: es ANTISUPLANTACION. "Yo me puedo registrar por
-- cualquier persona, por eso tiene que ser con el correo; si no, yo te
-- registro a vos y vos me registras a mi" (1:04:51).
-- ----------------------------------------------------------------------------
CREATE TABLE clave_acceso (
    id_clave                bigint       GENERATED ALWAYS AS IDENTITY,
    fk_asistente            bigint       NOT NULL,
    fk_enlace               bigint       NOT NULL,
    clave_hash              bytea        NOT NULL,
    enviado_a               citext       NOT NULL,
    es_correo_institucional boolean      NOT NULL,
    generado_en             timestamptz  NOT NULL DEFAULT now(),
    expira_en               timestamptz  NOT NULL,
    usado_en                timestamptz,
    intentos                smallint     NOT NULL DEFAULT 0,
    ip_solicitud            inet,

    CONSTRAINT pk_clave_acceso     PRIMARY KEY (id_clave),
    CONSTRAINT chk_clave_expira    CHECK (expira_en > generado_en),
    -- RN-20 · una clave usada lo fue dentro de su vigencia
    CONSTRAINT chk_clave_usada     CHECK (usado_en IS NULL
                                      OR (usado_en >= generado_en AND usado_en <= expira_en)),
    CONSTRAINT chk_clave_intentos  CHECK (intentos >= 0 AND intentos <= 10),
    CONSTRAINT chk_clave_correo    CHECK (enviado_a LIKE '%@%.%')
);

COMMENT ON COLUMN clave_acceso.clave_hash IS
    'RN-34 · La clave CIFRADA. Nunca se guarda en claro. Se calcula con '
    'digest() de pgcrypto en el procedimiento sp_solicitar_clave.';

COMMENT ON COLUMN clave_acceso.es_correo_institucional IS
    'DERIVADO del dominio de enviado_a por el disparador del script 10. '
    'Es la columna que responde al asunto que el profesor Carlos Castro dejo '
    'abierto en 55:32: "a mi no me gusta el correo que no sea institucional; '
    'dejame, yo lo resuelvo". El modelo deja el dato listo y medible (I18) '
    'para que la politica se decida con la evidencia a la vista.';

-- ----------------------------------------------------------------------------
-- registro_asistencia · EL ROMBO CENTRAL
-- ----------------------------------------------------------------------------
CREATE TABLE registro_asistencia (
    id_registro               bigint       GENERATED ALWAYS AS IDENTITY,
    fk_sesion                 bigint       NOT NULL,
    fk_asistente              bigint       NOT NULL,
    fk_enlace                 bigint,
    fk_clave                  bigint,
    registrado_en             timestamptz  NOT NULL DEFAULT now(),
    fk_programa_snapshot      varchar(5),
    fk_vinculacion_snapshot   varchar(15)  NOT NULL,
    origen                    varchar(15)  NOT NULL DEFAULT 'QR',
    ip                        inet,
    user_agent                varchar(300),

    CONSTRAINT pk_registro_asistencia PRIMARY KEY (id_registro),
    -- RN-21 · una persona se registra a lo sumo UNA VEZ por sesion
    CONSTRAINT uq_registro_sesion_asis UNIQUE (fk_sesion, fk_asistente),
    CONSTRAINT chk_registro_origen
        CHECK (origen IN ('QR', 'ENLACE', 'MANUAL', 'IMPORTADO')),
    -- Todo registro no manual nace de una clave usada (RN-17)
    CONSTRAINT chk_registro_clave
        CHECK (origen IN ('MANUAL', 'IMPORTADO') OR fk_clave IS NOT NULL)
);

COMMENT ON TABLE registro_asistencia IS
    'Hecho de que un asistente quedo registrado en una sesion, en un instante '
    'concreto, con el programa y la vinculacion que tenia en ese momento. Es la '
    'tabla central del sistema.';

COMMENT ON COLUMN registro_asistencia.fk_programa_snapshot IS
    'INSTANTANEA, no referencia viva. El programa que el asistente tenia EL DIA '
    'de la catedra. NUNCA se actualiza. Razon: "el programa es importante '
    'porque despues eso le da informacion a Registro de que programas hizo el '
    'estudiante" (50:14) - es una afirmacion sobre el pasado. Si se leyera del '
    'vigente, un estudiante que cambia de carrera reescribiria su propio '
    'historial y el archivo enviado al ASIS dejaria de ser reproducible. '
    'NULO cuando la vinculacion no exige programa (Rutas de Paz, RN-07).';

COMMENT ON COLUMN registro_asistencia.fk_vinculacion_snapshot IS
    'INSTANTANEA de la vinculacion. Un egresado que asistio siendo estudiante '
    'debe seguir contando como estudiante en los informes de aquel periodo.';

\echo '04 · Bloque D creado - 3 tablas, con el EXCLUDE de RN-36'


-- ==========================================================================
--  6/18  ·  DDL · Bloque E · encuesta
--  fuente: 05-ddl-encuesta.sql
-- ==========================================================================

\echo ''
\echo '>>> 6/18 · DDL · Bloque E · encuesta'

-- ============================================================================
--  05 · DDL - Bloque E · Encuesta de calidad parametrizable
--  Tablas: encuesta · tipo_pregunta · pregunta · opcion_pregunta
--          respuesta_encuesta · respuesta_item
--
--  Cuatro tablas de definicion y dos de respuesta, en vez de cinco columnas
--  fijas, porque el enunciado dice que "el administrador configura o
--  parametriza los valores que considere".
-- ============================================================================

SET search_path TO public;

-- ----------------------------------------------------------------------------
-- encuesta
-- ----------------------------------------------------------------------------
CREATE TABLE encuesta (
    id_encuesta     bigint       GENERATED ALWAYS AS IDENTITY,
    nombre          varchar(120) NOT NULL,
    version         smallint     NOT NULL DEFAULT 1,
    vigente_desde   date         NOT NULL DEFAULT current_date,
    vigente_hasta   date,
    activa          boolean      NOT NULL DEFAULT true,

    CONSTRAINT pk_encuesta        PRIMARY KEY (id_encuesta),
    CONSTRAINT uq_encuesta_ver    UNIQUE (nombre, version),
    CONSTRAINT chk_encuesta_ver   CHECK (version >= 1),
    CONSTRAINT chk_encuesta_vig   CHECK (vigente_hasta IS NULL
                                      OR vigente_hasta >= vigente_desde)
);

COMMENT ON TABLE encuesta IS
    'Cuestionario de calidad en una version concreta. Se versiona porque con '
    'columnas fijas, cambiar una pregunta romperia la comparabilidad '
    'historica: las respuestas viejas quedarian bajo un enunciado que no es el '
    'que se pregunto.';

-- ----------------------------------------------------------------------------
-- tipo_pregunta · decide DONDE se guarda la respuesta
-- ----------------------------------------------------------------------------
CREATE TABLE tipo_pregunta (
    id_tipo_pregunta  varchar(15)  NOT NULL,
    nombre            varchar(60)  NOT NULL,
    guarda_numero     boolean      NOT NULL DEFAULT false,
    guarda_texto      boolean      NOT NULL DEFAULT false,
    guarda_opcion     boolean      NOT NULL DEFAULT false,

    CONSTRAINT pk_tipo_pregunta PRIMARY KEY (id_tipo_pregunta),
    -- Exactamente uno de los tres destinos
    CONSTRAINT chk_tipo_pregunta_destino
        CHECK (guarda_numero::int + guarda_texto::int + guarda_opcion::int = 1)
);

COMMENT ON TABLE tipo_pregunta IS
    'Clase de pregunta. Las tres columnas booleanas dicen en cual de las tres '
    'columnas de valor de respuesta_item se guarda la respuesta. Es lo que '
    'permite que la regla condicional (RN-25) sea DATO y no codigo.';

-- ----------------------------------------------------------------------------
-- pregunta
-- ----------------------------------------------------------------------------
CREATE TABLE pregunta (
    id_pregunta       bigint       GENERATED ALWAYS AS IDENTITY,
    fk_encuesta       bigint       NOT NULL,
    enunciado         varchar(300) NOT NULL,
    orden             smallint     NOT NULL,
    fk_tipo_pregunta  varchar(15)  NOT NULL,
    obligatoria       boolean      NOT NULL DEFAULT false,
    valor_min         smallint,
    valor_max         smallint,

    CONSTRAINT pk_pregunta      PRIMARY KEY (id_pregunta),
    CONSTRAINT uq_pregunta_ord  UNIQUE (fk_encuesta, orden),
    CONSTRAINT chk_pregunta_ord CHECK (orden >= 1),
    CONSTRAINT chk_pregunta_rango
        CHECK ((valor_min IS NULL AND valor_max IS NULL)
            OR (valor_min IS NOT NULL AND valor_max IS NOT NULL AND valor_max > valor_min))
);

-- ----------------------------------------------------------------------------
-- opcion_pregunta
-- ----------------------------------------------------------------------------
CREATE TABLE opcion_pregunta (
    id_opcion    bigint       GENERATED ALWAYS AS IDENTITY,
    fk_pregunta  bigint       NOT NULL,
    etiqueta     varchar(150) NOT NULL,
    valor        smallint,
    orden        smallint     NOT NULL,

    CONSTRAINT pk_opcion_pregunta PRIMARY KEY (id_opcion),
    CONSTRAINT uq_opcion_orden    UNIQUE (fk_pregunta, orden)
);

-- ----------------------------------------------------------------------------
-- respuesta_encuesta · 1:1 con el registro
-- ----------------------------------------------------------------------------
CREATE TABLE respuesta_encuesta (
    id_respuesta   bigint       GENERATED ALWAYS AS IDENTITY,
    fk_registro    bigint       NOT NULL,
    fk_encuesta    bigint       NOT NULL,
    respondida_en  timestamptz  NOT NULL DEFAULT now(),
    completa       boolean      NOT NULL DEFAULT false,

    CONSTRAINT pk_respuesta_encuesta PRIMARY KEY (id_respuesta),
    -- RN-23 · una encuesta por registro, como maximo
    CONSTRAINT uq_respuesta_registro UNIQUE (fk_registro)
);

COMMENT ON COLUMN respuesta_encuesta.completa IS
    'Solo lo marca sp_cerrar_encuesta, tras comprobar que todas las preguntas '
    'obligatorias tienen respuesta (RN-26). Es una regla NO DECLARATIVA: '
    'ninguna clave foranea puede exigir "al menos uno".';

-- ----------------------------------------------------------------------------
-- respuesta_item · ENTIDAD DEBIL, con la regla condicional
-- ----------------------------------------------------------------------------
CREATE TABLE respuesta_item (
    id_item         bigint    GENERATED ALWAYS AS IDENTITY,
    fk_respuesta    bigint    NOT NULL,
    fk_pregunta     bigint    NOT NULL,
    valor_numerico  smallint,
    valor_texto     text,
    fk_opcion       bigint,

    CONSTRAINT pk_respuesta_item PRIMARY KEY (id_item),
    CONSTRAINT uq_respuesta_item UNIQUE (fk_respuesta, fk_pregunta),

    -- RN-25 · EXACTAMENTE UNA columna de valor. Los tres vacios, o dos llenos,
    --         es dato corrupto, no un caso opcional.
    CONSTRAINT chk_respuesta_item_un_valor
        CHECK ( (valor_numerico IS NOT NULL)::int
              + (valor_texto    IS NOT NULL)::int
              + (fk_opcion      IS NOT NULL)::int = 1 )
);

COMMENT ON CONSTRAINT chk_respuesta_item_un_valor ON respuesta_item IS
    'RN-25. Impide la corrupcion silenciosa: sin esta restriccion, un item con '
    'las tres columnas vacias se colaria y los promedios del informe de '
    'evaluacion saldrian mal SIN AVISAR. La concordancia entre la columna '
    'usada y el tipo de la pregunta la verifica el disparador del script 10.';

COMMENT ON TABLE respuesta_item IS
    'Respuesta a una pregunta concreta. La alternativa ortodoxa es una '
    'especializacion supertipo/subtipo con una tabla por tipo de respuesta: '
    'es correcta y se acepta, pero cuesta tres tablas y una union en cada '
    'consulta de evaluacion.';

\echo '05 · Bloque E creado - 6 tablas'


-- ==========================================================================
--  7/18  ·  DDL · Bloque F · integracion con el ASIS
--  fuente: 06-ddl-integracion.sql
-- ==========================================================================

\echo ''
\echo '>>> 7/18 · DDL · Bloque F · integracion con el ASIS'

-- ============================================================================
--  06 · DDL - Bloque F · Integracion con el ASIS
--  Tablas: lote_carga_asistente · novedad_carga · alias_programa
--          estado_proceso · lote_migracion · detalle_migracion
--
--  Entrada: el archivo de personas que se descarga del ASIS.
--  Salida:  el archivo plano de TRES columnas que exige la carga.
-- ============================================================================

SET search_path TO public;

-- ----------------------------------------------------------------------------
-- lote_carga_asistente
-- ----------------------------------------------------------------------------
CREATE TABLE lote_carga_asistente (
    id_lote_carga    bigint       GENERATED ALWAYS AS IDENTITY,
    nombre_archivo   varchar(200) NOT NULL,
    cargado_en       timestamptz  NOT NULL DEFAULT now(),
    fk_usuario       bigint,
    filas_leidas     integer      NOT NULL DEFAULT 0,
    filas_aceptadas  integer      NOT NULL DEFAULT 0,
    filas_rechazadas integer      NOT NULL DEFAULT 0,
    observaciones    text,

    CONSTRAINT pk_lote_carga PRIMARY KEY (id_lote_carga),
    CONSTRAINT chk_lote_carga_filas
        CHECK (filas_leidas >= 0 AND filas_aceptadas >= 0 AND filas_rechazadas >= 0
               AND filas_aceptadas + filas_rechazadas <= filas_leidas)
);

COMMENT ON TABLE lote_carga_asistente IS
    'Cada ejecucion de la carga del archivo de personas del ASIS. "Ese archivo '
    'lo cargamos en la base de datos como una tabla" (52:57). Una carga de '
    '16.093 filas necesita EVIDENCIA, no un mensaje en pantalla: sin estos '
    'contadores, "cargo menos filas de las que tenia" es indepurable.';

-- ----------------------------------------------------------------------------
-- novedad_carga
-- ----------------------------------------------------------------------------
CREATE TABLE novedad_carga (
    id_novedad       bigint       GENERATED ALWAYS AS IDENTITY,
    fk_lote_carga    bigint       NOT NULL,
    numero_fila      integer      NOT NULL,
    contenido_crudo  text         NOT NULL,
    motivo           varchar(200) NOT NULL,

    CONSTRAINT pk_novedad_carga  PRIMARY KEY (id_novedad),
    CONSTRAINT chk_novedad_fila  CHECK (numero_fila > 0)
);

COMMENT ON COLUMN novedad_carga.contenido_crudo IS
    'La fila del archivo TAL COMO VENIA, sin interpretar. Es lo unico que '
    'permite depurar un rechazo por formato: si se guardara ya convertida, se '
    'perderia justamente el dato que causo el problema.';

-- ----------------------------------------------------------------------------
-- alias_programa · tabla VIVA, no script de una vez
-- ----------------------------------------------------------------------------
CREATE TABLE alias_programa (
    id_alias           bigint       GENERATED ALWAYS AS IDENTITY,
    texto_normalizado  varchar(200) NOT NULL,
    fk_programa        varchar(5)   NOT NULL,
    origen             varchar(30)  NOT NULL DEFAULT 'FORMULARIO',
    creado_en          timestamptz  NOT NULL DEFAULT now(),

    CONSTRAINT pk_alias_programa PRIMARY KEY (id_alias),
    CONSTRAINT uq_alias_texto    UNIQUE (texto_normalizado)
);

COMMENT ON TABLE alias_programa IS
    'Texto libre con que se ha escrito un programa, y el codigo al que '
    'corresponde. Nace de la calidad real del formulario actual, que trae '
    '"Psicologica", "Entrenamiento Deportivo.", "Ingenieria de datos y '
    'software" y una celda con la facultad y el programa en dos lineas. '
    'Es una tabla VIVA porque los formularios en texto libre van a seguir '
    'llegando durante toda la transicion.';

-- ----------------------------------------------------------------------------
-- estado_proceso · los CINCO estados literales del manual, pagina 6
-- ----------------------------------------------------------------------------
CREATE TABLE estado_proceso (
    id_estado    varchar(12)  NOT NULL,
    nombre       varchar(40)  NOT NULL,
    es_final     boolean      NOT NULL DEFAULT false,
    es_exitoso   boolean      NOT NULL DEFAULT false,

    CONSTRAINT pk_estado_proceso PRIMARY KEY (id_estado),
    CONSTRAINT chk_estado_coherente
        CHECK (es_exitoso = false OR es_final = true)
);

COMMENT ON TABLE estado_proceso IS
    'Estados del Monitor Procesos del ASIS. Son los cinco literales del manual '
    'de migracion: En cola, En curso, Error, Correcto, Incorrecto.';

-- ----------------------------------------------------------------------------
-- lote_migracion
-- ----------------------------------------------------------------------------
CREATE TABLE lote_migracion (
    id_lote_migracion      bigint       GENERATED ALWAYS AS IDENTITY,
    fk_sesion              bigint       NOT NULL,
    nombre_proceso         varchar(60)  NOT NULL DEFAULT 'ME_MIGRACION_CATEDRA',
    nombre_archivo         varchar(200) NOT NULL,
    generado_en            timestamptz  NOT NULL DEFAULT now(),
    fk_usuario             bigint,
    instancia_proceso_asis varchar(30),
    fk_estado_proceso      varchar(12)  NOT NULL DEFAULT 'GENERADO',
    total_filas            integer      NOT NULL DEFAULT 0,
    observaciones          text,

    CONSTRAINT pk_lote_migracion PRIMARY KEY (id_lote_migracion),
    CONSTRAINT chk_lote_mig_filas CHECK (total_filas >= 0)
);

COMMENT ON COLUMN lote_migracion.instancia_proceso_asis IS
    'El numero de instancia que devuelve el ASIS al ejecutar el proceso en '
    'PSUNX01. Es lo que permite cerrar el ciclo contra el Monitor Procesos.';

-- ----------------------------------------------------------------------------
-- detalle_migracion · guarda LO QUE SE ENVIO
-- ----------------------------------------------------------------------------
CREATE TABLE detalle_migracion (
    id_detalle         bigint       GENERATED ALWAYS AS IDENTITY,
    fk_lote_migracion  bigint       NOT NULL,
    fk_registro        bigint       NOT NULL,
    id_asis_enviado    varchar(15)  NOT NULL,
    programa_enviado   varchar(5),
    reunion_enviada    smallint     NOT NULL,
    resultado          varchar(12)  NOT NULL DEFAULT 'PENDIENTE',
    mensaje            varchar(300),

    CONSTRAINT pk_detalle_migracion PRIMARY KEY (id_detalle),
    CONSTRAINT uq_detalle_lote_reg  UNIQUE (fk_lote_migracion, fk_registro),
    CONSTRAINT chk_detalle_resultado
        CHECK (resultado IN ('PENDIENTE', 'ACEPTADO', 'RECHAZADO'))
);

COMMENT ON TABLE detalle_migracion IS
    'Cada fila enviada en un lote, TAL COMO SE ENVIO, y el resultado que dio.';

COMMENT ON COLUMN detalle_migracion.id_asis_enviado IS
    'COPIA LITERAL del ID que salio en el archivo. Se repite a proposito una '
    'columna que ya esta en asistente: NO SON LO MISMO. Si el dato de origen '
    'cambia despues del envio, la tabla dira una cosa y el ASIS tendra otra, '
    'y sin esta copia un rechazo es indepurable seis meses despues.';

COMMENT ON COLUMN detalle_migracion.programa_enviado IS
    'COPIA LITERAL del codigo de programa. NULO solo es legitimo si la '
    'vinculacion no exigia programa - y en ese caso el registro no deberia '
    'haber entrado al lote (RN-28).';

\echo '06 · Bloque F creado - 6 tablas'


-- ==========================================================================
--  8/18  ·  DDL · Bloque G · seguridad y configuracion
--  fuente: 07-ddl-seguridad.sql
-- ==========================================================================

\echo ''
\echo '>>> 8/18 · DDL · Bloque G · seguridad y configuracion'

-- ============================================================================
--  07 · DDL - Bloque G · Seguridad, configuracion y auditoria
--  Tablas: usuario · rol · rol_por_usuario · parametro · bitacora
-- ============================================================================

SET search_path TO public;

-- ----------------------------------------------------------------------------
-- usuario
--
-- El administrador ES una persona del ASIS: se apoya en asistente y asi no se
-- duplican nombres ni correos.
-- ----------------------------------------------------------------------------
CREATE TABLE usuario (
    id_usuario     bigint       GENERATED ALWAYS AS IDENTITY,
    fk_asistente   bigint       NOT NULL,
    usuario        varchar(40)  NOT NULL,
    clave_hash     varchar(255) NOT NULL,
    activo         boolean      NOT NULL DEFAULT true,
    ultimo_acceso  timestamptz,
    creado_en      timestamptz  NOT NULL DEFAULT now(),

    CONSTRAINT pk_usuario         PRIMARY KEY (id_usuario),
    CONSTRAINT uq_usuario_login   UNIQUE (usuario),
    -- 1:1 con asistente
    CONSTRAINT uq_usuario_persona UNIQUE (fk_asistente),
    CONSTRAINT chk_usuario_login  CHECK (usuario ~ '^[a-z0-9._-]{4,40}$')
);

COMMENT ON COLUMN usuario.clave_hash IS
    'RN-34 · Nunca la clave en claro. Aqui se guarda un hash con sal; el '
    'algoritmo lo decide la aplicacion (bcrypt o argon2 preferiblemente).';

-- ----------------------------------------------------------------------------
-- rol
-- ----------------------------------------------------------------------------
CREATE TABLE rol (
    id_rol       varchar(20)  NOT NULL,
    nombre       varchar(60)  NOT NULL,
    descripcion  varchar(200),

    CONSTRAINT pk_rol        PRIMARY KEY (id_rol),
    CONSTRAINT uq_rol_nombre UNIQUE (nombre)
);

-- ----------------------------------------------------------------------------
-- rol_por_usuario · la misma leccion que vinculacion_asistente
-- ----------------------------------------------------------------------------
CREATE TABLE rol_por_usuario (
    fk_usuario  bigint       NOT NULL,
    fk_rol      varchar(20)  NOT NULL,
    fecha_ini   date         NOT NULL DEFAULT current_date,
    fecha_fin   date,

    CONSTRAINT pk_rol_por_usuario PRIMARY KEY (fk_usuario, fk_rol, fecha_ini),
    CONSTRAINT chk_rol_usuario_fechas
        CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_ini)
);

COMMENT ON CONSTRAINT pk_rol_por_usuario ON rol_por_usuario IS
    'RN-31 · fecha_ini EN LA CLAVE PRIMARIA. Sin ella, quien fue administrador, '
    'dejo de serlo y vuelve, quedaria bloqueado para siempre. Es el mismo '
    'error que en vinculacion_asistente, y falla igual de silenciosamente.';

-- ----------------------------------------------------------------------------
-- parametro
-- ----------------------------------------------------------------------------
CREATE TABLE parametro (
    clave               varchar(60)  NOT NULL,
    valor               varchar(200) NOT NULL,
    tipo_dato           varchar(15)  NOT NULL DEFAULT 'TEXTO',
    descripcion         varchar(300) NOT NULL,
    fk_usuario_modifica bigint,
    modificado_en       timestamptz  NOT NULL DEFAULT now(),

    CONSTRAINT pk_parametro PRIMARY KEY (clave),
    CONSTRAINT chk_parametro_tipo
        CHECK (tipo_dato IN ('TEXTO', 'ENTERO', 'BOOLEANO', 'FECHA', 'DECIMAL'))
);

COMMENT ON TABLE parametro IS
    'Configuracion que el administrador cambia sin tocar el codigo. Del .docx: '
    '"el administrador configura o parametriza los valores que considere".';

-- ----------------------------------------------------------------------------
-- bitacora
-- ----------------------------------------------------------------------------
CREATE TABLE bitacora (
    id_bitacora    bigint       GENERATED ALWAYS AS IDENTITY,
    ocurrido_en    timestamptz  NOT NULL DEFAULT now(),
    usuario_bd     name         NOT NULL DEFAULT current_user,
    fk_usuario     bigint,
    nombre_tabla   varchar(63)  NOT NULL,
    operacion      varchar(10)  NOT NULL,
    llave          varchar(100),
    datos_antes    jsonb,
    datos_despues  jsonb,

    CONSTRAINT pk_bitacora PRIMARY KEY (id_bitacora),
    CONSTRAINT chk_bitacora_operacion
        CHECK (operacion IN ('INSERT', 'UPDATE', 'DELETE'))
);

COMMENT ON TABLE bitacora IS
    'RN-35 · Registro de toda modificacion sobre datos sensibles, con el antes '
    'y el despues en jsonb. La alternativa - una tabla espejo por cada tabla '
    'auditada - costaria treinta y siete tablas mas.';

\echo '07 · Bloque G creado - 5 tablas'


-- ==========================================================================
--  9/18  ·  Claves foraneas
--  fuente: 08-constraints-fk.sql
-- ==========================================================================

\echo ''
\echo '>>> 9/18 · Claves foraneas'

-- ============================================================================
--  08 · Claves foraneas
--
--  Van todas juntas y despues del DDL para no depender del orden de creacion
--  de las tablas. Cada una lleva NOMBRE y POLITICA DECLARADA: ninguna se deja
--  con el comportamiento por defecto sin haberlo pensado.
--
--  Criterio de las politicas:
--    RESTRICT  -> el dato es evidencia y no debe desaparecer por arrastre
--    CASCADE   -> el hijo no tiene sentido sin el padre (composicion pura)
--    SET NULL  -> la referencia es informativa y el hijo sobrevive sin ella
-- ============================================================================

SET search_path TO public;

-- ---------------------------------------------------------------- Bloque A --
ALTER TABLE documento_asistente
    ADD CONSTRAINT fk_documento_asistente
        FOREIGN KEY (fk_asistente) REFERENCES asistente (id_asistente)
        ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_documento_tipo
        FOREIGN KEY (fk_tipo_documento) REFERENCES tipo_documento (id_tipo_documento)
        ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE vinculacion_asistente
    ADD CONSTRAINT fk_vinculacion_asistente
        FOREIGN KEY (fk_asistente) REFERENCES asistente (id_asistente)
        ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_vinculacion_tipo
        FOREIGN KEY (fk_tipo_vinculacion) REFERENCES tipo_vinculacion (id_tipo_vinculacion)
        ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE consentimiento_datos
    ADD CONSTRAINT fk_consentimiento_asistente
        FOREIGN KEY (fk_asistente) REFERENCES asistente (id_asistente)
        ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE asistente
    ADD CONSTRAINT fk_asistente_lote
        FOREIGN KEY (fk_lote_carga) REFERENCES lote_carga_asistente (id_lote_carga)
        ON DELETE SET NULL ON UPDATE CASCADE;

-- ---------------------------------------------------------------- Bloque B --
ALTER TABLE facultad
    ADD CONSTRAINT fk_facultad_padre
        FOREIGN KEY (fk_facultad_padre) REFERENCES facultad (id_facultad)
        ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE programa_academico
    ADD CONSTRAINT fk_programa_facultad
        FOREIGN KEY (fk_facultad) REFERENCES facultad (id_facultad)
        ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE programa_asistente
    ADD CONSTRAINT fk_progasi_asistente
        FOREIGN KEY (fk_asistente) REFERENCES asistente (id_asistente)
        ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_progasi_programa
        FOREIGN KEY (fk_programa) REFERENCES programa_academico (codigo)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_progasi_periodo
        FOREIGN KEY (fk_periodo) REFERENCES periodo_academico (id_periodo)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- ---------------------------------------------------------------- Bloque C --
ALTER TABLE dependencia
    ADD CONSTRAINT fk_dependencia_padre
        FOREIGN KEY (fk_dependencia_padre) REFERENCES dependencia (id_dependencia)
        ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE catedra
    ADD CONSTRAINT fk_catedra_tipo_evento
        FOREIGN KEY (fk_tipo_evento) REFERENCES tipo_evento (id_tipo_evento)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_catedra_dependencia
        FOREIGN KEY (fk_dependencia) REFERENCES dependencia (id_dependencia)
        ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE sesion
    -- CASCADE: la sesion es entidad DEBIL, no existe sin su catedra
    ADD CONSTRAINT fk_sesion_catedra
        FOREIGN KEY (fk_catedra) REFERENCES catedra (id_catedra)
        ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_sesion_modalidad
        FOREIGN KEY (fk_modalidad) REFERENCES modalidad (id_modalidad)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_sesion_sede
        FOREIGN KEY (fk_sede) REFERENCES sede (id_sede)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_sesion_periodo
        FOREIGN KEY (fk_periodo) REFERENCES periodo_academico (id_periodo)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_sesion_encuesta
        FOREIGN KEY (fk_encuesta) REFERENCES encuesta (id_encuesta)
        ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE ponencia
    ADD CONSTRAINT fk_ponencia_sesion
        FOREIGN KEY (fk_sesion) REFERENCES sesion (id_sesion)
        ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_ponencia_asistente
        FOREIGN KEY (fk_asistente) REFERENCES asistente (id_asistente)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- ---------------------------------------------------------------- Bloque D --
ALTER TABLE enlace_registro
    ADD CONSTRAINT fk_enlace_sesion
        FOREIGN KEY (fk_sesion) REFERENCES sesion (id_sesion)
        ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_enlace_usuario
        FOREIGN KEY (fk_usuario_crea) REFERENCES usuario (id_usuario)
        ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE clave_acceso
    ADD CONSTRAINT fk_clave_asistente
        FOREIGN KEY (fk_asistente) REFERENCES asistente (id_asistente)
        ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_clave_enlace
        FOREIGN KEY (fk_enlace) REFERENCES enlace_registro (id_enlace)
        ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE registro_asistencia
    -- RESTRICT en asistente y sesion: el registro es EVIDENCIA de asistencia.
    -- No debe desaparecer por arrastre; para dar de baja se usa activo.
    ADD CONSTRAINT fk_registro_sesion
        FOREIGN KEY (fk_sesion) REFERENCES sesion (id_sesion)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_registro_asistente
        FOREIGN KEY (fk_asistente) REFERENCES asistente (id_asistente)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_registro_enlace
        FOREIGN KEY (fk_enlace) REFERENCES enlace_registro (id_enlace)
        ON DELETE SET NULL ON UPDATE CASCADE,
    ADD CONSTRAINT fk_registro_clave
        FOREIGN KEY (fk_clave) REFERENCES clave_acceso (id_clave)
        ON DELETE SET NULL ON UPDATE CASCADE,
    -- La instantanea apunta al catalogo, pero NUNCA se actualiza en cascada
    -- de contenido: solo se protege que el codigo exista.
    ADD CONSTRAINT fk_registro_programa_snap
        FOREIGN KEY (fk_programa_snapshot) REFERENCES programa_academico (codigo)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_registro_vinculacion_snap
        FOREIGN KEY (fk_vinculacion_snapshot) REFERENCES tipo_vinculacion (id_tipo_vinculacion)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- ---------------------------------------------------------------- Bloque E --
ALTER TABLE pregunta
    ADD CONSTRAINT fk_pregunta_encuesta
        FOREIGN KEY (fk_encuesta) REFERENCES encuesta (id_encuesta)
        ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_pregunta_tipo
        FOREIGN KEY (fk_tipo_pregunta) REFERENCES tipo_pregunta (id_tipo_pregunta)
        ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE opcion_pregunta
    ADD CONSTRAINT fk_opcion_pregunta
        FOREIGN KEY (fk_pregunta) REFERENCES pregunta (id_pregunta)
        ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE respuesta_encuesta
    ADD CONSTRAINT fk_respenc_registro
        FOREIGN KEY (fk_registro) REFERENCES registro_asistencia (id_registro)
        ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_respenc_encuesta
        FOREIGN KEY (fk_encuesta) REFERENCES encuesta (id_encuesta)
        ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE respuesta_item
    ADD CONSTRAINT fk_respitem_respuesta
        FOREIGN KEY (fk_respuesta) REFERENCES respuesta_encuesta (id_respuesta)
        ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_respitem_pregunta
        FOREIGN KEY (fk_pregunta) REFERENCES pregunta (id_pregunta)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_respitem_opcion
        FOREIGN KEY (fk_opcion) REFERENCES opcion_pregunta (id_opcion)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- ---------------------------------------------------------------- Bloque F --
ALTER TABLE novedad_carga
    ADD CONSTRAINT fk_novedad_lote
        FOREIGN KEY (fk_lote_carga) REFERENCES lote_carga_asistente (id_lote_carga)
        ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE alias_programa
    ADD CONSTRAINT fk_alias_programa
        FOREIGN KEY (fk_programa) REFERENCES programa_academico (codigo)
        ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE lote_migracion
    ADD CONSTRAINT fk_lotemig_sesion
        FOREIGN KEY (fk_sesion) REFERENCES sesion (id_sesion)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_lotemig_estado
        FOREIGN KEY (fk_estado_proceso) REFERENCES estado_proceso (id_estado)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_lotemig_usuario
        FOREIGN KEY (fk_usuario) REFERENCES usuario (id_usuario)
        ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE detalle_migracion
    ADD CONSTRAINT fk_detmig_lote
        FOREIGN KEY (fk_lote_migracion) REFERENCES lote_migracion (id_lote_migracion)
        ON DELETE CASCADE ON UPDATE CASCADE,
    -- RESTRICT: el detalle es la evidencia de lo enviado al ASIS
    ADD CONSTRAINT fk_detmig_registro
        FOREIGN KEY (fk_registro) REFERENCES registro_asistencia (id_registro)
        ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE lote_carga_asistente
    ADD CONSTRAINT fk_lotecarga_usuario
        FOREIGN KEY (fk_usuario) REFERENCES usuario (id_usuario)
        ON DELETE SET NULL ON UPDATE CASCADE;

-- ---------------------------------------------------------------- Bloque G --
ALTER TABLE usuario
    ADD CONSTRAINT fk_usuario_asistente
        FOREIGN KEY (fk_asistente) REFERENCES asistente (id_asistente)
        ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE rol_por_usuario
    ADD CONSTRAINT fk_rolusr_usuario
        FOREIGN KEY (fk_usuario) REFERENCES usuario (id_usuario)
        ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_rolusr_rol
        FOREIGN KEY (fk_rol) REFERENCES rol (id_rol)
        ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE parametro
    ADD CONSTRAINT fk_parametro_usuario
        FOREIGN KEY (fk_usuario_modifica) REFERENCES usuario (id_usuario)
        ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE bitacora
    ADD CONSTRAINT fk_bitacora_usuario
        FOREIGN KEY (fk_usuario) REFERENCES usuario (id_usuario)
        ON DELETE SET NULL ON UPDATE CASCADE;

\echo '08 · Claves foraneas creadas'


-- ==========================================================================
--  10/18  ·  Disparadores
--  fuente: 10-triggers.sql
--
--  Van ANTES de los datos: la carga los ejercita, que es como se comprueban.
-- ==========================================================================

\echo ''
\echo '>>> 10/18 · Disparadores'

-- ============================================================================
--  10 · Disparadores
--
--  Aqui viven las reglas que PostgreSQL no puede declarar. Cada una lleva su
--  numero de RN, para que en la revision se vea que no se olvido ninguna:
--  lo que no es declarativo hay que escribirlo Y hay que medirlo.
-- ============================================================================

SET search_path TO public;

-- ============================================================================
-- RN-10 · El numero de reunion - PROPUESTA del sistema, autoridad del ASIS
--
-- El disparador propone el siguiente consecutivo de la catedra. Eso resuelve
-- el paso 2 del manual - "verificar el ID del evento y la ultima reunion que
-- se llevo a cabo" - para las catedras que nazcan en este sistema.
--
-- PERO NO SE PUEDE DERIVAR PARA LAS EXISTENTES, y el dato lo demuestra:
--
--   * De los 5.481 eventos con UNA sola reunion, solo 588 tienen el numero 1.
--     Los otros 4.893 traen valores arbitrarios, hasta 4348.
--   * Los eventos con muchas reuniones si empiezan en 1, pero CON HUECOS:
--     000035428 tiene 59 reuniones numeradas de 1 a 60.
--
-- Conclusion: el ASIS lleva un contador propio que este sistema no conoce.
-- Por eso sesion.numero_reunion_asis NO es una comodidad de conciliacion:
-- es el valor bueno cuando existe. Esto RESUELVE con dato la decision que el
-- plan dejo abierta en §8.3.
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_sesion_consecutivo()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.numero_reunion IS NULL OR NEW.numero_reunion = 0 THEN
        -- El bloqueo de la catedra serializa dos altas simultaneas
        PERFORM 1 FROM catedra WHERE id_catedra = NEW.fk_catedra FOR UPDATE;

        SELECT coalesce(max(s.numero_reunion), 0) + 1
          INTO NEW.numero_reunion
          FROM sesion s
         WHERE s.fk_catedra = NEW.fk_catedra;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sesion_consecutivo
    BEFORE INSERT ON sesion
    FOR EACH ROW EXECUTE FUNCTION fn_trg_sesion_consecutivo();

COMMENT ON FUNCTION fn_trg_sesion_consecutivo() IS
    'RN-10. PROPONE el siguiente consecutivo de la catedra cuando no se indica. '
    'El FOR UPDATE serializa dos altas simultaneas: sin el, uq_sesion_reunion '
    'rechazaria una de las dos con un error feo en vez de ordenarlas. '
    'NO sustituye al numero del ASIS: para las catedras que ya existen alli, la '
    'autoridad es numero_reunion_asis. Ver el comentario de arriba y §8.3.';

-- ============================================================================
-- RN-13 · El canal del enlace concuerda con la modalidad de la sesion
--         "cuando es virtual enviamos el enlace; si es presencial, el QR"
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_enlace_canal()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_canal_esperado varchar(10);
BEGIN
    SELECT m.canal_difusion
      INTO v_canal_esperado
      FROM sesion s
      JOIN modalidad m ON m.id_modalidad = s.fk_modalidad
     WHERE s.id_sesion = NEW.fk_sesion;

    IF v_canal_esperado IS DISTINCT FROM 'AMBOS'
       AND NEW.canal IS DISTINCT FROM v_canal_esperado THEN
        RAISE EXCEPTION
            'RN-13: la sesion % es de modalidad que se difunde por %, no por %',
            NEW.fk_sesion, v_canal_esperado, NEW.canal
            USING ERRCODE = 'check_violation';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_enlace_canal
    BEFORE INSERT OR UPDATE OF canal, fk_sesion ON enlace_registro
    FOR EACH ROW EXECUTE FUNCTION fn_trg_enlace_canal();

-- ============================================================================
-- RN-19 · es_correo_institucional se DERIVA del dominio de destino
--
-- Responde al asunto que el profesor Carlos Castro dejo abierto en 55:32.
-- Si se digitara, alguien lo marcaria mal justo en el caso que hay que vigilar.
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_clave_derivar()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_dominios text;
BEGIN
    SELECT valor INTO v_dominios
      FROM parametro WHERE clave = 'DOMINIOS_INSTITUCIONALES';

    v_dominios := coalesce(v_dominios, 'usbmed.edu.co,usb.edu.co');

    NEW.es_correo_institucional := EXISTS (
        SELECT 1
          FROM unnest(string_to_array(v_dominios, ',')) AS d(dom)
         WHERE lower(NEW.enviado_a::text) LIKE '%@' || lower(trim(d.dom))
    );
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_clave_derivar
    BEFORE INSERT OR UPDATE OF enviado_a ON clave_acceso
    FOR EACH ROW EXECUTE FUNCTION fn_trg_clave_derivar();

-- ============================================================================
-- RN-15, RN-22 y RN-38 · Todo lo que hay que comprobar al registrar
--   RN-15 · dentro de la ventana del enlace
--   RN-22 · instantanea de programa y vinculacion
--   RN-38 · cupo de la sesion
--   RN-07 · programa obligatorio salvo que la vinculacion no lo exija
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_registro_validar()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_ventana        tstzrange;
    v_revocado       timestamptz;
    v_cupo           integer;
    v_registrados    integer;
    v_exige_programa boolean;
BEGIN
    ------------------------------------------------------------------ RN-15 --
    IF NEW.fk_enlace IS NOT NULL AND NEW.origen NOT IN ('MANUAL', 'IMPORTADO') THEN
        SELECT e.ventana, e.revocado_en
          INTO v_ventana, v_revocado
          FROM enlace_registro e
         WHERE e.id_enlace = NEW.fk_enlace;

        IF v_revocado IS NOT NULL THEN
            RAISE EXCEPTION 'RN-15: el enlace % esta revocado', NEW.fk_enlace
                USING ERRCODE = 'check_violation';
        END IF;

        IF NOT (v_ventana @> NEW.registrado_en) THEN
            RAISE EXCEPTION
                'RN-15: % esta fuera de la ventana % del enlace %',
                NEW.registrado_en, v_ventana, NEW.fk_enlace
                USING ERRCODE = 'check_violation';
        END IF;
    END IF;

    ------------------------------------------------------------------ RN-22 --
    -- Instantanea de la VINCULACION vigente
    IF NEW.fk_vinculacion_snapshot IS NULL THEN
        SELECT v.fk_tipo_vinculacion
          INTO NEW.fk_vinculacion_snapshot
          FROM vinculacion_asistente v
         WHERE v.fk_asistente = NEW.fk_asistente
           AND v.fecha_fin IS NULL
         ORDER BY v.fecha_ini DESC
         LIMIT 1;

        IF NEW.fk_vinculacion_snapshot IS NULL THEN
            RAISE EXCEPTION
                'El asistente % no tiene ninguna vinculacion vigente',
                NEW.fk_asistente USING ERRCODE = 'check_violation';
        END IF;
    END IF;

    SELECT tv.exige_programa INTO v_exige_programa
      FROM tipo_vinculacion tv
     WHERE tv.id_tipo_vinculacion = NEW.fk_vinculacion_snapshot;

    -- Instantanea del PROGRAMA vigente, solo si la vinculacion lo exige
    IF NEW.fk_programa_snapshot IS NULL AND v_exige_programa THEN
        SELECT pa.fk_programa
          INTO NEW.fk_programa_snapshot
          FROM programa_asistente pa
          JOIN periodo_academico p ON p.id_periodo = pa.fk_periodo
         WHERE pa.fk_asistente = NEW.fk_asistente
           AND pa.estado = 'ACTIVO'
         ORDER BY p.fecha_ini DESC
         LIMIT 1;
    END IF;

    ------------------------------------------------------------------ RN-07 --
    IF v_exige_programa AND NEW.fk_programa_snapshot IS NULL THEN
        RAISE EXCEPTION
            'RN-07: la vinculacion % exige programa academico y el asistente % no tiene ninguno activo',
            NEW.fk_vinculacion_snapshot, NEW.fk_asistente
            USING ERRCODE = 'check_violation';
    END IF;

    IF NOT v_exige_programa THEN
        -- Rutas de Paz y similares entran SIN programa, a proposito
        NEW.fk_programa_snapshot := NULL;
    END IF;

    ------------------------------------------------------------------ RN-38 --
    SELECT s.cupo INTO v_cupo FROM sesion s WHERE s.id_sesion = NEW.fk_sesion FOR UPDATE;

    IF v_cupo IS NOT NULL THEN
        SELECT count(*) INTO v_registrados
          FROM registro_asistencia r WHERE r.fk_sesion = NEW.fk_sesion;

        IF v_registrados >= v_cupo THEN
            RAISE EXCEPTION 'RN-38: la sesion % alcanzo su cupo de %',
                NEW.fk_sesion, v_cupo USING ERRCODE = 'check_violation';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_registro_validar
    BEFORE INSERT ON registro_asistencia
    FOR EACH ROW EXECUTE FUNCTION fn_trg_registro_validar();

COMMENT ON FUNCTION fn_trg_registro_validar() IS
    'Cuatro reglas en un disparador porque las cuatro se comprueban en el mismo '
    'instante y sobre la misma fila. El FOR UPDATE sobre la sesion serializa el '
    'control de cupo: sin el, dos registros simultaneos podrian pasarse.';

-- ============================================================================
-- RN-25 · El tipo de pregunta decide QUE columna de valor se usa
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_respuesta_item_tipo()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    t record;
BEGIN
    SELECT tp.id_tipo_pregunta, tp.guarda_numero, tp.guarda_texto, tp.guarda_opcion,
           p.valor_min, p.valor_max
      INTO t
      FROM pregunta p
      JOIN tipo_pregunta tp ON tp.id_tipo_pregunta = p.fk_tipo_pregunta
     WHERE p.id_pregunta = NEW.fk_pregunta;

    IF t.guarda_numero AND NEW.valor_numerico IS NULL THEN
        RAISE EXCEPTION 'RN-25: la pregunta % es de tipo % y espera valor_numerico',
            NEW.fk_pregunta, t.id_tipo_pregunta USING ERRCODE = 'check_violation';
    ELSIF t.guarda_texto AND NEW.valor_texto IS NULL THEN
        RAISE EXCEPTION 'RN-25: la pregunta % es de tipo % y espera valor_texto',
            NEW.fk_pregunta, t.id_tipo_pregunta USING ERRCODE = 'check_violation';
    ELSIF t.guarda_opcion AND NEW.fk_opcion IS NULL THEN
        RAISE EXCEPTION 'RN-25: la pregunta % es de tipo % y espera fk_opcion',
            NEW.fk_pregunta, t.id_tipo_pregunta USING ERRCODE = 'check_violation';
    END IF;

    -- El rango declarado de la pregunta
    IF NEW.valor_numerico IS NOT NULL AND t.valor_min IS NOT NULL
       AND NEW.valor_numerico NOT BETWEEN t.valor_min AND t.valor_max THEN
        RAISE EXCEPTION 'RN-25: % esta fuera del rango [%, %] de la pregunta %',
            NEW.valor_numerico, t.valor_min, t.valor_max, NEW.fk_pregunta
            USING ERRCODE = 'check_violation';
    END IF;

    -- RN-24 · la opcion elegida pertenece a ESA pregunta
    IF NEW.fk_opcion IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM opcion_pregunta o
                        WHERE o.id_opcion = NEW.fk_opcion
                          AND o.fk_pregunta = NEW.fk_pregunta) THEN
        RAISE EXCEPTION 'RN-24: la opcion % no pertenece a la pregunta %',
            NEW.fk_opcion, NEW.fk_pregunta USING ERRCODE = 'check_violation';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_respuesta_item_tipo
    BEFORE INSERT OR UPDATE ON respuesta_item
    FOR EACH ROW EXECUTE FUNCTION fn_trg_respuesta_item_tipo();

-- ============================================================================
-- RN-35 · Bitacora sobre las tablas sensibles
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_trg_bitacora()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    v_antes   jsonb;
    v_despues jsonb;
    v_llave   text;
BEGIN
    -- Se convierte a jsonb PRIMERO y la llave se extrae de ahi.
    -- No se usa CASE sobre NEW.<columna> porque PL/pgSQL planifica la
    -- expresion COMPLETA contra el tipo de registro que dispara: una rama
    -- que nombre una columna de otra tabla revienta aunque no se ejecute.
    IF TG_OP IN ('UPDATE', 'DELETE') THEN v_antes   := to_jsonb(OLD); END IF;
    IF TG_OP IN ('INSERT', 'UPDATE') THEN v_despues := to_jsonb(NEW); END IF;

    v_llave := coalesce(v_despues, v_antes) ->> ('id_' || replace(TG_TABLE_NAME, '_asistencia', ''));

    INSERT INTO bitacora (nombre_tabla, operacion, llave, datos_antes, datos_despues)
    VALUES (TG_TABLE_NAME, TG_OP, v_llave, v_antes, v_despues);

    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$;

CREATE TRIGGER trg_bitacora_registro
    AFTER INSERT OR UPDATE OR DELETE ON registro_asistencia
    FOR EACH ROW EXECUTE FUNCTION fn_trg_bitacora();

CREATE TRIGGER trg_bitacora_asistente
    AFTER UPDATE OR DELETE ON asistente
    FOR EACH ROW EXECUTE FUNCTION fn_trg_bitacora();

\echo '10 · Disparadores creados - 6 funciones, 8 disparadores'


-- ==========================================================================
--  11/18  ·  Funciones y procedimientos
--  fuente: 11-funciones-procedimientos.sql
-- ==========================================================================

\echo ''
\echo '>>> 11/18 · Funciones y procedimientos'

-- ============================================================================
--  11 · Funciones y procedimientos
--
--  Aqui estan las tres participaciones minimas de uno que ninguna clave
--  foranea puede garantizar, y las tres operaciones del flujo de registro.
-- ============================================================================

SET search_path TO public;

-- ============================================================================
-- fn_siguiente_reunion · el numero que hoy se busca a mano (I8)
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_siguiente_reunion(p_id_evento_asis char(9))
RETURNS smallint
LANGUAGE sql STABLE
AS $$
    SELECT coalesce(max(s.numero_reunion), 0)::smallint + 1
      FROM catedra c
      LEFT JOIN sesion s ON s.fk_catedra = c.id_catedra
     WHERE c.id_evento_asis = p_id_evento_asis;
$$;

COMMENT ON FUNCTION fn_siguiente_reunion(char) IS
    'I8. Sustituye el paso 2 del manual de migracion: la busqueda manual de la '
    'ultima reunion en un listado de 5.711 filas.';

-- ============================================================================
-- fn_resolver_asistente · RN-06, las tres puertas de entrada
--
-- "Tiene que entrar por una de las 3" (57:27): codigo, documento o correo.
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_resolver_asistente(p_identificador text)
RETURNS bigint
LANGUAGE plpgsql STABLE
AS $$
DECLARE
    v_id  bigint;
    v_txt text := trim(p_identificador);
BEGIN
    IF v_txt IS NULL OR v_txt = '' THEN
        RETURN NULL;
    END IF;

    -- El formulario actual trae valores como 'ID:30000141979'
    v_txt := regexp_replace(v_txt, '^\s*(ID|Id|id)\s*[:.-]\s*', '');

    -- 1 · por codigo ASIS
    SELECT a.id_asistente INTO v_id
      FROM asistente a
     WHERE a.id_asis = v_txt AND a.activo;
    IF v_id IS NOT NULL THEN RETURN v_id; END IF;

    -- 2 · por correo, institucional o personal
    IF v_txt LIKE '%@%' THEN
        SELECT a.id_asistente INTO v_id
          FROM asistente a
         WHERE (a.correo_institucional = v_txt::citext
             OR a.correo_personal      = v_txt::citext)
           AND a.activo
         LIMIT 1;
        IF v_id IS NOT NULL THEN RETURN v_id; END IF;
    END IF;

    -- 3 · por numero de documento, VIGENTE O NO
    SELECT d.fk_asistente INTO v_id
      FROM documento_asistente d
      JOIN asistente a ON a.id_asistente = d.fk_asistente
     WHERE d.numero = v_txt AND a.activo
     ORDER BY d.vigente DESC
     LIMIT 1;

    RETURN v_id;
END;
$$;

COMMENT ON FUNCTION fn_resolver_asistente(text) IS
    'RN-06. Busca por las tres vias y devuelve el asistente, o NULL. Busca en '
    'documentos VIGENTES Y NO VIGENTES a proposito: los 707 casos de personas '
    'con varios documentos son justamente quienes digitan el antiguo. Elimina '
    'el trabajo manual que describio el profesor Hugo Nelson en 42:01.';

-- ============================================================================
-- fn_resolver_programa · H17, el texto libre de los formularios
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_resolver_programa(p_texto text,
                                                p_umbral real DEFAULT 0.45)
RETURNS varchar(5)
LANGUAGE plpgsql STABLE
AS $$
DECLARE
    v_norm   text := fn_normalizar(p_texto);
    v_codigo varchar(5);
BEGIN
    IF v_norm IS NULL OR v_norm = '' THEN RETURN NULL; END IF;

    -- 1 · el codigo ya viene bien escrito
    SELECT codigo INTO v_codigo FROM programa_academico
     WHERE upper(trim(p_texto)) = codigo;
    IF v_codigo IS NOT NULL THEN RETURN v_codigo; END IF;

    -- 2 · alias exacto ya conocido
    SELECT fk_programa INTO v_codigo FROM alias_programa
     WHERE texto_normalizado = v_norm;
    IF v_codigo IS NOT NULL THEN RETURN v_codigo; END IF;

    -- 3 · nombre exacto del programa
    SELECT codigo INTO v_codigo FROM programa_academico
     WHERE fn_normalizar(nombre) = v_norm;
    IF v_codigo IS NOT NULL THEN RETURN v_codigo; END IF;

    -- 4 · similitud por trigramas, con umbral
    SELECT codigo INTO v_codigo
      FROM programa_academico
     WHERE similarity(fn_normalizar(nombre), v_norm) >= p_umbral
     ORDER BY similarity(fn_normalizar(nombre), v_norm) DESC
     LIMIT 1;

    RETURN v_codigo;
END;
$$;

COMMENT ON FUNCTION fn_resolver_programa(text, real) IS
    'Resuelve el texto libre del formulario contra el catalogo. Cuatro pasos, '
    'del mas seguro al mas arriesgado. El paso 4 puede equivocarse: por eso '
    'devuelve NULL antes que adivinar por debajo del umbral, y lo que quede sin '
    'resolver se cuenta y se revisa a mano.';

-- ============================================================================
-- sp_emitir_enlace · el boton que genera el QR y la URL
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_emitir_enlace(
    p_id_sesion       bigint,
    p_minutos_antes   integer DEFAULT NULL,
    p_minutos_despues integer DEFAULT NULL,
    p_usuario         bigint  DEFAULT NULL,
    INOUT p_id_enlace bigint  DEFAULT NULL)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ini    timestamptz;
    v_fin    timestamptz;
    v_canal  varchar(10);
    v_antes  integer;
    v_desp   integer;
    v_token  uuid := gen_random_uuid();
    v_base   text;
BEGIN
    SELECT s.inicio, s.fin, m.canal_difusion
      INTO v_ini, v_fin, v_canal
      FROM sesion s
      JOIN modalidad m ON m.id_modalidad = s.fk_modalidad
     WHERE s.id_sesion = p_id_sesion;

    IF v_ini IS NULL THEN
        RAISE EXCEPTION 'No existe la sesion %', p_id_sesion;
    END IF;

    v_antes := coalesce(p_minutos_antes,
                        (SELECT valor::int FROM parametro WHERE clave = 'VENTANA_MINUTOS_ANTES'), 30);
    v_desp  := coalesce(p_minutos_despues,
                        (SELECT valor::int FROM parametro WHERE clave = 'VENTANA_MINUTOS_DESPUES'), 30);
    v_base  := coalesce((SELECT valor FROM parametro WHERE clave = 'URL_BASE'),
                        'https://catedras.usbmed.edu.co/r/');

    IF v_canal = 'AMBOS' THEN v_canal := 'QR'; END IF;

    -- RN-14 · se revoca el enlace vigente anterior, si lo hay
    UPDATE enlace_registro
       SET revocado_en = now()
     WHERE fk_sesion = p_id_sesion AND revocado_en IS NULL;

    INSERT INTO enlace_registro (fk_sesion, token, url_publica, ruta_imagen_qr,
                                 canal, ventana, fk_usuario_crea)
    VALUES (p_id_sesion, v_token, v_base || v_token::text,
            'qr/' || v_token::text || '.png', v_canal,
            tstzrange(v_ini - make_interval(mins => v_antes),
                      v_fin + make_interval(mins => v_desp), '[)'),
            p_usuario)
    RETURNING id_enlace INTO p_id_enlace;
END;
$$;

COMMENT ON PROCEDURE sp_emitir_enlace(bigint, integer, integer, bigint, bigint) IS
    'El boton del .docx: "el administrador toca un boton y genera el QR y URL '
    'del registro de la catedra especifica". La ventana sale de los parametros, '
    'que es lo que pide "el administrador configura hora de inicio y hora de fin".';

-- ============================================================================
-- sp_solicitar_clave · RN-17, RN-18, RN-19
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_solicitar_clave(
    p_identificador  text,
    p_token          uuid,
    p_ip             inet    DEFAULT NULL,
    INOUT p_id_clave bigint  DEFAULT NULL,
    INOUT p_clave    text    DEFAULT NULL,
    INOUT p_enviado_a text   DEFAULT NULL)
LANGUAGE plpgsql
AS $$
DECLARE
    v_asistente bigint;
    v_enlace    bigint;
    v_vigencia  integer;
    v_longitud  integer;
BEGIN
    -- RN-01 y RN-06 · solo entra quien esta en la tabla
    v_asistente := fn_resolver_asistente(p_identificador);
    IF v_asistente IS NULL THEN
        RAISE EXCEPTION
            'RN-01: no hay ningun asistente registrado con el identificador %', p_identificador
            USING ERRCODE = 'no_data_found';
    END IF;

    SELECT id_enlace INTO v_enlace
      FROM enlace_registro
     WHERE token = p_token AND revocado_en IS NULL AND ventana @> now();

    IF v_enlace IS NULL THEN
        RAISE EXCEPTION 'RN-15: el enlace no existe, esta revocado o esta fuera de su ventana'
            USING ERRCODE = 'check_violation';
    END IF;

    v_vigencia := coalesce((SELECT valor::int FROM parametro WHERE clave = 'CLAVE_VIGENCIA_MINUTOS'), 10);
    v_longitud := coalesce((SELECT valor::int FROM parametro WHERE clave = 'CLAVE_LONGITUD'), 6);

    -- La clave en claro se devuelve para enviarla por correo y NO se guarda
    p_clave := lpad((floor(random() * (10::numeric ^ v_longitud)))::bigint::text, v_longitud, '0');

    -- RN-19 · a que correo: institucional si existe, si no el personal
    SELECT coalesce(correo_institucional, correo_personal)::text
      INTO p_enviado_a
      FROM asistente WHERE id_asistente = v_asistente;

    INSERT INTO clave_acceso (fk_asistente, fk_enlace, clave_hash, enviado_a,
                              es_correo_institucional, expira_en, ip_solicitud)
    VALUES (v_asistente, v_enlace,
            digest(p_clave || p_enviado_a, 'sha256'),   -- RN-34, con sal
            p_enviado_a::citext,
            false,                                       -- lo deriva el disparador
            now() + make_interval(mins => v_vigencia),
            p_ip)
    RETURNING id_clave INTO p_id_clave;
END;
$$;

COMMENT ON PROCEDURE sp_solicitar_clave(text, uuid, inet, bigint, text, text) IS
    'RN-17. La razon de existir de esta clave no es autenticar, es impedir que '
    'uno registre a otro: "yo me puedo registrar por cualquier persona, por eso '
    'tiene que ser con el correo" (1:04:51). La clave en claro se DEVUELVE para '
    'que la aplicacion la envie, y nunca se almacena.';

-- ============================================================================
-- sp_validar_clave_y_registrar · el acto de registrarse
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_validar_clave_y_registrar(
    p_id_clave          bigint,
    p_clave             text,
    p_ip                inet   DEFAULT NULL,
    p_user_agent        text   DEFAULT NULL,
    INOUT p_id_registro bigint DEFAULT NULL)
LANGUAGE plpgsql
AS $$
DECLARE
    c              record;
    v_max_intentos integer;
    v_sesion       bigint;
    v_canal        varchar(10);
BEGIN
    SELECT * INTO c FROM clave_acceso WHERE id_clave = p_id_clave FOR UPDATE;

    IF c IS NULL THEN
        RAISE EXCEPTION 'No existe la clave %', p_id_clave USING ERRCODE = 'no_data_found';
    END IF;

    -- RN-20 · una clave usada no se reutiliza
    IF c.usado_en IS NOT NULL THEN
        RAISE EXCEPTION 'RN-20: esa clave ya se uso el %', c.usado_en
            USING ERRCODE = 'check_violation';
    END IF;

    IF now() > c.expira_en THEN
        RAISE EXCEPTION 'RN-18: la clave expiro el %', c.expira_en
            USING ERRCODE = 'check_violation';
    END IF;

    v_max_intentos := coalesce((SELECT valor::int FROM parametro WHERE clave = 'CLAVE_MAX_INTENTOS'), 3);

    IF c.clave_hash IS DISTINCT FROM digest(p_clave || c.enviado_a::text, 'sha256') THEN
        UPDATE clave_acceso SET intentos = intentos + 1 WHERE id_clave = p_id_clave;
        IF c.intentos + 1 >= v_max_intentos THEN
            UPDATE clave_acceso SET expira_en = now() WHERE id_clave = p_id_clave;
            RAISE EXCEPTION 'RN-18: se agotaron los % intentos; la clave queda anulada', v_max_intentos
                USING ERRCODE = 'check_violation';
        END IF;
        RAISE EXCEPTION 'Clave incorrecta. Intento % de %', c.intentos + 1, v_max_intentos
            USING ERRCODE = 'check_violation';
    END IF;

    SELECT e.fk_sesion, e.canal INTO v_sesion, v_canal
      FROM enlace_registro e WHERE e.id_enlace = c.fk_enlace;

    -- El disparador de registro hace el resto: ventana, instantaneas y cupo
    INSERT INTO registro_asistencia (fk_sesion, fk_asistente, fk_enlace, fk_clave,
                                     fk_vinculacion_snapshot, origen, ip, user_agent)
    VALUES (v_sesion, c.fk_asistente, c.fk_enlace, p_id_clave,
            NULL, v_canal, p_ip, left(p_user_agent, 300))
    RETURNING id_registro INTO p_id_registro;

    UPDATE clave_acceso SET usado_en = now() WHERE id_clave = p_id_clave;
END;
$$;

-- ============================================================================
-- sp_responder_encuesta · la PARTICIPACION MINIMA DE UNO
--
-- "Una clave foranea garantiza que lo que se inserte exista, no que se
--  inserte algo." Cabecera e items se crean JUNTOS, en una transaccion.
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_responder_encuesta(
    p_id_registro        bigint,
    p_respuestas         jsonb,
    INOUT p_id_respuesta bigint DEFAULT NULL)
LANGUAGE plpgsql
AS $$
DECLARE
    v_encuesta bigint;
    v_items    integer;
BEGIN
    SELECT s.fk_encuesta INTO v_encuesta
      FROM registro_asistencia r
      JOIN sesion s ON s.id_sesion = r.fk_sesion
     WHERE r.id_registro = p_id_registro;

    IF v_encuesta IS NULL THEN
        RAISE EXCEPTION 'La sesion de ese registro no tiene encuesta asignada'
            USING ERRCODE = 'check_violation';
    END IF;

    IF jsonb_array_length(p_respuestas) = 0 THEN
        RAISE EXCEPTION 'R29: una encuesta respondida debe tener al menos un item'
            USING ERRCODE = 'check_violation';
    END IF;

    INSERT INTO respuesta_encuesta (fk_registro, fk_encuesta)
    VALUES (p_id_registro, v_encuesta)
    RETURNING id_respuesta INTO p_id_respuesta;

    INSERT INTO respuesta_item (fk_respuesta, fk_pregunta, valor_numerico, valor_texto, fk_opcion)
    SELECT p_id_respuesta,
           (e ->> 'pregunta')::bigint,
           (e ->> 'numero')::smallint,
            e ->> 'texto',
           (e ->> 'opcion')::bigint
      FROM jsonb_array_elements(p_respuestas) AS e;

    GET DIAGNOSTICS v_items = ROW_COUNT;

    CALL sp_cerrar_encuesta(p_id_respuesta);
END;
$$;

-- ============================================================================
-- sp_cerrar_encuesta · RN-26, las preguntas OBLIGATORIAS
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_cerrar_encuesta(p_id_respuesta bigint)
LANGUAGE plpgsql
AS $$
DECLARE
    v_faltan text;
BEGIN
    SELECT string_agg(p.orden::text, ', ' ORDER BY p.orden)
      INTO v_faltan
      FROM respuesta_encuesta re
      JOIN pregunta p ON p.fk_encuesta = re.fk_encuesta AND p.obligatoria
     WHERE re.id_respuesta = p_id_respuesta
       AND NOT EXISTS (SELECT 1 FROM respuesta_item ri
                        WHERE ri.fk_respuesta = re.id_respuesta
                          AND ri.fk_pregunta  = p.id_pregunta);

    IF v_faltan IS NOT NULL THEN
        RAISE EXCEPTION 'RN-26: faltan por responder las preguntas obligatorias %', v_faltan
            USING ERRCODE = 'check_violation';
    END IF;

    UPDATE respuesta_encuesta SET completa = true WHERE id_respuesta = p_id_respuesta;
END;
$$;

COMMENT ON PROCEDURE sp_cerrar_encuesta(bigint) IS
    'RN-26. No es "al menos uno": es "uno por cada pregunta marcada obligatoria", '
    'y eso depende del contenido de otra tabla que ademas cambia con cada version '
    'de la encuesta. Ninguna restriccion declarativa puede expresarlo.';

-- ============================================================================
-- fn_exportar_asis · RN-27 y RN-28, el archivo plano de TRES columnas
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_exportar_asis(p_id_sesion bigint)
RETURNS TABLE (reunion smallint, id_asis varchar(15), programa varchar(5))
LANGUAGE sql STABLE
AS $$
    SELECT s.numero_reunion, a.id_asis, r.fk_programa_snapshot
      FROM registro_asistencia r
      JOIN sesion    s ON s.id_sesion    = r.fk_sesion
      JOIN asistente a ON a.id_asistente = r.fk_asistente
     WHERE r.fk_sesion = p_id_sesion
       -- RN-28 · solo se migra quien tiene ID y programa
       AND a.id_asis IS NOT NULL
       AND r.fk_programa_snapshot IS NOT NULL
       -- RN-08 · el externo se cuenta, pero NUNCA entra al archivo
       AND a.es_externo = false
     ORDER BY a.id_asis;
$$;

COMMENT ON FUNCTION fn_exportar_asis(bigint) IS
    'RN-27. TRES columnas exactas: reunion, ID y codigo de programa - "cuando '
    'tenemos el archivo plano, son 3" (32:34). Ni una mas. El manual insiste: '
    '"unicamente haya informacion en las tres columnas correspondientes".';

-- ============================================================================
-- sp_generar_lote_migracion · con su detalle, que tampoco puede ir vacio
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_generar_lote_migracion(
    p_id_sesion  bigint,
    p_usuario    bigint DEFAULT NULL,
    INOUT p_id_lote bigint DEFAULT NULL)
LANGUAGE plpgsql
AS $$
DECLARE
    v_filas integer;
    v_nombre text;
BEGIN
    SELECT count(*) INTO v_filas FROM fn_exportar_asis(p_id_sesion);

    IF v_filas = 0 THEN
        RAISE EXCEPTION
            'No hay registros migrables en la sesion %. Revise I10: asistentes sin ID o sin programa',
            p_id_sesion USING ERRCODE = 'check_violation';
    END IF;

    SELECT 'ME_CATEDRA_' || c.id_evento_asis || '_R' || s.numero_reunion || '.xlsx'
      INTO v_nombre
      FROM sesion s JOIN catedra c ON c.id_catedra = s.fk_catedra
     WHERE s.id_sesion = p_id_sesion;

    INSERT INTO lote_migracion (fk_sesion, nombre_archivo, fk_usuario,
                                fk_estado_proceso, total_filas)
    VALUES (p_id_sesion, v_nombre, p_usuario, 'GENERADO', v_filas)
    RETURNING id_lote_migracion INTO p_id_lote;

    INSERT INTO detalle_migracion (fk_lote_migracion, fk_registro, id_asis_enviado,
                                   programa_enviado, reunion_enviada)
    SELECT p_id_lote, r.id_registro, a.id_asis, r.fk_programa_snapshot, s.numero_reunion
      FROM registro_asistencia r
      JOIN sesion    s ON s.id_sesion    = r.fk_sesion
      JOIN asistente a ON a.id_asistente = r.fk_asistente
     WHERE r.fk_sesion = p_id_sesion
       AND a.id_asis IS NOT NULL
       AND r.fk_programa_snapshot IS NOT NULL
       AND a.es_externo = false;

    UPDATE sesion SET estado = 'MIGRADA' WHERE id_sesion = p_id_sesion;
END;
$$;

\echo '11 · Funciones y procedimientos creados - 4 funciones, 6 procedimientos'


-- ==========================================================================
--  12/18  ·  Catalogos
--  fuente: 12-datos-catalogos.sql
-- ==========================================================================

\echo ''
\echo '>>> 12/18 · Catalogos'

-- ============================================================================
--  12 · Datos de catalogo
--
--  Todos los valores salen de una fuente verificable: el dato real del ASIS,
--  el manual de migracion, o una cita de la reunion.
-- ============================================================================

SET search_path TO public;

-- ---------------------------------------------------------------------------
-- tipo_documento · cierra las mas de diez formas de escribir "cedula"
-- ---------------------------------------------------------------------------
INSERT INTO tipo_documento (id_tipo_documento, nombre) VALUES
    ('CC',  'Cedula de ciudadania'),
    ('TI',  'Tarjeta de identidad'),
    ('CE',  'Cedula de extranjeria'),
    ('PA',  'Pasaporte'),
    ('PEP', 'Permiso especial de permanencia'),
    ('NIT', 'Numero de identificacion tributaria');

-- ---------------------------------------------------------------------------
-- tipo_vinculacion · las dos columnas booleanas son las que deciden
-- ---------------------------------------------------------------------------
INSERT INTO tipo_vinculacion (id_tipo_vinculacion, nombre, es_interno, exige_programa) VALUES
    ('ESTUDIANTE',   'Estudiante USB',              true,  true),
    ('DOCENTE',      'Docente USB',                 true,  true),
    ('ADMINISTRATIVO','Administrativo USB',         true,  false),
    ('EGRESADO',     'Egresado USB',                true,  true),
    ('RUTAS_PAZ',    'Rutas de paz y formacion',    true,  false),
    ('COLEGIO',      'Colegio invitado',            false, false),
    ('EXTERNO',      'Publico externo',             false, false);

COMMENT ON TABLE tipo_vinculacion IS
    'RUTAS_PAZ tiene exige_programa = false por la excepcion que planteo el '
    'profesor Hugo Nelson en 41:16: "ellos entrarian sin programa, pero solo '
    'ellos". ADMINISTRATIVO tambien, porque no esta matriculado en nada.';

-- ---------------------------------------------------------------------------
-- tipo_evento · los OCHO codigos observados en las 5.711 filas reales
-- ---------------------------------------------------------------------------
INSERT INTO tipo_evento (id_tipo_evento, nombre) VALUES
    ('CAAB', 'Catedra abierta'),
    ('DLLH', 'Desarrollo humano'),
    ('DEPR', 'Deporte y recreacion'),
    ('SLDI', 'Salud integral'),
    ('ARCU', 'Arte y cultura'),
    ('MTG',  'Mesa de trabajo o grupo'),
    ('DIIB', 'Difusion institucional'),
    ('EIIC', 'Encuentro de investigacion');

-- ---------------------------------------------------------------------------
-- sede · "una catedra en San Benito, otra virtual y otra en Bello" (1:03:33)
-- ---------------------------------------------------------------------------
INSERT INTO sede (id_sede, nombre, direccion, es_virtual) VALUES
    ('SAN_BENITO', 'Campus San Benito', 'Carrera 56C 51-110, Medellin', false),
    ('BELLO',      'Campus Bello',      'Calle 45 61-40, Bello',        false),
    ('VIRTUAL',    'Virtual',           NULL,                            true);

-- ---------------------------------------------------------------------------
-- modalidad · canal_difusion decide QR o enlace (1:06:53)
-- ---------------------------------------------------------------------------
INSERT INTO modalidad (id_modalidad, nombre, canal_difusion) VALUES
    ('PRESENCIAL',    'Presencial',    'QR'),
    ('VIRTUAL',       'Virtual',       'ENLACE'),
    ('TELEPRESENCIAL','Telepresencial','ENLACE'),
    ('HIBRIDA',       'Hibrida',       'AMBOS');

-- ---------------------------------------------------------------------------
-- estado_proceso · los CINCO estados literales del manual, pagina 6
-- ---------------------------------------------------------------------------
INSERT INTO estado_proceso (id_estado, nombre, es_final, es_exitoso) VALUES
    ('GENERADO',   'Generado, sin enviar',  false, false),
    ('EN_COLA',    'En cola',               false, false),
    ('EN_CURSO',   'En curso',              false, false),
    ('ERROR',      'Error',                 true,  false),
    ('CORRECTO',   'Correcto',              true,  true),
    ('INCORRECTO', 'Incorrecto',            true,  false);

COMMENT ON TABLE estado_proceso IS
    'Los cinco estados del Monitor Procesos del ASIS, mas GENERADO para el '
    'momento en que el archivo existe pero todavia no se ha subido.';

-- ---------------------------------------------------------------------------
-- tipo_pregunta
-- ---------------------------------------------------------------------------
INSERT INTO tipo_pregunta (id_tipo_pregunta, nombre, guarda_numero, guarda_texto, guarda_opcion) VALUES
    ('ESCALA_5',    'Escala de 1 a 5',   true,  false, false),
    ('SI_NO',       'Si o no',           true,  false, false),
    ('TEXTO_LIBRE', 'Texto libre',       false, true,  false),
    ('OPCION_UNICA','Opcion unica',      false, false, true);

-- ---------------------------------------------------------------------------
-- rol
-- ---------------------------------------------------------------------------
INSERT INTO rol (id_rol, nombre, descripcion) VALUES
    ('ADMIN',       'Administrador',            'Gestiona catedras, enlaces, cargas y migraciones'),
    ('COORDINADOR', 'Coordinador de dependencia','Ve y gestiona lo de su dependencia'),
    ('CONSULTA',    'Consulta',                 'Solo lectura de informes');

-- ---------------------------------------------------------------------------
-- parametro · "el administrador configura o parametriza los valores que
--             considere" (.docx)
-- ---------------------------------------------------------------------------
INSERT INTO parametro (clave, valor, tipo_dato, descripcion) VALUES
    ('VENTANA_MINUTOS_ANTES',    '30',  'ENTERO',
     'Minutos antes del inicio en que se abre el registro'),
    ('VENTANA_MINUTOS_DESPUES',  '30',  'ENTERO',
     'Minutos despues del fin en que se cierra el registro'),
    ('CLAVE_VIGENCIA_MINUTOS',   '10',  'ENTERO',
     'Minutos que vive la clave enviada al correo'),
    ('CLAVE_LONGITUD',           '6',   'ENTERO',
     'Digitos de la clave de un solo uso'),
    ('CLAVE_MAX_INTENTOS',       '3',   'ENTERO',
     'Intentos antes de anular la clave'),
    ('DOMINIOS_INSTITUCIONALES', 'usbmed.edu.co,usb.edu.co', 'TEXTO',
     'Dominios que cuentan como correo institucional. Alimenta RN-19 e I18'),
    ('URL_BASE',                 'https://catedras.usbmed.edu.co/r/', 'TEXTO',
     'Prefijo de la URL publica de registro'),
    ('VERSION_POLITICA_DATOS',   '2026.1', 'TEXTO',
     'Version vigente de la politica de tratamiento de datos, Ley 1581 de 2012'),
    ('PERMITE_EXTERNOS',         'true', 'BOOLEANO',
     'DECISION ABIERTA §3.1: si es false, solo entra quien tenga ID en el ASIS');

-- ---------------------------------------------------------------------------
-- periodo_academico
-- ---------------------------------------------------------------------------
INSERT INTO periodo_academico (id_periodo, fecha_ini, fecha_fin) VALUES
    ('2025-1', '2025-01-20', '2025-06-07'),
    ('2025-2', '2025-07-21', '2025-12-06'),
    ('2026-1', '2026-01-19', '2026-06-06'),
    ('2026-2', '2026-07-20', '2026-12-05');

-- ---------------------------------------------------------------------------
-- dependencia · arbol
-- ---------------------------------------------------------------------------
INSERT INTO dependencia (id_dependencia, nombre, fk_dependencia_padre) VALUES
    ('VICE_ACAD',  'Vicerrectoria Academica',        NULL),
    ('BIENESTAR',  'Bienestar Institucional',        NULL),
    ('PASTORAL',   'Pastoral Universitaria',         'BIENESTAR'),
    ('DEPORTES',   'Deportes y Recreacion',          'BIENESTAR'),
    ('CULTURA',    'Arte y Cultura',                 'BIENESTAR'),
    ('SALUD',      'Salud Integral',                 'BIENESTAR'),
    ('DESA_HUM',   'Desarrollo Humano',              'BIENESTAR'),
    ('INVESTIG',   'Direccion de Investigaciones',   'VICE_ACAD');

-- ---------------------------------------------------------------------------
-- facultad · arbol
-- ---------------------------------------------------------------------------
INSERT INTO facultad (id_facultad, nombre, fk_facultad_padre) VALUES
    ('USB',      'Universidad de San Buenaventura',        NULL),
    ('F_ING',    'Facultad de Ingenierias',                'USB'),
    ('F_ARTES',  'Facultad de Artes Integradas',           'USB'),
    ('F_PSICO',  'Facultad de Psicologia',                 'USB'),
    ('F_DERECHO','Facultad de Derecho y Ciencias Politicas','USB'),
    ('F_EDU',    'Facultad de Educacion',                  'USB'),
    ('F_CIENCIAS','Facultad de Ciencias Empresariales',    'USB'),
    ('F_SALUD',  'Facultad de Ciencias de la Salud',       'USB'),
    ('F_OTRA',   'Otras unidades academicas',              'USB');

\echo '12 · Catalogos cargados'


-- ==========================================================================
--  13/18  ·  Carga REAL del ASIS
--  fuente: 13-carga-asis.sql
--
--  Necesita datos/*.csv  ->  ejecute antes:  python preparar-datos.py
-- ==========================================================================

\echo ''
\echo '>>> 13/18 · Carga REAL del ASIS'

-- ============================================================================
--  13 · Carga de los datos REALES del ASIS
--
--  Requisito: haber ejecutado antes  python preparar-datos.py
--             que escribe datos/*.csv a partir de los dos Excel.
--
--  Volumenes esperados, medidos sobre los archivos reales:
--      catedras     5.496      programas       105
--      sesiones     5.711      personas     14.808
--      documentos  15.517      matriculas   15.349
--
--  Se carga a tablas de paso y de ahi al modelo. Nada entra por conversion
--  implicita: todo llega como texto y se convierte con evidencia.
-- ============================================================================

SET search_path TO public;

\echo '13 · Cargando datos reales del ASIS...'

-- ---------------------------------------------------------------------------
-- Tablas de paso
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE stg_catedra   (id_evento_asis text, nombre text, tipo_evento text);
CREATE TEMP TABLE stg_sesion    (id_evento_asis text, numero_reunion text);
CREATE TEMP TABLE stg_programa  (codigo text, nombre text);
CREATE TEMP TABLE stg_asistente (id_asis text, nombres text, apellidos text,
                                 nombre_completo_asis text, correo_institucional text);
CREATE TEMP TABLE stg_documento (id_asis text, tipo text, numero text, vigente text);
CREATE TEMP TABLE stg_matricula (id_asis text, codigo text);
CREATE TEMP TABLE stg_novedad   (numero_fila text, contenido_crudo text, motivo text);

\copy stg_catedra   FROM 'datos/catedra.csv'   WITH (FORMAT csv, HEADER true)
\copy stg_sesion    FROM 'datos/sesion.csv'    WITH (FORMAT csv, HEADER true)
\copy stg_programa  FROM 'datos/programa.csv'  WITH (FORMAT csv, HEADER true)
\copy stg_asistente FROM 'datos/asistente.csv' WITH (FORMAT csv, HEADER true)
\copy stg_documento FROM 'datos/documento.csv' WITH (FORMAT csv, HEADER true)
\copy stg_matricula FROM 'datos/matricula.csv' WITH (FORMAT csv, HEADER true)
\copy stg_novedad   FROM 'datos/novedad.csv'   WITH (FORMAT csv, HEADER true)

-- ---------------------------------------------------------------------------
-- El lote, para que la carga deje evidencia
-- ---------------------------------------------------------------------------
INSERT INTO lote_carga_asistente (nombre_archivo, filas_leidas, observaciones)
SELECT 'USBME_EMPLID_CATED_V1_1504983333.xlsx',
       (SELECT count(*) FROM stg_asistente) + (SELECT count(*) FROM stg_novedad),
       'Carga inicial. Nombres y correos SINTETIZADOS: el informe actual del '
       'ASIS solo entrega tres columnas. Ver riesgo 1 del plan.';

-- ---------------------------------------------------------------------------
-- 1 · Programas
-- ---------------------------------------------------------------------------
INSERT INTO programa_academico (codigo, nombre, fk_facultad, nivel)
SELECT s.codigo, s.nombre, 'F_OTRA',
       CASE WHEN s.codigo ~ '^M0[0-4]' THEN 'PREGRADO' ELSE 'OTRO' END
  FROM stg_programa s
ON CONFLICT (codigo) DO NOTHING;

-- El unico programa cuyo nombre real conocemos: lo dijo el profesor Carlos
-- Castro en 49:55 y el profesor Hugo Nelson lo confirmo en 50:01.
UPDATE programa_academico
   SET nombre = 'Ingenieria de Datos y Software', fk_facultad = 'F_ING'
 WHERE codigo = 'M0286';

-- ---------------------------------------------------------------------------
-- 2 · Catedras · H8 · el id llega ya con ceros a la izquierda
-- ---------------------------------------------------------------------------
INSERT INTO catedra (id_evento_asis, nombre, fk_tipo_evento)
SELECT s.id_evento_asis, s.nombre,
       CASE WHEN EXISTS (SELECT 1 FROM tipo_evento t
                          WHERE t.id_tipo_evento = rpad(s.tipo_evento, 4))
            THEN rpad(s.tipo_evento, 4) ELSE 'CAAB' END
  FROM stg_catedra s
ON CONFLICT (id_evento_asis) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 3 · Sesiones · H12 · el numero llegaba como flotante y ya viene entero
--
-- Se cargan con fechas sinteticas derivadas del numero de reunion: el listado
-- del ASIS no trae fecha. Lo que importa aqui es el CONSECUTIVO, que es lo
-- que se va a comprobar.
-- ---------------------------------------------------------------------------
INSERT INTO sesion (fk_catedra, numero_reunion, inicio, fin,
                    fk_modalidad, fk_sede, fk_periodo, estado)
SELECT c.id_catedra,
       s.numero_reunion::smallint,
       timestamptz '2026-01-19 08:00-05' + (s.numero_reunion::int - 1) * interval '7 day',
       timestamptz '2026-01-19 10:00-05' + (s.numero_reunion::int - 1) * interval '7 day',
       'PRESENCIAL', 'SAN_BENITO', '2026-1', 'CERRADA'
  FROM stg_sesion s
  JOIN catedra c ON c.id_evento_asis = s.id_evento_asis
ON CONFLICT (fk_catedra, numero_reunion) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 4 · Asistentes
-- ---------------------------------------------------------------------------
INSERT INTO asistente (id_asis, nombres, apellidos, nombre_completo_asis,
                       correo_institucional, es_externo, fk_lote_carga)
SELECT s.id_asis, s.nombres, s.apellidos, s.nombre_completo_asis,
       s.correo_institucional::citext, false,
       (SELECT max(id_lote_carga) FROM lote_carga_asistente)
  FROM stg_asistente s
ON CONFLICT (id_asis) DO NOTHING;

-- Toda persona del maestro es interna, y su vinculacion por defecto es
-- estudiante. En produccion esto vendra en el informe ampliado.
INSERT INTO vinculacion_asistente (fk_asistente, fk_tipo_vinculacion, fecha_ini)
SELECT a.id_asistente, 'ESTUDIANTE', date '2026-01-19'
  FROM asistente a
 WHERE a.id_asis IS NOT NULL
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------------
-- 5 · Documentos · H10 · aqui se comprueban los 707 casos
-- ---------------------------------------------------------------------------
INSERT INTO documento_asistente (fk_asistente, fk_tipo_documento, numero, vigente)
SELECT a.id_asistente, s.tipo, s.numero, s.vigente::boolean
  FROM stg_documento s
  JOIN asistente a ON a.id_asis = s.id_asis
ON CONFLICT (fk_tipo_documento, numero) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 6 · Matriculas · H11 · los pares duplicados ya vienen deduplicados
-- ---------------------------------------------------------------------------
INSERT INTO programa_asistente (fk_asistente, fk_programa, fk_periodo, estado)
SELECT a.id_asistente, s.codigo, '2026-1', 'ACTIVO'
  FROM stg_matricula s
  JOIN asistente a ON a.id_asis = s.id_asis
  JOIN programa_academico p ON p.codigo = s.codigo
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------------
-- 7 · Novedades y cierre del lote
-- ---------------------------------------------------------------------------
INSERT INTO novedad_carga (fk_lote_carga, numero_fila, contenido_crudo, motivo)
SELECT (SELECT max(id_lote_carga) FROM lote_carga_asistente),
       s.numero_fila::int, s.contenido_crudo, s.motivo
  FROM stg_novedad s;

-- Se cuentan los asistentes de ESTE lote, no todos los de la tabla: si no,
-- una segunda carga violaria chk_lote_carga_filas al sumar los anteriores.
UPDATE lote_carga_asistente l
   SET filas_aceptadas  = (SELECT count(*) FROM asistente a WHERE a.fk_lote_carga = l.id_lote_carga),
       filas_rechazadas = (SELECT count(*) FROM stg_novedad)
 WHERE l.id_lote_carga = (SELECT max(id_lote_carga) FROM lote_carga_asistente);

-- ---------------------------------------------------------------------------
-- 8 · Alias de programa · lo que trae el formulario en texto libre
-- ---------------------------------------------------------------------------
INSERT INTO alias_programa (texto_normalizado, fk_programa, origen)
SELECT fn_normalizar(t.txt), 'M0286', 'FORMULARIO'
  FROM (VALUES ('Ingenieria de datos y software'),
               ('Ingenieria de Datos y Software'),
               ('ingenieria de datos'),
               ('Ing. datos y software')) AS t(txt)
ON CONFLICT (texto_normalizado) DO NOTHING;

-- ============================================================================
-- VERIFICACIONES · deben coincidir con los volumenes del encabezado
-- ============================================================================
\echo ''
\echo 'Verificacion de la carga:'

SELECT 'catedras'    AS objeto, count(*) AS filas, 5496 AS esperado FROM catedra
UNION ALL SELECT 'sesiones',   count(*), 5711  FROM sesion
UNION ALL SELECT 'programas',  count(*), 105   FROM programa_academico
UNION ALL SELECT 'asistentes', count(*), 14808 FROM asistente
UNION ALL SELECT 'documentos', count(*), 15517 FROM documento_asistente
UNION ALL SELECT 'matriculas', count(*), 15349 FROM programa_asistente;

\echo ''
\echo 'H10 · personas con mas de un documento (deben ser 707):'
SELECT count(*) AS personas_con_varios_documentos
  FROM (SELECT fk_asistente FROM documento_asistente
         GROUP BY fk_asistente HAVING count(*) > 1) q;

\echo ''
\echo 'H4 · el par (catedra, reunion) es unico - lo garantiza uq_sesion_reunion.'
\echo 'H2 · nombres truncados a 30 por el ASIS, recuperados en la columna nombre:'
SELECT nombre_asis, left(nombre, 45) AS nombre_completo
  FROM catedra
 WHERE length(nombre) >= 30
 LIMIT 3;

\echo '13 · Carga real terminada'


-- ==========================================================================
--  14/18  ·  Vistas
--  fuente: 15-vistas.sql
-- ==========================================================================

\echo ''
\echo '>>> 14/18 · Vistas'

-- ============================================================================
--  15 · Vistas
--
--  Seis vistas. Tres resuelven consultas que se repiten en varios informes,
--  y tres son CONTROLES: consultas que deben devolver cero.
-- ============================================================================

SET search_path TO public;

-- ---------------------------------------------------------------------------
-- v_asistente_vigente · la foto actual de una persona
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_asistente_vigente AS
SELECT a.id_asistente,
       a.id_asis,
       a.nombres || ' ' || a.apellidos          AS nombre_completo,
       a.es_externo,
       coalesce(a.correo_institucional, a.correo_personal) AS correo_contacto,
       (a.correo_institucional IS NOT NULL)     AS tiene_correo_institucional,
       d.numero                                  AS documento_vigente,
       d.fk_tipo_documento                       AS tipo_documento,
       v.fk_tipo_vinculacion                     AS vinculacion,
       tv.nombre                                 AS vinculacion_nombre,
       tv.es_interno,
       tv.exige_programa,
       a.activo
  FROM asistente a
  LEFT JOIN documento_asistente d
         ON d.fk_asistente = a.id_asistente AND d.vigente
  LEFT JOIN LATERAL (
        SELECT va.fk_tipo_vinculacion
          FROM vinculacion_asistente va
         WHERE va.fk_asistente = a.id_asistente AND va.fecha_fin IS NULL
         ORDER BY va.fecha_ini DESC LIMIT 1
       ) v ON true
  LEFT JOIN tipo_vinculacion tv ON tv.id_tipo_vinculacion = v.fk_tipo_vinculacion;

COMMENT ON VIEW v_asistente_vigente IS
    'La foto ACTUAL de una persona: su documento vigente y su vinculacion '
    'vigente. Ojo: para los informes de asistencia NO se usa esta vista, sino '
    'las instantaneas del registro. Aqui esta el hoy; alli, el dia de la '
    'catedra.';

-- ---------------------------------------------------------------------------
-- v_asistencia_completa · la union que necesitan casi todos los informes
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_asistencia_completa AS
SELECT r.id_registro,
       r.registrado_en,
       r.origen,
       c.id_evento_asis,
       c.nombre                AS catedra,
       s.id_sesion,
       s.numero_reunion,
       s.titulo                AS sesion,
       s.inicio,
       s.fk_periodo            AS periodo,
       se.nombre               AS sede,
       m.nombre                AS modalidad,
       a.id_asistente,
       a.id_asis,
       a.nombres || ' ' || a.apellidos AS asistente,
       a.es_externo,
       r.fk_programa_snapshot  AS programa,
       p.nombre                AS programa_nombre,
       p.fk_facultad           AS facultad,
       r.fk_vinculacion_snapshot AS vinculacion,
       tv.es_interno,
       (re.id_respuesta IS NOT NULL) AS respondio_encuesta
  FROM registro_asistencia r
  JOIN sesion   s  ON s.id_sesion    = r.fk_sesion
  JOIN catedra  c  ON c.id_catedra   = s.fk_catedra
  JOIN sede     se ON se.id_sede     = s.fk_sede
  JOIN modalidad m ON m.id_modalidad = s.fk_modalidad
  JOIN asistente a ON a.id_asistente = r.fk_asistente
  JOIN tipo_vinculacion tv ON tv.id_tipo_vinculacion = r.fk_vinculacion_snapshot
  LEFT JOIN programa_academico p ON p.codigo = r.fk_programa_snapshot
  LEFT JOIN respuesta_encuesta re ON re.fk_registro = r.id_registro;

COMMENT ON VIEW v_asistencia_completa IS
    'Base de los informes I1 a I5 y I14. Usa las INSTANTANEAS del registro, no '
    'el programa ni la vinculacion vigentes: es lo que hace que un informe de '
    'un periodo cerrado siga dando lo mismo dentro de un ano.';

-- ---------------------------------------------------------------------------
-- v_pendiente_migracion · la cola de trabajo del gestor
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_pendiente_migracion AS
SELECT s.id_sesion,
       c.id_evento_asis,
       c.nombre                    AS catedra,
       s.numero_reunion,
       s.inicio,
       count(*)                    AS registros,
       count(*) FILTER (WHERE a.id_asis IS NULL)              AS sin_id_asis,
       count(*) FILTER (WHERE r.fk_programa_snapshot IS NULL) AS sin_programa,
       count(*) FILTER (WHERE a.es_externo)                   AS externos,
       count(*) FILTER (WHERE a.id_asis IS NOT NULL
                          AND r.fk_programa_snapshot IS NOT NULL
                          AND NOT a.es_externo)               AS migrables
  FROM registro_asistencia r
  JOIN sesion    s ON s.id_sesion    = r.fk_sesion
  JOIN catedra   c ON c.id_catedra   = s.fk_catedra
  JOIN asistente a ON a.id_asistente = r.fk_asistente
 WHERE NOT EXISTS (SELECT 1 FROM lote_migracion lm
                    WHERE lm.fk_sesion = s.id_sesion
                      AND lm.fk_estado_proceso = 'CORRECTO')
 GROUP BY s.id_sesion, c.id_evento_asis, c.nombre, s.numero_reunion, s.inicio;

-- ---------------------------------------------------------------------------
-- v_evaluacion_sesion · el informe 3 del enunciado
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_evaluacion_sesion AS
SELECT s.id_sesion,
       c.nombre                       AS catedra,
       s.numero_reunion,
       p.orden,
       p.enunciado,
       tp.id_tipo_pregunta            AS tipo,
       count(ri.id_item)              AS respuestas,
       round(avg(ri.valor_numerico), 2) AS promedio,
       min(ri.valor_numerico)         AS minimo,
       max(ri.valor_numerico)         AS maximo
  FROM respuesta_item ri
  JOIN respuesta_encuesta re ON re.id_respuesta = ri.fk_respuesta
  JOIN registro_asistencia r ON r.id_registro   = re.fk_registro
  JOIN sesion  s ON s.id_sesion  = r.fk_sesion
  JOIN catedra c ON c.id_catedra = s.fk_catedra
  JOIN pregunta p ON p.id_pregunta = ri.fk_pregunta
  JOIN tipo_pregunta tp ON tp.id_tipo_pregunta = p.fk_tipo_pregunta
 WHERE tp.guarda_numero
 GROUP BY s.id_sesion, c.nombre, s.numero_reunion, p.orden, p.enunciado, tp.id_tipo_pregunta;

-- ---------------------------------------------------------------------------
-- v_embudo_registro · donde se cae la gente
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_embudo_registro AS
SELECT s.id_sesion,
       c.nombre AS catedra,
       s.numero_reunion,
       (SELECT count(*) FROM enlace_registro e WHERE e.fk_sesion = s.id_sesion)  AS enlaces,
       (SELECT count(*) FROM clave_acceso k
          JOIN enlace_registro e ON e.id_enlace = k.fk_enlace
         WHERE e.fk_sesion = s.id_sesion)                                        AS claves_enviadas,
       (SELECT count(*) FROM clave_acceso k
          JOIN enlace_registro e ON e.id_enlace = k.fk_enlace
         WHERE e.fk_sesion = s.id_sesion AND k.usado_en IS NOT NULL)             AS claves_usadas,
       (SELECT count(*) FROM registro_asistencia r WHERE r.fk_sesion = s.id_sesion) AS registros,
       (SELECT count(*) FROM respuesta_encuesta re
          JOIN registro_asistencia r ON r.id_registro = re.fk_registro
         WHERE r.fk_sesion = s.id_sesion)                                        AS encuestas
  FROM sesion s
  JOIN catedra c ON c.id_catedra = s.fk_catedra;

-- ---------------------------------------------------------------------------
-- v_control_ventana · CONTROL · debe devolver CERO filas
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_control_ventana AS
SELECT r.id_registro, r.registrado_en, e.ventana, r.origen
  FROM registro_asistencia r
  JOIN enlace_registro e ON e.id_enlace = r.fk_enlace
 WHERE r.origen NOT IN ('MANUAL', 'IMPORTADO')
   AND NOT (e.ventana @> r.registrado_en);

COMMENT ON VIEW v_control_ventana IS
    'CONTROL de RN-15. Debe devolver CERO filas siempre. Si alguna vez devuelve '
    'algo, es que se desactivo el disparador o que alguien inserto por detras.';

\echo '15 · Vistas creadas - 6'


-- ==========================================================================
--  15/18  ·  Datos de prueba
--  fuente: 14-datos-prueba.sql
--
--  Va DESPUES de las vistas porque algunas comprobaciones las usan.
-- ==========================================================================

\echo ''
\echo '>>> 15/18 · Datos de prueba'

-- ============================================================================
--  14 · Datos de prueba · el flujo completo, de punta a punta
--
--  Reconstruye la catedra "Pedagogia Electoral" que el profesor Hugo Nelson
--  mostro en la reunion (1:06:25) y que hoy se recoge con un formulario
--  anonimo de Microsoft Forms.
--
--  Los asistentes son SINTETICOS. Los 164 nombres y cedulas reales del
--  formulario NO se reproducen aqui: son datos personales y el modelo se
--  demuestra igual de bien sin ellos.
-- ============================================================================

SET search_path TO public;

\echo '14 · Datos de prueba - flujo completo...'

-- ---------------------------------------------------------------------------
-- 0 · Un administrador
-- ---------------------------------------------------------------------------
INSERT INTO asistente (id_asis, nombres, apellidos, correo_institucional, es_externo)
VALUES ('30016947', 'Administrador', 'Catedras', 'admin.catedras@usbmed.edu.co', false)
ON CONFLICT (id_asis) DO NOTHING;

INSERT INTO vinculacion_asistente (fk_asistente, fk_tipo_vinculacion, fecha_ini)
SELECT id_asistente, 'ADMINISTRATIVO', date '2026-01-01'
  FROM asistente WHERE id_asis = '30016947'
ON CONFLICT DO NOTHING;

-- El hash de BCrypt (coste 12) de la clave  Catedras2026*
--
-- Va escrito aqui a proposito, para que la base quede utilizable nada mas
-- construirla: sin esto no hay forma de pedir el primer token y la API entera
-- queda cerrada. Es la MISMA credencial que documenta el README de la API y
-- que usan pruebas/certificacion.sh y pruebas/flujo-completo.sh.
--
--   >>> ADVERTENCIA · ESTO NO PUEDE LLEGAR A PRODUCCION <<<
--   Una clave de administrador publicada en un repositorio no es una clave.
--   En produccion este bloque no debe ejecutarse: el primer administrador se
--   crea a mano, con una clave que nadie mas conozca, y el hash se calcula en
--   la aplicacion. Nunca se escribe una clave en claro en un script.
--
-- El login sigue siendo 'admin.catedras', pero NO es lo que se teclea: la API
-- autentica por CORREO (asistente.correo_institucional), de ahi que la
-- credencial sea admin.catedras@usbmed.edu.co. Ver AutenticacionRepositorio.cs.
INSERT INTO usuario (fk_asistente, usuario, clave_hash)
SELECT id_asistente, 'admin.catedras',
       '$2b$12$1hxs9gOETaNm5DV5pGEEGOpHVJwGoCP0Q9unvLt9oVyd5mbh6XLUm'
  FROM asistente WHERE id_asis = '30016947'
ON CONFLICT (usuario) DO NOTHING;

INSERT INTO rol_por_usuario (fk_usuario, fk_rol, fecha_ini)
SELECT id_usuario, 'ADMIN', date '2026-01-01' FROM usuario WHERE usuario = 'admin.catedras'
ON CONFLICT DO NOTHING;

-- RN-31 · el mismo usuario recupera un rol que ya tuvo.
-- Sin fecha_ini en la clave primaria, este INSERT se rechazaria.
INSERT INTO rol_por_usuario (fk_usuario, fk_rol, fecha_ini, fecha_fin)
SELECT id_usuario, 'CONSULTA', date '2025-01-01', date '2025-06-30'
  FROM usuario WHERE usuario = 'admin.catedras'
ON CONFLICT DO NOTHING;
INSERT INTO rol_por_usuario (fk_usuario, fk_rol, fecha_ini)
SELECT id_usuario, 'CONSULTA', date '2026-02-01'
  FROM usuario WHERE usuario = 'admin.catedras'
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------------
-- 1 · La encuesta de calidad
-- ---------------------------------------------------------------------------
INSERT INTO encuesta (nombre, version, vigente_desde)
VALUES ('Calidad de la catedra abierta', 1, date '2026-01-01')
ON CONFLICT (nombre, version) DO NOTHING;

INSERT INTO pregunta (fk_encuesta, enunciado, orden, fk_tipo_pregunta, obligatoria, valor_min, valor_max)
SELECT e.id_encuesta, t.enunciado, t.orden, t.tipo, t.oblig, t.vmin, t.vmax
  FROM encuesta e,
       (VALUES ('Como califica la calidad general de la catedra', 1, 'ESCALA_5', true,  1, 5),
               ('Como califica al ponente',                       2, 'ESCALA_5', true,  1, 5),
               ('La duracion fue adecuada',                       3, 'SI_NO',    false, 0, 1),
               ('Que sugerencia tiene para mejorar',              4, 'TEXTO_LIBRE', false, NULL, NULL)
       ) AS t(enunciado, orden, tipo, oblig, vmin, vmax)
 WHERE e.nombre = 'Calidad de la catedra abierta' AND e.version = 1
ON CONFLICT (fk_encuesta, orden) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2 · La catedra y tres sesiones simultaneas en sedes distintas
--     "puede que una catedra este en San Benito, otra este virtual y otra
--      este en Bello" (1:03:33)
-- ---------------------------------------------------------------------------
INSERT INTO catedra (id_evento_asis, nombre, fk_tipo_evento, fk_dependencia)
VALUES ('000099001', 'Pedagogia Electoral y participacion ciudadana', 'CAAB', 'DESA_HUM')
ON CONFLICT (id_evento_asis) DO NOTHING;

-- numero_reunion NO se digita: lo pone el disparador (RN-10)
INSERT INTO sesion (fk_catedra, numero_reunion, titulo, inicio, fin,
                    fk_modalidad, fk_sede, fk_periodo, fk_encuesta, lugar, cupo)
-- La catedra real fue el 2026-03-06 16:00. La sesion de prueba se ancla a la
-- hora de ejecucion para que la VENTANA DEL ENLACE este vigente y el flujo
-- completo se pueda ejercitar de verdad: si se dejara la fecha historica,
-- sp_solicitar_clave la rechazaria por RN-15, que es justo lo que debe hacer.
SELECT c.id_catedra, 0, t.titulo,
       date_trunc('hour', now()), date_trunc('hour', now()) + interval '2 hour',
       t.modalidad, t.sede,
       (SELECT id_periodo FROM periodo_academico
         WHERE current_date BETWEEN fecha_ini AND fecha_fin
         ORDER BY id_periodo LIMIT 1),
       (SELECT id_encuesta FROM encuesta WHERE nombre = 'Calidad de la catedra abierta' AND version = 1),
       t.lugar, t.cupo
  FROM catedra c,
       (VALUES ('Sesion San Benito', 'PRESENCIAL', 'SAN_BENITO', 'Auditorio Bolivariano', 200),
               ('Sesion Bello',      'PRESENCIAL', 'BELLO',      'Auditorio Bello',       80),
               ('Sesion virtual',    'VIRTUAL',    'VIRTUAL',    NULL,                  NULL)
       ) AS t(titulo, modalidad, sede, lugar, cupo)
 WHERE c.id_evento_asis = '000099001';

-- ---------------------------------------------------------------------------
-- 3 · Los enlaces · el boton que genera QR y URL
-- ---------------------------------------------------------------------------
DO $$
DECLARE
    r record;
    v_enlace bigint;
    v_admin  bigint;
BEGIN
    SELECT id_usuario INTO v_admin FROM usuario WHERE usuario = 'admin.catedras';

    FOR r IN SELECT s.id_sesion
               FROM sesion s JOIN catedra c ON c.id_catedra = s.fk_catedra
              WHERE c.id_evento_asis = '000099001'
              ORDER BY s.numero_reunion
    LOOP
        CALL sp_emitir_enlace(r.id_sesion, 60, 60, v_admin, v_enlace);
    END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- 4 · Los asistentes de prueba, incluidos los casos dificiles
-- ---------------------------------------------------------------------------

-- 4a · Un participante de RUTAS DE PAZ: sin programa y sin correo institucional
INSERT INTO asistente (id_asis, nombres, apellidos, correo_personal, es_externo)
VALUES ('30099001', 'Participante', 'Rutas de Paz', 'participante.rutas@gmail.com', false)
ON CONFLICT (id_asis) DO NOTHING;

INSERT INTO vinculacion_asistente (fk_asistente, fk_tipo_vinculacion, fecha_ini)
SELECT id_asistente, 'RUTAS_PAZ', date '2026-01-19'
  FROM asistente WHERE id_asis = '30099001'
ON CONFLICT DO NOTHING;

-- 4b · Un EXTERNO: sin id_asis. Se cuenta, pero nunca migra (RN-08)
INSERT INTO asistente (id_asis, nombres, apellidos, correo_personal, es_externo)
VALUES (NULL, 'Publico', 'Externo', 'publico.externo@gmail.com', true);

INSERT INTO vinculacion_asistente (fk_asistente, fk_tipo_vinculacion, fecha_ini)
SELECT id_asistente, 'EXTERNO', date '2026-03-06'
  FROM asistente WHERE correo_personal = 'publico.externo@gmail.com'::citext
ON CONFLICT DO NOTHING;

-- 4c · Consentimiento de todos los de prueba (Ley 1581)
INSERT INTO consentimiento_datos (fk_asistente, version_politica, canal)
SELECT id_asistente, '2026.1', 'WEB'
  FROM asistente
 WHERE id_asis IN ('30099001', '30016947')
    OR correo_personal = 'publico.externo@gmail.com'::citext
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------------
-- 5 · 164 registros en la sesion de San Benito, con el flujo real:
--     solicitar clave -> validar clave -> registrar
--
--     Son 164 porque es el numero exacto de respuestas que trajo el
--     formulario de Pedagogia Electoral.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
    v_sesion   bigint;
    v_token    uuid;
    v_clave_id bigint;
    v_clave    text;
    v_correo   text;
    v_reg      bigint;
    r          record;
    n          integer := 0;
BEGIN
    SELECT s.id_sesion INTO v_sesion
      FROM sesion s JOIN catedra c ON c.id_catedra = s.fk_catedra
     WHERE c.id_evento_asis = '000099001' AND s.fk_sede = 'SAN_BENITO';

    SELECT token INTO v_token FROM enlace_registro
     WHERE fk_sesion = v_sesion AND revocado_en IS NULL;

    -- DISTINCT porque una persona puede tener VARIOS programas (H12, el N:M).
    -- Sin el, el mismo asistente entraria dos veces y uq_registro_sesion_asis
    -- lo rechazaria - que es exactamente lo que debe hacer (RN-21).
    FOR r IN SELECT DISTINCT a.id_asis
               FROM asistente a
               JOIN programa_asistente pa ON pa.fk_asistente = a.id_asistente
              WHERE a.id_asis IS NOT NULL
              ORDER BY a.id_asis
              LIMIT 164
    LOOP
        CALL sp_solicitar_clave(r.id_asis, v_token, '10.0.0.1'::inet,
                                v_clave_id, v_clave, v_correo);
        CALL sp_validar_clave_y_registrar(v_clave_id, v_clave, '10.0.0.1'::inet,
                                          'Mozilla/5.0 (prueba)', v_reg);
        n := n + 1;
    END LOOP;

    RAISE NOTICE '% registros creados con el flujo completo', n;
END $$;

-- 5b · El de Rutas de Paz: se registra SIN programa (RN-07)
DO $$
DECLARE
    v_sesion bigint; v_token uuid; v_cid bigint; v_cl text; v_co text; v_reg bigint;
BEGIN
    SELECT s.id_sesion INTO v_sesion
      FROM sesion s JOIN catedra c ON c.id_catedra = s.fk_catedra
     WHERE c.id_evento_asis = '000099001' AND s.fk_sede = 'SAN_BENITO';
    SELECT token INTO v_token FROM enlace_registro
     WHERE fk_sesion = v_sesion AND revocado_en IS NULL;

    CALL sp_solicitar_clave('30099001', v_token, NULL, v_cid, v_cl, v_co);
    CALL sp_validar_clave_y_registrar(v_cid, v_cl, NULL, NULL, v_reg);
    RAISE NOTICE 'Rutas de Paz registrado sin programa. Correo destino: %', v_co;
END $$;

-- 5c · El externo, por la via manual (no esta en el maestro del ASIS)
INSERT INTO registro_asistencia (fk_sesion, fk_asistente, fk_vinculacion_snapshot, origen)
SELECT s.id_sesion, a.id_asistente, 'EXTERNO', 'MANUAL'
  FROM sesion s
  JOIN catedra c ON c.id_catedra = s.fk_catedra
  CROSS JOIN asistente a
 WHERE c.id_evento_asis = '000099001' AND s.fk_sede = 'SAN_BENITO'
   AND a.correo_personal = 'publico.externo@gmail.com'::citext
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------------
-- 6 · Encuestas respondidas · 60 de los 164
-- ---------------------------------------------------------------------------
DO $$
DECLARE
    r    record;
    v_rp bigint;
    p1 bigint; p2 bigint; p3 bigint; p4 bigint;
    n integer := 0;
BEGIN
    SELECT max(CASE WHEN orden=1 THEN id_pregunta END),
           max(CASE WHEN orden=2 THEN id_pregunta END),
           max(CASE WHEN orden=3 THEN id_pregunta END),
           max(CASE WHEN orden=4 THEN id_pregunta END)
      INTO p1, p2, p3, p4
      FROM pregunta p JOIN encuesta e ON e.id_encuesta = p.fk_encuesta
     WHERE e.nombre = 'Calidad de la catedra abierta';

    FOR r IN SELECT ra.id_registro, row_number() OVER (ORDER BY ra.id_registro) AS i
               FROM registro_asistencia ra
               JOIN sesion s ON s.id_sesion = ra.fk_sesion
               JOIN catedra c ON c.id_catedra = s.fk_catedra
              WHERE c.id_evento_asis = '000099001'
              ORDER BY ra.id_registro
              LIMIT 60
    LOOP
        CALL sp_responder_encuesta(r.id_registro,
             jsonb_build_array(
                jsonb_build_object('pregunta', p1, 'numero', 3 + (r.i % 3)),
                jsonb_build_object('pregunta', p2, 'numero', 4 + (r.i % 2)),
                jsonb_build_object('pregunta', p3, 'numero', r.i % 2),
                jsonb_build_object('pregunta', p4, 'texto',
                                   CASE WHEN r.i % 10 = 0
                                        THEN 'Mas tiempo para preguntas'
                                        ELSE 'Todo bien' END)),
             v_rp);
        n := n + 1;
    END LOOP;
    RAISE NOTICE '% encuestas respondidas', n;
END $$;

-- ---------------------------------------------------------------------------
-- 7 · El lote de migracion al ASIS
-- ---------------------------------------------------------------------------
DO $$
DECLARE
    v_sesion bigint; v_lote bigint;
BEGIN
    SELECT s.id_sesion INTO v_sesion
      FROM sesion s JOIN catedra c ON c.id_catedra = s.fk_catedra
     WHERE c.id_evento_asis = '000099001' AND s.fk_sede = 'SAN_BENITO';

    CALL sp_generar_lote_migracion(v_sesion, NULL, v_lote);

    UPDATE lote_migracion
       SET fk_estado_proceso = 'CORRECTO', instancia_proceso_asis = '9284471'
     WHERE id_lote_migracion = v_lote;

    UPDATE detalle_migracion SET resultado = 'ACEPTADO'
     WHERE fk_lote_migracion = v_lote;

    RAISE NOTICE 'Lote % generado y aceptado', v_lote;
END $$;

\echo '14 · Datos de prueba creados'


-- ==========================================================================
--  16/18  ·  Indices
--  fuente: 09-indices.sql
--
--  Van al final, con los datos ya cargados: un indice sobre una tabla vacia
--  no dice nada, y el plan de ejecucion sin datos es inutil.
-- ==========================================================================

\echo ''
\echo '>>> 16/18 · Indices'

-- ============================================================================
--  09 · Indices
--
--  Cada indice esta justificado por un informe o por una regla. No hay ninguno
--  "por si acaso": un indice que nadie usa cuesta escritura y espacio.
--
--  Las claves primarias y las restricciones UNIQUE ya crean su indice; aqui
--  solo van los que faltan.
-- ============================================================================

SET search_path TO public;

-- ============================================================================
-- A · Los tres indices del acceso (RN-06)
--
-- "Pongamosle 3 opciones, o sea, tiene que entrar por una de las 3" (57:27):
-- codigo, documento o correo. Los tres tienen que resolver igual de rapido,
-- porque los tres son la misma pantalla.
-- ============================================================================

-- 1 · por codigo ASIS  -> ya lo da uq_asistente_asis
-- 2 · por correo       -> ya lo dan uq_asistente_corinst y el indice de abajo
CREATE INDEX ix_asistente_correo_personal
    ON asistente (correo_personal)
    WHERE correo_personal IS NOT NULL;

-- 3 · por numero de documento -> ya lo da uq_documento_numero, pero la
--     pantalla busca SOLO por numero, sin saber el tipo
CREATE INDEX ix_documento_numero
    ON documento_asistente (numero);

COMMENT ON INDEX ix_documento_numero IS
    'La persona digita su cedula sin decir que tipo de documento es. Sin este '
    'indice, uq_documento_numero no sirve porque su primera columna es el tipo.';

-- RN-05 · un solo documento VIGENTE por asistente. Indice unico PARCIAL:
-- en MySQL no existen y habria que emularlo con una columna generada.
CREATE UNIQUE INDEX ux_documento_vigente
    ON documento_asistente (fk_asistente)
    WHERE vigente;

-- ============================================================================
-- B · Vinculacion y programas
-- ============================================================================

-- La vinculacion VIGENTE de una persona: la busca el disparador de instantanea
-- en cada registro, que es la operacion mas frecuente del sistema.
CREATE INDEX ix_vinculacion_vigente
    ON vinculacion_asistente (fk_asistente, fecha_ini DESC)
    WHERE fecha_fin IS NULL;

CREATE INDEX ix_progasi_programa  ON programa_asistente (fk_programa);
CREATE INDEX ix_progasi_periodo   ON programa_asistente (fk_periodo);

-- I2 e I3 · estadisticas por programa y por facultad
CREATE INDEX ix_programa_facultad ON programa_academico (fk_facultad);

-- ============================================================================
-- C · Catedras y sesiones
-- ============================================================================

-- I8 · siguiente numero de reunion -> lo resuelve uq_sesion_reunion
-- Agenda del dia y control de ventana
CREATE INDEX ix_sesion_inicio   ON sesion (inicio DESC);
CREATE INDEX ix_sesion_periodo  ON sesion (fk_periodo);

-- I14 · asistencia por sede y por modalidad
CREATE INDEX ix_sesion_sede      ON sesion (fk_sede);
CREATE INDEX ix_sesion_modalidad ON sesion (fk_modalidad);

CREATE INDEX ix_catedra_tipo   ON catedra (fk_tipo_evento);
CREATE INDEX ix_catedra_depend ON catedra (fk_dependencia)
    WHERE fk_dependencia IS NOT NULL;

-- ============================================================================
-- D · Acceso y registro - los mas criticos
-- ============================================================================

-- RN-14 · a lo sumo UN enlace vigente por sesion. Indice unico parcial.
CREATE UNIQUE INDEX ux_enlace_vigente
    ON enlace_registro (fk_sesion)
    WHERE revocado_en IS NULL;

-- RN-15 · resolver "este instante esta dentro de la ventana" con el indice
CREATE INDEX ix_enlace_ventana
    ON enlace_registro USING gist (ventana);

CREATE INDEX ix_clave_asistente ON clave_acceso (fk_asistente, generado_en DESC);
CREATE INDEX ix_clave_enlace    ON clave_acceso (fk_enlace);

-- I18 · claves enviadas a correo NO institucional. Parcial: es el caso raro,
-- y justamente por eso el indice es pequeno y muy selectivo.
CREATE INDEX ix_clave_no_institucional
    ON clave_acceso (generado_en DESC)
    WHERE NOT es_correo_institucional;

COMMENT ON INDEX ix_clave_no_institucional IS
    'I18. Alimenta la decision que el profesor Carlos Castro dejo pendiente en '
    '55:32 sobre los correos no institucionales.';

-- I19 · intentos fallidos, para vigilancia
CREATE INDEX ix_clave_intentos
    ON clave_acceso (fk_asistente, intentos)
    WHERE intentos > 0;

-- I1 · asistentes de una sesion. Es LA consulta de la pantalla del dia.
CREATE INDEX ix_registro_sesion    ON registro_asistencia (fk_sesion, registrado_en);
CREATE INDEX ix_registro_asistente ON registro_asistencia (fk_asistente);

-- I2 · estadisticas por programa, sobre la INSTANTANEA
CREATE INDEX ix_registro_programa_snap
    ON registro_asistencia (fk_programa_snapshot)
    WHERE fk_programa_snapshot IS NOT NULL;

-- I4 e I5 · internos contra externos, por vinculacion
CREATE INDEX ix_registro_vinc_snap ON registro_asistencia (fk_vinculacion_snapshot);

-- H18 · 164 personas registrandose en 60 segundos. La consulta de control de
-- concurrencia y el embudo I13 filtran por instante.
CREATE INDEX ix_registro_fecha ON registro_asistencia (registrado_en DESC);

-- ============================================================================
-- E · Encuesta
-- ============================================================================
CREATE INDEX ix_pregunta_encuesta  ON pregunta (fk_encuesta, orden);
CREATE INDEX ix_respitem_pregunta  ON respuesta_item (fk_pregunta);
CREATE INDEX ix_respenc_encuesta   ON respuesta_encuesta (fk_encuesta);

-- ============================================================================
-- F · Integracion
-- ============================================================================

-- H17 · emparejamiento DIFUSO del texto libre de los formularios contra el
-- catalogo de programas. Es lo que permite migrar lo historico.
CREATE INDEX ix_alias_trgm
    ON alias_programa USING gin (texto_normalizado gin_trgm_ops);

COMMENT ON INDEX ix_alias_trgm IS
    'Indice de trigramas. Permite resolver "Psicologica" -> PSICOLOGIA y '
    '"Ingenieria de datos y software" -> M0286 por similitud, no por igualdad. '
    'En otro motor esto exigiria una tabla de equivalencias exactas o trabajo '
    'manual sobre cada fila.';

CREATE INDEX ix_novedad_lote     ON novedad_carga (fk_lote_carga);
CREATE INDEX ix_lotemig_sesion   ON lote_migracion (fk_sesion, generado_en DESC);
CREATE INDEX ix_detmig_registro  ON detalle_migracion (fk_registro);

-- RN-29 · un registro solo puede quedar ACEPTADO en UN lote.
-- Indice unico parcial: los intentos rechazados pueden repetirse.
CREATE UNIQUE INDEX ux_detmig_aceptado
    ON detalle_migracion (fk_registro)
    WHERE resultado = 'ACEPTADO';

COMMENT ON INDEX ux_detmig_aceptado IS
    'RN-29. Permite reintentar cuantas veces haga falta y garantiza que la '
    'asistencia no se cargue dos veces en el ASIS.';

-- ============================================================================
-- G · Seguridad
-- ============================================================================
CREATE INDEX ix_bitacora_tabla  ON bitacora (nombre_tabla, ocurrido_en DESC);
CREATE INDEX ix_bitacora_fecha  ON bitacora (ocurrido_en DESC);

-- Rol vigente de un usuario
CREATE INDEX ix_rolusr_vigente
    ON rol_por_usuario (fk_usuario)
    WHERE fecha_fin IS NULL;

\echo '09 · Indices creados'


-- ==========================================================================
--  17/18  ·  Roles y permisos
--  fuente: 17-usuarios-permisos.sql
--
--  Necesita un usuario con privilegio de creacion de roles.
-- ==========================================================================

\echo ''
\echo '>>> 17/18 · Roles y permisos'

-- ============================================================================
--  17 · Roles de base de datos y permisos
--
--  Los permisos se aprueban demostrando un FALLO: al final hay un bloque de
--  pruebas que DEBE dar error. Un permiso que no se ha visto fallar no esta
--  comprobado.
-- ============================================================================

SET search_path TO public;

-- ---------------------------------------------------------------------------
-- Roles de grupo
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_admin_catedras') THEN
        CREATE ROLE rol_admin_catedras NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_coordinador') THEN
        CREATE ROLE rol_coordinador NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_consulta') THEN
        CREATE ROLE rol_consulta NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_app_registro') THEN
        CREATE ROLE rol_app_registro NOLOGIN;
    END IF;
END $$;

GRANT USAGE ON SCHEMA public TO rol_admin_catedras, rol_coordinador,
                                  rol_consulta, rol_app_registro;

-- ---------------------------------------------------------------------------
-- rol_consulta · SOLO LECTURA
-- ---------------------------------------------------------------------------
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rol_consulta;
REVOKE SELECT ON clave_acceso, bitacora FROM rol_consulta;

COMMENT ON ROLE rol_consulta IS
    'Solo lectura. Se le NIEGA clave_acceso y bitacora: los hash de las claves '
    'y el detalle de auditoria no son informacion de consulta.';

-- ---------------------------------------------------------------------------
-- rol_coordinador · lectura, mas registro manual
-- ---------------------------------------------------------------------------
GRANT SELECT ON ALL TABLES IN SCHEMA public TO rol_coordinador;
REVOKE SELECT ON clave_acceso FROM rol_coordinador;
GRANT INSERT, UPDATE ON catedra, sesion, enlace_registro, registro_asistencia,
                        encuesta, pregunta, opcion_pregunta TO rol_coordinador;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO rol_coordinador;

-- ---------------------------------------------------------------------------
-- rol_app_registro · lo MINIMO que necesita la aplicacion web
--
-- No se le da SELECT sobre asistente entero: entra por los procedimientos.
-- ---------------------------------------------------------------------------
GRANT SELECT ON sesion, catedra, enlace_registro, modalidad, sede,
                encuesta, pregunta, opcion_pregunta, tipo_pregunta,
                parametro TO rol_app_registro;
GRANT INSERT ON registro_asistencia, respuesta_encuesta, respuesta_item,
                consentimiento_datos TO rol_app_registro;
GRANT SELECT, INSERT, UPDATE ON clave_acceso TO rol_app_registro;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO rol_app_registro;

GRANT EXECUTE ON FUNCTION fn_resolver_asistente(text)          TO rol_app_registro;
GRANT EXECUTE ON FUNCTION fn_siguiente_reunion(char)           TO rol_app_registro;
GRANT EXECUTE ON PROCEDURE sp_solicitar_clave(text, uuid, inet, bigint, text, text)
                                                               TO rol_app_registro;
GRANT EXECUTE ON PROCEDURE sp_validar_clave_y_registrar(bigint, text, inet, text, bigint)
                                                               TO rol_app_registro;
GRANT EXECUTE ON PROCEDURE sp_responder_encuesta(bigint, jsonb, bigint)
                                                               TO rol_app_registro;

COMMENT ON ROLE rol_app_registro IS
    'La aplicacion web. NO tiene DELETE sobre nada, ni SELECT sobre asistente: '
    'resuelve la identidad llamando a fn_resolver_asistente, que devuelve solo '
    'un identificador. Asi la aplicacion no puede volcarse el maestro de '
    '14.808 personas.';

-- ---------------------------------------------------------------------------
-- rol_admin_catedras · todo menos borrar evidencia
-- ---------------------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO rol_admin_catedras;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO rol_admin_catedras;
GRANT EXECUTE ON ALL ROUTINES IN SCHEMA public TO rol_admin_catedras;

-- RN-32 · nadie borra. Ni el administrador.
REVOKE DELETE ON ALL TABLES IN SCHEMA public FROM rol_admin_catedras,
                                                    rol_coordinador,
                                                    rol_consulta,
                                                    rol_app_registro;

-- La bitacora no se modifica ni se borra, tampoco por el administrador
REVOKE UPDATE ON bitacora FROM rol_admin_catedras, rol_coordinador;

-- ---------------------------------------------------------------------------
-- Usuarios de ejemplo
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'u_gestor_catedras') THEN
        CREATE ROLE u_gestor_catedras LOGIN PASSWORD 'cambiar-en-produccion';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'u_app_web') THEN
        CREATE ROLE u_app_web LOGIN PASSWORD 'cambiar-en-produccion';
    END IF;
END $$;

GRANT rol_admin_catedras TO u_gestor_catedras;
GRANT rol_app_registro   TO u_app_web;

-- ============================================================================
--  PRUEBAS · estas TRES deben FALLAR. Si alguna pasa, los permisos estan mal.
-- ============================================================================
\echo ''
\echo '=== Pruebas de permisos: las tres deben dar error ==='

SET ROLE u_app_web;

\echo '--- 1 · la aplicacion NO puede volcarse el maestro de personas ---'
DO $$
BEGIN
    PERFORM count(*) FROM public.asistente;
    RAISE EXCEPTION 'FALLO DE SEGURIDAD: la aplicacion pudo leer asistente';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'CORRECTO: permiso denegado sobre asistente';
END $$;

\echo '--- 2 · nadie borra registros de asistencia (RN-32) ---'
DO $$
BEGIN
    DELETE FROM public.registro_asistencia WHERE false;
    RAISE EXCEPTION 'FALLO DE SEGURIDAD: se permitio DELETE';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'CORRECTO: DELETE denegado';
END $$;

RESET ROLE;
SET ROLE u_gestor_catedras;

\echo '--- 3 · ni el administrador puede alterar la bitacora ---'
DO $$
BEGIN
    UPDATE public.bitacora SET operacion = 'INSERT' WHERE false;
    RAISE EXCEPTION 'FALLO DE SEGURIDAD: se permitio UPDATE sobre bitacora';
EXCEPTION
    WHEN insufficient_privilege THEN
        RAISE NOTICE 'CORRECTO: UPDATE sobre bitacora denegado';
END $$;

RESET ROLE;

\echo '17 · Roles y permisos aplicados, con sus tres pruebas'


-- ==========================================================================
--  18/18  ·  Funciones envoltorio de la API
--  fuente: 19-funciones-api.sql
--
--  Viven aqui y no en la API: sin ellas los endpoints de acceso no responden.
-- ==========================================================================

\echo ''
\echo '>>> 18/18 · Funciones envoltorio de la API'

-- ============================================================================
--  19 · Funciones envoltorio para la API
--
--  Este script pertenece a ApiCatedrasUsbmed, no al diseno de la base: son
--  envoltorios delgados sobre los procedimientos del script 11.
--
--  POR QUE EXISTEN
--  Los procedimientos del modelo usan parametros INOUT y se invocan con CALL.
--  Npgsql y Dapper no pueden recoger esos valores de salida de forma portable:
--  CALL no devuelve un conjunto de resultados. Estas funciones hacen el CALL por
--  dentro y DEVUELVEN el resultado, que es lo que un SELECT si puede leer.
--
--  NO duplican logica. Cada una es un CALL y un RETURN: toda la regla de negocio
--  sigue viviendo en los procedimientos originales.
--
--  Aplicar despues de ejecutar-todo.sql:
--      psql -U postgres -d catedras -f sql/19-funciones-api.sql
-- ============================================================================

SET search_path TO public;

-- NOTA sobre SET search_path en cada funcion:
-- el search_path de este script NO se hereda dentro del cuerpo de una funcion: alli rige
-- el de la SESION QUE LLAMA. La API se conecta sin fijarlo, asi que sin la calificacion
-- public.sp_* y sin el SET de cada funcion, PostgreSQL responde
-- "no existe el procedimiento sp_emitir_enlace(...)" aunque exista.

-- ---------------------------------------------------------------------------
-- fn_solicitar_clave_api
-- Devuelve la clave EN CLARO para que la API la envie por correo. La base sigue
-- guardando solo el hash. La API no la propaga mas alla del servicio de correo.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_solicitar_clave_api(
    p_identificador text,
    p_token         uuid,
    p_ip            inet DEFAULT NULL)
RETURNS TABLE (id_clave bigint, clave text, enviado_a text)
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
    v_id     bigint;
    v_clave  text;
    v_correo text;
BEGIN
    CALL public.sp_solicitar_clave(p_identificador, p_token, p_ip, v_id, v_clave, v_correo);
    RETURN QUERY SELECT v_id, v_clave, v_correo;
END;
$$;

COMMENT ON FUNCTION fn_solicitar_clave_api(text, uuid, inet) IS
    'Envoltorio de sp_solicitar_clave para la API. RN-17.';

-- ---------------------------------------------------------------------------
-- fn_validar_clave_api
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_validar_clave_api(
    p_id_clave   bigint,
    p_clave      text,
    p_ip         inet DEFAULT NULL,
    p_user_agent text DEFAULT NULL)
RETURNS bigint
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
    v_registro bigint;
BEGIN
    CALL public.sp_validar_clave_y_registrar(p_id_clave, p_clave, p_ip, p_user_agent, v_registro);
    RETURN v_registro;
END;
$$;

-- ---------------------------------------------------------------------------
-- fn_responder_encuesta_api
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_responder_encuesta_api(
    p_id_registro bigint,
    p_respuestas  jsonb)
RETURNS bigint
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
    v_respuesta bigint;
BEGIN
    CALL public.sp_responder_encuesta(p_id_registro, p_respuestas, v_respuesta);
    RETURN v_respuesta;
END;
$$;

-- ---------------------------------------------------------------------------
-- fn_emitir_enlace_api
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_emitir_enlace_api(
    p_id_sesion       bigint,
    p_minutos_antes   integer DEFAULT NULL,
    p_minutos_despues integer DEFAULT NULL,
    p_usuario         bigint  DEFAULT NULL)
RETURNS bigint
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
    v_enlace bigint;
BEGIN
    CALL public.sp_emitir_enlace(p_id_sesion, p_minutos_antes, p_minutos_despues, p_usuario, v_enlace);
    RETURN v_enlace;
END;
$$;

-- ---------------------------------------------------------------------------
-- fn_generar_lote_api
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_generar_lote_api(
    p_id_sesion bigint,
    p_usuario   bigint DEFAULT NULL)
RETURNS bigint
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
    v_lote bigint;
BEGIN
    CALL public.sp_generar_lote_migracion(p_id_sesion, p_usuario, v_lote);
    RETURN v_lote;
END;
$$;

-- ---------------------------------------------------------------------------
-- Permisos: el camino publico solo necesita las tres del flujo de acceso.
-- ---------------------------------------------------------------------------
GRANT EXECUTE ON FUNCTION fn_solicitar_clave_api(text, uuid, inet)        TO rol_app_registro;
GRANT EXECUTE ON FUNCTION fn_validar_clave_api(bigint, text, inet, text)  TO rol_app_registro;
GRANT EXECUTE ON FUNCTION fn_responder_encuesta_api(bigint, jsonb)        TO rol_app_registro;
GRANT EXECUTE ON FUNCTION fn_emitir_enlace_api(bigint, integer, integer, bigint) TO rol_admin_catedras;
GRANT EXECUTE ON FUNCTION fn_generar_lote_api(bigint, bigint)             TO rol_admin_catedras;

\echo '19 · Funciones envoltorio de la API creadas'

-- ============================================================================
--  ARREGLO DE FONDO · search_path de las rutinas del modelo
--
--  Las rutinas de 11-funciones-procedimientos.sql referencian las tablas SIN
--  calificar y se crearon bajo un `SET search_path` de SCRIPT. Ese SET es de
--  SESION: NO queda horneado en la funcion. Llamadas desde un cliente que no lo
--  fija -como esta API-, PostgreSQL responde "no existe la relacion
--  registro_asistencia" aunque exista.
--
--  Se detecto ejecutando el recorrido completo por HTTP, no compilando.
--
--  Esto lo deja resuelto en la propia base. La API ademas fija Search Path en su
--  cadena de conexion, como cinturon.
-- ============================================================================

DO $$
DECLARE
    r record;
BEGIN
    FOR r IN
        SELECT p.oid::regprocedure AS firma, p.prokind
          FROM pg_proc p
          JOIN pg_namespace n ON n.oid = p.pronamespace
         WHERE n.nspname = 'public'
           AND p.proname LIKE ANY (ARRAY['fn\_%', 'sp\_%'])
           AND NOT EXISTS (
                 SELECT 1 FROM unnest(coalesce(p.proconfig, '{}')) c
                  WHERE c LIKE 'search_path=%')
    LOOP
        EXECUTE format('%s %s SET search_path = public',
                       CASE r.prokind WHEN 'p' THEN 'ALTER PROCEDURE' ELSE 'ALTER FUNCTION' END,
                       r.firma);
    END LOOP;
END $$;

\echo '19b · search_path fijado en todas las rutinas del esquema catedras'


-- ==========================================================================
--  VERIFICACION FINAL
-- ==========================================================================

ANALYZE;

\echo ''
\echo '>>> Verificacion'

SELECT (SELECT count(*) FROM information_schema.tables
         WHERE table_schema='public' AND table_type='BASE TABLE')   AS tablas,
       (SELECT count(*) FROM information_schema.views
         WHERE table_schema='public')                               AS vistas,
       -- NOT EXISTS sobre pg_depend: al vivir todo en public, las funciones de
       -- pgcrypto, citext, unaccent y pg_trgm caen en el mismo esquema y
       -- inflarian la cuenta a 328. deptype='e' es 'miembro de una extension'.
       (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
         WHERE n.nspname='public'
           AND NOT EXISTS (SELECT 1 FROM pg_depend d
                            WHERE d.objid = p.oid AND d.deptype = 'e'))    AS rutinas,
       (SELECT count(*) FROM pg_trigger t JOIN pg_class cl ON cl.oid=t.tgrelid
          JOIN pg_namespace n ON n.oid=cl.relnamespace
         WHERE n.nspname='public' AND NOT t.tgisinternal)           AS disparadores;

\echo '--- Volumenes, contra lo medido en los Excel ---'
SELECT 'catedras'   AS objeto, count(*) AS filas, 5497  AS esperado FROM public.catedra
UNION ALL SELECT 'sesiones',   count(*), 5714  FROM public.sesion
UNION ALL SELECT 'programas',  count(*), 105   FROM public.programa_academico
UNION ALL SELECT 'asistentes', count(*), 14811 FROM public.asistente
UNION ALL SELECT 'documentos', count(*), 15517 FROM public.documento_asistente;

\echo '--- CONTROLES · los tres deben dar CERO ---'
SELECT 'registros fuera de ventana (RN-15)' AS control,
       (SELECT count(*) FROM public.v_control_ventana) AS debe_ser_cero
UNION ALL
SELECT 'pares (catedra, reunion) duplicados (RN-10)',
       (SELECT count(*) FROM (SELECT fk_catedra, numero_reunion FROM public.sesion
                               GROUP BY 1,2 HAVING count(*)>1) q)
UNION ALL
SELECT 'externos colados en el archivo del ASIS (RN-08)',
       (SELECT count(*) FROM public.detalle_migracion dm
          JOIN public.registro_asistencia r ON r.id_registro = dm.fk_registro
          JOIN public.asistente a ON a.id_asistente = r.fk_asistente
         WHERE a.es_externo OR a.id_asis IS NULL);

\echo ''
\echo '=== LISTO · la base catedras esta construida ==='
