# -*- coding: utf-8 -*-
"""
Genera el MER completo en formato Draw.io, en notacion de CHEN.

    python SOLUCION/MER/drawio/generar_drawio.py

Notacion, tal como la pidio el profesor Carlos Castro en la reunion (19:11 -no le
gustan los diagramas de pata de gallina-):

    rectangulo             entidad
    rectangulo doble       entidad DEBIL
    rombo                  relacion (siempre un VERBO)
    rombo doble            relacion IDENTIFICADORA
    elipse                 atributo
    elipse subrayada       identificador
    elipse punteada        atributo DERIVADO
    elipse doble           atributo MULTIVALUADO

Siete paginas: una vista general y una por bloque con sus atributos.
"""
import os
import xml.sax.saxutils as saxutils


def esc_attr(texto):
    """
    Escapa para un ATRIBUTO XML.

    saxutils.escape() no toca las comillas, y un texto con comillas dobles rompe el
    archivo -Draw.io ni siquiera lo abre-. Los saltos de linea se convierten a &#10;,
    que es como Draw.io representa el salto dentro de una etiqueta.
    """
    return (saxutils.escape(texto, {'"': '&quot;', "'": '&apos;'})
            .replace(chr(10), '&#10;'))

SALIDA = os.path.join(os.path.dirname(__file__), 'MER-CatedrasAbiertas-Chen.drawio')

# ── Estilos de Chen ─────────────────────────────────────────────────────────
E_ENT   = ('rounded=0;whiteSpace=wrap;html=1;fillColor=#2d5a8c;strokeColor=#1a3a5c;'
           'fontColor=#ffffff;fontSize=13;fontStyle=1;')
E_NUC   = ('rounded=0;whiteSpace=wrap;html=1;fillColor=#8c2d3f;strokeColor=#5c1a28;'
           'fontColor=#ffffff;fontSize=13;fontStyle=1;')
E_DEBIL = ('shape=ext;double=1;whiteSpace=wrap;html=1;fillColor=#2d5a8c;'
           'strokeColor=#1a3a5c;fontColor=#ffffff;fontSize=13;fontStyle=1;')
E_REL   = ('rhombus;whiteSpace=wrap;html=1;fillColor=#c9a227;strokeColor=#8a6d1a;'
           'fontColor=#000000;fontSize=11;')
E_RELID = ('rhombus;double=1;whiteSpace=wrap;html=1;fillColor=#c9a227;'
           'strokeColor=#8a6d1a;fontColor=#000000;fontSize=11;')
E_ATR   = ('ellipse;whiteSpace=wrap;html=1;fillColor=#e8eef5;strokeColor=#7a94ad;'
           'fontSize=10;')
E_ATRPK = E_ATR + 'fontStyle=4;'                    # 4 = subrayado
E_ATRDER= E_ATR + 'dashed=1;'                       # derivado
E_ATRMV = ('ellipse;shape=doubleEllipse;whiteSpace=wrap;html=1;fillColor=#e8eef5;'
           'strokeColor=#7a94ad;fontSize=10;')
E_ARISTA= 'endArrow=none;html=1;strokeColor=#5a6b7a;'
E_CARD  = ('text;html=1;align=center;fontSize=10;fontColor=#6b7b8a;'
           'verticalAlign=middle;')
E_NOTA  = ('shape=note;whiteSpace=wrap;html=1;fillColor=#fff8dc;strokeColor=#c9a227;'
           'fontSize=11;align=left;size=14;')


