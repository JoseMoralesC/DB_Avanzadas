namespace Repuestos.Web.Models;

public sealed record Usuario(int IdUsuario, string Correo, string Hash, string Rol,
    int? IdEmpleado, int? IdAseguradora, string Nombre);

public sealed record BaseActiva(string Servidor, string Base, string Estado);
public sealed record CasoCliente(int IdCaso, string Placa, string Estado, DateTime FechaApertura);
public sealed record CotizacionCliente(int IdCotizacion, int IdCaso, string Estado, decimal Total, DateTime Fecha);
