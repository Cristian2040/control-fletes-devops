/// Punto de entrada de la aplicación Tracto Trak.
///
/// Configura el tema oscuro de alto contraste (documento de interfaces)
/// y el sistema de rutas con todas las 23 pantallas (C-01 a C-06, A-01 a A-17).
library;

import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/constants/app_constants.dart';
import 'core/network/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hasSession = await ApiClient().initSession();
  final initialRoute = hasSession
      ? (ApiClient().userRole == 'operador' ? AppRoutes.choferHome : AppRoutes.adminHome)
      : AppRoutes.login;

  runApp(TractoTrakApp(initialRoute: initialRoute));
}

class TractoTrakApp extends StatelessWidget {
  final String initialRoute;
  const TractoTrakApp({super.key, this.initialRoute = AppRoutes.login});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: initialRoute,
      routes: AppRoutes.routes,
    );
  }
}
