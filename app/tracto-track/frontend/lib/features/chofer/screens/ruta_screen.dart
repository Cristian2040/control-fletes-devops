import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/gasto_model.dart';
import '../../../shared/widgets/online_indicator.dart';
import '../../../shared/widgets/status_badge.dart';
import '../widgets/chofer_bottom_nav_bar.dart';

/**
 * C-02 · Ruta – Inicio del chofer (RF-02)
 * 
 * Resume la asignación vigente (unidad, tramo y cliente),
 * muestra los comprobantes capturados recientemente y da acceso
 * directo al registro de un nuevo gasto (+ Registrar Gasto de Ruta).
 */
class RutaScreen extends StatefulWidget {
  const RutaScreen({super.key});

  @override
  State<RutaScreen> createState() => _RutaScreenState();
}

class _RutaScreenState extends State<RutaScreen> {
  final ApiClient _apiClient = ApiClient();
  List<GastoModel> _gastosRecientes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final res = await _apiClient.obtenerGastos();
      final list = (res['gastos'] as List? ?? [])
          .map((e) => GastoModel.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _gastosRecientes = list;
        _cargando = false;
      });
    } catch (_) {
      setState(() => _cargando = false);
    }
  }

  String get _nombreChofer {
    final user = _apiClient.currentUser;
    if (user != null && user['nombre'] != null && user['nombre'].toString().isNotEmpty) {
      return user['nombre'];
    }
    return 'Jorge González';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.primaryBlue, width: 1),
              ),
              child: const Text(
                'TT',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Tracto Trak',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: OnlineIndicator(isOnline: true),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        color: AppTheme.primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Encabezado Operador Asignado
              _buildHeaderOperador(),
              const SizedBox(height: 16),

              // 2. Tarjeta de Unidad y Asignación
              _buildTarjetaUnidad(),
              const SizedBox(height: 20),

              // 3. Botón Principal: + Registrar Gasto de Ruta (RF-02)
              _buildBotonRegistrarGasto(context),
              const SizedBox(height: 24),

              // 4. Lista: Comprobantes Recientes
              _buildSeccionComprobantesRecientes(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const ChoferBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildHeaderOperador() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
            child: Text(
              _nombreChofer.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join(),
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Operador asignado',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _nombreChofer,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const StatusBadge(
            label: 'EN RUTA',
          ),

        ],
      ),
    );
  }

  Widget _buildTarjetaUnidad() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_shipping, color: AppTheme.primaryBlue, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Kenworth T680 · 2021',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NLZ-8823-A',
                  style: TextStyle(
                    color: AppTheme.accentYellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white12),
          Row(
            children: [
              Expanded(
                child: _buildDatoUnidad(
                  icon: Icons.speed,
                  label: 'Kilometraje actual',
                  valor: '142,500 KM',
                ),
              ),
              Expanded(
                child: _buildDatoUnidad(
                  icon: Icons.alt_route,
                  label: 'Tramo activo',
                  valor: 'Monterrey → CDMX',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDatoUnidad(
            icon: Icons.business,
            label: 'Cliente asignado',
            valor: 'CEMEX S.A. de C.V.',
          ),
        ],
      ),
    );
  }

  Widget _buildDatoUnidad({
    required IconData icon,
    required String label,
    required String valor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                valor,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBotonRegistrarGasto(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        key: const Key('btn_registrar_gasto_c02'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: () async {
          await Navigator.of(context).pushNamed(AppRoutes.choferCapturaGasto);
          _cargarDatos();
        },
        icon: const Icon(Icons.add_a_photo, size: 20),
        label: const Text(
          '+ Registrar Gasto de Ruta (RF-02)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionComprobantesRecientes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Comprobantes Recientes',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_gastosRecientes.length} capturados',
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_cargando)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            ),
          )
        else if (_gastosRecientes.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 40, color: AppTheme.textSecondary.withOpacity(0.5)),
                const SizedBox(height: 8),
                const Text(
                  'No hay comprobantes recientes',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _gastosRecientes.take(5).length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final gasto = _gastosRecientes[index];
              return _buildTarjetaComprobante(gasto);
            },
          ),
      ],
    );
  }

  Widget _buildTarjetaComprobante(GastoModel gasto) {
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      gasto.tipoLegible,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      gasto.folio,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  gasto.proveedor,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${gasto.monto.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
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