class Pagina:
    def __init__(self, nombre):
        self.nombre = nombre
        self.celdas = []
        self.n = 0

    def _id(self, pre):
        self.n += 1
        return f'{pre}{self.n}'

    def caja(self, texto, x, y, w=170, h=55, estilo=E_ENT, ident=None):
        i = ident or self._id('n')
        self.celdas.append(
            f'<mxCell id="{i}" value="{esc_attr(texto)}" style="{estilo}" vertex="1" parent="1">'
            f'<mxGeometry x="{x}" y="{y}" width="{w}" height="{h}" as="geometry"/></mxCell>')
        return i

    def entidad(self, t, x, y, **kw):   return self.caja(t, x, y, 170, 55, kw.get('estilo', E_ENT))
    def nucleo(self, t, x, y):          return self.caja(t, x, y, 190, 60, E_NUC)
    def debil(self, t, x, y):           return self.caja(t, x, y, 170, 55, E_DEBIL)
    def relacion(self, t, x, y, ident=False):
        return self.caja(t, x, y, 150, 70, E_RELID if ident else E_REL)
    def atributo(self, t, x, y, tipo='simple'):
        est = {'simple': E_ATR, 'pk': E_ATRPK, 'derivado': E_ATRDER, 'multi': E_ATRMV}[tipo]
        return self.caja(t, x, y, 130, 42, est)
    def nota(self, t, x, y, w=300, h=110):
        return self.caja(t, x, y, w, h, E_NOTA)

    def linea(self, o, d, etiqueta=''):
        i = self._id('a')
        v = f' value="{esc_attr(etiqueta)}"' if etiqueta else ''
        self.celdas.append(
            f'<mxCell id="{i}"{v} style="{E_ARISTA}" edge="1" parent="1" '
            f'source="{o}" target="{d}"><mxGeometry relative="1" as="geometry"/></mxCell>')

    def texto(self, t, x, y, w=200, h=24):
        return self.caja(t, x, y, w, h, E_CARD)

    def xml(self):
        return (f'  <diagram name="{esc_attr(self.nombre)}" id="{abs(hash(self.nombre))}">\n'
                f'    <mxGraphModel dx="1400" dy="900" grid="1" gridSize="10" guides="1" '
                f'tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" '
                f'pageWidth="1654" pageHeight="1169" math="0" shadow="0">\n'
                f'      <root>\n        <mxCell id="0"/>\n        <mxCell id="1" parent="0"/>\n'
                + '\n'.join('        ' + c for c in self.celdas)
                + '\n      </root>\n    </mxGraphModel>\n  </diagram>')


paginas = []

# ═══════════════════════════════════════════════════════ 00 · VISTA GENERAL ══
p = Pagina('00 · Vista general')
p.texto('MER · CATEDRAS ABIERTAS — Universidad de San Buenaventura, Medellin\n'
        '33 entidades · 35 relaciones · notacion de Chen', 40, 20, 700, 44)

# Bloque A
a_asi = p.nucleo('ASISTENTE', 620, 140)
a_doc = p.entidad('DOCUMENTO_ASISTENTE', 300, 120)
a_tdo = p.entidad('TIPO_DOCUMENTO', 60, 120)
a_tvi = p.entidad('TIPO_VINCULACION', 300, 300)
a_con = p.entidad('CONSENTIMIENTO_DATOS', 60, 240)
# Bloque B
b_fac = p.entidad('FACULTAD', 60, 480)
b_pro = p.entidad('PROGRAMA_ACADEMICO', 300, 480)
b_per = p.entidad('PERIODO_ACADEMICO', 60, 620)
# Bloque C
c_cat = p.entidad('CATEDRA', 1180, 140)
c_ses = p.debil('SESION', 940, 300)
c_tev = p.entidad('TIPO_EVENTO', 1420, 60)
c_dep = p.entidad('DEPENDENCIA', 1420, 200)
c_sed = p.entidad('SEDE', 1420, 340)
c_mod = p.entidad('MODALIDAD', 1420, 460)
# Bloque D
d_enl = p.entidad('ENLACE_REGISTRO', 940, 460)
d_cla = p.entidad('CLAVE_ACCESO', 700, 460)
d_reg = p.nucleo('REGISTRO_ASISTENCIA', 620, 620)
# Bloque E
e_enc = p.entidad('ENCUESTA', 940, 780)
e_pre = p.entidad('PREGUNTA', 1180, 780)
e_tpr = p.entidad('TIPO_PREGUNTA', 1420, 720)
e_opc = p.entidad('OPCION_PREGUNTA', 1420, 840)
e_res = p.entidad('RESPUESTA_ENCUESTA', 700, 780)
e_ite = p.debil('RESPUESTA_ITEM', 700, 900)
# Bloque F
f_lca = p.entidad('LOTE_CARGA_ASISTENTE', 60, 780)
f_nov = p.entidad('NOVEDAD_CARGA', 60, 900)
f_ali = p.entidad('ALIAS_PROGRAMA', 300, 620)
f_lmi = p.entidad('LOTE_MIGRACION', 300, 900)
f_dmi = p.entidad('DETALLE_MIGRACION', 300, 1020)
f_est = p.entidad('ESTADO_PROCESO', 60, 1020)
# Bloque G
g_usu = p.entidad('USUARIO', 620, 20)
g_rol = p.entidad('ROL', 860, 20)
g_par = p.entidad('PARAMETRO', 1100, 20)
g_bit = p.entidad('BITACORA', 1340, 940)

