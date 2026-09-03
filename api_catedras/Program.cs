using ApiCatedras.Repositorios;
using ApiCatedras.Servicios;
using Microsoft.AspNetCore.Mvc;

var builder = WebApplication.CreateBuilder(args);

// La API escucha en el 8037 también DENTRO del contenedor, para que el
// Dockerfile, el docker-compose y los contratos digan todos el mismo número.
builder.WebHost.UseUrls("http://0.0.0.0:8037");

// ============================================================
// EL ENSAMBLADOR (Artículo 3)
// Estas dos líneas son el ÚNICO lugar del proyecto donde una clase concreta
// aparece junto a su interfaz. Todo lo demás recibe interfaces por constructor.
//
// Y aquí se ve por qué importa: la clase se llama RepositorioSedePostgreSql.
// El día que hubiera un segundo motor, SOLO esta línea cambiaría.
// ============================================================
builder.Services.AddScoped<IRepositorioSede, RepositorioSedePostgreSql>();
builder.Services.AddScoped<IServicioSede, ServicioSede>();

builder.Services.AddControllers();

// ============================================================
// EL 422 DEL CONTRATO
// Con [ApiController], un cuerpo inválido corta la petición ANTES de entrar al
// método y responde 400 con ProblemDetails. El contrato exige 422 con el sobre
// {estado, mensaje, errores[]}: hay que reemplazar la fábrica de respuestas.
//
// Es la pieza que más sorprende: el 422 NO sale solo, hay que pedirlo.
// ============================================================
builder.Services.Configure<ApiBehaviorOptions>(opciones =>
{
    opciones.InvalidModelStateResponseFactory = contexto =>
    {
        var errores = contexto.ModelState
            .Where(e => e.Value?.Errors.Count > 0)
            .SelectMany(e => e.Value!.Errors.Select(x => x.ErrorMessage))
            .ToList();

        return new ObjectResult(new
        {
            estado = 422,
            mensaje = "Datos inválidos.",
            errores
        })
        { StatusCode = 422 };
    };
});

// Documentación interactiva
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();

// Diagnóstico: dice quién es y qué versión, SIN tocar la base de datos.
// Si esto no responde, el problema no es de contrato: la API no está arriba.
app.MapGet("/", () => Results.Ok(new
{
    mensaje = "API Cátedras Abiertas — módulo de sedes",
    version = "v1",
    contratos = "/swagger"
}));

app.MapControllers();

app.Run();
