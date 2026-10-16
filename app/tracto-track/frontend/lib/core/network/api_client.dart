/// ApiClient — Singleton (Patrón de diseño P1).
///
/// Punto único de acceso al cliente HTTP, token JWT y persistencia de sesión.
/// Todas las pantallas y servicios usan esta misma instancia para
/// realizar peticiones a la API REST (documento de patrones, P1).
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

import '../../data/models/gasto_model.dart';
import '../../data/models/catalogo_models.dart';
import '../../data/repositories/local_gasto_repository.dart';

class ApiClient {
  // --- Singleton ---
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  /// Repositorio local de gastos en dispositivo (Sprint 4, US-04)
  final LocalGastoRepository _localRepo = LocalGastoRepository();
  LocalGastoRepository get localRepo => _localRepo;

  /// Simulación de modo avión / sin red celular (US-04)
  bool _modoAvion = false;
  bool get isModoAvion => _modoAvion;
  bool get isOnline => !_modoAvion;

  /// Notificadores reactivos para la UI (US-05 / RF-04)
  final ValueNotifier<int> pendientesNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);

  Timer? _autoSyncTimer;

  /// Alterna o define el estado de conexión (Modo Avión vs Online).
  /// Al restaurar la conexión, desencadena sincronización automática inmediata (US-05).
  void setModoAvion(bool activo) {
    _modoAvion = activo;
    isOnlineNotifier.value = !activo;
    if (!activo) {
      sincronizarPendientes();
    }
  }

  /// Inicia el monitoreo continuo en segundo plano (US-05 / RF-04).
  ///
  /// Revisa periódicamente si existen registros pendientes y dispara la transmisión.
  void iniciarAutoSincronizacion({Duration intervalo = const Duration(seconds: 5)}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(intervalo, (_) async {
      if (!_modoAvion) {
        final count = await _localRepo.contarPendientes();
        pendientesNotifier.value = count;
        if (count > 0) {
          await sincronizarPendientes();
        }
      }
    });
  }

  /// Detiene el monitoreo en segundo plano
  void detenerAutoSincronizacion() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Token JWT actual (null si no hay sesión activa)
  String? _token;

  /// Datos del usuario autenticado actual
  Map<String, dynamic>? _currentUser;

  /// URL base de la API
  String _baseUrl = AppConstants.apiBaseUrl;

  // --- Getters ---
  String? get token => _token;
  String get baseUrl => _baseUrl;
  bool get hasToken => _token != null && _token!.isNotEmpty;
  Map<String, dynamic>? get currentUser => _currentUser;
  String get userRole => _currentUser?['rol'] ?? 'operador';

  // --- Claves de SharedPreferences ---
  static const String _keyToken = 'jwt_token';
  static const String _keyUserData = 'user_data';
  static const String _keyBaseUrl = 'custom_api_base_url';

  // --- Inicialización y Persistencia de Sesión ---

  /// Carga la sesión persistida y URL base en SharedPreferences al iniciar la app.
  Future<bool> initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customUrl = prefs.getString(_keyBaseUrl);
      if (customUrl != null && customUrl.isNotEmpty) {
        _baseUrl = customUrl;
      }
      _token = prefs.getString(_keyToken);
      final userStr = prefs.getString(_keyUserData);
      if (userStr != null && userStr.isNotEmpty) {
        _currentUser = jsonDecode(userStr);
      }
      return hasToken;
    } catch (_) {
      return false;
    }
  }

  /// Guarda la sesión en SharedPreferences.
  Future<void> saveSession(String token, Map<String, dynamic> user) async {
    _token = token;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUserData, jsonEncode(user));
  }

  /// Cierra la sesión activa y elimina las credenciales guardadas.
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserData);
  }

  /// Establece el token JWT en memoria.
  void setToken(String token) {
    _token = token;
  }

  /// Limpia el token en memoria.
  void clearToken() {
    _token = null;
    _currentUser = null;
  }

  /// Permite cambiar la URL base en memoria.
  void setBaseUrl(String url) {
    _baseUrl = url.trim();
  }

  /// Establece y persiste la URL base de la API para pruebas en red local.
  Future<void> updateBaseUrl(String url) async {
    _baseUrl = url.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyBaseUrl, _baseUrl);
    } catch (_) {}
  }

  /// Verifica si la API backend está accesible en la URL especificada o actual.
  Future<bool> checkHealth([String? testUrl]) async {
    try {
      final target = (testUrl != null && testUrl.isNotEmpty) ? testUrl.trim() : _baseUrl;
      final url = Uri.parse('$target/health');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['ok'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // --- Cabeceras HTTP ---
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (hasToken) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // --- Autenticación y Endpoints ---

  /// Inicia sesión con la API REST (POST /api/auth/login)
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await post('/api/auth/login', body: {
      'username': username,
      'password': password,
    });

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['ok'] == true) {
      final token = data['token'] as String;
      final user = data['usuario'] as Map<String, dynamic>;
      await saveSession(token, user);
      return data;
    } else {
      throw Exception(data['mensaje'] ?? 'Error al iniciar sesión');
    }
  }

  /// Registra un nuevo usuario en la API REST (POST /api/auth/register)
  Future<Map<String, dynamic>> register({
    required String nombre,
    required String username,
    required String password,
    required String rol,
    String? email,
  }) async {
    final response = await post('/api/auth/register', body: {
      'nombre': nombre,
      'username': username,
      'password': password,
      'rol': rol,
      'email': email ?? '',
    });

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data['ok'] == true) {
      final token = data['token'] as String;
      final user = data['usuario'] as Map<String, dynamic>;
      await saveSession(token, user);
      return data;
    } else {
      throw Exception(data['mensaje'] ?? 'Error al registrar usuario');
    }
  }

  /// Obtiene el perfil del usuario autenticado (GET /api/auth/perfil)
  Future<Map<String, dynamic>> fetchPerfil() async {
    final response = await get('/api/auth/perfil');
    handleUnauthorized(response);

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['ok'] == true) {
      _currentUser = data['usuario'];
      return data;
    } else {
      throw Exception(data['mensaje'] ?? 'Error al obtener perfil');
    }
  }

  // --- Métodos HTTP Base ---

  /// GET request
  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return http.get(url, headers: _headers).timeout(
          const Duration(milliseconds: AppConstants.httpTimeout),
        );
  }

  /// POST request
  Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return http.post(
      url,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(
      const Duration(milliseconds: AppConstants.httpTimeout),
    );
  }

  /// PUT request
  Future<http.Response> put(String endpoint, {Map<String, dynamic>? body}) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return http.put(
      url,
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    ).timeout(
      const Duration(milliseconds: AppConstants.httpTimeout),
    );
  }

  /// DELETE request
  Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return http.delete(url, headers: _headers).timeout(
          const Duration(milliseconds: AppConstants.httpTimeout),
        );
  }

  // --- Módulo de Gastos (RF-02, US-03, Sprint 3) ---

  final List<Map<String, dynamic>> _demoGastos = [
    {
      'id': 'demo_1',
      'folio': '#TT-000140',
      'tipo': 'diesel',
      'monto': 4850.0,
      'odometro': 141800.0,
      'proveedor': 'Oxxo Gas Matehuala',
      'fotografiaUrl': 'demo_ticket_diesel.jpg',
      'fotografiaBase64': 'demo_base64_foto',
      'placasCamion': 'NLZ-8823-A',
      'estadoSincronizacion': 'sincronizado',
      'estadoAuditoria': 'aprobado',
      'fecha': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
    },
    {
      'id': 'demo_2',
      'folio': '#TT-000141',
      'tipo': 'fluidos',
      'monto': 620.0,
      'odometro': 142100.0,
      'proveedor': 'Refaccionaria San Luis',
      'fotografiaUrl': 'demo_ticket_aceite.jpg',
      'fotografiaBase64': 'demo_base64_foto',
      'placasCamion': 'NLZ-8823-A',
      'estadoSincronizacion': 'sincronizado',
      'estadoAuditoria': 'aprobado',
      'fecha': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    },
    {
      'id': 'demo_3',
      'folio': '#TT-000142',
      'tipo': 'viaticos',
      'monto': 380.0,
      'odometro': null,
      'proveedor': 'Restaurante El Parador',
      'fotografiaUrl': 'demo_ticket_comida.jpg',
      'fotografiaBase64': 'demo_base64_foto',
      'placasCamion': 'NLZ-8823-A',
      'estadoSincronizacion': 'sincronizado',
      'estadoAuditoria': 'pendiente',
      'fecha': DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
    },
  ];

  /// Registra un nuevo gasto de ruta (POST /api/gastos o Local Offline US-04).
  Future<Map<String, dynamic>> registrarGasto({
    required String tipo,
    required double monto,
    double? odometro,
    required String proveedor,
    String? fotografiaUrl,
    String? fotografiaBase64,
    String? placasCamion,
  }) async {
    // Si estamos en modo avión / sin red, guardamos directamente de forma local (US-04)
    if (_modoAvion) {
      final nuevoGastoOffline = GastoModel(
        id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
        folio: '',
        tipo: tipo,
        monto: monto,
        odometro: odometro,
        proveedor: proveedor,
        fotografiaUrl: fotografiaUrl ?? 'ticket_offline.jpg',
        fotografiaBase64: fotografiaBase64 ?? '',
        compresionOptimizada: true,
        placasCamion: placasCamion ?? 'NLZ-8823-A',
        estadoSincronizacion: 'pendiente', // US-04: Marcar como pendiente
        estadoAuditoria: 'pendiente',
        fecha: DateTime.now(),
      );

      final guardado = await _localRepo.guardarGastoOffline(nuevoGastoOffline);
      return guardado.toJson();
    }

    final payload = {
      'tipo': tipo,
      'monto': monto,
      if (odometro != null) 'odometro': odometro,
      'proveedor': proveedor,
      'fotografiaUrl': fotografiaUrl ?? '',
      'fotografiaBase64': fotografiaBase64 ?? '',
      'placasCamion': placasCamion ?? 'NLZ-8823-A',
    };

    try {
      final response = await post('/api/gastos', body: payload);
      handleUnauthorized(response);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data']['gasto'] as Map<String, dynamic>;
      } else {
        final err = jsonDecode(response.body);
        final errMsg = (err['errores'] is List)
            ? (err['errores'] as List).join('\n')
            : (err['message'] ?? err['mensaje'] ?? 'Error al guardar gasto');
        throw Exception(errMsg);
      }
    } catch (e) {
      // Si la API falla o no hay conexión (offline accidental / tramo carretero),
      // persistir en la base de datos local embebida con estado 'pendiente' (US-04 / RF-03).
      final nuevoGastoOffline = GastoModel(
        id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
        folio: '',
        tipo: tipo,
        monto: monto,
        odometro: odometro,
        proveedor: proveedor,
        fotografiaUrl: fotografiaUrl ?? 'ticket_offline.jpg',
        fotografiaBase64: fotografiaBase64 ?? '',
        compresionOptimizada: true,
        placasCamion: placasCamion ?? 'NLZ-8823-A',
        estadoSincronizacion: 'pendiente', // US-04: Marcar como pendiente
        estadoAuditoria: 'pendiente',
        fecha: DateTime.now(),
      );

      final guardado = await _localRepo.guardarGastoOffline(nuevoGastoOffline);
      return guardado.toJson();
    }
  }

  /// Obtiene los gastos documentados por el chofer (GET /api/gastos con respaldo offline).
  Future<Map<String, dynamic>> obtenerGastos() async {
    // 1. Obtener gastos locales guardados en el dispositivo
    final gastosLocales = await _localRepo.obtenerTodos();
    final gastosLocalesMaps = gastosLocales.map((g) => g.toJson()).toList();

    List<Map<String, dynamic>> listaFinal = [];

    if (!_modoAvion) {
      try {
        final response = await get('/api/gastos');
        handleUnauthorized(response);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final serverList = (data['data']['gastos'] as List? ?? [])
              .map((e) => e as Map<String, dynamic>)
              .toList();

          // Filtrar gastos locales pendientes que aún no están en el servidor
          final foliosServidor = serverList.map((e) => e['folio']).toSet();
          final pendientesLocales = gastosLocalesMaps.where((l) =>
              (l['estadoSincronizacion'] == 'pendiente') &&
              !foliosServidor.contains(l['folio']));

          // Mostrar los pendientes arriba para que el chofer sepa qué falta por sincronizar
          listaFinal = [...pendientesLocales, ...serverList];
        }
      } catch (_) {
        // En caso de fallo de red, combinar locales con los datos demo
      }
    }

    if (listaFinal.isEmpty) {
      // Combinar pendientes locales con demo
      final foliosLocales = gastosLocalesMaps.map((e) => e['folio']).toSet();
      final demoNoRepetidos = _demoGastos.where((d) => !foliosLocales.contains(d['folio']));
      listaFinal = [...gastosLocalesMaps, ...demoNoRepetidos];
    }

    final total = listaFinal.fold<double>(
      0.0,
      (acc, item) => acc + ((item['monto'] as num?)?.toDouble() ?? 0.0),
    );
    final pendientesCount = listaFinal.where((g) => g['estadoSincronizacion'] == 'pendiente').length;

    return {
      'gastos': listaFinal,
      'totalImporte': total,
      'totalComprobantes': listaFinal.length,
      'totalPendientes': pendientesCount,
    };
  }

  /// Sincroniza automáticamente en segundo plano los registros guardados offline al recuperar señal (US-05 / RF-04).
  ///
  /// Transmite hacia MongoDB los registros locales pendientes, obtiene el folio
  /// oficial secuencial y actualiza el estado local a 'sincronizado'.
  Future<SyncResult> sincronizarPendientes({bool forzar = false}) async {
    final pendientes = await _localRepo.obtenerPendientes();
    pendientesNotifier.value = pendientes.length;
    if (pendientes.isEmpty) {
      return const SyncResult(totalPendientes: 0, totalSincronizados: 0, totalErrores: 0);
    }

    if (_modoAvion && !forzar) {
      return SyncResult(totalPendientes: pendientes.length, totalSincronizados: 0, totalErrores: 0);
    }

    int sincronizados = 0;
    int erroresCount = 0;
    final List<String> errores = [];

    for (final gasto in pendientes) {
      try {
        final payload = {
          'tipo': gasto.tipo,
          'monto': gasto.monto,
          if (gasto.odometro != null) 'odometro': gasto.odometro,
          'proveedor': gasto.proveedor,
          'fotografiaUrl': gasto.fotografiaUrl,
          'fotografiaBase64': gasto.fotografiaBase64,
          'placasCamion': gasto.placasCamion,
        };

        // Si tenemos sesión autenticada y conexión activa, transmitir a la API REST MongoDB
        if (hasToken) {
          final res = await post('/api/gastos', body: payload);
          if (res.statusCode == 201) {
            final data = jsonDecode(res.body);
            final gastoServidor = data['data']['gasto'] as Map<String, dynamic>;
            final nuevoFolio = gastoServidor['folio'] as String? ?? '';

            // Actualizar estado del registro a "sincronizado" tras confirmación del servidor (US-05)
            await _localRepo.marcarComoSincronizado(gasto.id, nuevoFolio: nuevoFolio);
            sincronizados++;
            continue;
          } else {
            final errBody = jsonDecode(res.body);
            final msg = (errBody['errores'] is List)
                ? (errBody['errores'] as List).join(', ')
                : (errBody['message'] ?? errBody['mensaje'] ?? 'HTTP ${res.statusCode}');
            erroresCount++;
            errores.add('Fallo al sincronizar ${gasto.folio}: $msg');
          }
        } else {
          // Modo demo o prueba local: asignar folio consecutivo oficial y marcar como sincronizado
          final nuevoFolio = '#TT-${(144 + sincronizados).toString().padLeft(6, '0')}';
          await _localRepo.marcarComoSincronizado(gasto.id, nuevoFolio: nuevoFolio);
          sincronizados++;
        }
      } catch (e) {
        erroresCount++;
        errores.add('Error al sincronizar ${gasto.folio}: $e');
      }
    }

    final pendientesRestantes = await _localRepo.contarPendientes();
    pendientesNotifier.value = pendientesRestantes;

    return SyncResult(
      totalPendientes: pendientes.length,
      totalSincronizados: sincronizados,
      totalErrores: erroresCount,
      errores: errores,
    );
  }

  // ========================================================
  // --- Módulo de Catálogos Operativos (RF-05, Sprint 6) ---
  // ========================================================

  final List<Map<String, dynamic>> _demoCamiones = [
    {
      'id': 'cam_1',
      'placas': 'NLZ-8823-A',
      'marca': 'Kenworth',
      'modelo': 'T680',
      'anio': 2021,
      'capacidadCarga': 28.0,
      'kilometraje': 142500.0,
      'estado': 'en_ruta',
    },
    {
      'id': 'cam_2',
      'placas': 'SPF-4412-B',
      'marca': 'Freightliner',
      'modelo': 'Cascadia',
      'anio': 2022,
      'capacidadCarga': 30.0,
      'kilometraje': 98200.0,
      'estado': 'disponible',
    },
    {
      'id': 'cam_3',
      'placas': 'MTY-9910-C',
      'marca': 'International',
      'modelo': 'LT',
      'anio': 2020,
      'capacidadCarga': 26.0,
      'kilometraje': 187400.0,
      'estado': 'en_taller',
    },
  ];

  final List<Map<String, dynamic>> _demoChoferes = [
    {
      'id': 'chof_1',
      'nombre': 'Jorge González',
      'licencia': 'LF-9928172',
      'telefono': '811-234-5678',
      'empresa': 'Transportes Flores S.A.',
      'estado': 'en_ruta',
    },
    {
      'id': 'chof_2',
      'nombre': 'Raúl Mendoza',
      'licencia': 'LF-8812301',
      'telefono': '818-456-7890',
      'empresa': 'Transportes Flores S.A.',
      'estado': 'disponible',
    },
    {
      'id': 'chof_3',
      'nombre': 'Carlos Herrera',
      'licencia': 'LF-7723910',
      'telefono': '812-789-0123',
      'empresa': 'Transportes Flores S.A.',
      'estado': 'inactivo',
    },
  ];

  final List<Map<String, dynamic>> _demoClientes = [
    {
      'id': 'cli_1',
      'razonSocial': 'CEMEX S.A. de C.V.',
      'rfc': 'CEM850101XYZ',
      'diasCredito': 30,
      'estado': 'activo',
    },
    {
      'id': 'cli_2',
      'razonSocial': 'Gruma Internacional',
      'rfc': 'GRU900215ABC',
      'diasCredito': 15,
      'estado': 'activo',
    },
    {
      'id': 'cli_3',
      'razonSocial': 'Ternium México',
      'rfc': 'TER050820DEF',
      'diasCredito': 45,
      'estado': 'activo',
    },
  ];

  final List<Map<String, dynamic>> _demoTarifas = [
    {
      'id': 'tar_1',
      'ruta': 'Monterrey → CDMX',
      'tipoCarga': 'General',
      'capacidadTon': 28.0,
      'montoBase': 18500.0,
      'estado': 'activa',
    },
    {
      'id': 'tar_2',
      'ruta': 'San Luis Potosí → GDL',
      'tipoCarga': 'Refrigerada',
      'capacidadTon': 24.0,
      'montoBase': 14200.0,
      'estado': 'activa',
    },
    {
      'id': 'tar_3',
      'ruta': 'Querétaro → Monterrey',
      'tipoCarga': 'General',
      'capacidadTon': 30.0,
      'montoBase': 16800.0,
      'estado': 'activa',
    },
  ];

  // --- Camiones ---

  Future<List<CamionModel>> fetchCamiones({String? query, String? estado}) async {
    if (hasToken && !_modoAvion) {
      try {
        final uri = Uri(path: '/api/camiones', queryParameters: {
          if (query != null && query.isNotEmpty) 'q': query,
          if (estado != null && estado.isNotEmpty) 'estado': estado,
        }).toString();
        final res = await get(uri);
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final list = (data['data']['camiones'] as List? ?? [])
              .map((e) => CamionModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return list;
        }
      } catch (_) {}
    }

    var list = _demoCamiones.map((e) => CamionModel.fromJson(e)).toList();
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((c) =>
          c.placas.toLowerCase().contains(q) ||
          c.marca.toLowerCase().contains(q) ||
          c.modelo.toLowerCase().contains(q)).toList();
    }
    if (estado != null && estado.isNotEmpty) {
      list = list.where((c) => c.estado.toLowerCase() == estado.toLowerCase()).toList();
    }
    return list;
  }

  Future<CamionModel> crearCamion({
    required String placas,
    required String marca,
    required String modelo,
    required int anio,
    required double capacidadCarga,
    String? estado,
  }) async {
    final payload = {
      'placas': placas.toUpperCase().trim(),
      'marca': marca.trim(),
      'modelo': modelo.trim(),
      'anio': anio,
      'capacidadCarga': capacidadCarga,
      'estado': estado ?? 'disponible',
    };

    if (hasToken && !_modoAvion) {
      try {
        final res = await post('/api/camiones', body: payload);
        if (res.statusCode == 201) {
          final data = jsonDecode(res.body);
          return CamionModel.fromJson(data['data']['camion']);
        } else {
          final err = jsonDecode(res.body);
          throw Exception(err['message'] ?? 'Error al guardar camión');
        }
      } catch (e) {
        if (!e.toString().contains('SocketException')) rethrow;
      }
    }

    final nuevo = CamionModel(
      id: 'cam_${DateTime.now().millisecondsSinceEpoch}',
      placas: placas.toUpperCase().trim(),
      marca: marca.trim(),
      modelo: modelo.trim(),
      anio: anio,
      capacidadCarga: capacidadCarga,
      estado: estado ?? 'disponible',
    );
    _demoCamiones.insert(0, nuevo.toJson());
    return nuevo;
  }

  // --- Choferes ---

  Future<List<ChoferModel>> fetchChoferes({String? query, String? estado}) async {
    if (hasToken && !_modoAvion) {
      try {
        final uri = Uri(path: '/api/choferes', queryParameters: {
          if (query != null && query.isNotEmpty) 'q': query,
          if (estado != null && estado.isNotEmpty) 'estado': estado,
        }).toString();
        final res = await get(uri);
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final list = (data['data']['choferes'] as List? ?? [])
              .map((e) => ChoferModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return list;
        }
      } catch (_) {}
    }

    var list = _demoChoferes.map((e) => ChoferModel.fromJson(e)).toList();
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((c) =>
          c.nombre.toLowerCase().contains(q) ||
          c.licencia.toLowerCase().contains(q) ||
          c.telefono.toLowerCase().contains(q)).toList();
    }
    if (estado != null && estado.isNotEmpty) {
      list = list.where((c) => c.estado.toLowerCase() == estado.toLowerCase()).toList();
    }
    return list;
  }

  Future<ChoferModel> crearChofer({
    required String nombre,
    required String licencia,
    required String telefono,
    String? empresa,
    String? estado,
  }) async {
    final payload = {
      'nombre': nombre.trim(),
      'licencia': licencia.trim(),
      'telefono': telefono.trim(),
      'empresa': (empresa ?? 'Transportes Flores S.A.').trim(),
      'estado': estado ?? 'disponible',
    };

    if (hasToken && !_modoAvion) {
      try {
        final res = await post('/api/choferes', body: payload);
        if (res.statusCode == 201) {
          final data = jsonDecode(res.body);
          return ChoferModel.fromJson(data['data']['chofer']);
        } else {
          final err = jsonDecode(res.body);
          throw Exception(err['message'] ?? 'Error al guardar chofer');
        }
      } catch (e) {
        if (!e.toString().contains('SocketException')) rethrow;
      }
    }

    final nuevo = ChoferModel(
      id: 'chof_${DateTime.now().millisecondsSinceEpoch}',
      nombre: nombre.trim(),
      licencia: licencia.trim(),
      telefono: telefono.trim(),
      empresa: empresa ?? 'Transportes Flores S.A.',
      estado: estado ?? 'disponible',
    );
    _demoChoferes.insert(0, nuevo.toJson());
    return nuevo;
  }

  // --- Clientes ---

  Future<List<ClienteModel>> fetchClientes({String? query, String? estado}) async {
    if (hasToken && !_modoAvion) {
      try {
        final uri = Uri(path: '/api/clientes', queryParameters: {
          if (query != null && query.isNotEmpty) 'q': query,
          if (estado != null && estado.isNotEmpty) 'estado': estado,
        }).toString();
        final res = await get(uri);
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final list = (data['data']['clientes'] as List? ?? [])
              .map((e) => ClienteModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return list;
        }
      } catch (_) {}
    }

    var list = _demoClientes.map((e) => ClienteModel.fromJson(e)).toList();
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((c) =>
          c.razonSocial.toLowerCase().contains(q) ||
          c.rfc.toLowerCase().contains(q)).toList();
    }
    if (estado != null && estado.isNotEmpty) {
      list = list.where((c) => c.estado.toLowerCase() == estado.toLowerCase()).toList();
    }
    return list;
  }

  Future<ClienteModel> crearCliente({
    required String razonSocial,
    required String rfc,
    required int diasCredito,
    String? estado,
  }) async {
    final payload = {
      'razonSocial': razonSocial.trim(),
      'rfc': rfc.toUpperCase().trim(),
      'diasCredito': diasCredito,
      'estado': estado ?? 'activo',
    };

    if (hasToken && !_modoAvion) {
      try {
        final res = await post('/api/clientes', body: payload);
        if (res.statusCode == 201) {
          final data = jsonDecode(res.body);
          return ClienteModel.fromJson(data['data']['cliente']);
        } else {
          final err = jsonDecode(res.body);
          throw Exception(err['message'] ?? 'Error al guardar cliente');
        }
      } catch (e) {
        if (!e.toString().contains('SocketException')) rethrow;
      }
    }

    final nuevo = ClienteModel(
      id: 'cli_${DateTime.now().millisecondsSinceEpoch}',
      razonSocial: razonSocial.trim(),
      rfc: rfc.toUpperCase().trim(),
      diasCredito: diasCredito,
      estado: estado ?? 'activo',
    );
    _demoClientes.insert(0, nuevo.toJson());
    return nuevo;
  }

  // --- Tarifas ---

  Future<List<TarifaModel>> fetchTarifas({String? query}) async {
    if (hasToken && !_modoAvion) {
      try {
        final uri = Uri(path: '/api/tarifas', queryParameters: {
          if (query != null && query.isNotEmpty) 'q': query,
        }).toString();
        final res = await get(uri);
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final list = (data['data']['tarifas'] as List? ?? [])
              .map((e) => TarifaModel.fromJson(e as Map<String, dynamic>))
              .toList();
          return list;
        }
      } catch (_) {}
    }

    var list = _demoTarifas.map((e) => TarifaModel.fromJson(e)).toList();
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((t) =>
          t.ruta.toLowerCase().contains(q) ||
          t.tipoCarga.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Future<TarifaModel> crearTarifa({
    required String ruta,
    required String tipoCarga,
    required double montoBase,
    double? capacidadTon,
    String? estado,
  }) async {
    final payload = {
      'ruta': ruta.trim(),
      'tipoCarga': tipoCarga.trim(),
      'montoBase': montoBase,
      'capacidadTon': capacidadTon ?? 25.0,
      'estado': estado ?? 'activa',
    };

    if (hasToken && !_modoAvion) {
      try {
        final res = await post('/api/tarifas', body: payload);
        if (res.statusCode == 201) {
          final data = jsonDecode(res.body);
          return TarifaModel.fromJson(data['data']['tarifa']);
        } else {
          final err = jsonDecode(res.body);
          throw Exception(err['message'] ?? 'Error al guardar tarifa');
        }
      } catch (e) {
        if (!e.toString().contains('SocketException')) rethrow;
      }
    }

    final nuevo = TarifaModel(
      id: 'tar_${DateTime.now().millisecondsSinceEpoch}',
      ruta: ruta.trim(),
      tipoCarga: tipoCarga.trim(),
      capacidadTon: capacidadTon ?? 25.0,
      montoBase: montoBase,
      estado: estado ?? 'activa',
    );
    _demoTarifas.insert(0, nuevo.toJson());
    return nuevo;
  }

  /// Verifica si la respuesta indica token expirado (401)
  /// y limpia la sesión automáticamente.
  bool handleUnauthorized(http.Response response) {
    if (response.statusCode == 401) {
      clearToken();
      return true;
    }
    return false;
  }
}

/// Resultado del proceso de sincronización offline-online.
class SyncResult {
  final int totalPendientes;
  final int totalSincronizados;
  final int totalErrores;
  final List<String> errores;

  const SyncResult({
    required this.totalPendientes,
    required this.totalSincronizados,
    required this.totalErrores,
    this.errores = const [],
  });

  bool get exitoso => totalErrores == 0 && totalSincronizados > 0;
}


