/// C-01 / A-01 · Pantalla de inicio de sesión (Login).
///
/// Pantalla unificada con selector de rol:
///   - "Chofer En Ruta" → C-01 (destino: C-02)
///   - "Dueño De Flota" → A-01 (destino: A-02)
///
/// Referencia: RNF-04
/// Sprint 1: esqueleto visual. Sprint 2: lógica de autenticación completa.
library;

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/online_indicator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// 0 = Chofer En Ruta, 1 = Dueño De Flota
  int _rolSeleccionado = 0;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // Barra de estado con indicador ONLINE
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OnlineIndicator(isOnline: true),
                ],
              ),

              const SizedBox(height: 32),

              // Logotipo TT
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Center(
                  child: Text(
                    'TT',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Nombre de la app
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                AppConstants.appSubtitle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 32),

              // Selector segmentado "Rol de acceso al sistema"
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rol de acceso al sistema',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildRoleTab('Chofer En Ruta', 0),
                    _buildRoleTab('Dueño De Flota', 1),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Campo: Identificador de Usuario
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Identificador de Usuario',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),

              const SizedBox(height: 16),

              // Campo: Contraseña o Clave de Acceso
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña o Clave de Acceso',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),

              const SizedBox(height: 28),

              // Botón principal "Acceder al Sistema"
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onAcceder,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Acceder al Sistema'),
                ),
              ),

              const SizedBox(height: 20),

              // Enlace a Pantalla de Registro
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿No tienes una cuenta?',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.register);
                    },
                    child: const Text(
                      'Regístrate aquí',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 100),

              // Leyenda de Version
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.textMuted, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'Versión Beta',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye una pestaña del selector de rol.
  Widget _buildRoleTab(String label, int index) {
    final isSelected = _rolSeleccionado == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _rolSeleccionado = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Acción del botón "Acceder al Sistema".
  /// Sprint 2: Autenticación real con JWT mediante ApiClient.
  Future<void> _onAcceder() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa tu identificador de usuario y contraseña'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiClient().login(username, password);

      if (!mounted) return;
      setState(() => _isLoading = false);

      final userRole = res['usuario']?['rol'] ?? (_rolSeleccionado == 0 ? 'operador' : 'administrador');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Bienvenido, ${res['usuario']?['nombre'] ?? username}!'),
          backgroundColor: AppColors.primary,
        ),
      );

      if (userRole == 'operador') {
        Navigator.pushReplacementNamed(context, AppRoutes.choferHome);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Si falla la red o desarrollo offline, permitir navegación directa en fallback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de autenticación: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: 'Modo Demo',
            textColor: Colors.white,
            onPressed: () {
              if (_rolSeleccionado == 0) {
                Navigator.pushReplacementNamed(context, AppRoutes.choferHome);
              } else {
                Navigator.pushReplacementNamed(context, AppRoutes.adminHome);
              }
            },
          ),
        ),
      );
    }
  }
}