rel = [
    (a_asi, 'se identifica con', a_doc, False, '1:N'),
    (a_doc, 'es de clase',       a_tdo, False, 'N:1'),
    (a_asi, 'se vincula como',   a_tvi, False, 'N:M'),
    (a_asi, 'autoriza',          a_con, False, '1:N'),
    (a_asi, 'opera como',        g_usu, False, '1:1'),
    (b_fac, 'agrupa',            b_pro, False, '1:N'),
    (a_asi, 'cursa',             b_pro, False, 'N:M'),
    (c_cat, 'se dicta en',       c_ses, True,  '1:N'),
    (c_cat, 'se clasifica como', c_tev, False, 'N:1'),
    (c_dep, 'organiza',          c_cat, False, '1:N'),
    (c_sed, 'aloja',             c_ses, False, '1:N'),
    (c_ses, 'se dicta en modalidad', c_mod, False, 'N:1'),
    (c_ses, 'ocurre en',         b_per, False, 'N:1'),
    (c_ses, 'se difunde mediante', d_enl, False, '1:N'),
    (d_enl, 'ampara',            d_cla, False, '1:N'),
    (a_asi, 'solicita',          d_cla, False, '1:N'),
    (d_cla, 'habilita',          d_reg, False, '1:1'),
    (a_asi, 'se registra en',    d_reg, False, 'N:M'),
    (c_ses, 'recibe',            d_reg, False, '1:N'),
    (d_reg, 'conserva instantanea de', b_pro, False, 'N:1'),
    (e_enc, 'se compone de',     e_pre, False, '1:N'),
    (e_pre, 'se responde segun', e_tpr, False, 'N:1'),
    (e_pre, 'ofrece',            e_opc, False, '1:N'),
    (c_ses, 'se evalua con',     e_enc, False, 'N:1'),
    (d_reg, 'es evaluado en',    e_res, False, '1:1'),
    (e_res, 'detalla',           e_ite, True,  '1:N'),
    (f_lca, 'rechaza',           f_nov, False, '1:N'),
    (f_lca, 'carga',             a_asi, False, '1:N'),
    (f_ali, 'resuelve a',        b_pro, False, 'N:1'),
    (c_ses, 'se migra en',       f_lmi, False, '1:N'),
    (f_lmi, 'migra',             f_dmi, True,  '1:N'),
    (f_dmi, 'corresponde a',     d_reg, False, 'N:1'),
    (f_lmi, 'termina en',        f_est, False, 'N:1'),
    (g_usu, 'desempena',         g_rol, False, 'N:M'),
    (g_usu, 'configura',         g_par, False, '1:N'),
    (g_usu, 'produce',           g_bit, False, '1:N'),
]
# El rombo se coloca en el punto medio de las dos entidades
geo = {}
for c in p.celdas:
    if 'vertex="1"' in c:
        cid = c.split('id="')[1].split('"')[0]
        x = float(c.split('x="')[1].split('"')[0]); y = float(c.split('y="')[1].split('"')[0])
        w = float(c.split('width="')[1].split('"')[0]); h = float(c.split('height="')[1].split('"')[0])
        geo[cid] = (x + w / 2, y + h / 2)

