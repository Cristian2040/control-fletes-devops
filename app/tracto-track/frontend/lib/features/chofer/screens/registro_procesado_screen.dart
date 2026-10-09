import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/gasto_model.dart';
import '../../../shared/widgets/status_badge.dart';

/**
 * C-04 · Registro Procesado – Evidencia Guardada (RF-02)
 * 
 * Confirma al chofer que su gasto fue guardado y transmitido,
 * mostrando el folio asignado (#TT-######) y el resumen del registro.
 * Permite capturar otro ticket o volver a la ruta activa.
 */
class RegistroProcesadoScreen extends StatelessWidget {
  final GastoModel? gasto;

  const RegistroProcesadoScreen({
    super.key,
    this.gasto,
  });

  @override
  Widget build(BuildContext context) {
    // Si no se pasó por constructor, intentar leer de arguments
    final gastoActual = gasto ?? (ModalRoute.of(context)?.settings.arguments as GastoModel?);

    final folio = gastoActual?.folio ?? '#TT-000142';
    final monto = gastoActual?.monto ?? 4850.0;
    final tipo = gastoActual?.tipoLegible ?? 'Diésel';
    final odometro = gastoActual?.odometro != null
        ? '${gastoActual!.odometro!.toStringAsFixed(0)} KM'
        : 'N/A';
    final proveedor = gastoActual?.proveedor ?? 'OXXO GAS Saltillo';

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Evidencia Guardada',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Ícono de confirmación y mensaje
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentGreen, width: 2),
                ),
                child: const Icon(
                  Icons.check,
                  color: AppTheme.accentGreen,
                  size: 46,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Registro Procesado',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Transmitido a la base de datos central en MongoDB',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // Tarjeta de resumen
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'FOLIO ASIGNADO',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const StatusBadge(
                        label: 'SINCRONIZADO',
                      ),

                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    folio,
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Divider(height: 28, color: Colors.white12),

                  _buildFilaResumen('Monto declarado', '\$${monto.toStringAsFixed(2)} MXN', esDestacado: true),
                  const SizedBox(height: 12),
                  _buildFilaResumen('Tipo de insumo', tipo),
                  const SizedBox(height: 12),
                  _buildFilaResumen('Lectura odómetro', odometro),
                  const SizedBox(height: 12),
                  _buildFilaResumen('Proveedor / Estación', proveedor),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Botón Secundario: Capturar Otro Ticket
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                key: const Key('btn_capturar_otro'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.choferCapturaGasto);
                },
                icon: const Icon(Icons.add_a_photo, size: 20),
                label: const Text(
                  'Capturar Otro Ticket',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Botón Principal: Regresar a Ruta Activa
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                key: const Key('btn_regresar_ruta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.choferHome);
                },
                icon: const Icon(Icons.navigation, size: 20),
                label: const Text(
                  'Regresar a Ruta Activa',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaResumen(String label, String valor, {bool esDestacado = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            color: esDestacado ? AppTheme.accentGreen : AppTheme.textPrimary,
            fontSize: esDestacado ? 15 : 13,
            fontWeight: esDestacado ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
