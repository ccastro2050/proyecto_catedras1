"""
app.py — La capa de PRESENTACIÓN del sistema.

Estas son las vistas: reciben lo que el usuario hizo en el navegador, se lo
piden a `cliente_api`, y eligen qué plantilla mostrar. Nada más.

Las tres reglas de este archivo:

1. **No habla con la base de datos.** Ni siquiera sabe que existe PostgreSQL.
   Todo lo pide por HTTP a la API.
2. **No valida negocio.** Si un nombre repetido está mal, lo dice la base con
   un 500 y aquí solo se muestra. Duplicar la regla en el front es tener dos
   dueños de la misma verdad.
3. **No sabe en qué lenguaje está escrita la API.** Y esa ignorancia es una
   virtud: lo único que comparten los dos procesos es el contrato.
"""

import os

from flask import Flask, flash, redirect, render_template, request, url_for

import cliente_api

app = Flask(__name__)

# `flash` guarda los avisos en la sesión, y la sesión va firmada: sin clave,
# Flask no arranca. En un proyecto real esto vive en un .env fuera de git.
app.secret_key = os.environ.get("CLAVE_SESION", "Catedras123!Sesion")

PUERTO = int(os.environ.get("PUERTO", 8038))


def _avisar(errores: list[str]) -> None:
    """Cada error de la API se muestra como un aviso rojo, uno por línea."""
    for mensaje in errores:
        flash(mensaje, "error")


@app.route("/")
def inicio():
    return redirect(url_for("listar"))


# ----------------------------------------------------------------------
# RF1 — Listar sedes
# ----------------------------------------------------------------------
@app.route("/sedes")
def listar():
    ok, sedes, errores = cliente_api.listar_sedes()
    if not ok:
        _avisar(errores)
    # Aun con error se renderiza la página: el usuario ve el aviso dentro de
    # la aplicación, no una pantalla de excepción de Flask.
    return render_template("sedes/lista.html", sedes=sedes)


# ----------------------------------------------------------------------
# RF2 — Crear una sede
# ----------------------------------------------------------------------
@app.route("/sedes/nueva", methods=["GET", "POST"])
def crear():
    if request.method == "GET":
        return render_template("sedes/formulario.html", sede=None)

    datos = {
        "idSede": request.form.get("idSede", "").strip(),
        "nombre": request.form.get("nombre", "").strip(),
        # Un opcional en blanco NO se envía como cadena vacía: se envía nulo.
        # Vacío y "no lo tiene" no son lo mismo, y la base los guarda distinto.
        "direccion": request.form.get("direccion", "").strip() or None,
        # La casilla marcada llega como "on"; sin marcar, no llega.
        "esVirtual": request.form.get("esVirtual") == "on",
    }

    ok, errores = cliente_api.crear_sede(datos)
    if ok:
        flash(f"Sede {datos['idSede']} creada.", "exito")
        return redirect(url_for("listar"))

    _avisar(errores)
    # Se devuelve el formulario CON lo que el usuario había escrito: perder lo
    # digitado por un error de validación es castigar al usuario dos veces.
    return render_template("sedes/formulario.html", sede=datos)


# ----------------------------------------------------------------------
# RF3 y RF4 — Editar: la MISMA pantalla, dos botones, dos verbos
# ----------------------------------------------------------------------
@app.route("/sedes/<codigo>/editar", methods=["GET", "POST"])
def editar(codigo):
    if request.method == "GET":
        ok, sede, errores = cliente_api.obtener_sede(codigo)
        if not ok:
            _avisar(errores)
            return redirect(url_for("listar"))
        return render_template("sedes/formulario.html", sede=sede)

    # Qué botón se oprimió decide el verbo. La diferencia NO está en un if de
    # negocio: está en qué se envía.
    verbo = request.form.get("verbo", "patch")

    nombre = request.form.get("nombre", "").strip()
    direccion = request.form.get("direccion", "").strip()
    es_virtual = request.form.get("esVirtual") == "on"

    if verbo == "put":
        # PUT: reemplazo COMPLETO. El nombre viaja aunque esté vacío, y por eso
        # un nombre en blanco responde 422. Es la semántica de PUT.
        cuerpo = {"nombre": nombre, "direccion": direccion or None,
                  "esVirtual": es_virtual}
        ok, errores = cliente_api.reemplazar_sede(codigo, cuerpo)
        hecho = "reemplazó (PUT)"
    else:
        # PATCH: viaja SOLO lo diligenciado. El mismo formulario a medio llenar
        # que el PUT rechaza, aquí funciona.
        cuerpo = {}
        if nombre:
            cuerpo["nombre"] = nombre
        if direccion:
            cuerpo["direccion"] = direccion
        # esVirtual siempre tiene un valor (marcada o no), así que siempre va:
        # una casilla no puede "no llegar" de forma distinguible.
        cuerpo["esVirtual"] = es_virtual
        ok, errores = cliente_api.actualizar_sede(codigo, cuerpo)
        hecho = "actualizó (PATCH)"

    if ok:
        flash(f"Se {hecho} la sede {codigo}.", "exito")
        return redirect(url_for("listar"))

    _avisar(errores)
    return render_template("sedes/formulario.html",
                           sede={"idSede": codigo, "nombre": nombre,
                                 "direccion": direccion, "esVirtual": es_virtual})


# ----------------------------------------------------------------------
# RF5 — Eliminar
# ----------------------------------------------------------------------
@app.route("/sedes/<codigo>/eliminar", methods=["POST"])
def eliminar(codigo):
    # Se exige POST a propósito: un enlace GET que borra lo puede disparar el
    # navegador solo al precargar la página.
    ok, errores = cliente_api.eliminar_sede(codigo)
    if ok:
        flash(f"Sede {codigo} eliminada.", "exito")
    else:
        _avisar(errores)
    return redirect(url_for("listar"))


if __name__ == "__main__":
    # host 0.0.0.0: dentro del contenedor hay que escuchar en todas las
    # interfaces, o el puerto publicado no llega a ninguna parte.
    app.run(host="0.0.0.0", port=PUERTO, debug=True)
