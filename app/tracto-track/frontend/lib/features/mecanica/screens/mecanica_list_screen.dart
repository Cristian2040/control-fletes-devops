/// M-01 · Listado de Órdenes de Mecánica.
///
/// Pantalla principal del módulo de Mecánica que muestra todas las
/// órdenes de reparación registradas, con filtro por estado y prioridad.
///
/// Navegación: AdminHome → M-01 → M-02 (detalle) / M-03 (nueva orden)
library;

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/online_indicator.dart';
import '../../../shared/widgets/status_badge.dart';

class MecanicaListScreen extends StatefulWidget {
  const MecanicaListScreen({super.key});

  @override
  State<MecanicaListScreen> createState() => _MecanicaListScreenState();
}

class _MecanicaListScreenState extends State<MecanicaListScreen> {
  String _filtroEstado = 'todas';

  // Datos de demostración (se conectará a la API en el sprint correspondiente)
  final List<Map<String, dynamic>> _ordenesMock = [
    {
      'folio': 'OM-0001',
      'placas': 'NLZ-8823-A',
      'descripcion': 'Fuga de aceite en el motor principal',
      'prioridad': 'alta',
      'estado': 'en_reparacion',
      'tiempoEstimado': '16 hrs',
      'mecanico': 'Roberto García',
      'piezas': 3,
    },
    {
      'folio': 'OM-0002',
      'placas': 'JKL-4421-B',
      'descripcion': 'Neumáticos delanteros desgastados',
      'prioridad': 'media',
      'estado': 'reportada',
      'tiempoEstimado': '4 hrs',
      'mecanico': 'Sin asignar',
      'piezas': 2,
    },
    {
      'folio': 'OM-0003',
      'placas': 'MNO-7712-C',
      'descripcion': 'Cambio de aceite y filtros programado',
      'prioridad': 'baja',
      'estado': 'completada',
      'tiempoEstimado': '2 hrs',
      'mecanico': 'Luis Hernández',
      'piezas': 4,
    },
  ];

  List<Map<String, dynamic>> get _ordenesFiltradas {
    if (_filtroEstado == 'todas') return _ordenesMock;
    return _ordenesMock.where((o) => o['estado'] == _filtroEstado).toList();
  }

  Color _prioridadColor(String prioridad) {
    switch (prioridad) {
      case 'alta':
        return AppColors.error;
      case 'media':
        return AppColors.warning;
      case 'baja':
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _estadoIcon(String estado) {
    switch (estado) {
      case 'reportada':
        return Icons.report_problem_outlined;
      case 'en_diagnostico':
        return Icons.search;
      case 'en_reparacion':
        return Icons.build_outlined;
      case 'completada':
        return Icons.check_circle_outline;
      case 'cancelada':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Órdenes de Mecánica'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: OnlineIndicator(isOnline: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros de estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('Todas', 'todas'),
                const SizedBox(width: 8),
                _buildFilterChip('Reportadas', 'reportada'),
                const SizedBox(width: 8),
                _buildFilterChip('En reparación', 'en_reparacion'),
                const SizedBox(width: 8),
                _buildFilterChip('Completadas', 'completada'),
              ],
            ),
          ),

          // Resumen rápido
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatCard('Activas', '2', AppColors.warning),
                const SizedBox(width: 12),
                _buildStatCard('En taller', '1', AppColors.info),
                const SizedBox(width: 12),
                _buildStatCard('Completadas', '1', AppColors.success),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Lista de órdenes
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _ordenesFiltradas.length,
              itemBuilder: (context, index) {
                final orden = _ordenesFiltradas[index];
                return _buildOrdenCard(orden);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.mecanicaForm);
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nueva Orden', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filtroEstado == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _filtroEstado = value),
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdenCard(Map<String, dynamic> orden) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.mecanicaDetalle);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Folio + Prioridad
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _estadoIcon(orden['estado']),
                        color: _prioridadColor(orden['prioridad']),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        orden['folio'],
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(label: orden['estado'].replaceAll('_', ' ')),
                ],
              ),

              const SizedBox(height: 10),

              // Placas
              Row(
                children: [
                  const Icon(Icons.local_shipping_outlined,
                      color: AppColors.textMuted, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Unidad: ${orden['placas']}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Descripción
              Text(
                orden['descripcion'],
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 10),

              // Detalles: Tiempo estimado | Piezas | Mecánico
              Row(
                children: [
                  Icon(Icons.access_time, color: AppColors.textMuted, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    orden['tiempoEstimado'],
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.settings_outlined,
                      color: AppColors.textMuted, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${orden['piezas']} piezas',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    orden['mecanico'],
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
