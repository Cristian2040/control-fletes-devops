/// Modelos de Catálogos Operativos (RF-05, Sprint 6)
///
/// Modela las 4 entidades maestras del módulo administrativo:
///   - Camión (A-05, A-09)
///   - Chofer (A-06, A-10)
///   - Cliente (A-07, A-11)
///   - Tarifa (A-08, A-12)
library;

/// Modelo de Camión / Unidad de Flota
class CamionModel {
  final String id;
  final String placas;
  final String marca;
  final String modelo;
  final int anio;
  final double capacidadCarga;
  final double kilometraje;
  final String estado; // 'disponible', 'en_ruta', 'en_taller'

  const CamionModel({
    required this.id,
    required this.placas,
    required this.marca,
    required this.modelo,
    required this.anio,
    required this.capacidadCarga,
    this.kilometraje = 0.0,
    this.estado = 'disponible',
  });

  String get descripcionCompleta => '$marca $modelo · $anio';

  String get estadoLegible {
    switch (estado.toLowerCase()) {
      case 'en_ruta':
        return 'En Ruta';
      case 'en_taller':
        return 'En Taller';
      default:
        return 'Disponible';
    }
  }

  factory CamionModel.fromJson(Map<String, dynamic> json) {
    return CamionModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      placas: json['placas'] as String? ?? '',
      marca: json['marca'] as String? ?? '',
      modelo: json['modelo'] as String? ?? '',
      anio: (json['anio'] as num?)?.toInt() ?? DateTime.now().year,
      capacidadCarga: (json['capacidadCarga'] as num?)?.toDouble() ?? 0.0,
      kilometraje: (json['kilometraje'] as num?)?.toDouble() ?? 0.0,
      estado: json['estado'] as String? ?? 'disponible',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'placas': placas,
        'marca': marca,
        'modelo': modelo,
        'anio': anio,
        'capacidadCarga': capacidadCarga,
        'kilometraje': kilometraje,
        'estado': estado,
      };
}

/// Modelo de Chofer
class ChoferModel {
  final String id;
  final String nombre;
  final String licencia;
  final String telefono;
  final String empresa;
  final String estado; // 'disponible', 'en_ruta', 'inactivo'

  const ChoferModel({
    required this.id,
    required this.nombre,
    required this.licencia,
    required this.telefono,
    this.empresa = 'Transportes Flores S.A.',
    this.estado = 'disponible',
  });

  String get estadoLegible {
    switch (estado.toLowerCase()) {
      case 'en_ruta':
        return 'En Ruta';
      case 'inactivo':
        return 'Inactivo';
      default:
        return 'Disponible';
    }
  }

  factory ChoferModel.fromJson(Map<String, dynamic> json) {
    return ChoferModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      nombre: json['nombre'] as String? ?? '',
      licencia: json['licencia'] as String? ?? '',
      telefono: json['telefono'] as String? ?? '',
      empresa: json['empresa'] as String? ?? 'Transportes Flores S.A.',
      estado: json['estado'] as String? ?? 'disponible',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'licencia': licencia,
        'telefono': telefono,
        'empresa': empresa,
        'estado': estado,
      };
}

/// Modelo de Cliente
class ClienteModel {
  final String id;
  final String razonSocial;
  final String rfc;
  final int diasCredito;
  final String estado; // 'activo', 'inactivo'

  const ClienteModel({
    required this.id,
    required this.razonSocial,
    required this.rfc,
    required this.diasCredito,
    this.estado = 'activo',
  });

  String get estadoLegible => estado.toLowerCase() == 'activo' ? 'Activo' : 'Inactivo';

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    return ClienteModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      razonSocial: json['razonSocial'] as String? ?? '',
      rfc: json['rfc'] as String? ?? '',
      diasCredito: (json['diasCredito'] as num?)?.toInt() ?? 0,
      estado: json['estado'] as String? ?? 'activo',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'razonSocial': razonSocial,
        'rfc': rfc,
        'diasCredito': diasCredito,
        'estado': estado,
      };
}

/// Modelo de Tarifa Pactada
class TarifaModel {
  final String id;
  final String ruta;
  final String tipoCarga;
  final double capacidadTon;
  final double montoBase;
  final String estado; // 'activa', 'inactiva'

  const TarifaModel({
    required this.id,
    required this.ruta,
    required this.tipoCarga,
    required this.capacidadTon,
    required this.montoBase,
    this.estado = 'activa',
  });

  String get estadoLegible => estado.toLowerCase() == 'activa' ? 'Activa' : 'Inactiva';

  factory TarifaModel.fromJson(Map<String, dynamic> json) {
    return TarifaModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      ruta: json['ruta'] as String? ?? '',
      tipoCarga: json['tipoCarga'] as String? ?? 'General',
      capacidadTon: (json['capacidadTon'] as num?)?.toDouble() ?? 25.0,
      montoBase: (json['montoBase'] as num?)?.toDouble() ?? 0.0,
      estado: json['estado'] as String? ?? 'activa',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ruta': ruta,
        'tipoCarga': tipoCarga,
        'capacidadTon': capacidadTon,
        'montoBase': montoBase,
        'estado': estado,
      };
}
