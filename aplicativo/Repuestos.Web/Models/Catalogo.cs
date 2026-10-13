using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc.ModelBinding;

namespace Repuestos.Web.Models;

public sealed record Opcion(int Id, string Nombre);
public sealed record Repuesto(int IdRepuesto, int IdCategoria, string Categoria, string Codigo,
    string Nombre, decimal PrecioVenta, decimal Costo, bool Activo, int Existencias);

public sealed class FiltroCatalogo
{
    [StringLength(120)] public string? Texto { get; set; }
    [Range(1, int.MaxValue)] public int? IdCategoria { get; set; }
    [Range(1, int.MaxValue)] public int? IdMarca { get; set; }
    [Range(1, int.MaxValue)] public int? IdModelo { get; set; }
    [Range(typeof(decimal), "0", "99999999.99")] public decimal? PrecioMaximo { get; set; }
    public bool SoloDisponibles { get; set; }
}

public sealed class CatalogoViewModel
{
    public FiltroCatalogo Filtro { get; set; } = new();
    public IReadOnlyList<Repuesto> Repuestos { get; set; } = [];
    public IReadOnlyList<Opcion> Categorias { get; set; } = [];
    public IReadOnlyList<Opcion> Marcas { get; set; } = [];
    public IReadOnlyList<Opcion> Modelos { get; set; } = [];
    public string? Error { get; set; }
}

public sealed class RepuestoForm
{
    [Range(0, int.MaxValue)] public int IdRepuesto { get; set; }
    [Required, Range(1, int.MaxValue), Display(Name = "Categoria")] public int IdCategoria { get; set; }
    [BindNever] public string Codigo { get; set; } = "";
    [Required, StringLength(120)] public string Nombre { get; set; } = "";
    [Range(typeof(decimal), "0", "99999999.99"), Display(Name = "Precio de venta")] public decimal PrecioVenta { get; set; }
    [Range(typeof(decimal), "0", "99999999.99")] public decimal Costo { get; set; }
    public bool Activo { get; set; } = true;
    public IReadOnlyList<Opcion> Categorias { get; set; } = [];
}
