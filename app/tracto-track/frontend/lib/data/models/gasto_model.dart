/**
 * Modelo de datos: Gasto (RF-02, US-03)
 * Representa un comprobante de gasto documentado en ruta.
 */
class GastoModel {
  final String id;
  final String folio;
  final String tipo; // 'diesel', 'fluidos', 'viaticos'
  final double monto;
  final double? odometro;
  final String proveedor;
  final String fotografiaUrl;
  final String fotografiaBase64;
  final bool compresionOptimizada;
  final String placasCamion;
  final String estadoSincronizacion; // 'sincronizado', 'pendiente'
  final String estadoAuditoria; // 'pendiente', 'aprobado', 'rechazado'
  final DateTime fecha;

  const GastoModel({
    required this.id,
    required this.folio,
    required this.tipo,
    required this.monto,
    this.odometro,
    required this.proveedor,
    this.fotografiaUrl = '',
    this.fotografiaBase64 = '',
    this.compresionOptimizada = true,
    this.placasCamion = 'NLZ-8823-A',
    this.estadoSincronizacion = 'sincronizado',
    this.estadoAuditoria = 'pendiente',
    required this.fecha,
  });

  factory GastoModel.fromJson(Map<String, dynamic> json) {
    return GastoModel(
      id: (json['_id'] ?? json['id'] ?? '') as String,
      folio: (json['folio'] ?? '#TT-000000') as String,
      tipo: (json['tipo'] ?? 'diesel') as String,
      monto: (json['monto'] is num) ? (json['monto'] as num).toDouble() : double.tryParse('${json['monto']}') ?? 0.0,
      odometro: (json['odometro'] != null && json['odometro'] is num)
          ? (json['odometro'] as num).toDouble()
          : (json['odometro'] != null ? double.tryParse('${json['odometro']}') : null),
      proveedor: (json['proveedor'] ?? '') as String,
      fotografiaUrl: (json['fotografiaUrl'] ?? '') as String,
      fotografiaBase64: (json['fotografiaBase64'] ?? '') as String,
      compresionOptimizada: json['compresionOptimizada'] as bool? ?? true,
      placasCamion: (json['placasCamion'] ?? 'NLZ-8823-A') as String,
      estadoSincronizacion: (json['estadoSincronizacion'] ?? 'sincronizado') as String,
      estadoAuditoria: (json['estadoAuditoria'] ?? 'pendiente') as String,
      fecha: json['fecha'] != null
          ? DateTime.tryParse('${json['fecha']}') ?? DateTime.now()
          : (json['createdAt'] != null
              ? DateTime.tryParse('${json['createdAt']}') ?? DateTime.now()
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'folio': folio,
      'tipo': tipo,
      'monto': monto,
      if (odometro != null) 'odometro': odometro,
      'proveedor': proveedor,
      'fotografiaUrl': fotografiaUrl,
      'fotografiaBase64': fotografiaBase64,
      'compresionOptimizada': compresionOptimizada,
      'placasCamion': placasCamion,
      'estadoSincronizacion': estadoSincronizacion,
      'estadoAuditoria': estadoAuditoria,
      'fecha': fecha.toIso8601String(),
    };
  }

  String get tipoLegible {
    switch (tipo.toLowerCase()) {
      case 'diesel':
      case 'diésel':
        return 'Diésel';
      case 'fluidos':
        return 'Fluidos';
      case 'viaticos':
      case 'viáticos':
        return 'Viáticos';
      default:
        return tipo;
    }
  }
}
