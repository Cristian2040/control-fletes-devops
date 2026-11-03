import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';

/// Pantalla A-04 · Asignación de Viaje (RF-05, US-07, Sprint 7)
///
/// Formulario de despacho de Flete y Anticipo:
///   - Cliente Solicitante
///   - Origen y Destino (en la misma fila)
///   - Tractocamión Asignado
///   - Chofer Designado
///   - Tarifa Pactada (MXN) y Anticipo Entregado (MXN) (en la misma fila)
///   - Botón principal: "Emitir Orden de Viaje (US-07)"
class AsignacionViajeScreen extends StatefulWidget {
  const AsignacionViajeScreen({super.key});

  @override
  State<AsignacionViajeScreen> createState() => _AsignacionViajeScreenState();
}

class _AsignacionViajeScreenState extends State<AsignacionViajeScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _api = ApiClient();

  final TextEditingController _clienteCtrl =
      TextEditingController(text: 'CEMEX S.A. de C.V.');
  final TextEditingController _origenCtrl =
      TextEditingController(text: 'Monterrey');
  final TextEditingController _destinoCtrl =
      TextEditingController(text: 'CDMX');
  final TextEditingController _camionCtrl =
      TextEditingController(text: 'Kenworth T680 (NLZ-8823-A)');
  final TextEditingController _choferCtrl =
      TextEditingController(text: 'Jorge González');
  final TextEditingController _tarifaCtrl =
      TextEditingController(text: '18500');
  final TextEditingController _anticipoCtrl =
      TextEditingController(text: '5000');

  bool _guardando = false;

  @override
  void dispose() {
    _clienteCtrl.dispose();
    _origenCtrl.dispose();
    _destinoCtrl.dispose();
    _camionCtrl.dispose();
    _choferCtrl.dispose();
    _tarifaCtrl.dispose();
    _anticipoCtrl.dispose();
    super.dispose();
  }

  Future<void> _emitirOrdenViaje() async {
    if (!_formKey.currentState!.validate()) return;

    final tarifa = double.tryParse(_tarifaCtrl.text.trim()) ?? 0.0;
    final anticipo = double.tryParse(_anticipoCtrl.text.trim()) ?? 0.0;

    setState(() => _guardando = true);
    try {
      final nuevoViaje = await _api.crearViaje(
        cliente: _clienteCtrl.text,
        origen: _origenCtrl.text,
        destino: _destinoCtrl.text,
        camion: _camionCtrl.text,
        chofer: _choferCtrl.text,
        tarifaPactada: tarifa,
        anticipoEntregado: anticipo,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Orden de viaje ${nuevoViaje.folio} emitida exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.adminViajes);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Asignación de Viaje (RF-05)',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Flete y Anticipo',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Cliente Solicitante'),
                TextFormField(
                  key: const Key('input_viaje_cliente'),
                  controller: _clienteCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: _inputDecoration('Ej. CEMEX S.A. de C.V.'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Ingrese el cliente solicitante' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Origen'),
                          TextFormField(
                            key: const Key('input_viaje_origen'),
                            controller: _origenCtrl,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: _inputDecoration('Ej. Monterrey'),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Destino'),
                          TextFormField(
                            key: const Key('input_viaje_destino'),
                            controller: _destinoCtrl,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: _inputDecoration('Ej. CDMX'),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLabel('Tractocamión Asignado'),
                TextFormField(
                  key: const Key('input_viaje_camion'),
                  controller: _camionCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: _inputDecoration('Ej. Kenworth T680 (NLZ-8823-A)'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Seleccione el tractocamión' : null,
                ),
                const SizedBox(height: 16),
                _buildLabel('Chofer Designado'),
                TextFormField(
                  key: const Key('input_viaje_chofer'),
                  controller: _choferCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: _inputDecoration('Ej. Jorge González'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Seleccione el chofer designado' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Tarifa Pactada (MXN)'),
                          TextFormField(
                            key: const Key('input_viaje_tarifa'),
                            controller: _tarifaCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: _inputDecoration('18500.00'),
                            validator: (v) {
                              final numVal = double.tryParse(v ?? '');
                              if (numVal == null || numVal <= 0) {
                                return 'Tarifa inválida';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Anticipo Entregado (MXN)'),
                          TextFormField(
                            key: const Key('input_viaje_anticipo'),
                            controller: _anticipoCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: _inputDecoration('5000.00'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final numVal = double.tryParse(v);
                              if (numVal == null || numVal < 0) {
                                return 'Anticipo inválido';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    key: const Key('btn_emitir_orden_viaje'),
                    onPressed: _guardando ? null : _emitirOrdenViaje,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: const Text(
                      'Emitir Orden de Viaje (US-07)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        texto,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      filled: true,
      fillColor: AppTheme.surfaceDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
      ),
    );
  }
}
