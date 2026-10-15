import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Almacenamiento local embebido para gastos en modo offline (Sprint 4, US-04, RF-03).
///
/// Persiste en el almacenamiento seguro del dispositivo los registros de gastos
/// y las fotografías capturadas cuando no hay señal celular.
class LocalGastoStorage {
  static const String storageKey = 'tracto_trak_offline_gastos_v1';
  static const String sequenceKey = 'tracto_trak_offline_seq_v1';

  static final List<Map<String, dynamic>> _inMemoryStore = [];
  static int _inMemorySeq = 0;

  final SharedPreferences? _customPrefs;

  LocalGastoStorage({SharedPreferences? prefs}) : _customPrefs = prefs;

  Future<SharedPreferences?> _getPrefs() async {
    if (_customPrefs != null) return _customPrefs;
    try {
      return await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 300),
      );
    } catch (_) {
      return null;
    }
  }

  /// Lee todos los registros crudos persistidos localmente.
  Future<List<Map<String, dynamic>>> readAllRaw() async {
    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        final listJson = prefs.getStringList(storageKey);
        if (listJson != null && listJson.isNotEmpty) {
          final loaded = listJson
              .map((item) => jsonDecode(item) as Map<String, dynamic>)
              .toList();
          _inMemoryStore
            ..clear()
            ..addAll(loaded);
          return List<Map<String, dynamic>>.from(_inMemoryStore);
        }
      }
    } catch (_) {}
    return List<Map<String, dynamic>>.from(_inMemoryStore);
  }

  /// Sobrescribe la lista de registros crudos en el almacenamiento local.
  Future<void> writeAllRaw(List<Map<String, dynamic>> items) async {
    _inMemoryStore
      ..clear()
      ..addAll(items);
    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        final listJson = items.map((item) => jsonEncode(item)).toList();
        await prefs.setStringList(storageKey, listJson);
      }
    } catch (_) {}
  }

  /// Agrega un nuevo registro al inicio de la lista local.
  Future<void> insertRaw(Map<String, dynamic> item) async {
    final items = await readAllRaw();
    items.removeWhere((existing) =>
        (existing['id'] != null && existing['id'] == item['id']) ||
        (existing['folio'] != null && existing['folio'] == item['folio']));
    items.insert(0, item);
    await writeAllRaw(items);
  }

  /// Genera el siguiente número secuencial para folios offline (#TT-OFF-######).
  Future<int> getNextSequence() async {
    _inMemorySeq++;
    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        final current = prefs.getInt(sequenceKey) ?? (_inMemorySeq - 1);
        final next = current + 1;
        await prefs.setInt(sequenceKey, next);
        _inMemorySeq = next;
        return next;
      }
    } catch (_) {}
    return _inMemorySeq;
  }

  /// Limpia todo el almacenamiento local de gastos (útil en pruebas y reset).
  Future<void> clearAll() async {
    _inMemoryStore.clear();
    _inMemorySeq = 0;
    try {
      final prefs = await _getPrefs();
      if (prefs != null) {
        await prefs.remove(storageKey);
        await prefs.remove(sequenceKey);
      }
    } catch (_) {}
  }
}
