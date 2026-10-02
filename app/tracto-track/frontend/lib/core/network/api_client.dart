/// ApiClient — Singleton (Patrón de diseño P1).
///
/// Punto único de acceso al cliente HTTP, token JWT y persistencia de sesión.
/// Todas las pantallas y servicios usan esta misma instancia para
/// realizar peticiones a la API REST (documento de patrones, P1).
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiClient {
  // --- Singleton ---
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

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

  // --- Inicialización y Persistencia de Sesión ---

  /// Carga la sesión persistida en SharedPreferences al iniciar la app.
  Future<bool> initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
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

  /// Permite cambiar la URL base (útil en pruebas).
  void setBaseUrl(String url) {
    _baseUrl = url;
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
