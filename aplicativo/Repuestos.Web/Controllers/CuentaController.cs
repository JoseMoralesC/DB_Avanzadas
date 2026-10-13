using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Data.SqlClient;
using Repuestos.Web.Models;
using Repuestos.Web.Services;

namespace Repuestos.Web.Controllers;

public sealed class CuentaController(AutenticacionService autenticacion, ILogger<CuentaController> logger) : Controller
{
    [AllowAnonymous, HttpGet]
    public IActionResult Login(string? returnUrl = null) => User.Identity?.IsAuthenticated == true
        ? RedirectToAction("Index", "Catalogo") : View(new LoginForm { ReturnUrl = returnUrl });

    [AllowAnonymous, HttpPost, EnableRateLimiting("login")]
    public async Task<IActionResult> Login(LoginForm form, CancellationToken ct)
    {
        if (!ModelState.IsValid) return View(form);
        try
        {
            var principal = await autenticacion.LoginAsync(form.Correo, form.Contrasena, ct);
            if (principal is null) { ModelState.AddModelError("", "Credenciales incorrectas o cuenta no disponible."); return View(form); }
            await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme, principal);
            return form.ReturnUrl is not null && Url.IsLocalUrl(form.ReturnUrl)
                ? LocalRedirect(form.ReturnUrl) : RedirectToAction("Index", "Catalogo");
        }
        catch (Exception ex) when (ex is SqlException or InvalidOperationException)
        {
            logger.LogError(ex, "No se pudo completar el inicio de sesion.");
            ModelState.AddModelError("", "No se pudo conectar al servicio. Intente nuevamente.");
            return View(form);
        }
    }

    [Authorize, HttpPost]
    public async Task<IActionResult> Salir()
    {
        await HttpContext.SignOutAsync();
        return RedirectToAction(nameof(Login));
    }

    [AllowAnonymous, HttpGet]
    public IActionResult AccesoDenegado() { Response.StatusCode = 403; return View(); }
}