for o, verbo, d, ident, card in rel:
    ox, oy = geo[o]; dx, dy = geo[d]
    r = p.relacion(f'{verbo}\n{card}', (ox + dx) / 2 - 75, (oy + dy) / 2 - 35, ident)
    p.linea(o, r); p.linea(r, d)

p.nota('Notacion de Chen\n\n'
       'rectangulo         entidad\n'
       'rectangulo doble   entidad DEBIL\n'
       'rombo              relacion (un VERBO)\n'
       'rombo doble        relacion IDENTIFICADORA\n'
       'elipse             atributo\n'
       'elipse subrayada   identificador\n'
       'elipse punteada    atributo DERIVADO\n'
       'elipse doble       atributo MULTIVALUADO\n\n'
       'En rojo, las dos entidades centrales.', 60, 20, 330, 200)
paginas.append(p)


# ══════════════════════════════════════════════ paginas por bloque ══════════
def pagina_bloque(nombre, titulo, entidades, relaciones, atributos, notas):
    """entidades: [(clave, texto, x, y, tipo)]  ·  atributos: [(clave_ent, [(texto,tipo,dx,dy)])]"""
    pg = Pagina(nombre)
    pg.texto(titulo, 40, 20, 900, 30)
    ids = {}
    for k, t, x, y, tipo in entidades:
        ids[k] = (pg.nucleo(t, x, y) if tipo == 'nucleo' else
                  pg.debil(t, x, y) if tipo == 'debil' else pg.entidad(t, x, y))
    for k, lista in atributos:
        bx, by = next((x, y) for kk, _, x, y, _ in entidades if kk == k)
        for txt, tipo, dx, dy in lista:
            a = pg.atributo(txt, bx + dx, by + dy, tipo)
            pg.linea(ids[k], a)
    for o, verbo, d, ident, card in relaciones:
        ox, oy = next((x, y) for kk, _, x, y, _ in entidades if kk == o)
        dx_, dy_ = next((x, y) for kk, _, x, y, _ in entidades if kk == d)
        r = pg.relacion(f'{verbo}\n{card}', (ox + dx_) / 2, (oy + dy_) / 2, ident)
        pg.linea(ids[o], r); pg.linea(r, ids[d])
    for t, x, y, w, h in notas:
        pg.nota(t, x, y, w, h)
    return pg


