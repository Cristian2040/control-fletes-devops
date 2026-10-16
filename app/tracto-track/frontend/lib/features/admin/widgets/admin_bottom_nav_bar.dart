import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';

/**
 * Barra de navegación inferior para el módulo Administrador (A-02 a A-17).
 * Secciones:
 *   - 0: Tablero (A-02)
 *   - 1: Viajes (A-03)
 *   - 2: Catálogos (A-05 a A-08)
 *   - 3: Auditoría (A-13)
 *   - 4: Liquidación (A-15)
 *   - 5: Perfil (A-17)
 */
class AdminBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AdminBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.adminHome);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.adminViajes);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.adminCatalogos);
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(AppRoutes.adminAuditoria);
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.adminLiquidacionSelector);
        break;
      case 5:
        Navigator.of(context).pushReplacementNamed(AppRoutes.adminPerfil);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (idx) => _onTap(context, idx),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: AppTheme.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Tablero',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Viajes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_shared_outlined),
            activeIcon: Icon(Icons.folder_shared),
            label: 'Catálogos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fact_check_outlined),
            activeIcon: Icon(Icons.fact_check),
            label: 'Auditoría',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            activeIcon: Icon(Icons.payments),
            label: 'Liquidación',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts_outlined),
            activeIcon: Icon(Icons.manage_accounts),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
