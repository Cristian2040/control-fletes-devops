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

  /// Retorna true si el gasto aún no se ha sincronizado con la nube (US-04).
  bool get isPendiente => estadoSincronizacion.toLowerCase() == 'pendiente';

  /// Retorna true si el gasto ya está sincronizado en MongoDB.
  bool get isSincronizado => estadoSincronizacion.toLowerCase() == 'sincronizado';

  /// Etiqueta amigable de sincronización para la interfaz.
  String get estadoSincronizacionLegible =>
      isPendiente ? 'Pendiente de sincronización' : 'Sincronizado';

  /// Genera una copia del modelo modificando solo los campos requeridos.
  GastoModel copyWith({
    String? id,
    String? folio,
    String? tipo,
    double? monto,
    double? odometro,
    String? proveedor,
    String? fotografiaUrl,
    String? fotografiaBase64,
    bool? compresionOptimizada,
    String? placasCamion,
    String? estadoSincronizacion,
    String? estadoAuditoria,
    DateTime? fecha,
  }) {
    return GastoModel(
      id: id ?? this.id,
      folio: folio ?? this.folio,
      tipo: tipo ?? this.tipo,
      monto: monto ?? this.monto,
      odometro: odometro ?? this.odometro,
      proveedor: proveedor ?? this.proveedor,
      fotografiaUrl: fotografiaUrl ?? this.fotografiaUrl,
      fotografiaBase64: fotografiaBase64 ?? this.fotografiaBase64,
      compresionOptimizada: compresionOptimizada ?? this.compresionOptimizada,
      placasCamion: placasCamion ?? this.placasCamion,
      estadoSincronizacion: estadoSincronizacion ?? this.estadoSincronizacion,
      estadoAuditoria: estadoAuditoria ?? this.estadoAuditoria,
      fecha: fecha ?? this.fecha,
    );
  }
}

