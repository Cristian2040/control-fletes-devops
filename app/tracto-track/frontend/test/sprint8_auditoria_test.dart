import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracto_trak/core/routes/app_routes.dart';
import 'package:tracto_trak/core/theme/app_theme.dart';
import 'package:tracto_trak/data/models/gasto_model.dart';
import 'package:tracto_trak/features/admin/screens/auditoria_screen.dart';
import 'package:tracto_trak/features/admin/screens/validacion_fotografia_screen.dart';

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

  group('Sprint 8 — Auditoría en Ruta y Validación de Fotografía (A-13, A-14 — RF-06, US-08, US-08b)', () {
    test('1. GastoModel soporta choferNombre, motivoRechazo y helpers de auditoría', () {
      final gasto = GastoModel.fromJson({
        'id': 'g1',
        'folio': '#TT-000140',
        'tipo': 'diesel',
        'monto': 1240.0,
        'odometro': 148320,
        'proveedor': 'ESTACIÓN PEMEX 4402',
        'placasCamion': 'NLZ-8823-A',
        'chofer': {'nombre': 'Jorge González'},
        'estadoAuditoria': 'pendiente',
      });

      expect(gasto.choferNombre, 'Jorge González');
      expect(gasto.isAuditoriaPendiente, isTrue);
      expect(gasto.isAprobado, isFalse);

      final aprobado = gasto.copyWith(estadoAuditoria: 'aprobado');
      expect(aprobado.isAprobado, isTrue);
    });

    testWidgets('2. AuditoriaScreen (A-13) muestra comprobantes pendientes de revisión (RF-06)', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const AuditoriaScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Auditoría en Ruta (RF-06)'), findsOneWidget);
      expect(find.text('PENDIENTE'), findsOneWidget);
      expect(find.text('Cotejo de tickets fotográficos en tiempo real'), findsOneWidget);
      expect(find.textContaining('tickets por revisar'), findsOneWidget);
      expect(find.text('Auditar Ticket'), findsAtLeastNWidgets(1));
    });

    testWidgets('3. ValidacionFotografiaScreen (A-14) despliega evidencia comprimida y datos declarados (US-09comp)', (tester) async {
      final gasto = GastoModel(
        id: 'test_aud_1',
        folio: '#TT-115694',
        tipo: 'viaticos',
        monto: 1240.0,
        odometro: 148320.0,
        proveedor: 'ESTACIÓN PEMEX 4402',
        placasCamion: 'NLZ-8823-A',
        choferNombre: 'Jorge González',
        fecha: DateTime(2026, 9, 18, 14, 7),
      );

      await tester.pumpWidget(_wrapWithApp(ValidacionFotografiaScreen(gasto: gasto)));
      await tester.pumpAndSettle();

      expect(find.text('Validación de Fotografía'), findsOneWidget);
      expect(find.text('#TT-115694'), findsOneWidget);
      expect(find.text('ESTACIÓN PEMEX 4402'), findsOneWidget);
      expect(find.text('Evidencia Fotográfica Comprimida (US-09comp)'), findsOneWidget);
      expect(find.text('Jorge González'), findsOneWidget);
      expect(find.text('NLZ-8823-A'), findsOneWidget);
      expect(find.text('148320 km'), findsOneWidget);
      expect(find.text('Rechazar Ticket (US-08b)'), findsOneWidget);
      expect(find.text('Aprobar Ticket (US-08)'), findsOneWidget);
    });

    testWidgets('4. Flujo A-13 -> A-14 permite Aprobar Ticket (US-08) y Rechazar Ticket (US-08b)', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const AuditoriaScreen()));
      await tester.pumpAndSettle();

      // Abrir primer ticket pendiente (#TT-000140)
      await tester.tap(find.text('Auditar Ticket').first);
      await tester.pumpAndSettle();

      expect(find.text('Validación de Fotografía'), findsOneWidget);

      // Aprobar Ticket (US-08)
      await tester.tap(find.byKey(const Key('btn_aprobar_ticket')));
      await tester.pumpAndSettle();

      // Regresa a A-13 y el filtro de Aprobados ahora cuenta con 1 comprobante
      expect(find.text('Auditoría en Ruta (RF-06)'), findsOneWidget);
      expect(find.text('Aprobados (1)'), findsOneWidget);

      // Limpiar SnackBar flotante antes de abrir el siguiente ticket
      ScaffoldMessenger.of(tester.element(find.byType(AuditoriaScreen))).clearSnackBars();
      await tester.pumpAndSettle();

      // Abrir siguiente ticket pendiente y Rechazarlo (US-08b)
      await tester.tap(find.text('Auditar Ticket').first);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_rechazar_ticket')));
      await tester.pumpAndSettle();

      expect(find.text('Rechazados (1)'), findsOneWidget);
    });
  });
}
