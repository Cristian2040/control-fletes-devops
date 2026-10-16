/// Constantes globales de la aplicación Tracto Trak.
library;

class AppConstants {
  AppConstants._();

  /// Nombre de la aplicación
  static const String appName = 'Tracto Trak';

  /// Subtítulo
  static const String appSubtitle = 'Control Operativo SPF';

  /// Versión
  static const String appVersion = '1.0.0';

  /// URL base de la API predeterminada.
  /// - Dispositivo físico en misma red local: http://172.16.33.178:3000 (o Hotspot http://192.168.137.1:3000)
  /// - Dispositivo físico con cable USB (adb reverse): http://127.0.0.1:3000
  /// - Emulador Android Studio: http://10.0.2.2:3000
  static const String apiBaseUrl = 'http://172.16.33.178:3000';

  /// Timeout de conexión HTTP (milisegundos)
  static const int httpTimeout = 10000;

  /// Formato de folio de gasto (C-04): #TT-######
  static const String folioGastoPrefix = '#TT-';

  /// Formato de folio de flete (A-03): FL-###
  static const String folioFletePrefix = 'FL-';

  /// Tipos de gasto disponibles (C-03, Strategy pattern)
  static const List<String> tiposGasto = ['Diésel', 'Fluidos', 'Viáticos'];

  /// Estados de sincronización
  static const String estadoPendiente = 'pendiente';
  static const String estadoSincronizado = 'sincronizado';

  /// Estados de auditoría
  static const String estadoAuditoriaPendiente = 'pendiente';
  static const String estadoAuditoriaAprobado = 'aprobado';
  static const String estadoAuditoriaRechazado = 'rechazado';

  /// Roles del sistema (RF-01)
  static const String rolOperador = 'operador';
  static const String rolAdministrador = 'administrador';
}
