/// Widget indicador de estado de conexión ONLINE/OFFLINE.
///
/// Visible en la barra superior de todas las pantallas (documento de interfaces,
/// sección "Estado de conexión siempre visible").
///
/// Color semántico:
/// - Verde (ONLINE): conectado a la red
/// - Rojo (OFFLINE): sin conexión
library;

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class OnlineIndicator extends StatelessWidget {
  /// Si es true, muestra ONLINE (verde). Si es false, OFFLINE (rojo).
  /// En Sprint 4 se conectará al servicio de detección de conectividad real.
  final bool isOnline;

  const OnlineIndicator({super.key, this.isOnline = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline
            ? AppColors.online.withValues(alpha: 0.15)
            : AppColors.offline.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline ? AppColors.online : AppColors.offline,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? AppColors.online : AppColors.offline,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(
              color: isOnline ? AppColors.online : AppColors.offline,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
