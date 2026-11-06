import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracto_trak/core/routes/app_routes.dart';
import 'package:tracto_trak/core/theme/app_theme.dart';
import 'package:tracto_trak/data/models/viaje_model.dart';
import 'package:tracto_trak/features/admin/screens/asignacion_viaje_screen.dart';
import 'package:tracto_trak/features/admin/screens/tablero_screen.dart';
import 'package:tracto_trak/features/admin/screens/viajes_screen.dart';

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
  group('Sprint 7 — Tablero de Control, Viajes y Asignación de Viaje (A-02, A-03, A-04)', () {
    test('1. Modelos ViajeModel y TableroResumenModel serializan correctamente', () {
      final resumen = TableroResumenModel.fromJson({
        'empresa': 'Transportes Flores S.A.',
        'base': 'Base Monterrey',
        'viajesActivos': 2,
        'ticketsPorAuditar': 3,
        'unidadesFlota': 4,
      });

      expect(resumen.empresa, 'Transportes Flores S.A.');
      expect(resumen.baseOperativa, 'Base Monterrey');
      expect(resumen.viajesActivos, 2);
      expect(resumen.ticketsPorAuditar, 3);
      expect(resumen.unidadesFlota, 4);

      final viaje = ViajeModel.fromJson({
        'id': 'v1',
        'folio': 'FL-101',
        'cliente': 'CEMEX S.A. de C.V.',
        'origen': 'Monterrey',
        'destino': 'CDMX',
        'camion': 'Kenworth T680 (NLZ-8823-A)',
        'chofer': 'Jorge González',
        'tarifaPactada': 18500.0,
        'anticipoEntregado': 5000.0,
        'estado': 'en_ruta',
      });

      expect(viaje.folio, 'FL-101');
      expect(viaje.ruta, 'Monterrey → CDMX');
      expect(viaje.estadoBadge, 'EN RUTA');
    });

    testWidgets('2. TableroScreen (A-02) despliega KPIs y tarjetas de módulos (RNF-01)', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const TableroScreen()));
      await tester.pumpAndSettle();

      expect(find.text('A-02'), findsOneWidget);
      expect(find.text('Panel de Control (RNF-01)'), findsOneWidget);
      expect(find.text('Transportes Flores S.A.'), findsOneWidget);
      expect(find.text('Base Monterrey'), findsOneWidget);

      expect(find.text('Viajes Activos'), findsOneWidget);
      expect(find.text('Tickets Auditoría'), findsOneWidget);
      expect(find.text('Unidades Flota'), findsOneWidget);

      expect(find.text('Asignar Nuevo Viaje (RF-05)'), findsOneWidget);
      expect(find.text('Auditoría en Ruta (RF-06)'), findsOneWidget);
      expect(find.text('Motor de Liquidaciones (US-13)'), findsOneWidget);
    });

    testWidgets('3. ViajesScreen (A-03) muestra despachos activos con folio FL-###', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const ViajesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Módulo de Viajes y Fletes'), findsOneWidget);
      expect(find.text('Control de despachos activos'), findsOneWidget);
      expect(find.text('+ Asignar'), findsOneWidget);

      expect(find.text('FL-101'), findsOneWidget);
      expect(find.text('CEMEX S.A. de C.V.'), findsOneWidget);
      expect(find.text('Monterrey → CDMX'), findsOneWidget);
      expect(find.text('\$18,500.00 MXN'), findsOneWidget);
    });

    testWidgets('4. AsignacionViajeScreen (A-04) permite seleccionar de desplegables y emitir Orden de Viaje (US-07)', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const AsignacionViajeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Asignación de Viaje (RF-05)'), findsOneWidget);
      expect(find.text('Flete y Anticipo'), findsOneWidget);
      expect(find.text('Cliente Solicitante'), findsOneWidget);
      expect(find.text('Emitir Orden de Viaje (US-07)'), findsOneWidget);

      // Seleccionar Cliente desde el desplegable
      await tester.tap(find.byKey(const Key('input_viaje_cliente')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ternium México').last);
      await tester.pumpAndSettle();

      // Seleccionar Ruta desde el desplegable de catálogo (auto-llena Querétaro -> Monterrey y 16800)
      await tester.tap(find.byKey(const Key('input_viaje_ruta_catalogo')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Querétaro → Monterrey').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('input_viaje_anticipo')), '4500');

      final btnEmitir = find.byKey(const Key('btn_emitir_orden_viaje'));
      await tester.ensureVisible(btnEmitir);
      await tester.tap(btnEmitir);
      await tester.pumpAndSettle();

      // Navega hacia ViajesScreen (A-03) donde aparece el nuevo despacho FL-103
      expect(find.text('FL-103'), findsOneWidget);
      expect(find.text('Ternium México'), findsOneWidget);
      expect(find.text('Querétaro → Monterrey'), findsOneWidget);
    });
  });
}
