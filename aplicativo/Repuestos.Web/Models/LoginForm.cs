using System.ComponentModel.DataAnnotations;

namespace Repuestos.Web.Models;

public sealed class LoginForm
{
    [Required, EmailAddress, StringLength(100)] public string Correo { get; set; } = "";
    [Required, StringLength(256), DataType(DataType.Password), Display(Name = "Contrasena")] public string Contrasena { get; set; } = "";
    public string? ReturnUrl { get; set; }
}

public sealed record MisCasosViewModel(IReadOnlyList<CasoCliente> Casos, IReadOnlyList<CotizacionCliente> Cotizaciones);
