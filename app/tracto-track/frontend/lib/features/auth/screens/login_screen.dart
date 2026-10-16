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
              // Barra de estado con configuración de IP de servidor e indicador ONLINE
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    key: const Key('btn_config_servidor'),
                    icon: const Icon(Icons.settings_ethernet, color: AppColors.textSecondary, size: 22),
                    tooltip: 'Configurar IP del Servidor Backend',
                    onPressed: _abrirConfiguracionServidor,
                  ),
                  const OnlineIndicator(isOnline: true),
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

  Future<void> _abrirConfiguracionServidor() async {
    final ipController = TextEditingController(text: ApiClient().baseUrl);
    bool probando = false;
    String? estadoPrueba;
    bool pruebaExitosa = false;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.wifi, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Servidor Backend (API)',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dirección IP de tu laptop para pruebas en red local:',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ipController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.background,
                        hintText: 'http://172.16.33.178:3000',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.link, color: AppColors.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Opciones rápidas según tu conexión:',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildPresetChip('http://172.16.33.178:3000', 'Red Local / Wi-Fi', ipController, setDialogState),
                        _buildPresetChip('http://192.168.137.1:3000', 'Hotspot Laptop', ipController, setDialogState),
                        _buildPresetChip('http://127.0.0.1:3000', 'USB (adb reverse)', ipController, setDialogState),
                        _buildPresetChip('http://10.0.2.2:3000', 'Emulador', ipController, setDialogState),
                      ],
                    ),
                    if (estadoPrueba != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: (pruebaExitosa ? AppColors.success : AppColors.error).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: pruebaExitosa ? AppColors.success : AppColors.error),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              pruebaExitosa ? Icons.check_circle : Icons.error_outline,
                              color: pruebaExitosa ? AppColors.success : AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                estadoPrueba!,
                                style: TextStyle(
                                  color: pruebaExitosa ? AppColors.success : AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: probando
                      ? null
                      : () async {
                          setDialogState(() {
                            probando = true;
                            estadoPrueba = 'Probando conexión con el servidor...';
                            pruebaExitosa = false;
                          });
                          final ok = await ApiClient().checkHealth(ipController.text.trim());
                          setDialogState(() {
                            probando = false;
                            pruebaExitosa = ok;
                            estadoPrueba = ok
                                ? '¡Conexión exitosa con Tracto Trak API (200 OK)!'
                                : 'No se pudo conectar. Verifica que npm run dev esté corriendo.';
                          });
                        },
                  child: probando
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Probar Conexión', style: TextStyle(color: AppColors.accent)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () async {
                    final nuevaUrl = ipController.text.trim();
                    if (nuevaUrl.isNotEmpty) {
                      await ApiClient().updateBaseUrl(nuevaUrl);
                      if (context.mounted) {
                        Navigator.of(dialogCtx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Servidor configurado: $nuevaUrl'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Guardar y Usar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPresetChip(String url, String label, TextEditingController controller, StateSetter setDialogState) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: AppColors.surfaceVariant,
      onPressed: () {
        setDialogState(() {
          controller.text = url;
        });
      },
    );
  }
}