paginas.append(pagina_bloque(
    '01 · A · Asistentes e identidad',
    'BLOQUE A · Asistentes e identidad — quien es cada asistente y con que autoridad se afirma',
    [('asi', 'ASISTENTE', 640, 420, 'nucleo'),
     ('doc', 'DOCUMENTO_ASISTENTE', 240, 700, 'entidad'),
     ('tdo', 'TIPO_DOCUMENTO', 40, 880, 'entidad'),
     ('tvi', 'TIPO_VINCULACION', 1080, 700, 'entidad'),
     ('con', 'CONSENTIMIENTO_DATOS', 640, 900, 'entidad')],
    [('asi', 'se identifica con', 'doc', False, '1:N  (0,N)/(1,1)'),
     ('doc', 'es de clase', 'tdo', False, 'N:1'),
     ('asi', 'se vincula como', 'tvi', False, 'N:M  fecha_ini en la clave'),
     ('asi', 'autoriza', 'con', False, '1:N')],
    [('asi', [('id_asistente', 'pk', -260, -180), ('id_asis  (unico)', 'simple', -110, -250),
              ('nombres', 'simple', 60, -270), ('apellidos', 'simple', 220, -230),
              ('correo_institucional', 'simple', 300, -140), ('correo_personal', 'simple', 320, -40),
              ('celular', 'simple', 300, 60), ('es_externo', 'simple', 200, 130),
              ('activo', 'simple', 40, 160)]),
     ('doc', [('id_documento', 'pk', -180, -80), ('numero', 'multi', -180, 20),
              ('vigente', 'simple', -60, 110)]),
     ('tvi', [('id_tipo_vinculacion', 'pk', 200, -80), ('es_interno', 'simple', 220, 20),
              ('exige_programa', 'simple', 200, 110)]),
     ('con', [('version_politica', 'simple', -180, 100), ('aceptado_en', 'simple', 20, 130)])],
    [('numero es MULTIVALUADO -elipse doble-: 707 personas del maestro\n'
      'real tienen mas de un documento. Por eso es tabla propia.', 40, 620, 340, 80),
     ('exige_programa convierte en DATO la frase "ellos entrarian sin\n'
      'programa, pero solo ellos" (41:16). Habilitar una excepcion es\n'
      'un UPDATE, no un ALTER TABLE.', 1080, 900, 360, 90)]))

paginas.append(pagina_bloque(
    '02 · C · Catedras, sesiones y sedes',
    'BLOQUE C · Catedras, sesiones y sedes — el evento, sus reuniones, donde y cuando',
    [('cat', 'CATEDRA', 620, 300, 'entidad'),
     ('ses', 'SESION', 620, 640, 'debil'),
     ('tev', 'TIPO_EVENTO', 1080, 200, 'entidad'),
     ('dep', 'DEPENDENCIA', 180, 200, 'entidad'),
     ('sed', 'SEDE', 180, 640, 'entidad'),
     ('mod', 'MODALIDAD', 1080, 640, 'entidad'),
     ('per', 'PERIODO_ACADEMICO', 1080, 880, 'entidad')],
    [('cat', 'se dicta en', 'ses', True, '1:N  IDENTIFICADORA'),
     ('cat', 'se clasifica como', 'tev', False, 'N:1'),
     ('dep', 'organiza', 'cat', False, '1:N'),
     ('sed', 'aloja', 'ses', False, '1:N'),
     ('ses', 'se dicta en modalidad', 'mod', False, 'N:1'),
     ('ses', 'ocurre en', 'per', False, 'N:1')],
    [('cat', [('id_catedra', 'pk', -240, -140), ('id_evento_asis  char(9)', 'simple', -60, -190),
              ('nombre', 'simple', 160, -170), ('nombre_asis  (30)', 'derivado', 260, -70)]),
     ('ses', [('id_sesion', 'pk', -240, 120), ('numero_reunion', 'derivado', -60, 190),
              ('inicio', 'simple', 120, 200), ('fin', 'simple', 260, 160),
              ('cupo', 'simple', 300, 60), ('estado', 'simple', 300, -30)]),
     ('mod', [('canal_difusion\nQR / ENLACE', 'simple', 200, 60)])],
    [('nombre_asis es DERIVADO -elipse punteada-: los 30 primeros\n'
      'caracteres. El ASIS trunca ahi. Se guarda el largo y se deriva\n'
      'el corto; al reves se perderia informacion.', 40, 300, 360, 90),
     ('SESION es entidad DEBIL: la "reunion 3" no significa nada suelta,\n'
      'es la reunion 3 DE UN EVENTO. Su identificador incluye la catedra.\n'
      'El par (catedra, reunion) es unico en las 5.711 filas reales.', 40, 880, 380, 100),
     ('canal_difusion gobierna comportamiento, no es una etiqueta:\n'
      'presencial se difunde por QR, virtual por enlace (1:06:53).', 1080, 460, 360, 70)]))

