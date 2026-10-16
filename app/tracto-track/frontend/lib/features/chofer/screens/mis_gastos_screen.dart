import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/gasto_model.dart';
import '../../../shared/widgets/status_badge.dart';
import '../widgets/chofer_bottom_nav_bar.dart';

/**
 * C-05 · Bitácora de Gastos – Mis Gastos (RF-02)
 * 
 * Historial de los gastos documentados en ruta, con el total acumulado
 * y el estatus de sincronización y de auditoría de cada comprobante.
 */
class MisGastosScreen extends StatefulWidget {
  const MisGastosScreen({super.key});

  @override
  State<MisGastosScreen> createState() => _MisGastosScreenState();
}

class _MisGastosScreenState extends State<MisGastosScreen> {
  final ApiClient _apiClient = ApiClient();
  List<GastoModel> _gastos = [];
  double _totalImporte = 0.0;
  int _totalComprobantes = 0;
  bool _cargando = true;
  bool _sincronizando = false;

  @override
  void initState() {
    super.initState();
    _apiClient.pendientesNotifier.addListener(_onPendientesUpdate);
    _cargarGastos();
  }

  @override
  void dispose() {
    _apiClient.pendientesNotifier.removeListener(_onPendientesUpdate);
    super.dispose();
  }

  void _onPendientesUpdate() {
    if (mounted) {
      _cargarGastos(sincronizar: false);
    }
  }

