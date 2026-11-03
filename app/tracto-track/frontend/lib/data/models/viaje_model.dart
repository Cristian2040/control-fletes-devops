/// Modelos de Viajes / Despachos y Tablero de Control (Sprint 7)
///
/// Modela:
///   - TableroResumenModel (A-02 · Panel de Control, RNF-01)
///   - ViajeModel (A-03 · Módulo de Viajes y Fletes, A-04 · Asignación de Viaje, RF-05, US-07)
library;

/// Modelo de Resumen KPI del Tablero de Control (A-02)
class TableroResumenModel {
  final String empresa;
  final String baseOperativa;
  final int viajesActivos;
  final int ticketsPorAuditar;
  final int unidadesFlota;

  const TableroResumenModel({
    this.empresa = 'Transportes Flores S.A.',
    this.baseOperativa = 'Base Monterrey',
    required this.viajesActivos,
    required this.ticketsPorAuditar,
    required this.unidadesFlota,
  });

  factory TableroResumenModel.fromJson(Map<String, dynamic> json) {
    return TableroResumenModel(
      empresa: json['empresa'] as String? ?? 'Transportes Flores S.A.',
      baseOperativa: json['base'] as String? ?? 'Base Monterrey',
      viajesActivos: (json['viajesActivos'] as num?)?.toInt() ?? 0,
      ticketsPorAuditar: (json['ticketsPorAuditar'] as num?)?.toInt() ?? 0,
      unidadesFlota: (json['unidadesFlota'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Modelo de Orden de Viaje / Despacho de Flete (A-03, A-04)
class ViajeModel {
  final String id;
  final String folio; // Ej. FL-101
  final String cliente;
  final String origen;
  final String destino;
  final String ruta;
  final String camion;
  final String placasCamion;
  final String chofer;
  final double tarifaPactada;
  final double anticipoEntregado;
  final String estado; // 'en_ruta', 'completado', 'liquidado', 'cancelado'

  const ViajeModel({
    required this.id,
    required this.folio,
    required this.cliente,
    required this.origen,
    required this.destino,
    required this.ruta,
    required this.camion,
    this.placasCamion = 'NLZ-8823-A',
    required this.chofer,
    required this.tarifaPactada,
    this.anticipoEntregado = 0.0,
    this.estado = 'en_ruta',
  });

  String get estadoBadge {
    switch (estado.toLowerCase()) {
      case 'completado':
        return 'COMPLETADO';
      case 'liquidado':
        return 'LIQUIDADO';
      case 'cancelado':
        return 'CANCELADO';
      default:
        return 'EN RUTA';
    }
  }

  factory ViajeModel.fromJson(Map<String, dynamic> json) {
    final origenVal = json['origen'] as String? ?? '';
    final destinoVal = json['destino'] as String? ?? '';
    final rutaVal = (json['ruta'] as String?)?.isNotEmpty == true
        ? json['ruta'] as String
        : '$origenVal → $destinoVal';

    return ViajeModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      folio: json['folio'] as String? ?? 'FL-101',
      cliente: json['cliente'] as String? ?? '',
      origen: origenVal,
      destino: destinoVal,
      ruta: rutaVal,
      camion: json['camion'] as String? ?? '',
      placasCamion: json['placasCamion'] as String? ?? 'NLZ-8823-A',
      chofer: json['chofer'] as String? ?? '',
      tarifaPactada: (json['tarifaPactada'] as num?)?.toDouble() ?? 0.0,
      anticipoEntregado: (json['anticipoEntregado'] as num?)?.toDouble() ?? 0.0,
      estado: json['estado'] as String? ?? 'en_ruta',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'folio': folio,
        'cliente': cliente,
        'origen': origen,
        'destino': destino,
        'ruta': ruta,
        'camion': camion,
        'placasCamion': placasCamion,
        'chofer': chofer,
        'tarifaPactada': tarifaPactada,
        'anticipoEntregado': anticipoEntregado,
        'estado': estado,
      };
}
