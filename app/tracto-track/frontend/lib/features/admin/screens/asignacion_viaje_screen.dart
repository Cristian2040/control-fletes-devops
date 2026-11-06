import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/catalogo_models.dart';

/// Pantalla A-04 · Asignación de Viaje (RF-05, US-07, Sprint 7)
///
/// Formulario de despacho de Flete y Anticipo conectado a los catálogos
/// operativos (Clientes, Tarifas/Rutas, Camiones y Choferes) mediante listas
/// desplegables para selección rápida sin necesidad de escribir manualmente:
///   - Cliente Solicitante (Desplegable de Clientes)
///   - Ruta / Tarifa de Catálogo (Auto-llena Origen, Destino y Tarifa Pactada)
///   - Origen y Destino (Desplegables de plazas/ciudades)
///   - Tractocamión Asignado (Desplegable de Unidades de Flota)
///   - Chofer Designado (Desplegable de Operadores)
///   - Tarifa Pactada (MXN) y Anticipo Entregado (MXN)
///   - Botón principal: "Emitir Orden de Viaje (US-07)"
class AsignacionViajeScreen extends StatefulWidget {
  const AsignacionViajeScreen({super.key});

  @override
  State<AsignacionViajeScreen> createState() => _AsignacionViajeScreenState();
}