paginas.append(pagina_bloque(
    '03 · D · Acceso y registro — EL NUCLEO',
    'BLOQUE D · Acceso y registro — el QR, la clave al correo y el acto de registrarse',
    [('ses', 'SESION', 200, 200, 'entidad'),
     ('enl', 'ENLACE_REGISTRO', 620, 200, 'entidad'),
     ('cla', 'CLAVE_ACCESO', 1060, 380, 'entidad'),
     ('asi', 'ASISTENTE', 1060, 700, 'entidad'),
     ('reg', 'REGISTRO_ASISTENCIA', 560, 620, 'nucleo'),
     ('pro', 'PROGRAMA_ACADEMICO', 180, 880, 'entidad'),
     ('tvi', 'TIPO_VINCULACION', 560, 940, 'entidad')],
    [('ses', 'se difunde mediante', 'enl', False, '1:N'),
     ('enl', 'ampara', 'cla', False, '1:N'),
     ('asi', 'solicita', 'cla', False, '1:N'),
     ('cla', 'habilita', 'reg', False, '1:1  (0,1)/(1,1)'),
     ('asi', 'se registra en', 'reg', False, 'N:M'),
     ('ses', 'recibe', 'reg', False, '1:N'),
     ('reg', 'conserva instantanea de', 'pro', False, 'N:1'),
     ('reg', 'conserva instantanea de', 'tvi', False, 'N:1')],
    [('enl', [('id_enlace', 'pk', -60, -140), ('token  (unico)', 'simple', 120, -120),
              ('ventana\ntstzrange', 'simple', 220, -20), ('canal', 'simple', 200, 80)]),
     ('cla', [('clave_hash', 'simple', 200, -100), ('enviado_a', 'simple', 240, 0),
              ('es_correo_institucional', 'derivado', 220, 90), ('expira_en', 'simple', 60, 150),
              ('usado_en', 'simple', -80, 170)]),
     ('reg', [('id_registro', 'pk', -220, -120), ('registrado_en', 'simple', 220, -80),
              ('origen', 'simple', 240, 20)])],
    [('La ventana es UN atributo de tipo rango, no dos columnas.\n'
      'Eso hace declarativas dos reglas: que dos enlaces de la misma\n'
      'sesion no se solapen (RN-36) y que un instante este dentro (RN-15).', 620, 20, 400, 100),
     ('clave_hash: NUNCA la clave en claro.\n'
      'es_correo_institucional es DERIVADO del dominio de destino:\n'
      'vigila el asunto que quedo abierto en 55:32.', 1060, 180, 360, 90),
     ('LAS DOS INSTANTANEAS son la decision mas importante del modelo.\n'
      'No son referencias vivas: guardan el programa y la vinculacion que\n'
      'la persona tenia EL DIA de la catedra, y no se actualizan nunca.\n'
      'Sin ellas, el archivo enviado al ASIS deja de ser reproducible.', 40, 460, 420, 110),
     ('CLAVE habilita REGISTRO es (1,1) por el lado del registro:\n'
      'NO HAY REGISTRO SIN CLAVE USADA. Es la antisuplantacion\n'
      'de 1:04:51 — "si no, yo te registro a vos y vos me registras a mi".', 1040, 880, 420, 100)]))

