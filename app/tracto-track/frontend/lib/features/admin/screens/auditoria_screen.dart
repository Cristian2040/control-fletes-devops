import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/gasto_model.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import 'validacion_fotografia_screen.dart';

/// Pantalla A-13 · Auditoría en Ruta (RF-06, Sprint 8)
///
/// Lista los comprobantes enviados por los choferes que están pendientes de
/// revisión para cotejar los tickets fotográficos en tiempo real:
///   - Encabezado con flecha de regreso (→ A-02 Tablero), título "Auditoría en Ruta (RF-06)",
///     contador de tickets por revisar y etiqueta "PENDIENTE".
///   - Leyenda "Cotejo de tickets fotográficos en tiempo real".
///   - Tarjetas de ticket: chofer, placas de la unidad, tipo de gasto, hora e importe.
///   - Enlace "Auditar Ticket" en cada tarjeta → navega a A-14 Validación de Fotografía.
class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({super.key});

  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  final ApiClient _api = ApiClient();

  List<GastoModel> _todosGastos = [];
  bool _cargando = true;
  String _filtroEstado = 'pendiente'; // 'pendiente', 'aprobado', 'rechazado'

  @override
  void initState() {
    super.initState();
    _cargarGastos();
  }

  Future<void> _cargarGastos() async {
    setState(() => _cargando = true);
    try {
      final lista = await _api.fetchGastosAuditoria();
      if (mounted) {
        setState(() {
          _todosGastos = lista;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<GastoModel> get _gastosFiltrados {
    if (_filtroEstado == 'todos') return _todosGastos;
    if (_filtroEstado == 'pendiente') {
      return _todosGastos.where((g) => g.isAuditoriaPendiente).toList();
    }
    return _todosGastos
        .where((g) => g.estadoAuditoria.toLowerCase() == _filtroEstado)
        .toList();
  }

  int get _pendientesCount =>
      _todosGastos.where((g) => g.isAuditoriaPendiente).length;

  int get _aprobadosCount => _todosGastos.where((g) => g.isAprobado).length;

  int get _rechazadosCount => _todosGastos.where((g) => g.isRechazado).length;

  String _formatearHora(DateTime fecha) {
    final hh = fecha.hour.toString().padLeft(2, '0');
    final mm = fecha.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _abrirValidacionFotografia(GastoModel gasto) async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ValidacionFotografiaScreen(gasto: gasto),
      ),
    );
    if (resultado == true || mounted) {
      await _cargarGastos();
    }
  }

  void _regresarAlTablero() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.adminHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listaVisible = _gastosFiltrados;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 3),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEncabezado(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: const Text(
                'Cotejo de tickets fotográficos en tiempo real',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _buildFiltrosEstado(),
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryBlue,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarGastos,
                      color: AppTheme.primaryBlue,
                      child: listaVisible.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 80),
                                Center(
                                  child: Text(
                                    'No hay comprobantes en esta categoría',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: listaVisible.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return _buildTarjetaTicket(listaVisible[index]);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEncabezado() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('btn_regresar_tablero_auditoria'),
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: _regresarAlTablero,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auditoría en Ruta (RF-06)',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_pendientesCount tickets por revisar',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.45),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 7, color: AppColors.warning),
                SizedBox(width: 5),
                Text(
                  'PENDIENTE',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosEstado() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _buildChipFiltro(
            key: const Key('filtro_auditoria_pendientes'),
            label: 'Por Revisar ($_pendientesCount)',
            valor: 'pendiente',
            colorActivo: AppColors.warning,
          ),
          const SizedBox(width: 8),
          _buildChipFiltro(
            key: const Key('filtro_auditoria_aprobados'),
            label: 'Aprobados ($_aprobadosCount)',
            valor: 'aprobado',
            colorActivo: AppColors.success,
          ),
          const SizedBox(width: 8),
          _buildChipFiltro(
            key: const Key('filtro_auditoria_rechazados'),
            label: 'Rechazados ($_rechazadosCount)',
            valor: 'rechazado',
            colorActivo: AppColors.error,
          ),
          const SizedBox(width: 8),
          _buildChipFiltro(
            key: const Key('filtro_auditoria_todos'),
            label: 'Todos (${_todosGastos.length})',
            valor: 'todos',
            colorActivo: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildChipFiltro({
    required Key key,
    required String label,
    required String valor,
    required Color colorActivo,
  }) {
    final activo = _filtroEstado == valor;
    return InkWell(
      key: key,
      onTap: () => setState(() => _filtroEstado = valor),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: activo
              ? colorActivo.withValues(alpha: 0.18)
              : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo
                ? colorActivo
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: activo ? colorActivo : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTarjetaTicket(GastoModel gasto) {
    final horaStr = _formatearHora(gasto.fecha);
    final importeStr = '\$${gasto.monto.toStringAsFixed(2)}';

    Color colorAccion = AppColors.warning;
    String textoAccion = 'Auditar Ticket';
    if (gasto.isAprobado) {
      colorAccion = AppColors.success;
      textoAccion = 'Aprobado (Revisar)';
    } else if (gasto.isRechazado) {
      colorAccion = AppColors.error;
      textoAccion = 'Rechazado (Revisar)';
    }

    return InkWell(
      key: Key('card_ticket_auditoria_${gasto.folio}'),
      onTap: () => _abrirValidacionFotografia(gasto),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          gasto.choferNombre,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          gasto.placasCamion,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  importeStr,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${gasto.tipoLegible} · $horaStr  (${gasto.folio})',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _abrirValidacionFotografia(gasto),
                  child: Text(
                    textoAccion,
                    style: TextStyle(
                      color: colorAccion,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
