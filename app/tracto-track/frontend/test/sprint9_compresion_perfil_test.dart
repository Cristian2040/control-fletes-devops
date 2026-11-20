import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracto_trak/core/routes/app_routes.dart';
import 'package:tracto_trak/core/services/image_compressor_service.dart';
import 'package:tracto_trak/core/theme/app_theme.dart';
import 'package:tracto_trak/features/admin/screens/perfil_admin_screen.dart';
import 'package:tracto_trak/features/chofer/screens/captura_gasto_screen.dart';

Widget _wrapWithApp(Widget child) {
  final routes = Map<String, WidgetBuilder>.from(AppRoutes.routes)
    ..remove(AppRoutes.login);
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: child,
    routes: routes,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Sprint 9 — Compresión Automática de Imágenes (S9-01, US-09comp) y Perfil Admin (A-17)', () {
    test('1. ImageCompressorService redimensiona y comprime imágenes grandes a JPEG optimizado (US-09comp)', () {
      // Crear una imagen BMP sin comprimir de 1400x1000 px
      final original = img.Image(width: 1400, height: 1000);
      img.fill(original, color: img.ColorRgb8(240, 240, 240));
      img.fillRect(
        original,
        x1: 100,
        y1: 100,
        x2: 1300,
        y2: 300,
        color: img.ColorRgb8(40, 80, 140),
      );
      final rawBmpBytes = Uint8List.fromList(img.encodeBmp(original));

      final resultado = ImageCompressorService.comprimirBytes(
        rawBmpBytes,
        maxAncho: 1024,
        calidad: 68,
      );

      // Debe haber reducido tanto dimensiones (<= 1024) como peso en bytes
      expect(resultado.anchoFinal, 1024);
      expect(resultado.altoFinal, lessThanOrEqualTo(1024));
      expect(resultado.tamanoComprimidoBytes, lessThan(resultado.tamanoOriginalBytes));
      expect(resultado.porcentajeAhorro, greaterThan(70));
      expect(resultado.base64DataUri.startsWith('data:image/jpeg;base64,'), isTrue);
      expect(resultado.resumenCompresion, contains('US-09comp:'));
    });

    testWidgets('2. CapturaGastoScreen (C-03) ofrece botones de Cámara y Galería y muestra imagen comprimida real', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrapWithApp(const CapturaGastoScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_tomar_foto')), findsOneWidget);
      expect(find.byKey(const Key('btn_elegir_galeria')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_tomar_foto')));
      await tester.pumpAndSettle();

      expect(find.text('Fotografía Adjuntada y Optimizada'), findsOneWidget);
      expect(find.textContaining('US-09comp:'), findsAtLeastNWidgets(1));
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('3. PerfilAdminScreen (A-17) despliega Supervisión General y Parámetros de Infraestructura (RNF-02, RNF-04)', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const PerfilAdminScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Supervisión General'), findsOneWidget);
      expect(find.text('HQ'), findsOneWidget);
      expect(find.text('Administrador de Flota'), findsOneWidget);
      expect(find.text('ACCESO TOTAL'), findsOneWidget);
      expect(find.text('PARÁMETROS DE INFRAESTRUCTURA'), findsOneWidget);
      expect(find.text('MongoDB NoSQL (RNF-02)'), findsOneWidget);
      expect(find.text('Node.js / Express'), findsOneWidget);
      expect(find.text('HTTPS + JWT (RNF-04)'), findsOneWidget);
      expect(find.text('Cerrar Sesión de Administrador'), findsOneWidget);
    });
  });
}
