import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/gasto_model.dart';
import '../strategies/gasto_validation_strategy.dart';


/**
 * C-03 · Captura de Gasto en Ruta (RF-02, US-03, US-09comp, P3 Strategy)
 * 
 * Formulario para registrar un gasto de combustible, insumos o viáticos.
 * Aplica el patrón Strategy para validar campos según el tipo de gasto.
 * Exige obligatoriamente fotografía del comprobante (US-03) con
 * compresión automática activa (US-09comp).
 */
class CapturaGastoScreen extends StatefulWidget {
  const CapturaGastoScreen({super.key});

  @override
  State<CapturaGastoScreen> createState() => _CapturaGastoScreenState();
}

class _CapturaGastoScreenState extends State<CapturaGastoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();

  TipoGasto _tipoSeleccionado = TipoGasto.diesel;
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _odometroController = TextEditingController(text: '142500');
  final TextEditingController _proveedorController = TextEditingController(text: 'OXXO GAS Saltillo');

  bool _tieneFotografia = false;
  String _fotoBase64 = '';
  bool _enviando = false;
  String? _errorFoto;

  GastoValidationStrategy get _estrategiaActual =>
      GastoValidationContext.getStrategy(_tipoSeleccionado);

  @override
  void dispose() {
    _montoController.dispose();
    _odometroController.dispose();
    _proveedorController.dispose();
    super.dispose();
  }

  void _simularCapturaFotografia() {
    setState(() {
      _tieneFotografia = true;
      _errorFoto = null;
      _fotoBase64 = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBD...TICKET_EVIDENCIA';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fotografía capturada y optimizada (1.8 MB → 142 KB, US-09comp)'),
        backgroundColor: AppTheme.accentGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _guardarYTransmitir() async {
    setState(() => _errorFoto = null);

    // Validación de fotografía (escenario US-03)
    if (!_tieneFotografia) {
      setState(() {
        _errorFoto = 'Se requiere capturar la fotografía del comprobante antes de continuar';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          key: Key('snack_error_foto'),
          content: Text('Se requiere capturar la fotografía del comprobante antes de continuar'),
          backgroundColor: AppTheme.accentRed,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _enviando = true);

    try {
      final monto = double.parse(_montoController.text.replaceAll(',', '').trim());
      final double? odometro = _odometroController.text.trim().isNotEmpty
          ? double.tryParse(_odometroController.text.replaceAll(',', '').trim())
          : null;

      final gastoData = await _apiClient.registrarGasto(
        tipo: _estrategiaActual.tipoNombre.toLowerCase(),
        monto: monto,
        odometro: odometro,
        proveedor: _proveedorController.text.trim(),
        fotografiaUrl: 'ticket_${DateTime.now().millisecondsSinceEpoch}.jpg',
        fotografiaBase64: _fotoBase64,
        placasCamion: 'NLZ-8823-A',
      );

      final nuevoGasto = GastoModel.fromJson(gastoData);

      if (mounted) {
        setState(() => _enviando = false);
        // Navegar a C-04 con el gasto creado
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.choferRegistro,
          arguments: nuevoGasto,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al transmitir: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estrategia = _estrategiaActual;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Captura de Gasto en Ruta',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner de unidad y compresión activa
              _buildBannerUnidad(),
              const SizedBox(height: 20),

              // 1. Selector segmentado: Tipo de Insumo o Gasto
              _buildSelectorTipoGasto(),
              const SizedBox(height: 20),

              // 2. Campo: Monto del Comprobante
              _buildCampoMonto(estrategia),
              const SizedBox(height: 16),

              // 3. Campo: Lectura de Odómetro (Obligatorio/Opcional según Strategy)
              _buildCampoOdometro(estrategia),
              const SizedBox(height: 16),

              // 4. Campo: Proveedor o Estación de Carga
              _buildCampoProveedor(estrategia),
              const SizedBox(height: 20),

              // 5. Zona: Fotografía del Ticket (Obligatoria, US-03, US-09comp)
              _buildZonaFotografia(),
              const SizedBox(height: 28),

              // Botón Principal: Guardar y Transmitir Registro
              _buildBotonGuardar(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerUnidad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.local_shipping, size: 18, color: AppTheme.primaryBlue),
              SizedBox(width: 8),
              Text(
                'Kenworth T680 · NLZ-8823-A',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Compresión Activa',
              style: TextStyle(
                color: AppTheme.accentGreen,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorTipoGasto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. Tipo de Insumo o Gasto',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildOpcionTipo(
              tipo: TipoGasto.diesel,
              label: 'Diésel',
              icon: Icons.local_gas_station,
            ),
            const SizedBox(width: 8),
            _buildOpcionTipo(
              tipo: TipoGasto.fluidos,
              label: 'Fluidos',
              icon: Icons.oil_barrel,
            ),
            const SizedBox(width: 8),
            _buildOpcionTipo(
              tipo: TipoGasto.viaticos,
              label: 'Viáticos',
              icon: Icons.restaurant,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOpcionTipo({
    required TipoGasto tipo,
    required String label,
    required IconData icon,
  }) {
    final activo = _tipoSeleccionado == tipo;
    return Expanded(
      child: InkWell(
        key: Key('opcion_tipo_${tipo.name}'),
        onTap: () {
          setState(() {
            _tipoSeleccionado = tipo;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: activo ? AppTheme.primaryBlue : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: activo ? AppTheme.primaryBlue : Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: activo ? Colors.white : AppTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: activo ? Colors.white : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: activo ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampoMonto(GastoValidationStrategy estrategia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. Monto del Comprobante (MXN)',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: const Key('campo_monto'),
          controller: _montoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.attach_money, color: AppTheme.primaryBlue),
            hintText: '0.00',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.surfaceDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
          ),
          validator: estrategia.validarMonto,
        ),
      ],
    );
  }

  Widget _buildCampoOdometro(GastoValidationStrategy estrategia) {
    final obligatorio = estrategia.requiereOdometro;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '3. Lectura de Odómetro (${obligatorio ? "Obligatorio" : "Opcional"})',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (obligatorio)
              const Text(
                ' *',
                style: TextStyle(color: AppTheme.accentRed, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: const Key('campo_odometro'),
          controller: _odometroController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.speed, color: AppTheme.textSecondary),
            suffixText: 'KM',
            suffixStyle: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
            hintText: 'Ej. 142500',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.surfaceDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
          ),
          validator: estrategia.validarOdometro,
        ),
      ],
    );
  }

  Widget _buildCampoProveedor(GastoValidationStrategy estrategia) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '4. Proveedor o Estación de Carga',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: const Key('campo_proveedor'),
          controller: _proveedorController,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.storefront, color: AppTheme.textSecondary),
            hintText: 'Ej. OXXO GAS Saltillo',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.surfaceDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
            ),
          ),
          validator: estrategia.validarProveedor,
        ),
      ],
    );
  }

  Widget _buildZonaFotografia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              '5. Fotografía del Ticket (Obligatoria)',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(color: AppTheme.accentRed, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!_tieneFotografia) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _errorFoto != null ? AppTheme.accentRed : Colors.white.withOpacity(0.15),
                style: BorderStyle.solid,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.camera_alt_outlined,
                  size: 44,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Capture una foto legible del ticket o comprobante',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  key: const Key('btn_tomar_foto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                    foregroundColor: AppTheme.primaryBlue,
                    elevation: 0,
                    side: const BorderSide(color: AppTheme.primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _simularCapturaFotografia,
                  icon: const Icon(Icons.add_a_photo, size: 18),
                  label: const Text('Tomar Foto con Cámara (RF-02)'),
                ),
              ],
            ),
          ),
          if (_errorFoto != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                _errorFoto!,
                style: const TextStyle(color: AppTheme.accentRed, fontSize: 12),
              ),
            ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentGreen, width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.receipt,
                        color: AppTheme.accentGreen,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Fotografía Adjuntada y Optimizada',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                            'US-09comp: 1.8 MB → 142 KB (92% optimizado)',
                            style: TextStyle(
                              color: AppTheme.accentGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
                      onPressed: _simularCapturaFotografia,
                      tooltip: 'Volver a tomar',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBotonGuardar() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        key: const Key('btn_guardar_transmitir'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: _enviando ? null : _guardarYTransmitir,
        child: _enviando
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Guardar y Transmitir Registro',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
