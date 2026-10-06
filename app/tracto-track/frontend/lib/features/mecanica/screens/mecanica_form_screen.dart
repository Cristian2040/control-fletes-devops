/// M-03 · Formulario para crear/editar Orden de Mecánica.
///
/// Permite registrar una nueva orden de reparación con:
/// - Selección de unidad (camión/tráiler)
/// - Descripción de la falla
/// - Tipo de servicio (correctivo/preventivo)
/// - Prioridad (alta/media/baja)
/// - Tiempo estimado de reparación
/// - Piezas necesarias (agregado dinámico)
/// - Mecánico asignado
/// - Notas adicionales
///
/// Navegación: M-01 → M-03
library;

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/online_indicator.dart';

class MecanicaFormScreen extends StatefulWidget {
  const MecanicaFormScreen({super.key});

  @override
  State<MecanicaFormScreen> createState() => _MecanicaFormScreenState();
}

class _MecanicaFormScreenState extends State<MecanicaFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final _descripcionController = TextEditingController();
  final _tiempoEstimadoController = TextEditingController();
  final _mecanicoController = TextEditingController();
  final _kilometrajeController = TextEditingController();
  final _costoEstimadoController = TextEditingController();
  final _notasController = TextEditingController();

  // Estado del formulario
  String _tipoServicio = 'correctivo';
  String _prioridad = 'media';
  String? _camionSeleccionado;
  bool _isLoading = false;

  // Lista dinámica de piezas
  final List<Map<String, dynamic>> _piezas = [];

  // Datos de demostración para el selector de camiones
  final List<Map<String, String>> _camionesMock = [
    {'id': '1', 'label': 'NLZ-8823-A — Kenworth T680 (2021)'},
    {'id': '2', 'label': 'JKL-4421-B — Freightliner Cascadia (2020)'},
    {'id': '3', 'label': 'MNO-7712-C — International LT (2022)'},
  ];

  @override
  void dispose() {
    _descripcionController.dispose();
    _tiempoEstimadoController.dispose();
    _mecanicoController.dispose();
    _kilometrajeController.dispose();
    _costoEstimadoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Orden de Mecánica'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: OnlineIndicator(isOnline: true),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Sección: Unidad ---
                _buildSectionTitle(
                    'Unidad afectada', Icons.local_shipping_outlined),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _camionSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Seleccionar camión/tráiler',
                    prefixIcon: Icon(Icons.local_shipping_outlined,
                        color: AppColors.textMuted),
                  ),
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: _camionesMock
                      .map((c) => DropdownMenuItem(
                            value: c['id'],
                            child: Text(c['label']!,
                                style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _camionSeleccionado = val),
                  validator: (val) =>
                      val == null ? 'Selecciona una unidad' : null,
                ),

                const SizedBox(height: 8),
                TextFormField(
                  controller: _kilometrajeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Kilometraje al ingreso',
                    prefixIcon:
                        Icon(Icons.speed, color: AppColors.textMuted),
                    hintText: 'Ej. 125340',
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),

                const SizedBox(height: 20),

                // --- Sección: Falla ---
                _buildSectionTitle(
                    'Descripción de la falla', Icons.report_problem_outlined),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descripcionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Describe la falla o problema detectado',
                    alignLabelWithHint: true,
                    hintText:
                        'Ej. Fuga de aceite en el motor principal detectada durante inspección de rutina',
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'La descripción es obligatoria'
                      : null,
                ),

                const SizedBox(height: 20),

                // --- Sección: Tipo y Prioridad ---
                _buildSectionTitle(
                    'Clasificación', Icons.category_outlined),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tipo de servicio',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                          const SizedBox(height: 6),
                          _buildSegmentedSelector(
                            options: ['correctivo', 'preventivo'],
                            labels: ['Correctivo', 'Preventivo'],
                            selected: _tipoServicio,
                            onChanged: (val) =>
                                setState(() => _tipoServicio = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Prioridad',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                          const SizedBox(height: 6),
                          _buildPrioridadSelector(),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // --- Sección: Tiempo y mecánico ---
                _buildSectionTitle('Reparación', Icons.build_outlined),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tiempoEstimadoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tiempo estimado (hrs)',
                          prefixIcon: Icon(Icons.access_time,
                              color: AppColors.textMuted),
                        ),
                        style:
                            const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _costoEstimadoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Costo estimado (\$)',
                          prefixIcon: Icon(Icons.attach_money,
                              color: AppColors.textMuted),
                        ),
                        style:
                            const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _mecanicoController,
                  decoration: const InputDecoration(
                    labelText: 'Mecánico asignado',
                    prefixIcon: Icon(Icons.engineering,
                        color: AppColors.textMuted),
                    hintText: 'Ej. Roberto García',
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),

                const SizedBox(height: 20),

                // --- Sección: Piezas ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle(
                        'Piezas necesarias', Icons.settings_outlined),
                    TextButton.icon(
                      onPressed: _mostrarDialogoPieza,
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Agregar'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_piezas.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.textMuted.withValues(alpha: 0.3)),
                    ),
                    child: const Center(
                      child: Text(
                        'Sin piezas registradas.\nPresiona "Agregar" para añadir refacciones.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  ..._piezas.asMap().entries.map((entry) {
                    final i = entry.key;
                    final p = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.settings,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['nombre'],
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Cant: ${p['cantidad']}  •  \$${(p['costoUnitario'] ?? p['costo'] ?? 0)} c/u',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error, size: 20),
                            onPressed: () =>
                                setState(() => _piezas.removeAt(i)),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 20),

                // --- Sección: Notas ---
                _buildSectionTitle('Notas adicionales', Icons.note_alt_outlined),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notasController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones o instrucciones especiales',
                    alignLabelWithHint: true,
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),

                const SizedBox(height: 32),

                // --- Botón Crear Orden ---
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _onCrearOrden,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save, color: Colors.white),
                    label: Text(
                      _isLoading ? 'Registrando...' : 'Registrar Orden',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedSelector({
    required List<String> options,
    required List<String> labels,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final isSelected = selected == options[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(options[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPrioridadSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildPrioridadChip('alta', 'Alta', AppColors.error),
          _buildPrioridadChip('media', 'Media', AppColors.warning),
          _buildPrioridadChip('baja', 'Baja', AppColors.success),
        ],
      ),
    );
  }

  Widget _buildPrioridadChip(String value, String label, Color color) {
    final isSelected = _prioridad == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _prioridad = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoPieza() {
    final nombreCtrl = TextEditingController();
    final cantidadCtrl = TextEditingController(text: '1');
    final costoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Agregar Pieza',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre de la pieza'),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: cantidadCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: costoCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Costo unitario'),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nombreCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _piezas.add({
                    'nombre': nombreCtrl.text.trim(),
                    'cantidad': int.tryParse(cantidadCtrl.text) ?? 1,
                    'costoUnitario': double.tryParse(costoCtrl.text) ?? 0,
                    'costo': double.tryParse(costoCtrl.text) ?? 0,
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Agregar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _onCrearOrden() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulación (se conectará a ApiClient en sprint correspondiente)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Orden de mecánica registrada exitosamente'),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.pop(context);
  }
}
