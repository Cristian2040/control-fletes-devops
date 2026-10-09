/**
 * Patrón de Diseño P3: Strategy en Flutter
 * 
 * Encapsula las reglas de validación específicas para cada tipo de gasto
 * (Diésel, Fluidos, Viáticos) en clases intercambiables en tiempo de ejecución.
 */

enum TipoGasto {
  diesel,
  fluidos,
  viaticos,
}

abstract class GastoValidationStrategy {
  String get tipoNombre;
  bool get requiereOdometro;

  String? validarMonto(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El monto es obligatorio';
    }
    final monto = double.tryParse(value.replaceAll(',', '').trim());
    if (monto == null || monto <= 0) {
      return 'Ingrese un monto numérico mayor a 0';
    }
    return null;
  }

  String? validarOdometro(String? value);

  String? validarFotografia(String? base64OrUrl) {
    if (base64OrUrl == null || base64OrUrl.trim().isEmpty) {
      return 'La fotografía del comprobante es obligatoria';
    }
    return null;
  }

  String? validarProveedor(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El proveedor o estación es obligatorio';
    }
    return null;
  }
}

/// Estrategia para Diésel: Odómetro estrictamente obligatorio
class DieselValidationStrategy extends GastoValidationStrategy {
  @override
  String get tipoNombre => 'Diésel';

  @override
  bool get requiereOdometro => true;

  @override
  String? validarOdometro(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Lectura de odómetro obligatoria para Diésel';
    }
    final num = double.tryParse(value.replaceAll(',', '').trim());
    if (num == null || num < 0) {
      return 'El odómetro debe ser un número válido';
    }
    return null;
  }
}

/// Estrategia para Fluidos (aceite, anticongelante): Odómetro obligatorio
class FluidosValidationStrategy extends GastoValidationStrategy {
  @override
  String get tipoNombre => 'Fluidos';

  @override
  bool get requiereOdometro => true;

  @override
  String? validarOdometro(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Lectura de odómetro obligatoria para Fluidos';
    }
    final num = double.tryParse(value.replaceAll(',', '').trim());
    if (num == null || num < 0) {
      return 'El odómetro debe ser un número válido';
    }
    return null;
  }
}

/// Estrategia para Viáticos: Odómetro opcional (P3)
class ViaticosValidationStrategy extends GastoValidationStrategy {
  @override
  String get tipoNombre => 'Viáticos';

  @override
  bool get requiereOdometro => false;

  @override
  String? validarOdometro(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Opcional en viáticos
    }
    final num = double.tryParse(value.replaceAll(',', '').trim());
    if (num == null || num < 0) {
      return 'El odómetro debe ser un número válido';
    }
    return null;
  }
}

/// Factoría y contexto para resolver la estrategia según el tipo
class GastoValidationContext {
  static final Map<TipoGasto, GastoValidationStrategy> _strategies = {
    TipoGasto.diesel: DieselValidationStrategy(),
    TipoGasto.fluidos: FluidosValidationStrategy(),
    TipoGasto.viaticos: ViaticosValidationStrategy(),
  };

  static GastoValidationStrategy getStrategy(TipoGasto tipo) {
    return _strategies[tipo] ?? _strategies[TipoGasto.diesel]!;
  }

  static GastoValidationStrategy getStrategyByString(String tipo) {
    final t = tipo.toLowerCase().trim();
    if (t.contains('fluid')) {
      return _strategies[TipoGasto.fluidos]!;
    }
    if (t.contains('viatic') || t.contains('viátic')) {
      return _strategies[TipoGasto.viaticos]!;
    }
    return _strategies[TipoGasto.diesel]!;
  }

}