class _AsignacionViajeScreenState extends State<AsignacionViajeScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _api = ApiClient();

  List<TarifaModel> _tarifasCatalogo = [];

  List<String> _opcionesClientes = [
    'CEMEX S.A. de C.V.',
    'Gruma Internacional',
    'Ternium México',
  ];

  List<String> _opcionesCiudades = [
    'Monterrey',
    'CDMX',
    'San Luis Potosí',
    'GDL',
    'Querétaro',
    'Saltillo',
    'Nuevo Laredo',
    'Veracruz',
  ];

  List<String> _opcionesCamiones = [
    'Kenworth T680 (NLZ-8823-A)',
    'Freightliner Cascadia (SPF-4412-B)',
    'International LT (MTY-9910-C)',
  ];

  List<String> _opcionesChoferes = [
    'Jorge González',
    'Raúl Mendoza',
    'Carlos Herrera',
  ];

  String _clienteSeleccionado = 'CEMEX S.A. de C.V.';
  String _origenSeleccionado = 'Monterrey';
  String _destinoSeleccionado = 'CDMX';
  String _camionSeleccionado = 'Kenworth T680 (NLZ-8823-A)';
  String _choferSeleccionado = 'Jorge González';
  String? _rutaTarifaSeleccionada;

  final TextEditingController _tarifaCtrl =
      TextEditingController(text: '18500');
  final TextEditingController _anticipoCtrl =
      TextEditingController(text: '5000');

  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
  }

  Future<void> _cargarCatalogos() async {
    try {
      final results = await Future.wait([
        _api.fetchClientes(),
        _api.fetchCamiones(),
        _api.fetchChoferes(),
        _api.fetchTarifas(),
      ]);

      if (!mounted) return;

      final clientes = results[0] as List<ClienteModel>;
      final camiones = results[1] as List<CamionModel>;
      final choferes = results[2] as List<ChoferModel>;
      final tarifas = results[3] as List<TarifaModel>;

      setState(() {
        _tarifasCatalogo = tarifas;

        if (clientes.isNotEmpty) {
          final nombresClientes =
              clientes.map((c) => c.razonSocial).toSet().toList();
          _opcionesClientes = nombresClientes;
          if (!_opcionesClientes.contains(_clienteSeleccionado)) {
            _clienteSeleccionado = _opcionesClientes.first;
          }
        }

        if (camiones.isNotEmpty) {
          final etiquetasCamiones = camiones
              .map((c) => '${c.marca} ${c.modelo} (${c.placas})')
              .toSet()
              .toList();
          _opcionesCamiones = etiquetasCamiones;
          if (!_opcionesCamiones.contains(_camionSeleccionado)) {
            _camionSeleccionado = _opcionesCamiones.first;
          }
        }

        if (choferes.isNotEmpty) {
          final nombresChoferes =
              choferes.map((ch) => ch.nombre).toSet().toList();
          _opcionesChoferes = nombresChoferes;
          if (!_opcionesChoferes.contains(_choferSeleccionado)) {
            _choferSeleccionado = _opcionesChoferes.first;
          }
        }

        if (tarifas.isNotEmpty) {
          final ciudadesSet = <String>{..._opcionesCiudades};
          for (final t in tarifas) {
            final partes = t.ruta.split('→').map((s) => s.trim()).toList();
            if (partes.length == 2) {
              if (partes[0].isNotEmpty) ciudadesSet.add(partes[0]);
              if (partes[1].isNotEmpty) ciudadesSet.add(partes[1]);
            }
          }
          _opcionesCiudades = ciudadesSet.toList();
          _rutaTarifaSeleccionada ??= tarifas.first.ruta;
        }
      });
    } catch (_) {}
  }

  void _alSeleccionarTarifaCatalogo(String? rutaSeleccionada) {
    if (rutaSeleccionada == null) return;
    final tarifaObj = _tarifasCatalogo.firstWhere(
      (t) => t.ruta == rutaSeleccionada,
      orElse: () => TarifaModel(
        id: '',
        ruta: rutaSeleccionada,
        tipoCarga: 'General',
        capacidadTon: 28,
        montoBase: 18500,
      ),
    );

    final partes = rutaSeleccionada.split('→').map((e) => e.trim()).toList();
    setState(() {
      _rutaTarifaSeleccionada = rutaSeleccionada;
      if (partes.length == 2) {
        if (!_opcionesCiudades.contains(partes[0])) {
          _opcionesCiudades.add(partes[0]);
        }
        if (!_opcionesCiudades.contains(partes[1])) {
          _opcionesCiudades.add(partes[1]);
        }
        _origenSeleccionado = partes[0];
        _destinoSeleccionado = partes[1];
      }
      _tarifaCtrl.text = tarifaObj.montoBase.toStringAsFixed(0);
    });
  }

  @override
  void dispose() {
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
        cliente: _clienteSeleccionado,
        origen: _origenSeleccionado,
        destino: _destinoSeleccionado,
        camion: _camionSeleccionado,
        chofer: _choferSeleccionado,
        tarifaPactada: tarifa,
        anticipoEntregado: anticipo,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Orden de viaje ${nuevoViaje.folio} emitida exitosamente'),
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
                // 1. CLIENTE SOLICITANTE (Desplegable)
                _buildLabel('Cliente Solicitante'),
                DropdownButtonFormField<String>(
                  key: const Key('input_viaje_cliente'),
                  initialValue: _opcionesClientes.contains(_clienteSeleccionado)
                      ? _clienteSeleccionado
                      : _opcionesClientes.first,
                  dropdownColor: AppTheme.cardDark,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: _inputDecoration(
                    'Seleccione un cliente',
                    prefixIcon: Icons.business_rounded,
                  ),
                  items: _opcionesClientes.map((cliente) {
                    return DropdownMenuItem<String>(
                      value: cliente,
                      child: Text(
                        cliente,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _clienteSeleccionado = val);
                    }
                  },
                ),

                const SizedBox(height: 16),

                // 2. RUTA / TARIFA DEL CATÁLOGO (Opcional para auto-llenar Origen, Destino y Tarifa)
                if (_tarifasCatalogo.isNotEmpty) ...[
                  _buildLabel('Ruta Pactada de Catálogo (Auto-llena tramo y tarifa)'),
                  DropdownButtonFormField<String>(
                    key: const Key('input_viaje_ruta_catalogo'),
                    initialValue: _tarifasCatalogo
                            .any((t) => t.ruta == _rutaTarifaSeleccionada)
                        ? _rutaTarifaSeleccionada
                        : _tarifasCatalogo.first.ruta,
                    dropdownColor: AppTheme.cardDark,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.primaryBlue,
                    ),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: _inputDecoration(
                      'Seleccione ruta registrada',
                      prefixIcon: Icons.route_rounded,
                    ),
                    items: _tarifasCatalogo.map((t) {
                      return DropdownMenuItem<String>(
                        value: t.ruta,
                        child: Text(
                          '${t.ruta}  •  \$${t.montoBase.toStringAsFixed(0)} MXN',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _alSeleccionarTarifaCatalogo,
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. ORIGEN Y DESTINO (Desplegables en la misma fila)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Origen'),
                          DropdownButtonFormField<String>(
                            key: const Key('input_viaje_origen'),
                            initialValue:
                                _opcionesCiudades.contains(_origenSeleccionado)
                                    ? _origenSeleccionado
                                    : _opcionesCiudades.first,
                            isExpanded: true,
                            dropdownColor: AppTheme.cardDark,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.primaryBlue,
                            ),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: _inputDecoration('Origen'),
                            items: _opcionesCiudades.map((ciudad) {
                              return DropdownMenuItem<String>(
                                value: ciudad,
                                child: Text(
                                  ciudad,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _origenSeleccionado = val);
                              }
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
                          _buildLabel('Destino'),
                          DropdownButtonFormField<String>(
                            key: const Key('input_viaje_destino'),
                            initialValue:
                                _opcionesCiudades.contains(_destinoSeleccionado)
                                    ? _destinoSeleccionado
                                    : _opcionesCiudades.first,
                            isExpanded: true,
                            dropdownColor: AppTheme.cardDark,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.primaryBlue,
                            ),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: _inputDecoration('Destino'),
                            items: _opcionesCiudades.map((ciudad) {
                              return DropdownMenuItem<String>(
                                value: ciudad,
                                child: Text(
                                  ciudad,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _destinoSeleccionado = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 4. TRACTOCAMIÓN ASIGNADO (Desplegable)
                _buildLabel('Tractocamión Asignado'),
                DropdownButtonFormField<String>(
                  key: const Key('input_viaje_camion'),
                  initialValue: _opcionesCamiones.contains(_camionSeleccionado)
                      ? _camionSeleccionado
                      : _opcionesCamiones.first,
                  isExpanded: true,
                  dropdownColor: AppTheme.cardDark,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: _inputDecoration(
                    'Seleccione el tractocamión',
                    prefixIcon: Icons.local_shipping_outlined,
                  ),
                  items: _opcionesCamiones.map((camion) {
                    return DropdownMenuItem<String>(
                      value: camion,
                      child: Text(
                        camion,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _camionSeleccionado = val);
                    }
                  },
                ),

                const SizedBox(height: 16),

                // 5. CHOFER DESIGNADO (Desplegable)
                _buildLabel('Chofer Designado'),
                DropdownButtonFormField<String>(
                  key: const Key('input_viaje_chofer'),
                  initialValue: _opcionesChoferes.contains(_choferSeleccionado)
                      ? _choferSeleccionado
                      : _opcionesChoferes.first,
                  isExpanded: true,
                  dropdownColor: AppTheme.cardDark,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.primaryBlue,
                  ),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                  ),
                  decoration: _inputDecoration(
                    'Seleccione el chofer designado',
                    prefixIcon: Icons.badge_outlined,
                  ),
                  items: _opcionesChoferes.map((chofer) {
                    return DropdownMenuItem<String>(
                      value: chofer,
                      child: Text(
                        chofer,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _choferSeleccionado = val);
                    }
                  },
                ),

                const SizedBox(height: 16),

                // 6. TARIFA PACTADA Y ANTICIPO ENTREGADO (Con selector rápido y edición)
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
                            decoration: _inputDecoration(
                              '18500.00',
                              suffixWidget: PopupMenuButton<String>(
                                tooltip: 'Seleccionar tarifa rápida',
                                icon: const Icon(
                                  Icons.arrow_drop_down_circle_outlined,
                                  color: AppTheme.primaryBlue,
                                  size: 20,
                                ),
                                color: AppTheme.cardDark,
                                onSelected: (val) {
                                  setState(() => _tarifaCtrl.text = val);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: '14200',
                                    child: Text('\$14,200 MXN'),
                                  ),
                                  PopupMenuItem(
                                    value: '16800',
                                    child: Text('\$16,800 MXN'),
                                  ),
                                  PopupMenuItem(
                                    value: '18500',
                                    child: Text('\$18,500 MXN'),
                                  ),
                                  PopupMenuItem(
                                    value: '22000',
                                    child: Text('\$22,000 MXN'),
                                  ),
                                ],
                              ),
                            ),
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
                            decoration: _inputDecoration(
                              '5000.00',
                              suffixWidget: PopupMenuButton<String>(
                                tooltip: 'Seleccionar anticipo rápido',
                                icon: const Icon(
                                  Icons.arrow_drop_down_circle_outlined,
                                  color: AppTheme.primaryBlue,
                                  size: 20,
                                ),
                                color: AppTheme.cardDark,
                                onSelected: (val) {
                                  setState(() => _anticipoCtrl.text = val);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: '3000',
                                    child: Text('\$3,000 MXN'),
                                  ),
                                  PopupMenuItem(
                                    value: '4000',
                                    child: Text('\$4,000 MXN'),
                                  ),
                                  PopupMenuItem(
                                    value: '5000',
                                    child: Text('\$5,000 MXN'),
                                  ),
                                  PopupMenuItem(
                                    value: '7500',
                                    child: Text('\$7,500 MXN'),
                                  ),
                                ],
                              ),
                            ),
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
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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

  InputDecoration _inputDecoration(
    String hint, {
    IconData? prefixIcon,
    Widget? suffixWidget,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppTheme.primaryBlue, size: 20)
          : null,
      suffixIcon: suffixWidget,
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
