import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/online_indicator.dart';

/**
 * A-09 · Alta en Catálogo – Camiones (RF-05)
 * 
 * Formulario para registrar un nuevo camión en el catálogo operativo:
 * placas, marca, modelo, año y capacidad de carga.
 */
class AltaCamionScreen extends StatefulWidget {
  const AltaCamionScreen({super.key});

  @override
  State<AltaCamionScreen> createState() => _AltaCamionScreenState();
}

class _AltaCamionScreenState extends State<AltaCamionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();

  final _placasCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _anioCtrl = TextEditingController(text: DateTime.now().year.toString());
  final _capacidadCtrl = TextEditingController(text: '30.0');

  bool _guardando = false;

  @override
  void dispose() {
    _placasCtrl.dispose();
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _anioCtrl.dispose();
    _capacidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final anio = int.tryParse(_anioCtrl.text.trim()) ?? DateTime.now().year;
      final capacidad = double.tryParse(_capacidadCtrl.text.trim()) ?? 0.0;

      await _apiClient.crearCamion(
        placas: _placasCtrl.text.trim().toUpperCase(),
        marca: _marcaCtrl.text.trim(),
        modelo: _modeloCtrl.text.trim(),
        anio: anio,
        capacidadCarga: capacidad,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camión registrado en catálogo con éxito'),
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
              'Alta en Catálogo: Camiones',
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
                          Icon(Icons.local_shipping, color: AppTheme.primaryBlue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Datos de la Unidad',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('input_camion_placas'),
                        controller: _placasCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Placas del Camión *',
                          hintText: 'Ej. NLZ-8823-A',
                          prefixIcon: Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Capture las placas del camión';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('input_camion_marca'),
                        controller: _marcaCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Marca *',
                          hintText: 'Ej. Kenworth, Freightliner, Volvo',
                          prefixIcon: Icon(Icons.business_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Capture la marca';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('input_camion_modelo'),
                        controller: _modeloCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Modelo *',
                          hintText: 'Ej. T680, Cascadia',
                          prefixIcon: Icon(Icons.commute_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Capture el modelo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: const Key('input_camion_anio'),
                              controller: _anioCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Año *',
                                hintText: '2023',
                                prefixIcon: Icon(Icons.calendar_today_outlined),
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Requerido';
                                final val = int.tryParse(v.trim());
                                if (val == null || val < 1990 || val > 2035) {
                                  return 'Año inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              key: const Key('input_camion_capacidad'),
                              controller: _capacidadCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Capacidad (Ton) *',
                                hintText: '30.0',
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
                  key: const Key('btn_guardar_camion'),
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
