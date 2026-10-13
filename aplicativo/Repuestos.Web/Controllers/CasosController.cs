using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Repuestos.Web.Data;

namespace Repuestos.Web.Controllers;

[Authorize(Roles = "Cliente")]
public sealed class CasosController(ICatalogoRepository catalogo) : Controller
{
    public async Task<IActionResult> Index(CancellationToken ct) =>
        View(await catalogo.MisCasosAsync(int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!), ct));
}
