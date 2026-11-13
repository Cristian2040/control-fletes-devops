import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/gasto_model.dart';

/// Pantalla A-14 · Validación de Fotografía (US-08, US-08b, US-09comp — Sprint 8)
///
/// Permite al administrador revisar la fotografía comprimida del ticket junto
/// con los datos declarados por el chofer y decidir si el gasto se aprueba o
/// se rechaza:
///   - Encabezado con flecha de regreso (→ A-13), título "Validación de Fotografía" y folio del ticket.
///   - Tarjeta de evidencia: imagen del ticket (estación, fecha, hora, tipo y total) con la leyenda
///     "Evidencia Fotográfica Comprimida (US-09comp)".
///   - Tarjeta de datos declarados: chofer, unidad, odómetro declarado y monto en comprobante.
///   - Botón secundario "Rechazar Ticket (US-08b)" (rojo).
///   - Botón principal "Aprobar Ticket (US-08)".
class ValidacionFotografiaScreen extends StatefulWidget {
  final GastoModel? gasto;

  const ValidacionFotografiaScreen({
    super.key,
    this.gasto,
  });

  @override
  State<ValidacionFotografiaScreen> createState() =>
      _ValidacionFotografiaScreenState();
}

class _ValidacionFotografiaScreenState
    extends State<ValidacionFotografiaScreen> {
  final ApiClient _api = ApiClient();
  bool _procesando = false;

  GastoModel _resolverGasto(BuildContext context) {
    if (widget.gasto != null) return widget.gasto!;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is GastoModel) return arg;
    if (arg is Map<String, dynamic>) return GastoModel.fromJson(arg);

    return GastoModel(
      id: 'demo_1',
      folio: '#TT-115694',
      tipo: 'viaticos',
      monto: 1240.0,
      odometro: 148320.0,
      proveedor: 'ESTACIÓN PEMEX 4402',
      placasCamion: 'NLZ-8823-A',
      choferNombre: 'Jorge González',
      fecha: DateTime(2026, 9, 18, 14, 7),
    );
  }

  Uint8List? _decodificarFotoReal(String base64Str) {
    if (base64Str.isEmpty ||
        base64Str == 'demo_base64_foto' ||
        base64Str.length < 40) {
      return null;
    }
    try {
      final limpia = base64Str.contains(',')
          ? base64Str.split(',').last.trim()
          : base64Str.trim();
      return base64Decode(limpia);
    } catch (_) {
      return null;
    }
  }

  String _formatearFecha(DateTime f) {
    final dd = f.day.toString().padLeft(2, '0');
    final mm = f.month.toString().padLeft(2, '0');
    final yyyy = f.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String _formatearHora(DateTime f) {
    final hh = f.hour.toString().padLeft(2, '0');
    final mm = f.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _dictaminarTicket(GastoModel gasto, String nuevoEstado) async {
    setState(() => _procesando = true);
    try {
      await _api.auditarGasto(
        gasto: gasto,
        estadoAuditoria: nuevoEstado,
        motivoRechazo: nuevoEstado == 'rechazado'
            ? 'Rechazado en validación de fotografía (US-08b)'
            : null,
      );

      if (!mounted) return;

      final esAprobado = nuevoEstado == 'aprobado';
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            esAprobado
                ? 'Ticket ${gasto.folio} aprobado correctamente (US-08)'
                : 'Ticket ${gasto.folio} rechazado (US-08b)',
          ),
          backgroundColor: esAprobado ? AppColors.success : AppColors.error,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al auditar ticket: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gasto = _resolverGasto(context);
    final bytesFoto = _decodificarFotoReal(gasto.fotografiaBase64);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        leading: IconButton(
          key: const Key('btn_regresar_auditoria'),
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Validación de Fotografía',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              gasto.folio,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildTarjetaEvidencia(gasto, bytesFoto),
                    const SizedBox(height: 18),
                    _buildTarjetaDatosDeclarados(gasto),
                  ],
                ),
              ),
            ),
            _buildBotonesAccion(gasto),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaEvidencia(GastoModel gasto, Uint8List? bytesFoto) {
    final proveedorTitulo = gasto.proveedor.trim().isNotEmpty
        ? gasto.proveedor.toUpperCase()
        : 'ESTACIÓN PEMEX 4402';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          if (bytesFoto != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                bytesFoto,
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 14),
          ],
          // Representación clara del ticket físico para cotejo de datos
          Container(
            width: 240,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  proveedorTitulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Colors.black26),
                ),
                _buildFilaRecibo('FECHA:', _formatearFecha(gasto.fecha)),
                const SizedBox(height: 4),
                _buildFilaRecibo('HORA:', _formatearHora(gasto.fecha)),
                const SizedBox(height: 4),
                _buildFilaRecibo('TIPO:', gasto.tipoLegible.toUpperCase()),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Colors.black26),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL:',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '\$${gasto.monto.toStringAsFixed(2)} MXN',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Evidencia Fotográfica Comprimida (US-09comp)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilaRecibo(String etiqueta, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaDatosDeclarados(GastoModel gasto) {
    final odometroTexto = gasto.odometro != null
        ? '${gasto.odometro!.toStringAsFixed(0)} km'
        : '148320 km';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          _buildFilaDeclarada('Chofer:', gasto.choferNombre),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Colors.white10),
          ),
          _buildFilaDeclarada('Unidad:', gasto.placasCamion),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Colors.white10),
          ),
          _buildFilaDeclarada('Odómetro Declarado:', odometroTexto),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Colors.white10),
          ),
          _buildFilaDeclarada(
            'Monto en Comprobante:',
            '\$${gasto.monto.toStringAsFixed(2)} MXN',
            valorColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildFilaDeclarada(
    String etiqueta,
    String valor, {
    Color valorColor = AppTheme.textPrimary,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            color: valorColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildBotonesAccion(GastoModel gasto) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                key: const Key('btn_rechazar_ticket'),
                onPressed: _procesando
                    ? null
                    : () => _dictaminarTicket(gasto, 'rechazado'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.14),
                  foregroundColor: AppColors.errorLight,
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Rechazar Ticket (US-08b)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                key: const Key('btn_aprobar_ticket'),
                onPressed: _procesando
                    ? null
                    : () => _dictaminarTicket(gasto, 'aprobado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Aprobar Ticket (US-08)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
