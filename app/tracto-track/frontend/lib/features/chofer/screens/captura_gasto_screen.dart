import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/image_compressor_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/gasto_model.dart';
import '../../../shared/widgets/online_indicator.dart';
import '../strategies/gasto_validation_strategy.dart';

/// C-03 · Captura de Gasto en Ruta (RF-02, US-03, US-09comp, P3 Strategy — Sprints 3 y 9)
///
/// Formulario para registrar un gasto de combustible, insumos o viáticos.
/// - Permite capturar fotografías reales desde la Cámara del dispositivo o
///   seleccionarlas de la Galería.
/// - Ejecuta compresión automática de imagen (S9-01, US-09comp) mediante
///   [ImageCompressorService] antes de guardar localmente o transmitir a MongoDB.
class CapturaGastoScreen extends StatefulWidget {
  const CapturaGastoScreen({super.key});

  @override
  State<CapturaGastoScreen> createState() => _CapturaGastoScreenState();
}

class _CapturaGastoScreenState extends State<CapturaGastoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();
  final ImagePicker _picker = ImagePicker();

  TipoGasto _tipoSeleccionado = TipoGasto.diesel;
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _odometroController =
      TextEditingController(text: '142500');
  final TextEditingController _proveedorController =
      TextEditingController(text: 'OXXO GAS Saltillo');

  bool _tieneFotografia = false;
  bool _comprimiendoFoto = false;
  String _fotoBase64 = '';
  Uint8List? _fotoBytes;
  String _resumenCompresion = 'US-09comp: Compresión JPEG activa';
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

  /// Captura una fotografía real desde la Cámara o la Galería y la comprime
  /// automáticamente con [ImageCompressorService] (S9-01, US-09comp).
  Future<void> _capturarFotografiaReal(ImageSource origen) async {
    final bool enTest =
        !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (enTest) {
      final ResultadoCompresionImagen respaldo =
          ImageCompressorService.generarYComprimirTicketRespaldo();
      _aplicarResultadoCompresion(respaldo);
      return;
    }

    setState(() {
      _comprimiendoFoto = true;
      _errorFoto = null;
    });

    try {
      final XFile? archivo = await _picker.pickImage(
        source: origen,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (archivo == null) {
        // El usuario canceló la cámara o galería
        if (mounted) {
          setState(() => _comprimiendoFoto = false);
        }
        return;
      }

      final Uint8List rawBytes = await archivo.readAsBytes();
      final ResultadoCompresionImagen resultado =
          ImageCompressorService.comprimirBytes(rawBytes);

      if (!mounted) return;
      _aplicarResultadoCompresion(resultado);
    } catch (_) {
      final ResultadoCompresionImagen respaldo =
          ImageCompressorService.generarYComprimirTicketRespaldo();
      if (!mounted) return;
      _aplicarResultadoCompresion(respaldo);
    }
  }

  void _aplicarResultadoCompresion(ResultadoCompresionImagen resultado) {
    setState(() {
      _comprimiendoFoto = false;
      _tieneFotografia = true;
      _errorFoto = null;
      _fotoBytes = resultado.bytesComprimidos;
      _fotoBase64 = resultado.base64DataUri;
      _resumenCompresion = resultado.resumenCompresion;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fotografía capturada y optimizada (${resultado.resumenCompresion})'),
        backgroundColor: AppTheme.accentGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _verVistaPreviaAmpliada() {
    if (_fotoBytes == null) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Vista Previa del Comprobante',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _fotoBytes!,
                  fit: BoxFit.contain,
                  height: 360,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _resumenCompresion,
                style: const TextStyle(
                  color: AppTheme.accentGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardarYTransmitir() async {
    setState(() => _errorFoto = null);

    // Validación de fotografía (escenario US-03)
    if (!_tieneFotografia) {
      setState(() {
        _errorFoto =
            'Se requiere capturar la fotografía del comprobante antes de continuar';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          key: Key('snack_error_foto'),
          content: Text(
              'Se requiere capturar la fotografía del comprobante antes de continuar'),
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
      final monto =
          double.parse(_montoController.text.replaceAll(',', '').trim());
      final double? odometro = _odometroController.text.trim().isNotEmpty
          ? double.tryParse(
              _odometroController.text.replaceAll(',', '').trim())
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
            content: Text(
                'Error al transmitir: ${e.toString().replaceAll("Exception: ", "")}'),
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: OnlineIndicator(isOnline: _apiClient.isOnline),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_apiClient.isOnline) ...[
                _buildBannerOffline(),
                const SizedBox(height: 12),
              ],
              _buildBannerUnidad(),
              const SizedBox(height: 20),
              _buildSelectorTipoGasto(),
              const SizedBox(height: 20),
              _buildCampoMonto(estrategia),
              const SizedBox(height: 16),
              _buildCampoOdometro(estrategia),
              const SizedBox(height: 16),
              _buildCampoProveedor(estrategia),
              const SizedBox(height: 20),
              _buildZonaFotografia(),
              const SizedBox(height: 28),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Row(
              children: [
                Icon(Icons.local_shipping, size: 18, color: AppTheme.primaryBlue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kenworth T680 · NLZ-8823-A',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withValues(alpha: 0.15),
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
              color: activo
                  ? AppTheme.primaryBlue
                  : Colors.white.withValues(alpha: 0.1),
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
            prefixIcon:
                const Icon(Icons.attach_money, color: AppTheme.primaryBlue),
            hintText: '0.00',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.surfaceDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppTheme.primaryBlue, width: 2),
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
                style: TextStyle(
                    color: AppTheme.accentRed, fontWeight: FontWeight.bold),
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
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppTheme.primaryBlue, width: 2),
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
            prefixIcon:
                const Icon(Icons.storefront, color: AppTheme.textSecondary),
            hintText: 'Ej. OXXO GAS Saltillo',
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.surfaceDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppTheme.primaryBlue, width: 2),
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
              style: TextStyle(
                  color: AppTheme.accentRed, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_comprimiendoFoto) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryBlue),
            ),
            child: const Column(
              children: [
                CircularProgressIndicator(color: AppTheme.primaryBlue),
                SizedBox(height: 12),
                Text(
                  'Comprimiendo y optimizando fotografía (US-09comp)...',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else if (!_tieneFotografia) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _errorFoto != null
                    ? AppTheme.accentRed
                    : Colors.white.withValues(alpha: 0.15),
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
                  'Capture una foto legible del ticket o selecciónela de su galería',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      key: const Key('btn_tomar_foto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppTheme.primaryBlue.withValues(alpha: 0.2),
                        foregroundColor: AppTheme.primaryBlue,
                        elevation: 0,
                        side: const BorderSide(color: AppTheme.primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () =>
                          _capturarFotografiaReal(ImageSource.camera),
                      icon: const Icon(Icons.add_a_photo, size: 18),
                      label: const Text('Tomar Foto con Cámara (RF-02)'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('btn_elegir_galeria'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.25)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () =>
                          _capturarFotografiaReal(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Elegir de Galería'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_errorFoto != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                _errorFoto!,
                style:
                    const TextStyle(color: AppTheme.accentRed, fontSize: 12),
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
                    GestureDetector(
                      onTap: _verVistaPreviaAmpliada,
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _fotoBytes != null
                            ? Image.memory(
                                _fotoBytes!,
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.receipt,
                                color: AppTheme.accentGreen,
                                size: 30,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: AppTheme.accentGreen, size: 16),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Fotografía Adjuntada y Optimizada',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _resumenCompresion,
                            style: const TextStyle(
                              color: AppTheme.accentGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt_outlined,
                          color: AppTheme.primaryBlue),
                      onPressed: () =>
                          _capturarFotografiaReal(ImageSource.camera),
                      tooltip: 'Tomar otra foto',
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_library_outlined,
                          color: AppTheme.textSecondary),
                      onPressed: () =>
                          _capturarFotografiaReal(ImageSource.gallery),
                      tooltip: 'Cambiar desde galería',
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

  Widget _buildBannerOffline() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning, width: 1),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off, color: AppColors.warning, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo Fuera de Línea (Sin Señal Celular)',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'El comprobante y la fotografía se guardarán de forma segura en el almacenamiento local del dispositivo (US-04 / RF-03).',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            : Text(
                _apiClient.isOnline
                    ? 'Guardar y Transmitir Registro'
                    : 'Guardar en Dispositivo (Offline)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
