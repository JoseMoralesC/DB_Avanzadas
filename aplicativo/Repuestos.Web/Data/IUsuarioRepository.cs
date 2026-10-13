using Repuestos.Web.Models;

namespace Repuestos.Web.Data;

public interface IUsuarioRepository
{
    Task<Usuario?> ObtenerCredencialAsync(string correo, CancellationToken cancellationToken);
    Task<Usuario?> ConfirmarLoginAsync(string correo, string hashVerificado, CancellationToken cancellationToken);
}
