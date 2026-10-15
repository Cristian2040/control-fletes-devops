import '../datasources/local_gasto_storage.dart';
import '../models/gasto_model.dart';

/// Repositorio local de gastos en dispositivo (Sprint 4, US-04, RF-03).
///
/// Encapsula las operaciones de almacenamiento embebido en Flutter para
/// garantizar que ningún comprobante o fotografía se pierda cuando el chofer
/// opera en tramos carreteros sin cobertura celular.
class LocalGastoRepository {
  static final LocalGastoRepository _instance = LocalGastoRepository._internal();
  factory LocalGastoRepository() => _instance;
  LocalGastoRepository._internal({LocalGastoStorage? storage})
      : _storage = storage ?? LocalGastoStorage();

  // Constructor para inyección de dependencias en pruebas
  LocalGastoRepository.withStorage(this._storage);

  final LocalGastoStorage _storage;

  /// Genera un folio único para registros capturados en modo offline.
  Future<String> generarFolioOffline() async {
    final seq = await _storage.getNextSequence();
    return '#TT-OFF-${seq.toString().padLeft(6, '0')}';
  }

  /// Guarda un gasto en el almacenamiento local.
  /// Por defecto se marca con estado "pendiente" de sincronización (US-04).
  Future<GastoModel> guardarGastoOffline(GastoModel gasto) async {
    final folioFinal = gasto.folio.startsWith('#TT-') && !gasto.folio.contains('000000')
        ? gasto.folio
        : await generarFolioOffline();

    final gastoGuardado = gasto.copyWith(
      id: gasto.id.isNotEmpty ? gasto.id : 'offline_${DateTime.now().millisecondsSinceEpoch}',
      folio: folioFinal,
      estadoSincronizacion: 'pendiente', // US-04: Marcar como pendiente de sincronización
    );

    await _storage.insertRaw(gastoGuardado.toJson());
    return gastoGuardado;
  }

  /// Obtiene todos los gastos almacenados en el dispositivo.
  Future<List<GastoModel>> obtenerTodos() async {
    final rawList = await _storage.readAllRaw();
    return rawList.map((e) => GastoModel.fromJson(e)).toList();
  }

  /// Obtiene exclusivamente los comprobantes pendientes de sincronización.
  Future<List<GastoModel>> obtenerPendientes() async {
    final todos = await obtenerTodos();
    return todos.where((g) => g.isPendiente).toList();
  }

  /// Obtiene los comprobantes que ya fueron sincronizados.
  Future<List<GastoModel>> obtenerSincronizados() async {
    final todos = await obtenerTodos();
    return todos.where((g) => g.isSincronizado).toList();
  }

  /// Cuenta cuántos registros pendientes de sincronización existen localmente.
  Future<int> contarPendientes() async {
    final pendientes = await obtenerPendientes();
    return pendientes.length;
  }

  /// Actualiza el estado de sincronización a 'sincronizado'.
  Future<void> marcarComoSincronizado(String id, {String? nuevoFolio}) async {
    final rawList = await _storage.readAllRaw();
    final updated = rawList.map((item) {
      final itemId = (item['id'] ?? item['_id'] ?? '').toString();
      if (itemId == id) {
        final map = Map<String, dynamic>.from(item);
        map['estadoSincronizacion'] = 'sincronizado';
        if (nuevoFolio != null && nuevoFolio.isNotEmpty) {
          map['folio'] = nuevoFolio;
        }
        return map;
      }
      return item;
    }).toList();

    await _storage.writeAllRaw(updated);
  }

  /// Elimina un gasto local por su ID.
  Future<void> eliminar(String id) async {
    final rawList = await _storage.readAllRaw();
    rawList.removeWhere((item) => (item['id'] ?? item['_id'] ?? '').toString() == id);
    await _storage.writeAllRaw(rawList);
  }

  /// Limpia todo el almacenamiento local de gastos.
  Future<void> limpiar() async {
    await _storage.clearAll();
  }
}
