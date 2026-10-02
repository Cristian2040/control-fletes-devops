/// Pantalla placeholder para las pantallas del módulo Chofer
/// que aún no se implementan en el Sprint actual.
///
/// Muestra claramente el código de pantalla, nombre y Sprint pendiente.
library;

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/online_indicator.dart';

class ChoferPlaceholderScreen extends StatelessWidget {
  final String codigo;
  final String nombre;
  final int sprint;

  const ChoferPlaceholderScreen({
    super.key,
    required this.codigo,
    required this.nombre,
    required this.sprint,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(codigo),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: OnlineIndicator(isOnline: true),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.construction,
                  size: 40,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pendiente: $codigo, Sprint $sprint',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                nombre,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Regresar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
