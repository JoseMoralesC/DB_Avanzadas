using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Repuestos.Web.Data;
using Repuestos.Web.Models;

namespace Repuestos.Web.Controllers;

[Authorize]
public sealed class CatalogoController(ICatalogoRepository catalogo, ILogger<CatalogoController> logger) : Controller
{
    public async Task<IActionResult> Index(FiltroCatalogo filtro, CancellationToken ct)
    {
        var model = new CatalogoViewModel { Filtro = filtro };
        try
        {
            model.Categorias = await catalogo.CategoriasAsync(ct);
            model.Marcas = await catalogo.MarcasAsync(ct);
            model.Modelos = await catalogo.ModelosAsync(filtro.IdMarca, ct);
            if (ModelState.IsValid) model.Repuestos = await catalogo.ConsultarAsync(filtro, EsPersonal, ct);
        }
        catch (Exception ex) when (ex is SqlException or InvalidOperationException)
        { logger.LogError(ex, "Error consultando catalogo."); model.Error = "El catalogo no esta disponible. Intente nuevamente."; }
        return View(model);
    }

    [Authorize(Roles = "Administrador,Empleado"), HttpGet]
    public async Task<IActionResult> Editar(int id = 0, CancellationToken ct = default)
    {
        var form = new RepuestoForm();
        if (id != 0)
        {
            var repuesto = await catalogo.ObtenerAsync(id, ct);
            if (repuesto is null) return NotFound();
            form = new() { IdRepuesto = id, IdCategoria = repuesto.IdCategoria, Codigo = repuesto.Codigo,
                Nombre = repuesto.Nombre, PrecioVenta = repuesto.PrecioVenta, Costo = repuesto.Costo, Activo = repuesto.Activo };
        }
        form.Categorias = await catalogo.CategoriasAsync(ct);
        return View(form);
    }

    [Authorize(Roles = "Administrador,Empleado"), HttpPost]
    public async Task<IActionResult> Editar(RepuestoForm form, CancellationToken ct)
    {
        form.Nombre = form.Nombre?.Trim() ?? "";
        if (string.IsNullOrWhiteSpace(form.Nombre)) ModelState.AddModelError(nameof(form.Nombre), "Indique un nombre.");
        if (ModelState.IsValid)
        {
            try
            {
                await catalogo.GuardarAsync(form, ct);
                TempData["Exito"] = "Repuesto guardado.";
                return RedirectToAction(nameof(Index));
            }
            catch (SqlException ex) when (ex.Number is 2601 or 2627) { ModelState.AddModelError("", "No se pudo asignar un codigo unico. Vuelva a intentar."); }
            catch (SqlException ex) when (ex.Number == 547) { ModelState.AddModelError("", "Verifique la categoria y los valores del repuesto."); }
            catch (Exception ex) when (ex is SqlException or InvalidOperationException)
            { logger.LogWarning(ex, "No se pudo guardar el repuesto."); ModelState.AddModelError("", "No se pudo guardar. Verifique los datos y vuelva a intentar."); }
        }
        if (form.IdRepuesto > 0)
            form.Codigo = (await catalogo.ObtenerAsync(form.IdRepuesto, ct))?.Codigo ?? "";
        form.Categorias = await catalogo.CategoriasAsync(ct);
        return View(form);
    }

    [Authorize(Roles = "Administrador,Empleado"), HttpGet]
    public async Task<IActionResult> Conexion(CancellationToken ct) => View(await catalogo.BaseActivaAsync(ct));

    private bool EsPersonal => User.IsInRole("Administrador") || User.IsInRole("Empleado");
}
