using Repuestos.Web.Models;

namespace Repuestos.Web.Data;

public interface ICatalogoRepository
{
    Task<IReadOnlyList<Repuesto>> ConsultarAsync(FiltroCatalogo filtro, bool incluirInactivos, CancellationToken ct);
    Task<IReadOnlyList<Opcion>> CategoriasAsync(CancellationToken ct);
    Task<IReadOnlyList<Opcion>> MarcasAsync(CancellationToken ct);
    Task<IReadOnlyList<Opcion>> ModelosAsync(int? idMarca, CancellationToken ct);
    Task<Repuesto?> ObtenerAsync(int id, CancellationToken ct);
    Task<int> GuardarAsync(RepuestoForm form, CancellationToken ct);
    Task<BaseActiva> BaseActivaAsync(CancellationToken ct);
    Task<MisCasosViewModel> MisCasosAsync(int idUsuario, CancellationToken ct);
}
