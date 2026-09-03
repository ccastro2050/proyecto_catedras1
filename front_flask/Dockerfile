# Dockerfile del FRONT — Flask + Jinja2, puerto 8038.
#
# Imagen de Python, cuando la API es de .NET. Eso NO es una inconsistencia:
# es el punto entero del proyecto. Son dos procesos distintos, con
# dependencias distintas y hasta con lenguajes distintos, y lo único que los
# une es un contrato HTTP.
FROM python:3.12-slim

WORKDIR /app

# Primero las dependencias y después el código: mientras requirements.txt no
# cambie, Docker reutiliza la capa del pip install.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV PUERTO=8038
EXPOSE 8038

CMD ["python", "app.py"]
