import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracto_trak/core/theme/app_theme.dart';
import 'package:tracto_trak/data/models/gasto_model.dart';
import 'package:tracto_trak/features/chofer/screens/captura_gasto_screen.dart';
import 'package:tracto_trak/features/chofer/screens/mis_gastos_screen.dart';
import 'package:tracto_trak/features/chofer/screens/perfil_chofer_screen.dart';
import 'package:tracto_trak/features/chofer/screens/registro_procesado_screen.dart';
import 'package:tracto_trak/features/chofer/screens/ruta_screen.dart';
import 'package:tracto_trak/features/chofer/strategies/gasto_validation_strategy.dart';

void main() {
  group('Patrón de Diseño P3: Strategy en Dart (Validación de Gastos)', () {
    final diesel = DieselValidationStrategy();
    final fluidos = FluidosValidationStrategy();
    final viaticos = ViaticosValidationStrategy();

    test('US-03: Exige fotografía obligatoria en todos los tipos de gasto', () {
      expect(diesel.validarFotografia(null), isNotNull);
      expect(diesel.validarFotografia(''), isNotNull);
      expect(diesel.validarFotografia('foto_base64_valida'), isNull);

      expect(viaticos.validarFotografia(null), isNotNull);
      expect(viaticos.validarFotografia('foto_base64_valida'), isNull);
    });

    test('Diésel exige lectura de odómetro obligatoria', () {
      expect(diesel.requiereOdometro, isTrue);
      expect(diesel.validarOdometro(null), isNotNull);
      expect(diesel.validarOdometro(''), isNotNull);
      expect(diesel.validarOdometro('142500'), isNull);
    });

    test('Fluidos exige lectura de odómetro obligatoria', () {
      expect(fluidos.requiereOdometro, isTrue);
      expect(fluidos.validarOdometro(null), isNotNull);
      expect(fluidos.validarOdometro(''), isNotNull);
      expect(fluidos.validarOdometro('142500'), isNull);
    });

    test('Viáticos tiene odómetro opcional (P3 Strategy)', () {
      expect(viaticos.requiereOdometro, isFalse);
      expect(viaticos.validarOdometro(null), isNull);
      expect(viaticos.validarOdometro(''), isNull);
      expect(viaticos.validarOdometro('142500'), isNull);
      expect(viaticos.validarOdometro('-10'), isNotNull);
    });

    test('GastoValidationContext resuelve la estrategia correcta', () {
      expect(GastoValidationContext.getStrategy(TipoGasto.diesel), isA<DieselValidationStrategy>());
      expect(GastoValidationContext.getStrategy(TipoGasto.fluidos), isA<FluidosValidationStrategy>());
      expect(GastoValidationContext.getStrategy(TipoGasto.viaticos), isA<ViaticosValidationStrategy>());

      expect(GastoValidationContext.getStrategyByString('diésel'), isA<DieselValidationStrategy>());
      expect(GastoValidationContext.getStrategyByString('fluidos'), isA<FluidosValidationStrategy>());
      expect(GastoValidationContext.getStrategyByString('viáticos'), isA<ViaticosValidationStrategy>());
    });
  });

  group('Modelo GastoModel', () {
    test('Serialización y deserialización JSON', () {
      final json = {
        'id': 'gasto_123',
        'folio': '#TT-000140',
        'tipo': 'diesel',
        'monto': 4850.50,
        'odometro': 142500.0,
        'proveedor': 'Oxxo Gas',
        'estadoSincronizacion': 'sincronizado',
        'estadoAuditoria': 'aprobado',
        'fecha': DateTime.now().toIso8601String(),
      };

      final model = GastoModel.fromJson(json);
      expect(model.folio, '#TT-000140');
      expect(model.monto, 4850.50);
      expect(model.tipoLegible, 'Diésel');
      expect(model.odometro, 142500.0);
      expect(model.toJson()['folio'], '#TT-000140');
    });
  });

  group('Pantallas del Chofer (Sprint 3)', () {
    Widget createTestApp(Widget child) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: child,
      );
    }

    testWidgets('C-02: RutaScreen muestra operador, unidad, placas y botón de registro', (tester) async {
      await tester.pumpWidget(createTestApp(const RutaScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Operador asignado'), findsOneWidget);
      expect(find.text('EN RUTA'), findsOneWidget);
      expect(find.text('Kenworth T680 · 2021'), findsOneWidget);
      expect(find.text('NLZ-8823-A'), findsOneWidget);
      expect(find.text('142,500 KM'), findsOneWidget);
      expect(find.text('Monterrey → CDMX'), findsOneWidget);
      expect(find.text('+ Registrar Gasto de Ruta (RF-02)'), findsOneWidget);
      expect(find.text('Ruta'), findsOneWidget);
      expect(find.text('Mis Gastos'), findsOneWidget);
      expect(find.text('Mi Perfil'), findsOneWidget);
    });

    testWidgets('C-03: CapturaGastoScreen rechaza registro sin fotografía (Escenario US-03)', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(const CapturaGastoScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Captura de Gasto en Ruta'), findsOneWidget);
      expect(find.text('Compresión Activa'), findsOneWidget);
      expect(find.text('Diésel'), findsOneWidget);
      expect(find.text('Fluidos'), findsOneWidget);
      expect(find.text('Viáticos'), findsOneWidget);

      // Intentar guardar sin fotografía
      final btnGuardar = find.byKey(const Key('btn_guardar_transmitir'));
      expect(btnGuardar, findsOneWidget);
      await tester.ensureVisible(btnGuardar);
      await tester.tap(btnGuardar);
      await tester.pumpAndSettle();

      // Debe mostrar el error de validación de foto
      expect(find.text('Se requiere capturar la fotografía del comprobante antes de continuar'), findsAtLeastNWidgets(1));
    });

    testWidgets('C-03: Captura de fotografía activa la vista previa y compresión US-09comp', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp(const CapturaGastoScreen()));
      await tester.pumpAndSettle();

      final btnFoto = find.byKey(const Key('btn_tomar_foto'));
      expect(btnFoto, findsOneWidget);
      await tester.ensureVisible(btnFoto);
      await tester.tap(btnFoto);
      await tester.pumpAndSettle();

      expect(find.text('Fotografía Adjuntada y Optimizada'), findsOneWidget);
      expect(find.textContaining('US-09comp'), findsAtLeastNWidgets(1));
    });



    testWidgets('C-04: RegistroProcesadoScreen muestra folio #TT-###### y resumen', (tester) async {
      final gasto = GastoModel(
        id: 'test_1',
        folio: '#TT-000142',
        tipo: 'diesel',
        monto: 4850.0,
        odometro: 142500,
        proveedor: 'OXXO GAS Saltillo',
        fecha: DateTime.now(),
      );

      await tester.pumpWidget(createTestApp(RegistroProcesadoScreen(gasto: gasto)));
      await tester.pumpAndSettle();

      expect(find.text('Evidencia Guardada'), findsOneWidget);
      expect(find.text('Registro Procesado'), findsOneWidget);
      expect(find.text('#TT-000142'), findsOneWidget);
      expect(find.text('\$4850.00 MXN'), findsOneWidget);
      expect(find.text('Capturar Otro Ticket'), findsOneWidget);
      expect(find.text('Regresar a Ruta Activa'), findsOneWidget);
    });

    testWidgets('C-05: MisGastosScreen muestra bitácora y barra de total', (tester) async {
      await tester.pumpWidget(createTestApp(const MisGastosScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Bitácora de Gastos'), findsOneWidget);
      expect(find.text('EVIDENCIAS DOCUMENTADAS EN RUTA'), findsOneWidget);
      expect(find.text('TOTAL ACUMULADO'), findsOneWidget);
    });

    testWidgets('C-06: PerfilChoferScreen muestra datos de operador y botón Cerrar Sesión', (tester) async {
      await tester.pumpWidget(createTestApp(const PerfilChoferScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Perfil de Operador'), findsOneWidget);
      expect(find.text('ESTADO ACTIVO'), findsOneWidget);
      expect(find.text('Licencia Federal: LF-9928172'), findsOneWidget);
      expect(find.text('DATOS DE LA ASIGNACIÓN'), findsOneWidget);
      expect(find.text('Cerrar Sesión'), findsOneWidget);
    });
  });
}
