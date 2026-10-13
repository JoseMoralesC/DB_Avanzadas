using System.Threading.RateLimiting;
using DotNetEnv;
using DotNetEnv.Configuration;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Repuestos.Web.Data;
using Repuestos.Web.Models;
using Repuestos.Web.Services;

if (args.Contains("--hash-password"))
{
    Console.Error.WriteLine("Ingrese la contrasena por stdin (no se guardara):");
    var password = Console.ReadLine();
    if (string.IsNullOrEmpty(password)) throw new InvalidOperationException("Contrasena vacia.");
    Console.WriteLine(new PasswordHasher<Usuario>().HashPassword(null!, password));
    return;
}

var builder = WebApplication.CreateBuilder(args);
builder.Configuration.AddJsonFile("appsettings.Local.json", optional: true, reloadOnChange: false);
var envPath = Path.Combine(builder.Environment.ContentRootPath, ".env");
if (builder.Environment.IsDevelopment() && File.Exists(envPath))
    builder.Configuration.AddDotNetEnv(envPath, LoadOptions.NoEnvVars());
builder.Configuration.AddEnvironmentVariables().AddCommandLine(args);
builder.Services.AddControllersWithViews(options => options.Filters.Add(new AutoValidateAntiforgeryTokenAttribute()));
builder.Services.AddSingleton<IPasswordHasher<Usuario>, PasswordHasher<Usuario>>();
builder.Services.AddScoped<AutenticacionService>();
builder.Services.AddSingleton<SqlConnectionFactory>();
builder.Services.AddScoped<IUsuarioRepository, SqlUsuarioRepository>();
builder.Services.AddScoped<ICatalogoRepository, SqlCatalogoRepository>();
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme).AddCookie(options =>
{
    options.LoginPath = "/Cuenta/Login";
    options.AccessDeniedPath = "/Cuenta/AccesoDenegado";
    options.Cookie.Name = "Repuestos.Sesion";
    options.Cookie.HttpOnly = true;
    options.Cookie.SameSite = SameSiteMode.Strict;
    options.Cookie.SecurePolicy = builder.Environment.IsDevelopment() ? CookieSecurePolicy.SameAsRequest : CookieSecurePolicy.Always;
    options.ExpireTimeSpan = TimeSpan.FromMinutes(30);
    options.SlidingExpiration = true;
    options.Events.OnValidatePrincipal = async context =>
    {
        try
        {
            var service = context.HttpContext.RequestServices.GetRequiredService<AutenticacionService>();
            if (context.Principal is not null && await service.SesionValidaAsync(context.Principal, context.HttpContext.RequestAborted)) return;
        }
        catch (Exception ex) when (ex is SqlException or InvalidOperationException)
        {
            context.HttpContext.RequestServices.GetRequiredService<ILoggerFactory>().CreateLogger("Sesion").LogWarning(ex, "No se pudo validar la sesion.");
        }
        context.RejectPrincipal();
        await context.HttpContext.SignOutAsync();
    };
});
builder.Services.AddAuthorization();
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = 429;
    options.AddPolicy("login", context => RateLimitPartition.GetFixedWindowLimiter(
        context.Connection.RemoteIpAddress?.ToString() ?? "local",
        _ => new FixedWindowRateLimiterOptions { PermitLimit = 10, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }));
});
var app = builder.Build();
// Form numbers use a stable decimal separator; display currency uses es-CR explicitly.
app.UseRequestLocalization(new RequestLocalizationOptions().SetDefaultCulture("en-US").AddSupportedCultures("en-US").AddSupportedUICultures("en-US"));
app.UseExceptionHandler("/Home/Error");
if (!app.Environment.IsDevelopment()) { app.UseHsts(); app.UseHttpsRedirection(); }
app.Use(async (context, next) =>
{
    context.Response.Headers["X-Content-Type-Options"] = "nosniff";
    context.Response.Headers["Referrer-Policy"] = "same-origin";
    context.Response.Headers["Content-Security-Policy"] = "default-src 'self'; img-src 'self'; style-src 'self'; script-src 'self'; form-action 'self'; frame-ancestors 'none'; base-uri 'self'";
    context.Response.Headers.CacheControl = "no-store";
    await next();
});
app.UseStaticFiles();
app.UseRouting();
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllerRoute("default", "{controller=Catalogo}/{action=Index}/{id?}");
app.Run();
