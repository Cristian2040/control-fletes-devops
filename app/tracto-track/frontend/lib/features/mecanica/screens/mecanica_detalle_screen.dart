/// M-02 · Detalle de Orden de Mecánica.
///
/// Muestra toda la información de una orden de reparación:
/// datos de la unidad, falla reportada, diagnóstico, piezas necesarias,
/// tiempos, costos y estado actual.
///
/// Navegación: M-01 → M-02
library;

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/online_indicator.dart';
import '../../../shared/widgets/status_badge.dart';

class MecanicaDetalleScreen extends StatelessWidget {
  const MecanicaDetalleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos de demostración (se conectará a la API en sprint correspondiente)
    return Scaffold(
      appBar: AppBar(
        title: const Text('OM-0001'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: OnlineIndicator(isOnline: true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado y prioridad
            Row(
              children: [
                const StatusBadge(label: 'en reparacion'),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.error, width: 1),
                  ),
                  child: const Text(
                    'PRIORIDAD ALTA',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Correctivo',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Información de la unidad
            _buildSectionTitle('Unidad afectada', Icons.local_shipping_outlined),
            const SizedBox(height: 8),
            _buildInfoCard([
              _buildInfoRow('Placas', 'NLZ-8823-A'),
              _buildInfoRow('Unidad', 'Kenworth T680 (2021)'),
              _buildInfoRow('Km al ingreso', '125,340 km'),
              _buildInfoRow('Fecha ingreso', '06/Oct/2026 09:30'),
            ]),

            const SizedBox(height: 20),

            // Falla reportada
            _buildSectionTitle('Falla reportada', Icons.report_problem_outlined),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Fuga de aceite en el motor principal. Se detectó pérdida de presión en el sistema de lubricación durante la última ruta Monterrey–CDMX.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Diagnóstico
            _buildSectionTitle('Diagnóstico', Icons.search),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Junta de culata dañada y empaque de cárter con desgaste. Se requiere reemplazo completo de ambas piezas y verificación del sistema de enfriamiento.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tiempos
            _buildSectionTitle('Tiempos', Icons.access_time),
            const SizedBox(height: 8),
            _buildInfoCard([
              _buildInfoRow('Tiempo estimado', '16 horas'),
              _buildInfoRow('Fecha estimada entrega', '08/Oct/2026'),
              _buildInfoRow('Mecánico asignado', 'Roberto García'),
            ]),

            const SizedBox(height: 20),

            // Piezas / Refacciones
            _buildSectionTitle('Piezas requeridas', Icons.settings_outlined),
            const SizedBox(height: 8),
            _buildPiezaItem('Junta de culata', 1, 1500, 'instalada'),
            const SizedBox(height: 8),
            _buildPiezaItem('Empaque de cárter', 2, 350, 'recibida'),
            const SizedBox(height: 8),
            _buildPiezaItem('Tornillería grado 8', 1, 220, 'pendiente'),

            const SizedBox(height: 20),

            // Costos
            _buildSectionTitle('Costos', Icons.attach_money),
            const SizedBox(height: 8),
            _buildInfoCard([
              _buildInfoRow('Costo piezas', '\$2,420.00'),
              _buildInfoRow('Mano de obra', '\$3,500.00'),
              _buildInfoRow('Costo estimado total', '\$5,920.00'),
            ]),

            const SizedBox(height: 20),

            // Notas
            _buildSectionTitle('Notas', Icons.note_alt_outlined),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Revisar también mangueras del sistema de enfriamiento antes de liberar la unidad. El chofer reportó temperatura elevada en el último tramo.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Completar',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPiezaItem(
      String nombre, int cantidad, double costo, String estado) {
    Color estadoColor;
    switch (estado) {
      case 'instalada':
        estadoColor = AppColors.success;
        break;
      case 'recibida':
        estadoColor = AppColors.info;
        break;
      case 'solicitada':
        estadoColor = AppColors.warning;
        break;
      default:
        estadoColor = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: estadoColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: estadoColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.settings, color: estadoColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Cantidad: $cantidad  •  \$${costo.toStringAsFixed(0)} c/u',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(label: estado, color: estadoColor),
        ],
      ),
    );
  }
}
