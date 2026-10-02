/// Badge de estado reutilizable.
///
/// Muestra una etiqueta con color semántico según el estado:
/// - SINCRONIZADO / APROBADO → verde
/// - PENDIENTE → ámbar
/// - EN RUTA → azul
/// - RECHAZADO → rojo
library;

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
  });

  /// Determina el color semántico automáticamente según la etiqueta.
  Color get _resolvedColor {
    if (color != null) return color!;

    final lower = label.toLowerCase();
    if (lower.contains('sincronizado') || lower.contains('aprobado') || lower.contains('activo')) {
      return AppColors.success;
    } else if (lower.contains('pendiente')) {
      return AppColors.warning;
    } else if (lower.contains('ruta') || lower.contains('en_ruta')) {
      return AppColors.info;
    } else if (lower.contains('rechazado') || lower.contains('inactivo')) {
      return AppColors.error;
    } else if (lower.contains('disponible')) {
      return AppColors.success;
    } else if (lower.contains('taller')) {
      return AppColors.warning;
    }
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _resolvedColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
