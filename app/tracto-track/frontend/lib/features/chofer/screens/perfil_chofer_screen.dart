import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/status_badge.dart';
import '../widgets/chofer_bottom_nav_bar.dart';

/**
 * C-06 · Perfil de Operador (Cierre de Sesión y Asignación)
 * 
 * Muestra los datos del operador y su asignación vigente,
 * y permite cerrar la sesión activa.
 */
class PerfilChoferScreen extends StatelessWidget {
  const PerfilChoferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final user = apiClient.currentUser;
    final nombre = user?['nombre'] ?? 'Jorge González';
    final iniciales = nombre.toString().split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        title: const Text(
          'Perfil de Operador',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Tarjeta de Identidad
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                    child: Text(
                      iniciales,
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nombre,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Licencia Federal: LF-9928172',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const StatusBadge(
                    label: 'ESTADO ACTIVO',
                  ),

                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Tarjeta Datos de la Asignación
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DATOS DE LA ASIGNACIÓN',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 20, color: Colors.white12),
                  _buildFilaDato('Unidad asignada', 'Kenworth T680 · NLZ-8823-A'),
                  const SizedBox(height: 12),
                  _buildFilaDato('Empresa transportista', 'Transportes Flores S.A.'),
                  const SizedBox(height: 12),
                  _buildFilaDato('Ruta activa', 'Monterrey → CDMX'),
                  const SizedBox(height: 12),
                  _buildFilaDato('Cliente pactado', 'CEMEX S.A. de C.V.'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 3. Botón destructivo Cerrar Sesión (Rojo)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                key: const Key('btn_cerrar_sesion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: () async {
                  await apiClient.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, size: 20),
                label: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ChoferBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildFilaDato(String label, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        Text(
          valor,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
