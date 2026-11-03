import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/viaje_model.dart';
import '../widgets/admin_bottom_nav_bar.dart';

/// Pantalla A-02 · Tablero – Panel de Control (RNF-01, Sprint 7)
///
/// Vista principal del Administrador / Dueño de Flota tras iniciar sesión.
/// Muestra el resumen de indicadores operativos en tiempo real (Viajes Activos,
/// Tickets Auditoría y Unidades Flota) y accesos directos a los módulos clave.
class TableroScreen extends StatefulWidget {
  const TableroScreen({super.key});

  @override
  State<TableroScreen> createState() => _TableroScreenState();
}

class _TableroScreenState extends State<TableroScreen> {
  final ApiClient _api = ApiClient();

  TableroResumenModel _resumen = const TableroResumenModel(
    viajesActivos: 2,
    ticketsPorAuditar: 3,
    unidadesFlota: 3,
  );
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarResumen();
  }

  Future<void> _cargarResumen() async {
    setState(() => _cargando = true);
    try {
      final res = await _api.fetchTableroResumen();
      if (mounted) {
        setState(() {
          _resumen = res;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarResumen,
          color: AppTheme.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEncabezado(),
                const SizedBox(height: 20),
                _buildTarjetasKpi(),
                const SizedBox(height: 28),
                const Text(
                  'Módulos del sistema',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _buildTarjetaModulo(
                  key: const Key('card_modulo_asignar_viaje'),
                  icono: Icons.add_road_rounded,
                  colorIcono: AppTheme.primaryBlue,
                  titulo: 'Asignar Nuevo Viaje (RF-05)',
                  subtitulo: 'Emitir orden de despacho, asignar unidad, chofer y anticipo',
                  codigoDestino: 'A-04',
                  onTap: () async {
                    await Navigator.of(context).pushNamed(AppRoutes.adminAsignacion);
                    _cargarResumen();
                  },
                ),
                const SizedBox(height: 12),
                _buildTarjetaModulo(
                  key: const Key('card_modulo_auditoria'),
                  icono: Icons.fact_check_rounded,
                  colorIcono: AppColors.warning,
                  titulo: 'Auditoría en Ruta (RF-06)',
                  subtitulo: 'Validar comprobantes fotográficos y gastos documentados',
                  codigoDestino: 'A-13',
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.adminAuditoria);
                  },
                ),
                const SizedBox(height: 12),
                _buildTarjetaModulo(
                  key: const Key('card_modulo_liquidaciones'),
                  icono: Icons.calculate_rounded,
                  colorIcono: AppColors.success,
                  titulo: 'Motor de Liquidaciones (US-13)',
                  subtitulo: 'Cálculo automatizado de fletes, anticipos, gastos y comisiones',
                  codigoDestino: 'A-15',
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.adminLiquidacionSelector);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEncabezado() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'A-02',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Panel de Control (RNF-01)',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 13, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      _resumen.baseOperativa,
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _resumen.empresa,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Monitoreo operativo de fletes, unidades y comprobaciones',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetasKpi() {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildKpiItem(
            key: const Key('kpi_viajes_activos'),
            valor: '${_resumen.viajesActivos}',
            etiqueta: 'Viajes Activos',
            icono: Icons.local_shipping_rounded,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKpiItem(
            key: const Key('kpi_tickets_auditoria'),
            valor: '${_resumen.ticketsPorAuditar}',
            etiqueta: 'Tickets Auditoría',
            icono: Icons.receipt_long_rounded,
            color: AppColors.warning,
            destacadoAmbar: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKpiItem(
            key: const Key('kpi_unidades_flota'),
            valor: '${_resumen.unidadesFlota}',
            etiqueta: 'Unidades Flota',
            icono: Icons.directions_bus_filled_rounded,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiItem({
    required Key key,
    required String valor,
    required String etiqueta,
    required IconData icono,
    required Color color,
    bool destacadoAmbar = false,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: destacadoAmbar
            ? AppColors.warning.withValues(alpha: 0.12)
            : AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: destacadoAmbar
              ? AppColors.warning.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            valor,
            style: TextStyle(
              color: destacadoAmbar ? AppColors.warning : AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            etiqueta,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaModulo({
    required Key key,
    required IconData icono,
    required Color colorIcono,
    required String titulo,
    required String subtitulo,
    required String codigoDestino,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorIcono.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: colorIcono, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
