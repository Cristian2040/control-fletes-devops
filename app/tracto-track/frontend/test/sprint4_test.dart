/// Pruebas del Sprint 4 — Almacenamiento Local Offline (US-04, RF-03).
///
/// Valida:
/// 1. Integración de la base de datos local embebida en Flutter (LocalGastoRepository/Storage).
/// 2. Flujo de captura de gastos y fotografías guardado localmente sin red (Modo Avión).
/// 3. Bandera de estado 'pendiente de sincronización' frente a 'sincronizado'.
/// 4. Vistas C-02, C-03, C-04 y C-05 en condiciones offline.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracto_trak/core/network/api_client.dart';
import 'package:tracto_trak/core/theme/app_theme.dart';
import 'package:tracto_trak/data/datasources/local_gasto_storage.dart';
import 'package:tracto_trak/data/models/gasto_model.dart';
import 'package:tracto_trak/data/repositories/local_gasto_repository.dart';
import 'package:tracto_trak/features/chofer/screens/captura_gasto_screen.dart';
import 'package:tracto_trak/features/chofer/screens/mis_gastos_screen.dart';
import 'package:tracto_trak/features/chofer/screens/registro_procesado_screen.dart';
import 'package:tracto_trak/features/chofer/screens/ruta_screen.dart';
import 'package:tracto_trak/shared/widgets/online_indicator.dart';
import 'package:tracto_trak/shared/widgets/status_badge.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient().setModoAvion(false);
  });

  group('Punto 1: Base de datos local embebida (LocalGastoRepository / Storage)', () {
    test('Guarda un gasto localmente con fotografía base64 y estado pendiente', () async {
      final storage = LocalGastoStorage();
      await storage.clearAll();
      final repo = LocalGastoRepository.withStorage(storage);

      final gasto = GastoModel(
        id: 'offline_001',
        folio: '',
        tipo: 'diesel',
        monto: 3500.0,
        odometro: 143200,
        proveedor: 'Gasolinera El Trébol',
        fotografiaBase64: 'data:image/jpeg;base64,/9j/4AAQSkZJRg...',
        fotografiaUrl: 'ticket_offline_001.jpg',
        fecha: DateTime.now(),
      );

      final guardado = await repo.guardarGastoOffline(gasto);

      expect(guardado.id, 'offline_001');
      expect(guardado.folio, startsWith('#TT-OFF-'));
      expect(guardado.estadoSincronizacion, 'pendiente');
      expect(guardado.isPendiente, isTrue);
      expect(guardado.isSincronizado, isFalse);
      expect(guardado.fotografiaBase64, contains('base64'));

      final todos = await repo.obtenerTodos();
      expect(todos.length, 1);
      expect(todos.first.folio, guardado.folio);
      expect(todos.first.monto, 3500.0);
    });

    test('Filtra pendientes y cuenta registros pendientes', () async {
      final storage = LocalGastoStorage();
      await storage.clearAll();
      final repo = LocalGastoRepository.withStorage(storage);

      await repo.guardarGastoOffline(GastoModel(
        id: 'gasto_a',
        folio: '',
        tipo: 'diesel',
        monto: 1200.0,
        proveedor: 'Estación Norte',
        fecha: DateTime.now(),
      ));

      await repo.guardarGastoOffline(GastoModel(
        id: 'gasto_b',
        folio: '',
        tipo: 'fluidos',
        monto: 450.0,
        proveedor: 'Refaccionaria Centro',
        fecha: DateTime.now(),
      ));

      expect(await repo.contarPendientes(), 2);
      final pendientes = await repo.obtenerPendientes();
      expect(pendientes.length, 2);

      // Marcar uno como sincronizado
      await repo.marcarComoSincronizado('gasto_a', nuevoFolio: '#TT-000201');
      expect(await repo.contarPendientes(), 1);

      final sincronizados = await repo.obtenerSincronizados();
      expect(sincronizados.length, 1);
      expect(sincronizados.first.folio, '#TT-000201');
      expect(sincronizados.first.isSincronizado, isTrue);
    });

    test('Elimina un gasto local por ID', () async {
      final storage = LocalGastoStorage();
      await storage.clearAll();
      final repo = LocalGastoRepository.withStorage(storage);

      await repo.guardarGastoOffline(GastoModel(
        id: 'gasto_eliminar',
        folio: '',
        tipo: 'viaticos',
        monto: 300.0,
        proveedor: 'Comedor Ruta 57',
        fecha: DateTime.now(),
      ));

      expect(await repo.contarPendientes(), 1);
      await repo.eliminar('gasto_eliminar');
      expect(await repo.contarPendientes(), 0);
    });
  });

  group('Punto 2 y US-04: Captura de gastos en modo avión / offline', () {
    test('Escenario US-04: Chofer sin señal celular registra gasto con fotografía', () async {
      final api = ApiClient();
      await api.localRepo.limpiar();

      // Given que el dispositivo del chofer no tiene señal de red celular (modo avión)
      api.setModoAvion(true);
      expect(api.isOnline, isFalse);
      expect(api.isModoAvion, isTrue);

      // When el chofer registra un gasto con fotografía
      final resultado = await api.registrarGasto(
        tipo: 'diesel',
        monto: 4950.0,
        odometro: 144000,
        proveedor: 'Oxxo Gas Matehuala Km 180',
        fotografiaBase64: 'base64_foto_evidencia_tramo_carretero',
        fotografiaUrl: 'ticket_offline.jpg',
      );

      // Then el sistema guarda el registro y la fotografía localmente en el dispositivo
      expect(resultado['id'], startsWith('offline_'));
      expect(resultado['fotografiaBase64'], 'base64_foto_evidencia_tramo_carretero');
      expect(resultado['monto'], 4950.0);

      // And marca el registro con el estado "pendiente de sincronización"
      expect(resultado['estadoSincronizacion'], 'pendiente');

      // Comprobar que en obtenerGastos() aparece como pendiente en la lista
      final bitacora = await api.obtenerGastos();
      final list = bitacora['gastos'] as List;
      final encontrado = list.firstWhere((e) => e['id'] == resultado['id']);
      expect(encontrado['estadoSincronizacion'], 'pendiente');
      expect(bitacora['totalPendientes'], greaterThanOrEqualTo(1));
    });
  });

  group('Punto 3: Banderas de estado en interfaz visual', () {
    test('StatusBadge muestra icono offline y color de advertencia para pendientes', () {
      const badgePendiente = StatusBadge(
        label: 'PENDIENTE DE SINCRONIZACIÓN',
        showIcon: true,
      );
      expect(badgePendiente.label, 'PENDIENTE DE SINCRONIZACIÓN');
      expect(badgePendiente.showIcon, isTrue);

      const badgeSincronizado = StatusBadge(
        label: 'SINCRONIZADO',
        showIcon: true,
      );
      expect(badgeSincronizado.label, 'SINCRONIZADO');
    });

    test('GastoModel expone getters isPendiente, isSincronizado y estadoSincronizacionLegible', () {
      final gastoPendiente = GastoModel(
        id: '1',
        folio: '#TT-OFF-000001',
        tipo: 'diesel',
        monto: 1000,
        proveedor: 'Oxxo',
        estadoSincronizacion: 'pendiente',
        fecha: DateTime.now(),
      );
      expect(gastoPendiente.isPendiente, isTrue);
      expect(gastoPendiente.isSincronizado, isFalse);
      expect(gastoPendiente.estadoSincronizacionLegible, 'Pendiente de sincronización');

      final gastoSync = gastoPendiente.copyWith(estadoSincronizacion: 'sincronizado');
      expect(gastoSync.isPendiente, isFalse);
      expect(gastoSync.isSincronizado, isTrue);
      expect(gastoSync.estadoSincronizacionLegible, 'Sincronizado');
    });
  });

  group('Punto 4: Pruebas de widgets en modo offline', () {
    Widget createTestApp(Widget child) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: child,
      );
    }

    testWidgets('C-02: RutaScreen permite alternar modo online/offline con toggle', (tester) async {
      final api = ApiClient();
      api.setModoAvion(false);

      await tester.pumpWidget(createTestApp(const RutaScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(OnlineIndicator), findsOneWidget);
      expect(find.text('ONLINE'), findsOneWidget);

      // Alternar a modo offline
      final btnToggle = find.byKey(const Key('btn_toggle_online'));
      expect(btnToggle, findsOneWidget);
      await tester.tap(btnToggle);
      await tester.pumpAndSettle();

      expect(api.isModoAvion, isTrue);
      expect(find.descendant(of: find.byType(OnlineIndicator), matching: find.text('OFFLINE')), findsOneWidget);
    });

    testWidgets('C-03: CapturaGastoScreen muestra banner y botón offline al estar sin red', (tester) async {
      final api = ApiClient();
      api.setModoAvion(true); // Sin red celular

      await tester.pumpWidget(createTestApp(const CapturaGastoScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Modo Fuera de Línea'), findsOneWidget);
      expect(find.textContaining('US-04 / RF-03'), findsOneWidget);
      expect(find.text('Guardar en Dispositivo (Offline)'), findsOneWidget);

      api.setModoAvion(false);
    });

    testWidgets('C-04: RegistroProcesadoScreen muestra badge PENDIENTE DE SINCRONIZACIÓN si se guardó offline', (tester) async {
      final gastoOffline = GastoModel(
        id: 'off_1',
        folio: '#TT-OFF-000005',
        tipo: 'diesel',
        monto: 3200.0,
        odometro: 145000,
        proveedor: 'Estación Matehuala',
        estadoSincronizacion: 'pendiente',
        fecha: DateTime.now(),
      );

      await tester.pumpWidget(createTestApp(RegistroProcesadoScreen(gasto: gastoOffline)));
      await tester.pumpAndSettle();

      expect(find.text('Registro Guardado Localmente'), findsOneWidget);
      expect(find.text('PENDIENTE DE SINCRONIZACIÓN'), findsOneWidget);
      expect(find.textContaining('sin red celular (US-04 / RF-03)'), findsOneWidget);
      expect(find.text('#TT-OFF-000005'), findsOneWidget);
    });

    testWidgets('C-05: MisGastosScreen tiene filtros por estado y muestra badge correspondiente', (tester) async {
      final api = ApiClient();
      await api.localRepo.limpiar();

      // Guardar un gasto offline pendiente
      await api.localRepo.guardarGastoOffline(GastoModel(
        id: 'gasto_test_offline',
        folio: '#TT-OFF-000099',
        tipo: 'fluidos',
        monto: 850.0,
        odometro: 142000,
        proveedor: 'Refaccionaria San Luis',
        estadoSincronizacion: 'pendiente',
        fecha: DateTime.now(),
      ));

      await tester.pumpWidget(createTestApp(const MisGastosScreen()));
      await tester.pumpAndSettle();

      // Verifica presencia de filtros
      expect(find.textContaining('Todos'), findsOneWidget);
      expect(find.textContaining('Pendientes'), findsOneWidget);
      expect(find.textContaining('Sincronizados'), findsOneWidget);

      // Filtrar por Pendientes
      final tabPendientes = find.textContaining('Pendientes');
      await tester.tap(tabPendientes);
      await tester.pumpAndSettle();

      expect(find.text('Refaccionaria San Luis'), findsOneWidget);
      expect(find.text('PENDIENTE DE SINCRONIZACIÓN'), findsWidgets);
    });
  });
}
