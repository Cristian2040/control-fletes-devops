import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracto_trak/core/network/api_client.dart';
import 'package:tracto_trak/core/routes/app_routes.dart';
import 'package:tracto_trak/core/theme/app_theme.dart';
import 'package:tracto_trak/features/admin/screens/catalogos_screen.dart';
import 'package:tracto_trak/features/admin/screens/alta_camion_screen.dart';
import 'package:tracto_trak/features/admin/screens/alta_chofer_screen.dart';
import 'package:tracto_trak/features/admin/screens/alta_cliente_screen.dart';
import 'package:tracto_trak/features/admin/screens/alta_tarifa_screen.dart';
import 'package:tracto_trak/features/admin/widgets/admin_bottom_nav_bar.dart';

Widget _wrapWithApp(Widget child) {
  final routes = Map<String, WidgetBuilder>.from(AppRoutes.routes);
  routes.remove(AppRoutes.login);
  return MaterialApp(
    theme: AppTheme.darkTheme,
    routes: routes,
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final client = ApiClient();
    client.clearToken();
    client.setModoAvion(false);
  });

  group('RF-05 / Sprint 6: Panel Móvil de Catálogos (A-05 a A-08)', () {
    testWidgets('A-05: CatalogosScreen inicializa en pestaña Camiones y lista unidades', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const CatalogosScreen()));
      await tester.pumpAndSettle();

      // Verificar AppBar y título
      expect(find.text('Catálogos Operativos (RF-05)'), findsOneWidget);
      expect(find.byKey(const Key('btn_alta_catalogo')), findsOneWidget);

      // Verificar 4 pestañas
      expect(find.text('Camiones'), findsOneWidget);
      expect(find.text('Choferes'), findsOneWidget);
      expect(find.text('Clientes'), findsOneWidget);
      expect(find.text('Tarifas'), findsOneWidget);

      // Verificar buscador con placeholder dinámico
      expect(find.text('Buscar en camiones...'), findsOneWidget);

      // Verificar que se listan unidades de semilla/demo
      expect(find.text('NLZ-8823-A'), findsOneWidget);
      expect(find.textContaining('Kenworth T680'), findsOneWidget);
      expect(find.text('DISPONIBLE'), findsWidgets);

      // Verificar barra inferior de administrador
      expect(find.byType(AdminBottomNavBar), findsOneWidget);
      expect(find.text('Catálogos'), findsWidgets);
    });

    testWidgets('A-05: Buscador filtra camiones en tiempo real', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const CatalogosScreen()));
      await tester.pumpAndSettle();

      expect(find.text('NLZ-8823-A'), findsOneWidget);
      expect(find.text('SPF-4412-B'), findsOneWidget);

      // Escribir en el buscador 'NLZ'
      await tester.enterText(find.byKey(const Key('input_buscar_catalogo')), 'NLZ');
      await tester.pumpAndSettle();

      expect(find.text('NLZ-8823-A'), findsOneWidget);
      expect(find.text('SPF-4412-B'), findsNothing);

      // Limpiar texto
      await tester.enterText(find.byKey(const Key('input_buscar_catalogo')), '');
      await tester.pumpAndSettle();

      expect(find.text('NLZ-8823-A'), findsOneWidget);
      expect(find.text('SPF-4412-B'), findsOneWidget);
    });

    testWidgets('A-06: Cambio a pestaña Choferes muestra operadores y licencias', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const CatalogosScreen()));
      await tester.pumpAndSettle();

      // Tocar pestaña Choferes
      await tester.tap(find.text('Choferes'));
      await tester.pumpAndSettle();

      expect(find.text('Buscar en choferes...'), findsOneWidget);
      expect(find.text('Jorge González'), findsOneWidget);
      expect(find.textContaining('LF-9928172'), findsOneWidget);
    });

    testWidgets('A-07: Cambio a pestaña Clientes muestra razones sociales y RFC', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const CatalogosScreen()));
      await tester.pumpAndSettle();

      // Tocar pestaña Clientes
      await tester.tap(find.text('Clientes'));
      await tester.pumpAndSettle();

      expect(find.text('Buscar en clientes...'), findsOneWidget);
      expect(find.text('CEMEX S.A. de C.V.'), findsOneWidget);
      expect(find.textContaining('CEM850101XYZ'), findsOneWidget);
      expect(find.textContaining('30 días'), findsOneWidget);
    });

    testWidgets('A-08: Cambio a pestaña Tarifas muestra tramos e importes en MXN', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const CatalogosScreen()));
      await tester.pumpAndSettle();

      // Tocar pestaña Tarifas
      await tester.tap(find.text('Tarifas'));
      await tester.pumpAndSettle();

      expect(find.text('Buscar en tarifas...'), findsOneWidget);
      expect(find.text('Monterrey → CDMX'), findsOneWidget);
      expect(find.text('\$18500.00 MXN'), findsOneWidget);
      expect(find.textContaining('General'), findsWidgets);
    });
  });

  group('RF-05 / Sprint 6: Formularios de Alta en Catálogos (A-09 a A-12)', () {
    testWidgets('A-09: AltaCamionScreen valida campos obligatorios y registra nuevo camión', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const AltaCamionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Alta en Catálogo: Camiones'), findsOneWidget);
      expect(find.byKey(const Key('btn_guardar_camion')), findsOneWidget);

      // Intentar guardar con campos vacíos
      await tester.tap(find.byKey(const Key('btn_guardar_camion')));
      await tester.pumpAndSettle();

      expect(find.text('Capture las placas del camión'), findsOneWidget);
      expect(find.text('Capture la marca'), findsOneWidget);

      // Completar formulario
      await tester.enterText(find.byKey(const Key('input_camion_placas')), 'TEST-777-X');
      await tester.enterText(find.byKey(const Key('input_camion_marca')), 'Volvo');
      await tester.enterText(find.byKey(const Key('input_camion_modelo')), 'VNL 860');
      await tester.enterText(find.byKey(const Key('input_camion_anio')), '2024');
      await tester.enterText(find.byKey(const Key('input_camion_capacidad')), '35.0');

      await tester.tap(find.byKey(const Key('btn_guardar_camion')));
      await tester.pumpAndSettle();

      // Verificar que el camión quedó agregado al cliente
      final camiones = await ApiClient().fetchCamiones();
      expect(camiones.any((c) => c.placas == 'TEST-777-X'), isTrue);
    });

    testWidgets('A-10: AltaChoferScreen valida campos y registra nuevo chofer', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const AltaChoferScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Alta en Catálogo: Choferes'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('input_chofer_nombre')), 'Roberto Gómez Flores');
      await tester.enterText(find.byKey(const Key('input_chofer_licencia')), 'Federal Tipo B · Venc. 2029');
      await tester.enterText(find.byKey(const Key('input_chofer_telefono')), '81 1234 5678');

      await tester.tap(find.byKey(const Key('btn_guardar_chofer')));
      await tester.pumpAndSettle();

      final choferes = await ApiClient().fetchChoferes();
      expect(choferes.any((c) => c.nombre == 'Roberto Gómez Flores'), isTrue);
    });

    testWidgets('A-11: AltaClienteScreen valida campos y registra nuevo cliente', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const AltaClienteScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Alta en Catálogo: Clientes'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('input_cliente_razon')), 'Distribuidora del Norte S.A.');
      await tester.enterText(find.byKey(const Key('input_cliente_rfc')), 'DNO950412-XX1');
      await tester.enterText(find.byKey(const Key('input_cliente_credito')), '45');

      await tester.tap(find.byKey(const Key('btn_guardar_cliente')));
      await tester.pumpAndSettle();

      final clientes = await ApiClient().fetchClientes();
      expect(clientes.any((c) => c.razonSocial == 'Distribuidora del Norte S.A.'), isTrue);
    });

    testWidgets('A-12: AltaTarifaScreen valida campos y registra nueva tarifa', (tester) async {
      await tester.pumpWidget(_wrapWithApp(const AltaTarifaScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Alta en Catálogo: Tarifas'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('input_tarifa_ruta')), 'Monterrey — Laredo (TX)');
      await tester.enterText(find.byKey(const Key('input_tarifa_capacidad')), '30.0');
      await tester.enterText(find.byKey(const Key('input_tarifa_monto')), '28500.00');

      await tester.tap(find.byKey(const Key('btn_guardar_tarifa')));
      await tester.pumpAndSettle();

      final tarifas = await ApiClient().fetchTarifas();
      expect(tarifas.any((t) => t.ruta == 'Monterrey — Laredo (TX)'), isTrue);
    });
  });

  group('AdminBottomNavBar (6 Secciones: A-02 a A-17)', () {
    testWidgets('Muestra los 6 módulos con Catálogos activo', (tester) async {
      await tester.pumpWidget(_wrapWithApp(
        const Scaffold(
          body: Center(child: Text('Contenido')),
          bottomNavigationBar: AdminBottomNavBar(currentIndex: 2),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tablero'), findsOneWidget);
      expect(find.text('Viajes'), findsOneWidget);
      expect(find.text('Catálogos'), findsOneWidget);
      expect(find.text('Auditoría'), findsOneWidget);
      expect(find.text('Liquidación'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });
  });
}
