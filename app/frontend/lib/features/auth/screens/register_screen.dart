/// Pantalla de Registro de Usuario (RegisterScreen).
///
/// Permite el registro de nuevos choferes u operadores y administradores
/// en la plataforma Tracto Trak (SPF).
library;

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/online_indicator.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  /// 0 = Chofer En Ruta (operador), 1 = Dueño De Flota (administrador)
  int _rolSeleccionado = 0;

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: OnlineIndicator(isOnline: true),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Encabezado con Isotipo TT
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          'TT',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crear Cuenta',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Registro de Usuario SPF',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Selector segmentado de Rol
                const Text(
                  'Tipo de cuenta a registrar',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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

                // Campo: Nombre Completo
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    hintText: 'Ej. Juan Pérez López',
                    prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textMuted),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa tu nombre completo';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Campo: Identificador de Usuario
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Identificador de Usuario',
                    hintText: 'Ej. chofer_juan',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un nombre de usuario';
                    }
                    if (value.trim().length < 4) {
                      return 'El usuario debe tener al menos 4 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Campo: Correo Electrónico
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico (Opcional)',
                    hintText: 'ejemplo@tractotrak.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),

                const SizedBox(height: 16),

                // Campo: Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa una contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Campo: Confirmar Contraseña
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    prefixIcon: const Icon(Icons.lock_reset, color: AppColors.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirma tu contraseña';
                    }
                    if (value != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 28),

                // Botón principal "Registrar Cuenta"
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onRegistrar,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Registrar Cuenta'),
                  ),
                ),

                const SizedBox(height: 20),

                // Enlace "¿Ya tienes cuenta? Inicia sesión"
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿Ya tienes una cuenta?',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Inicia sesión aquí',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
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

  /// Procesa el registro del usuario con ApiClient en la API REST.
  Future<void> _onRegistrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final rolNombre = _rolSeleccionado == 0 ? 'operador' : 'administrador';

    try {
      final res = await ApiClient().register(
        nombre: _nombreController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        rol: rolNombre,
        email: _emailController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Cuenta de ${res['usuario']?['nombre'] ?? "Usuario"} creada exitosamente!'),
          backgroundColor: AppColors.primary,
        ),
      );

      if (rolNombre == 'operador') {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.choferHome, (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.adminHome, (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.error,
          action: SnackBarAction(
            label: 'Modo Demo',
            textColor: Colors.white,
            onPressed: () {
              if (_rolSeleccionado == 0) {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.choferHome, (route) => false);
              } else {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.adminHome, (route) => false);
              }
            },
          ),
        ),
      );
    }
  }
}
