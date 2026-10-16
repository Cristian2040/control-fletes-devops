import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/online_indicator.dart';

/**
 * A-12 · Alta en Catálogo – Tarifas (RF-05)
 * 
 * Formulario para registrar una nueva tarifa base en el catálogo operativo:
 * ruta pactada, tipo de carga, capacidad y monto base en MXN.
 */
class AltaTarifaScreen extends StatefulWidget {
  const AltaTarifaScreen({super.key});

  @override
  State<AltaTarifaScreen> createState() => _AltaTarifaScreenState();
}

class _AltaTarifaScreenState extends State<AltaTarifaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();

  final _rutaCtrl = TextEditingController();
  final _tipoCargaCtrl = TextEditingController(text: 'General');
  final _capacidadCtrl = TextEditingController(text: '25.0');
  final _montoCtrl = TextEditingController();

  bool _guardando = false;

  @override
  void dispose() {
    _rutaCtrl.dispose();
    _tipoCargaCtrl.dispose();
    _capacidadCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final monto = double.tryParse(_montoCtrl.text.replaceAll(',', '').trim()) ?? 0.0;
      final capacidad = double.tryParse(_capacidadCtrl.text.trim()) ?? 25.0;

      await _apiClient.crearTarifa(
        ruta: _rutaCtrl.text.trim(),
        tipoCarga: _tipoCargaCtrl.text.trim(),
        montoBase: monto,
        capacidadTon: capacidad,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarifa registrada en catálogo con éxito'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Column(
          children: [
            Text(
              'Alta en Catálogo: Tarifas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Registro para asignaciones operativas (RF-05)',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: OnlineIndicator(isOnline: true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: AppTheme.surfaceDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.request_quote, color: AppTheme.primaryBlue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Parámetros de la Tarifa Pactada',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('input_tarifa_ruta'),
                        controller: _rutaCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Ruta o Tramo Pactado *',
                          hintText: 'Ej. Monterrey — Guadalajara',
                          prefixIcon: Icon(Icons.route_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Capture la ruta o tramo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _tipoCargaCtrl.text.isEmpty ? 'General' : _tipoCargaCtrl.text,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Carga *',
                          prefixIcon: Icon(Icons.category_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'General', child: Text('Carga General')),
                          DropdownMenuItem(value: 'Refrigerada', child: Text('Refrigerada')),
                          DropdownMenuItem(value: 'Peligrosa', child: Text('Material Peligroso')),
                          DropdownMenuItem(value: 'Granel', child: Text('A Granel')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            _tipoCargaCtrl.text = val;
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: const Key('input_tarifa_capacidad'),
                              controller: _capacidadCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Capacidad (Ton) *',
                                hintText: '25.0',
                                prefixIcon: Icon(Icons.scale_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Requerido';
                                final val = double.tryParse(v.trim());
                                if (val == null || val <= 0) return 'Mayor a 0';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              key: const Key('input_tarifa_monto'),
                              controller: _montoCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Monto Base (MXN) *',
                                hintText: '24,500.00',
                                prefixIcon: Icon(Icons.attach_money),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Requerido';
                                final val = double.tryParse(v.replaceAll(',', '').trim());
                                if (val == null || val <= 0) return 'Importe inválido';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  key: const Key('btn_guardar_tarifa'),
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _guardando ? 'Guardando...' : 'Guardar en Catálogo (RF-05)',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
