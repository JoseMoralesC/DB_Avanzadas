using System.Globalization;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Identity;
using Repuestos.Web.Data;
using Repuestos.Web.Models;

namespace Repuestos.Web.Services;

public sealed class AutenticacionService(IUsuarioRepository usuarios, IPasswordHasher<Usuario> hasher)
{
    private static readonly string DummyHash = new PasswordHasher<Usuario>().HashPassword(null!, Guid.NewGuid().ToString());

    public async Task<ClaimsPrincipal?> LoginAsync(string correo, string password, CancellationToken ct)
    {
        var usuario = await usuarios.ObtenerCredencialAsync(correo.Trim(), ct);
        PasswordVerificationResult resultado;
        try { resultado = hasher.VerifyHashedPassword(usuario!, usuario?.Hash ?? DummyHash, password); }
        catch (FormatException) { return null; }
        if (usuario is null || resultado == PasswordVerificationResult.Failed) return null;
        usuario = await usuarios.ConfirmarLoginAsync(usuario.Correo, password, usuario.Hash, ct);
        return usuario is null ? null : CrearPrincipal(usuario);
    }

    public async Task<bool> SesionValidaAsync(ClaimsPrincipal principal, CancellationToken ct)
    {
        var correo = principal.FindFirstValue(ClaimTypes.Email);
        if (correo is null) return false;
        var usuario = await usuarios.ObtenerCredencialAsync(correo, ct);
        return usuario is not null && principal.FindFirstValue(ClaimTypes.NameIdentifier) == usuario.IdUsuario.ToString(CultureInfo.InvariantCulture)
            && principal.FindFirstValue(ClaimTypes.Role) == usuario.Rol
            && principal.FindFirstValue("Perfil") == Perfil(usuario)
            && principal.FindFirstValue("CredencialVersion") == Version(usuario.Hash);
    }

    private static ClaimsPrincipal CrearPrincipal(Usuario usuario) => new(new ClaimsIdentity(new[]
    {
        new Claim(ClaimTypes.NameIdentifier, usuario.IdUsuario.ToString(CultureInfo.InvariantCulture)),
        new Claim(ClaimTypes.Email, usuario.Correo),
        new Claim(ClaimTypes.Name, usuario.Nombre),
        new Claim(ClaimTypes.Role, usuario.Rol),
        new Claim("Perfil", Perfil(usuario)),
        new Claim("CredencialVersion", Version(usuario.Hash))
    }, CookieAuthenticationDefaults.AuthenticationScheme));

    private static string Perfil(Usuario usuario) => $"{usuario.IdEmpleado}:{usuario.IdAseguradora}";
    private static string Version(string hash) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(hash)));
}
