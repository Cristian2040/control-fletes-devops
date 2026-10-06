/// Pruebas del Sprint 1 y 2 — Widget, Autenticación y Estructura.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracto_trak/main.dart';
import 'package:tracto_trak/core/theme/app_theme.dart';
import 'package:tracto_trak/core/constants/app_constants.dart';
import 'package:tracto_trak/core/network/api_client.dart';
import 'package:tracto_trak/shared/widgets/online_indicator.dart';
import 'package:tracto_trak/shared/widgets/status_badge.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TractoTrakApp — Sprint 1 y 2', () {
    testWidgets('La app arranca y muestra la pantalla de login', (tester) async {
      await tester.pumpWidget(const TractoTrakApp());
      await tester.pumpAndSettle();

      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text(AppConstants.appSubtitle), findsOneWidget);
      expect(find.text('Acceder al Sistema'), findsOneWidget);
      expect(find.text('Versión Beta'), findsOneWidget);
    });

    testWidgets('Muestra el selector de rol con ambas opciones', (tester) async {
      await tester.pumpWidget(const TractoTrakApp());
      await tester.pumpAndSettle();

      expect(find.text('Chofer En Ruta'), findsOneWidget);
      expect(find.text('Dueño De Flota'), findsOneWidget);
    });

    testWidgets('Muestra los campos de usuario y contraseña', (tester) async {
      await tester.pumpWidget(const TractoTrakApp());
      await tester.pumpAndSettle();

      expect(find.text('Identificador de Usuario'), findsOneWidget);
      expect(find.text('Contraseña o Clave de Acceso'), findsOneWidget);
    });

    testWidgets('Muestra el indicador ONLINE', (tester) async {
      await tester.pumpWidget(const TractoTrakApp());
      await tester.pumpAndSettle();

      expect(find.text('ONLINE'), findsOneWidget);
    });

    testWidgets('Navega al placeholder Chofer al presionar Acceder en Modo Demo', (tester) async {
      await tester.pumpWidget(const TractoTrakApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'chofer_test');
      await tester.enterText(find.byType(TextField).at(1), 'password123');

      await tester.tap(find.text('Acceder al Sistema'));
      await tester.pumpAndSettle();

      if (find.text('Modo Demo').evaluate().isNotEmpty) {
        await tester.tap(find.text('Modo Demo'));
        await tester.pumpAndSettle();
      }

      expect(find.text('C-02'), findsOneWidget);
    });

    testWidgets('Navega al placeholder Admin al seleccionar Dueño De Flota en Modo Demo', (tester) async {
      await tester.pumpWidget(const TractoTrakApp());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'admin_test');
      await tester.enterText(find.byType(TextField).at(1), 'password123');

      await tester.tap(find.text('Dueño De Flota'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Acceder al Sistema'));
      await tester.pumpAndSettle();

      if (find.text('Modo Demo').evaluate().isNotEmpty) {
        await tester.tap(find.text('Modo Demo'));
        await tester.pumpAndSettle();
      }

      expect(find.text('A-02'), findsOneWidget);
    });
  });

  group('AppTheme', () {
    test('El tema es oscuro (brightness = dark)', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
    });

    test('El fondo es casi negro para alto contraste', () {
      expect(AppColors.background, const Color(0xFF0D0D0D));
    });
  });

  group('ApiClient — Singleton y Persistencia', () {
    test('Siempre devuelve la misma instancia', () {
      final a = ApiClient();
      final b = ApiClient();
      expect(identical(a, b), isTrue);
    });

    test('setToken / clearToken funciona', () {
      final client = ApiClient();
      expect(client.hasToken, isFalse);

      client.setToken('test-token');
      expect(client.hasToken, isTrue);
      expect(client.token, 'test-token');

      client.clearToken();
      expect(client.hasToken, isFalse);
    });
  });

  group('OnlineIndicator', () {
    testWidgets('Muestra ONLINE con texto visible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: OnlineIndicator(isOnline: true)),
        ),
      );

      expect(find.text('ONLINE'), findsOneWidget);
    });

    testWidgets('Muestra OFFLINE cuando isOnline=false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: OnlineIndicator(isOnline: false)),
        ),
      );

      expect(find.text('OFFLINE'), findsOneWidget);
    });
  });

  group('StatusBadge', () {
    testWidgets('Muestra la etiqueta en mayúsculas', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: StatusBadge(label: 'sincronizado')),
        ),
      );

      expect(find.text('SINCRONIZADO'), findsOneWidget);
    });
  });

  group('AppConstants', () {
    test('Folio de gasto tiene formato #TT-', () {
      expect(AppConstants.folioGastoPrefix, '#TT-');
    });

    test('Folio de flete tiene formato FL-', () {
      expect(AppConstants.folioFletePrefix, 'FL-');
    });
  });
}

