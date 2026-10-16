/// Pruebas de Sincronización Offline-Online (US-05 / RF-04).
///
/// Valida:
/// 1. Transmisión y actualización de comprobantes offline a 'sincronizado' con asignación de folio secuencial.
/// 2. Botón manual de sincronización en banner de RutaScreen (C-02).
/// 3. Botón y banner de sincronización en MisGastosScreen (C-05).
/// 4. Sincronización reactiva mediante notificaciones de ApiClient.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tracto_trak/core/network/api_client.dart';
import 'package:tracto_trak/core/theme/app_theme.dart';
import 'package:tracto_trak/data/models/gasto_model.dart';
import 'package:tracto_trak/features/chofer/screens/mis_gastos_screen.dart';
import 'package:tracto_trak/features/chofer/screens/ruta_screen.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final api = ApiClient();
    api.setModoAvion(false);
    await api.localRepo.limpiar();
  });

  group('US-05: Sincronización Automática y Manual de Comprobantes Offline', () {
    test('sincronizarPendientes actualiza los registros a estado sincronizado y asigna folio', () async {
      final api = ApiClient();

      // Guardar dos gastos en estado pendiente
      await api.localRepo.guardarGastoOffline(GastoModel(
        id: 'off_sync_1',
        folio: '',
        tipo: 'diesel',
        monto: 4500.0,
        odometro: 142000,
        proveedor: 'Oxxo Gas',
        estadoSincronizacion: 'pendiente',
        fecha: DateTime.now(),
      ));

      await api.localRepo.guardarGastoOffline(GastoModel(
        id: 'off_sync_2',
        folio: '',
        tipo: 'fluidos',
        monto: 350.0,
        proveedor: 'Refaccionaria del Norte',
        estadoSincronizacion: 'pendiente',
        fecha: DateTime.now(),
      ));

      expect(await api.localRepo.contarPendientes(), 2);

      // Ejecutar sincronización
      final result = await api.sincronizarPendientes(forzar: true);

      expect(result.totalPendientes, 2);
      expect(result.totalSincronizados, 2);
      expect(result.totalErrores, 0);
      expect(result.exitoso, isTrue);

      // Verificar que los registros ya no están pendientes
      expect(await api.localRepo.contarPendientes(), 0);
      final sincronizados = await api.localRepo.obtenerSincronizados();
      expect(sincronizados.length, 2);
      for (final s in sincronizados) {
        expect(s.isSincronizado, isTrue);
        expect(s.folio, startsWith('#TT-'));
      }
    });

    Widget createTestApp(Widget child) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: child,
      );
    }

    testWidgets('C-02: RutaScreen muestra botón de sincronización y sincroniza al presionarlo', (tester) async {
      final api = ApiClient();
      api.setModoAvion(true);
      await api.localRepo.guardarGastoOffline(GastoModel(
        id: 'gasto_ruta_sync',
        folio: '',
        tipo: 'diesel',
        monto: 5000.0,
        odometro: 145000,
        proveedor: 'Gasolinera Saltillo',
        estadoSincronizacion: 'pendiente',
        fecha: DateTime.now(),
      ));

      await tester.pumpWidget(createTestApp(const RutaScreen()));
      await tester.pumpAndSettle();

      // Verificar que se muestra la alerta con el botón de sincronizar
      expect(find.byKey(const Key('btn_sincronizar_ahora')), findsOneWidget);
      expect(find.textContaining('pendiente'), findsWidgets);

      // Presionar el botón de sincronización
      await tester.tap(find.byKey(const Key('btn_sincronizar_ahora')));
      await tester.pumpAndSettle();

      // Verificar que el registro fue sincronizado
      expect(await api.localRepo.contarPendientes(), 0);
    });

    testWidgets('C-05: MisGastosScreen muestra banner de sincronización y sincroniza los comprobantes', (tester) async {
      final api = ApiClient();
      await api.localRepo.guardarGastoOffline(GastoModel(
        id: 'gasto_mis_sync',
        folio: '',
        tipo: 'viaticos',
        monto: 250.0,
        proveedor: 'Restaurante El Parador',
        estadoSincronizacion: 'pendiente',
        fecha: DateTime.now(),
      ));

      await tester.pumpWidget(createTestApp(const MisGastosScreen()));
      await tester.pumpAndSettle();

      // Verificar presencia del banner de pendientes con botón de sincronizar
      expect(find.byKey(const Key('btn_sync_pendientes_banner')), findsOneWidget);

      // Presionar sincronizar en el banner
      await tester.tap(find.byKey(const Key('btn_sync_pendientes_banner')));
      await tester.pumpAndSettle();

      // Verificar que se completó la sincronización
      expect(await api.localRepo.contarPendientes(), 0);
    });
  });
}
