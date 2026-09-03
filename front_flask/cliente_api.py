"""
cliente_api.py — La capa de DATOS del front.

Es al front lo que el repositorio es al back: la ÚNICA pieza que sabe dónde
viven los datos —en la API, nunca en la base— y la única que habla HTTP.
Traduce cada respuesta a `(ok, datos, errores)` para que las vistas no tengan
que saber qué es un 422.

**Lo notable de este archivo es lo que NO dice:** en ninguna línea aparece que
la API esté escrita en C#. No lo sabe y no le hace falta. Si mañana esa API se
reescribiera en Go, este archivo no cambiaría — mientras el contrato se
respete. Eso es lo que significa "separación de capas a nivel de sistema", y
aquí se puede comprobar, no solo afirmar.
"""

import os

import requests

# El hostname INTERNO del compose (api-catedras), jamás localhost: dentro de
# un contenedor, localhost es él mismo.
URL_API = os.environ.get("API_CATEDRAS_URL", "http://localhost:8037")

TIEMPO_MAXIMO = 10  # segundos

NO_DISPONIBLE = ["El servicio no está disponible. ¿Está arriba la API?"]


def _llamar(metodo: str, ruta: str, **kwargs):
    """Ejecuta la petición y unifica un solo caso: 'la API no responde'.

    Devuelve None cuando NO hubo respuesta —API caída, timeout—, que es
    distinto de 'respondió con un error'. Un 404 es la API funcionando y
    diciendo que no existe; un None es que no hay con quién hablar.
    """
    try:
        return requests.request(
            metodo, f"{URL_API}{ruta}", timeout=TIEMPO_MAXIMO, **kwargs
        )
    except requests.RequestException:
        return None


def _cuerpo(respuesta):
    """El JSON, o un diccionario vacío si no vino JSON.

    Un 500 puede llegar como HTML; sin esto el front se caería justo cuando
    tiene que explicar que algo falló.
    """
    try:
        return respuesta.json()
    except ValueError:
        return {}


def _mensajes(respuesta) -> list[str]:
    """Traduce a texto los errores que produce ESTA API.

    El sobre lo define el contrato de la v1, y es PLANO:

        {"estado": 422, "mensaje": "Datos inválidos.",
         "errores": ["El campo nombre es obligatorio.", …]}

        {"estado": 404, "mensaje": "Sede no encontrada.",
         "detalle": "No existe una sede con el código X."}

    Fíjese en la diferencia con un front que hable con FastAPI: allá todo
    llega anidado bajo `detail`. Aquí no. **El front tiene que conocer el
    sobre de SU API**, y por eso este archivo es el único que lo conoce: si el
    sobre cambiara, se cambia aquí y en ningún otro sitio.
    """
    cuerpo = _cuerpo(respuesta)

    errores = cuerpo.get("errores")
    if isinstance(errores, list) and errores:
        return [str(e) for e in errores]

    partes = [cuerpo.get("mensaje", ""), cuerpo.get("detalle", "")]
    partes = [p for p in partes if p]
    return partes or ["No se pudo completar la operación."]


def listar_sedes():
    """GET /api/sede → (ok, lista, errores).

    El 204 NO es un error: es la tabla vacía. Se devuelve como lista vacía y
    la pantalla dirá 'no hay sedes', no 'algo falló'.
    """
    respuesta = _llamar("GET", "/api/sede")
    if respuesta is None:
        return False, [], NO_DISPONIBLE
    if respuesta.status_code == 204:
        return True, [], []
    if respuesta.status_code == 200:
        return True, _cuerpo(respuesta).get("datos", []), []
    return False, [], _mensajes(respuesta)


def obtener_sede(codigo: str):
    """GET /api/sede/{codigo} → (ok, sede, errores)."""
    respuesta = _llamar("GET", f"/api/sede/{codigo}")
    if respuesta is None:
        return False, None, NO_DISPONIBLE
    if respuesta.status_code == 200:
        return True, _cuerpo(respuesta), []
    return False, None, _mensajes(respuesta)


def crear_sede(datos: dict):
    """POST /api/sede → (ok, errores)."""
    respuesta = _llamar("POST", "/api/sede", json=datos)
    if respuesta is None:
        return False, NO_DISPONIBLE
    if respuesta.status_code == 200:
        return True, []
    return False, _mensajes(respuesta)


def reemplazar_sede(codigo: str, datos: dict):
    """PUT /api/sede/{codigo} → (ok, errores).

    Reemplazo COMPLETO: los obligatorios viajan siempre. Omitir uno es 422, y
    eso es lo que se quiere mostrar junto al PATCH de abajo.
    """
    respuesta = _llamar("PUT", f"/api/sede/{codigo}", json=datos)
    if respuesta is None:
        return False, NO_DISPONIBLE
    if respuesta.status_code == 200:
        return True, []
    return False, _mensajes(respuesta)


def actualizar_sede(codigo: str, datos: dict):
    """PATCH /api/sede/{codigo} → (ok, errores).

    Actualización PARCIAL: viaja SOLO lo que el usuario diligenció. El mismo
    formulario que por PUT daría 422 aquí responde 200.
    """
    respuesta = _llamar("PATCH", f"/api/sede/{codigo}", json=datos)
    if respuesta is None:
        return False, NO_DISPONIBLE
    if respuesta.status_code == 200:
        return True, []
    return False, _mensajes(respuesta)


def eliminar_sede(codigo: str):
    """DELETE /api/sede/{codigo} → (ok, errores)."""
    respuesta = _llamar("DELETE", f"/api/sede/{codigo}")
    if respuesta is None:
        return False, NO_DISPONIBLE
    if respuesta.status_code == 200:
        return True, []
    return False, _mensajes(respuesta)