paginas.append(pagina_bloque(
    '04 · E · Encuesta de calidad',
    'BLOQUE E · Encuesta parametrizable — cuestionario y respuestas',
    [('enc', 'ENCUESTA', 240, 260, 'entidad'),
     ('pre', 'PREGUNTA', 640, 260, 'entidad'),
     ('tpr', 'TIPO_PREGUNTA', 1080, 160, 'entidad'),
     ('opc', 'OPCION_PREGUNTA', 1080, 400, 'entidad'),
     ('reg', 'REGISTRO_ASISTENCIA', 240, 620, 'entidad'),
     ('res', 'RESPUESTA_ENCUESTA', 640, 620, 'entidad'),
     ('ite', 'RESPUESTA_ITEM', 640, 900, 'debil')],
    [('enc', 'se compone de', 'pre', False, '1:N  (1,N)/(1,1)'),
     ('pre', 'se responde segun', 'tpr', False, 'N:1'),
     ('pre', 'ofrece', 'opc', False, '1:N'),
     ('reg', 'es evaluado en', 'res', False, '1:1  (0,1)/(1,1)'),
     ('res', 'detalla', 'ite', True, '1:N  NO DECLARATIVA')],
    [('pre', [('enunciado', 'simple', -40, -120), ('orden', 'simple', 140, -100),
              ('obligatoria', 'simple', 200, 0)]),
     ('tpr', [('guarda_numero', 'simple', 200, -60), ('guarda_texto', 'simple', 220, 30),
              ('guarda_opcion', 'simple', 200, 120)]),
     ('ite', [('valor_numerico', 'simple', -240, 60), ('valor_texto', 'simple', -60, 130),
              ('fk_opcion', 'simple', 140, 100)])],
    [('RESPUESTA_ENCUESTA detalla RESPUESTA_ITEM es (1,N):\n'
      'toda encuesta respondida tiene AL MENOS UN item.\n\n'
      'NINGUNA CLAVE FORANEA PUEDE GARANTIZARLO. Una clave foranea\n'
      'garantiza que lo que se inserte EXISTA, no que se INSERTE algo.\n'
      'Se resuelve con procedimiento y se mide con una consulta de control.', 1040, 700, 440, 130),
     ('Los tres valores de RESPUESTA_ITEM no son opcionalidad:\n'
      'son una REGLA CONDICIONAL. El tipo de la pregunta decide cual\n'
      'de los tres se usa. Los tres vacios, o dos llenos, es dato corrupto.', 40, 900, 420, 100)]))

paginas.append(pagina_bloque(
    '05 · F · Integracion con el ASIS',
    'BLOQUE F · Integracion — cargas de entrada, lotes de salida y su resultado',
    [('lca', 'LOTE_CARGA_ASISTENTE', 200, 200, 'entidad'),
     ('nov', 'NOVEDAD_CARGA', 200, 460, 'entidad'),
     ('asi', 'ASISTENTE', 620, 200, 'entidad'),
     ('ali', 'ALIAS_PROGRAMA', 200, 720, 'entidad'),
     ('pro', 'PROGRAMA_ACADEMICO', 620, 720, 'entidad'),
     ('ses', 'SESION', 1060, 200, 'entidad'),
     ('lmi', 'LOTE_MIGRACION', 1060, 460, 'entidad'),
     ('dmi', 'DETALLE_MIGRACION', 1060, 720, 'entidad'),
     ('reg', 'REGISTRO_ASISTENCIA', 620, 460, 'entidad'),
     ('est', 'ESTADO_PROCESO', 1420, 340, 'entidad')],
    [('lca', 'rechaza', 'nov', False, '1:N'),
     ('lca', 'carga', 'asi', False, '1:N'),
     ('ali', 'resuelve a', 'pro', False, 'N:1'),
     ('ses', 'se migra en', 'lmi', False, '1:N'),
     ('lmi', 'migra', 'dmi', True, '1:N'),
     ('dmi', 'corresponde a', 'reg', False, 'N:1'),
     ('lmi', 'termina en', 'est', False, 'N:1')],
    [('nov', [('numero_fila', 'simple', -180, 0), ('contenido_crudo', 'simple', -180, 90),
              ('motivo', 'simple', -40, 140)]),
     ('lmi', [('nombre_proceso', 'simple', 200, -60), ('instancia_proceso_asis', 'simple', 220, 30)]),
     ('dmi', [('id_asis_enviado', 'simple', 200, 60), ('programa_enviado', 'simple', 200, 150),
              ('reunion_enviada', 'simple', 40, 190), ('resultado', 'simple', -120, 170)])],
    [('DETALLE_MIGRACION repite tres columnas a proposito: guarda LO QUE\n'
      'SE ENVIO, no lo que hoy dice la tabla. Si el programa de alguien\n'
      'cambia despues, los dos valores divergen legitimamente — y sin la\n'
      'copia, un rechazo del ASIS es indepurable seis meses despues.', 1400, 720, 420, 110),
     ('ESTADO_PROCESO son los CINCO estados literales del manual de\n'
      'migracion, pagina 6: En cola, En curso, Error, Correcto, Incorrecto.', 1400, 60, 400, 70)]))

