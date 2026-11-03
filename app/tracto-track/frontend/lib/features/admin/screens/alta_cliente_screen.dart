import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/online_indicator.dart';

/**
 * A-11 · Alta en Catálogo – Clientes (RF-05)
 * 
 * Formulario para registrar un nuevo cliente en el catálogo operativo:
 * razón social, RFC y días de crédito.
 */
class AltaClienteScreen extends StatefulWidget {
  const AltaClienteScreen({super.key});

  @override
  State<AltaClienteScreen> createState() => _AltaClienteScreenState();
}

class _AltaClienteScreenState extends State<AltaClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();

  final _razonCtrl = TextEditingController();
  final _rfcCtrl = TextEditingController();
  final _diasCreditoCtrl = TextEditingController(text: '30');

  bool _guardando = false;

  @override
  void dispose() {
    _razonCtrl.dispose();
    _rfcCtrl.dispose();
    _diasCreditoCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    try {
      final diasCredito = int.tryParse(_diasCreditoCtrl.text.trim()) ?? 0;

      await _apiClient.crearCliente(
        razonSocial: _razonCtrl.text.trim(),
        rfc: _rfcCtrl.text.trim().toUpperCase(),
        diasCredito: diasCredito,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cliente registrado en catálogo con éxito'),
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
              'Alta en Catálogo: Clientes',
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
                          Icon(Icons.business, color: AppTheme.primaryBlue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Datos del Cliente / Empresa',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('input_cliente_razon'),
                        controller: _razonCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Razón Social / Cliente *',
                          hintText: 'Ej. Aceros Monterrey S.A. de C.V.',
                          prefixIcon: Icon(Icons.corporate_fare_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Capture la razón social';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('input_cliente_rfc'),
                        controller: _rfcCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Registro Federal de Contribuyentes (RFC) *',
                          hintText: 'Ej. AMO890315-K42',
                          prefixIcon: Icon(Icons.receipt_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Capture el RFC';
                          }
                          if (v.trim().length < 9) {
                            return 'RFC inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('input_cliente_credito'),
                        controller: _diasCreditoCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Días de Crédito *',
                          hintText: 'Ej. 15, 30, 45',
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Capture los días de crédito';
                          }
                          final dias = int.tryParse(v.trim());
                          if (dias == null || dias < 0) {
                            return 'Número inválido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  key: const Key('btn_guardar_cliente'),
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