  Future<void> _cargarGastos({bool sincronizar = false, bool mostrarMensaje = false}) async {
    setState(() => _cargando = true);
    try {
      if (sincronizar && _apiClient.isOnline) {
        final resSync = await _apiClient.sincronizarPendientes();
        if (mounted && resSync.totalSincronizados > 0 && mostrarMensaje) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${resSync.totalSincronizados} comprobante(s) sincronizado(s) exitosamente (US-05)'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      final res = await _apiClient.obtenerGastos();
      final list = (res['gastos'] as List? ?? [])
          .map((e) => GastoModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = (res['totalImporte'] as num?)?.toDouble() ?? 0.0;
      final count = res['totalComprobantes'] as int? ?? list.length;

      setState(() {
        _gastos = list;
        _totalImporte = total;
        _totalComprobantes = count;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _sincronizarAhora() async {
    if (_sincronizando) return;
    setState(() => _sincronizando = true);
    try {
      final resSync = await _apiClient.sincronizarPendientes(forzar: true);
      if (mounted) {
        setState(() => _sincronizando = false);
        if (resSync.totalSincronizados > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${resSync.totalSincronizados} comprobante(s) sincronizado(s) con la base de datos (US-05)'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (resSync.totalErrores > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al sincronizar: ${resSync.errores.firstOrNull ?? "Fallo de conexión"}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Todos los comprobantes ya se encuentran sincronizados'),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 2),
            ),
          );
        }
        await _cargarGastos(sincronizar: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sincronizando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de sincronización: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _filtro = 'todos'; // 'todos', 'pendientes', 'sincronizados'

  List<GastoModel> get _gastosFiltrados {
    switch (_filtro) {
      case 'pendientes':
        return _gastos.where((g) => g.isPendiente).toList();
      case 'sincronizados':
        return _gastos.where((g) => g.isSincronizado).toList();
      default:
        return _gastos;
    }
  }

  int get _pendientesCount => _gastos.where((g) => g.isPendiente).length;
  int get _sincronizadosCount => _gastos.where((g) => g.isSincronizado).length;

  @override
  Widget build(BuildContext context) {
    final listaMostrada = _gastosFiltrados;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        title: const Text(
          'Bitácora de Gastos',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            key: const Key('btn_refresh_mis_gastos'),
            icon: _sincronizando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.sync, color: AppColors.online),
            tooltip: 'Sincronizar comprobantes',
            onPressed: _sincronizando ? null : _sincronizarAhora,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _cargarGastos(sincronizar: true, mostrarMensaje: true),
        color: AppTheme.primaryBlue,
        child: Column(
          children: [
            // Alerta de pendientes si hay registros offline
            _buildBannerPendientes(),

            // Barra de Total Acumulado
            _buildBarraTotal(),

            // Filtros segmentados (Todos / Pendientes offline / Sincronizados)
            _buildFiltros(),

            // Lista de Comprobantes
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                    )
                  : listaMostrada.isEmpty
                      ? Center(
                          child: Text(
                            _filtro == 'pendientes'
                                ? 'No hay comprobantes pendientes de sincronización'
                                : _filtro == 'sincronizados'
                                    ? 'No hay comprobantes sincronizados'
                                    : 'No se han registrado comprobantes en la bitácora',
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: listaMostrada.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final gasto = listaMostrada[index];
                            return _buildTarjetaGasto(gasto);
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ChoferBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildBannerPendientes() {
    if (_pendientesCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$_pendientesCount ticket${_pendientesCount > 1 ? "s" : ""} pendiente${_pendientesCount > 1 ? "s" : ""} de sincronización',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton.icon(
            key: const Key('btn_sync_pendientes_banner'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              elevation: 0,
            ),
            onPressed: _sincronizando ? null : _sincronizarAhora,
            icon: _sincronizando
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.sync, size: 14),
            label: const Text('Sincronizar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.surfaceDark,
      child: Row(
        children: [
          _buildChipFiltro('todos', 'Todos (${_gastos.length})'),
          const SizedBox(width: 8),
          _buildChipFiltro(
            'pendientes',
            'Pendientes ($_pendientesCount)',
            esAdvertencia: _pendientesCount > 0,
          ),
          const SizedBox(width: 8),
          _buildChipFiltro('sincronizados', 'Sincronizados ($_sincronizadosCount)'),
        ],
      ),
    );
  }

  Widget _buildChipFiltro(String keyFiltro, String label, {bool esAdvertencia = false}) {
    final seleccionado = _filtro == keyFiltro;
    final colorActivo = esAdvertencia ? AppColors.warning : AppTheme.primaryBlue;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _filtro = keyFiltro),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: seleccionado ? colorActivo : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado ? colorActivo : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: seleccionado
                ? (esAdvertencia ? Colors.black : Colors.white)
                : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBarraTotal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EVIDENCIAS DOCUMENTADAS EN RUTA',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_totalComprobantes comprobantes',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'TOTAL ACUMULADO',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${_totalImporte.toStringAsFixed(2)} MXN',
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaGasto(GastoModel gasto) {
    IconData icon;
    Color iconColor;
    switch (gasto.tipo.toLowerCase()) {
      case 'diesel':
      case 'diésel':
        icon = Icons.local_gas_station;
        iconColor = AppTheme.accentYellow;
        break;
      case 'fluidos':
        icon = Icons.oil_barrel;
        iconColor = AppTheme.primaryBlue;
        break;
      default:
        icon = Icons.restaurant;
        iconColor = AppTheme.accentGreen;
    }

    final esAprobado = gasto.estadoAuditoria == 'aprobado';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: Tipo, Folio y Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gasto.tipoLegible,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        gasto.folio,
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${gasto.monto.toStringAsFixed(2)} MXN',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  StatusBadge(
                    label: esAprobado ? 'APROBADO' : 'PENDIENTE AUDITORÍA',
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20, color: Colors.white12),

          // Fila inferior: Proveedor, Odómetro y Sincronizado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gasto.proveedor,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (gasto.odometro != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Odómetro: ${gasto.odometro!.toStringAsFixed(0)} KM',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              StatusBadge(
                label: gasto.isPendiente ? 'PENDIENTE DE SINCRONIZACIÓN' : 'SINCRONIZADO',
                showIcon: true,
              ),

            ],
          ),
        ],
      ),
    );
  }
}
