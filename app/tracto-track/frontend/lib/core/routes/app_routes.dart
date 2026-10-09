/// Definición centralizada de rutas de navegación.
///
/// Replica exactamente la navegación documentada en cada pantalla:
/// - Chofer: C-01→C-02; C-02→C-03→C-04→(C-03|C-02); barra C-02⇄C-05⇄C-06; C-06→C-01
/// - Admin: A-01→A-02; A-02/A-03→A-04→A-03; catálogos A-05⇄A-06⇄A-07⇄A-08;
///          cada alta (A-09..A-12) regresa a su lista; A-02→A-13→A-14→A-13;
///          A-02→A-15→A-16; A-17→A-01
library;

import 'package:flutter/material.dart';

// Importar pantallas (se implementan progresivamente por Sprint)
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/chofer/screens/ruta_screen.dart';
import '../../features/chofer/screens/captura_gasto_screen.dart';
import '../../features/chofer/screens/registro_procesado_screen.dart';
import '../../features/chofer/screens/mis_gastos_screen.dart';
import '../../features/chofer/screens/perfil_chofer_screen.dart';
import '../../features/admin/screens/placeholder_screen.dart';

class AppRoutes {
  AppRoutes._();

  // --- Rutas del módulo de autenticación ---
  static const String login = '/';
  static const String register = '/register';

  // --- Rutas del módulo Chofer (C-01 a C-06) ---
  static const String choferHome = '/chofer/home';         // C-02
  static const String choferCapturaGasto = '/chofer/gasto'; // C-03
  static const String choferRegistro = '/chofer/registro';  // C-04
  static const String choferBitacora = '/chofer/bitacora';  // C-05
  static const String choferPerfil = '/chofer/perfil';      // C-06

  // --- Rutas del módulo Administrador (A-01 a A-17) ---
  static const String adminHome = '/admin/home';             // A-02
  static const String adminViajes = '/admin/viajes';          // A-03
  static const String adminAsignacion = '/admin/asignacion';  // A-04
  static const String adminCatalogos = '/admin/catalogos';    // A-05 a A-08
  static const String adminAltaCamion = '/admin/alta/camion';  // A-09
  static const String adminAltaChofer = '/admin/alta/chofer';  // A-10
  static const String adminAltaCliente = '/admin/alta/cliente'; // A-11
  static const String adminAltaTarifa = '/admin/alta/tarifa';   // A-12
  static const String adminAuditoria = '/admin/auditoria';      // A-13
  static const String adminValidacion = '/admin/validacion';    // A-14
  static const String adminLiquidacionSelector = '/admin/liquidacion'; // A-15
  static const String adminLiquidacionResumen = '/admin/liquidacion/resumen'; // A-16
  static const String adminPerfil = '/admin/perfil';            // A-17

  /// Mapa de rutas de la aplicación.
  static Map<String, WidgetBuilder> get routes {
    return {
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),

      // Módulo Chofer (C-02 a C-06) — Implementado en Sprint 3
      choferHome: (context) => const RutaScreen(),
      choferCapturaGasto: (context) => const CapturaGastoScreen(),
      choferRegistro: (context) => const RegistroProcesadoScreen(),
      choferBitacora: (context) => const MisGastosScreen(),
      choferPerfil: (context) => const PerfilChoferScreen(),


      // Módulo Administrador — placeholders hasta sus Sprints correspondientes
      adminHome: (context) => const AdminPlaceholderScreen(
            codigo: 'A-02',
            nombre: 'Tablero – Panel de Control',
            sprint: 7,
          ),
      adminViajes: (context) => const AdminPlaceholderScreen(
            codigo: 'A-03',
            nombre: 'Módulo de Viajes y Fletes',
            sprint: 7,
          ),
      adminAsignacion: (context) => const AdminPlaceholderScreen(
            codigo: 'A-04',
            nombre: 'Asignación de Viaje',
            sprint: 7,
          ),
      adminCatalogos: (context) => const AdminPlaceholderScreen(
            codigo: 'A-05',
            nombre: 'Catálogos Operativos',
            sprint: 6,
          ),
      adminAltaCamion: (context) => const AdminPlaceholderScreen(
            codigo: 'A-09',
            nombre: 'Alta en Catálogo – Camiones',
            sprint: 6,
          ),
      adminAltaChofer: (context) => const AdminPlaceholderScreen(
            codigo: 'A-10',
            nombre: 'Alta en Catálogo – Choferes',
            sprint: 6,
          ),
      adminAltaCliente: (context) => const AdminPlaceholderScreen(
            codigo: 'A-11',
            nombre: 'Alta en Catálogo – Clientes',
            sprint: 6,
          ),
      adminAltaTarifa: (context) => const AdminPlaceholderScreen(
            codigo: 'A-12',
            nombre: 'Alta en Catálogo – Tarifas',
            sprint: 6,
          ),
      adminAuditoria: (context) => const AdminPlaceholderScreen(
            codigo: 'A-13',
            nombre: 'Auditoría en Ruta',
            sprint: 8,
          ),
      adminValidacion: (context) => const AdminPlaceholderScreen(
            codigo: 'A-14',
            nombre: 'Validación de Fotografía',
            sprint: 8,
          ),
      adminLiquidacionSelector: (context) => const AdminPlaceholderScreen(
            codigo: 'A-15',
            nombre: 'Liquidación Automatizada – Selector',
            sprint: 10,
          ),
      adminLiquidacionResumen: (context) => const AdminPlaceholderScreen(
            codigo: 'A-16',
            nombre: 'Liquidación Automatizada – Resumen',
            sprint: 10,
          ),
      adminPerfil: (context) => const AdminPlaceholderScreen(
            codigo: 'A-17',
            nombre: 'Perfil de Administrador',
            sprint: 9,
          ),
    };
  }
}