paginas.append(pagina_bloque(
    '06 · B y G · Academico, seguridad y configuracion',
    'BLOQUES B y G · Estructura academica · Usuarios, roles, parametros y bitacora',
    [('fac', 'FACULTAD', 200, 220, 'entidad'),
     ('pro', 'PROGRAMA_ACADEMICO', 560, 220, 'entidad'),
     ('per', 'PERIODO_ACADEMICO', 200, 500, 'entidad'),
     ('asi', 'ASISTENTE', 560, 500, 'entidad'),
     ('usu', 'USUARIO', 1080, 220, 'entidad'),
     ('rol', 'ROL', 1440, 220, 'entidad'),
     ('par', 'PARAMETRO', 1080, 500, 'entidad'),
     ('bit', 'BITACORA', 1080, 760, 'entidad')],
    [('fac', 'agrupa', 'pro', False, '1:N'),
     ('asi', 'cursa', 'pro', False, 'N:M  por periodo'),
     ('asi', 'opera como', 'usu', False, '1:1  (0,1)/(1,1)'),
     ('usu', 'desempena', 'rol', False, 'N:M  fecha_ini en la clave'),
     ('usu', 'configura', 'par', False, '1:N'),
     ('usu', 'produce', 'bit', False, '1:N')],
    [('fac', [('id_facultad', 'pk', -160, -80), ('nombre', 'simple', -20, -120),
              ('fk_facultad_padre\n(reflexiva)', 'simple', -200, 60)]),
     ('pro', [('codigo  char(5)', 'pk', -40, -120), ('nombre', 'simple', 140, -100),
              ('nivel', 'simple', 200, 0)]),
     ('usu', [('usuario  (unico)', 'simple', -40, -120), ('clave_hash', 'simple', 140, -100),
              ('ultimo_acceso', 'simple', 200, 0)]),
     ('bit', [('datos_antes  jsonb', 'simple', 200, -40), ('datos_despues  jsonb', 'simple', 220, 60),
              ('operacion', 'simple', 60, 150)])],
    [('FACULTAD depende de FACULTAD es REFLEXIVA y produce un ARBOL:\n'
      'cada nodo tiene un solo padre. Por eso se resuelve con una columna\n'
      'en la misma tabla, y se consulta con WITH RECURSIVE.', 180, 760, 400, 90),
     ('fecha_ini ENTRA EN LA CLAVE PRIMARIA de rol_por_usuario.\n'
      'Sin ella, quien fue administrador, dejo de serlo y vuelve, quedaria\n'
      'bloqueado para siempre. Es el error que NO falla ruidosamente.', 1420, 420, 420, 100)]))

# ═══════════════════════════════════════════════════════════ escritura ══════
with open(SALIDA, 'w', encoding='utf-8') as f:
    f.write('<mxfile host="app.diagrams.net" agent="generador-mer" type="device">\n')
    f.write('\n'.join(pg.xml() for pg in paginas))
    f.write('\n</mxfile>\n')

print('OK -> %s' % SALIDA)
print('paginas: %d' % len(paginas))
for pg in paginas:
    print('  %-46s %3d celdas' % (pg.nombre, len(pg.celdas)))
