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

  @override
  void initState() {
    super.initState();
    _cargarGastos();
  }

  Future<void> _cargarGastos() async {
    setState(() => _cargando = true);
    try {
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

  @override
  Widget build(BuildContext context) {
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
      ),
      body: RefreshIndicator(
        onRefresh: _cargarGastos,
        color: AppTheme.primaryBlue,
        child: Column(
          children: [
            // Barra de Total Acumulado
            _buildBarraTotal(),

            // Lista de Comprobantes
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                    )
                  : _gastos.isEmpty
                      ? const Center(
                          child: Text(
                            'No se han registrado comprobantes en la bitácora',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _gastos.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final gasto = _gastos[index];
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
              const StatusBadge(
                label: 'SINCRONIZADO',
              ),

            ],
          ),
        ],
      ),
    );
  }
}
