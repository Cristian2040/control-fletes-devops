import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';

/**
 * Barra de navegación inferior para el módulo Chofer (C-02, C-05, C-06).
 * Secciones:
 *   - 0: Ruta (C-02)
 *   - 1: Mis Gastos (C-05)
 *   - 2: Mi Perfil (C-06)
 */
class ChoferBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const ChoferBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.choferHome);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.choferBitacora);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.choferPerfil);
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
            color: Colors.white.withOpacity(0.08),
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
        selectedFontSize: 12,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.navigation_outlined),
            activeIcon: Icon(Icons.navigation),
            label: 'Ruta',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Mis Gastos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Mi Perfil',
          ),
        ],
      ),
    );
  }
}
