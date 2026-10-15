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
  final IconData? icon;
  final bool showIcon;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.showIcon = false,
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

  IconData? get _resolvedIcon {
    if (icon != null) return icon;
    if (!showIcon) return null;
    final lower = label.toLowerCase();
    if (lower.contains('pendiente')) {
      return Icons.cloud_off;
    } else if (lower.contains('sincronizado')) {
      return Icons.cloud_done;
    } else if (lower.contains('aprobado')) {
      return Icons.check_circle_outline;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _resolvedColor;
    final badgeIcon = _resolvedIcon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeIcon != null) ...[
            Icon(badgeIcon, size: 13, color: badgeColor),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
