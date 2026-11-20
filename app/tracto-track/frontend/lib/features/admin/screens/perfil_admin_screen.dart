import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/online_indicator.dart';
import '../widgets/admin_bottom_nav_bar.dart';

/// Pantalla A-17 · Perfil de Administrador – Supervisión General (RNF-02, RNF-04 — Sprint 9)
///
/// Muestra la cuenta del administrador con acceso total y los parámetros de
/// infraestructura del sistema, y permite cerrar la sesión:
///   - Encabezado "Supervisión General"
///   - Tarjeta de cuenta: iniciales ("HQ"), "Administrador de Flota", correo y etiqueta "ACCESO TOTAL"
///   - Tarjeta "Parámetros de infraestructura":
///       - Base de Datos: MongoDB NoSQL (RNF-02)
///       - API Backend: Node.js / Express
///       - Protocolo de Seguridad: HTTPS + JWT (RNF-04)
///   - Botón de acción destructiva "Cerrar Sesión de Administrador" (rojo) -> A-01
///   - Barra de navegación inferior de 6 secciones con "Perfil" activa
class PerfilAdminScreen extends StatelessWidget {
  const PerfilAdminScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    await ApiClient().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiClient().currentUser;
    final correo = (user?['email'] as String?)?.isNotEmpty == true
        ? user!['email'] as String
        : 'admin.flores@transportes.mx';

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Supervisión General',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  OnlineIndicator(isOnline: ApiClient().isOnline),
                ],
              ),
              const SizedBox(height: 20),
              _buildTarjetaCuenta(correo),
              const SizedBox(height: 18),
              _buildTarjetaInfraestructura(),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  key: const Key('btn_cerrar_sesion_admin'),
                  onPressed: () => _cerrarSesion(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.error.withValues(alpha: 0.14),
                    foregroundColor: AppColors.errorLight,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.6),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text(
                    'Cerrar Sesión de Administrador',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTarjetaCuenta(String correo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'HQ',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Administrador de Flota',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  correo,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 7,
                        color: AppTheme.primaryBlue,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'ACCESO TOTAL',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaInfraestructura() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PARÁMETROS DE INFRAESTRUCTURA',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          _buildFilaParametro('Base de Datos:', 'MongoDB NoSQL (RNF-02)'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Colors.white10),
          ),
          _buildFilaParametro('API Backend:', 'Node.js / Express'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Colors.white10),
          ),
          _buildFilaParametro('Protocolo de Seguridad:', 'HTTPS + JWT (RNF-04)'),
        ],
      ),
    );
  }

  Widget _buildFilaParametro(String etiqueta, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
