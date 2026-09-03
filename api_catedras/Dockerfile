# ==============================================================
# Dockerfile de la API Cátedras — ASP.NET Core / .NET 10 (puerto 8037)
#
# Usa la imagen del SDK (no la de runtime) a propósito: el contenedor corre
# `dotnet watch`, que RECOMPILA Y REINICIA solo cuando se guarda un .cs.
# Ese es el ciclo que promete el Artículo 4.
# ==============================================================

FROM mcr.microsoft.com/dotnet/sdk:10.0

# El compose monta aquí el código fuente:
WORKDIR /app

# DOTNET_USE_POLLING_FILE_WATCHER: en Docker sobre Windows los avisos de
#   "archivo cambiado" no siempre llegan al contenedor. El sondeo revisa los
#   archivos cada tanto y el watch funciona de verdad.
# ASPNETCORE_URLS: en qué dirección y puerto escucha la API adentro (el
#   compose publica ese mismo 8037 hacia el host).
ENV DOTNET_USE_POLLING_FILE_WATCHER=1 \
    ASPNETCORE_URLS=http://0.0.0.0:8037

EXPOSE 8037

CMD ["dotnet", "watch", "run", "--non-interactive", "--project", "ApiCatedras.csproj"]
