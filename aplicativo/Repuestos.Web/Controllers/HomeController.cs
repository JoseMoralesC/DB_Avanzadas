using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Repuestos.Web.Controllers;

public sealed class HomeController : Controller
{
    [AllowAnonymous]
    public IActionResult Error() { Response.StatusCode = 503; return View(); }
}
