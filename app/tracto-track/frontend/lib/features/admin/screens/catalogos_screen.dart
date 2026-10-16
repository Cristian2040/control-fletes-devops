import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/catalogo_models.dart';
import '../../../shared/widgets/online_indicator.dart';
import '../../../shared/widgets/status_badge.dart';
import '../widgets/admin_bottom_nav_bar.dart';

/**
 * A-05 a A-08 · Catálogos Operativos (RF-05)
 * 
 * Permite al administrador consultar y buscar en las 4 entidades operativas:
 *   - A-05: Camiones (placas, marca, modelo, año, capacidad, estado)
 *   - A-06: Choferes (nombre, licencia federal, contacto, disponibilidad)
 *   - A-07: Clientes (razón social, RFC, días de crédito, estado)
 *   - A-08: Tarifas (ruta pactada, tipo de carga, capacidad, importe MXN)
 * 
 * Cada pestaña incluye buscador en tiempo real y acceso al alta correspondiente (+ Alta).
 */
class CatalogosScreen extends StatefulWidget {
  final int initialTabIndex;

  const CatalogosScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<CatalogosScreen> createState() => _CatalogosScreenState();
}

class _CatalogosScreenState extends State<CatalogosScreen> with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late TabController _tabController;

  final TextEditingController _searchCtrl = TextEditingController();

  List<CamionModel> _camiones = [];
  List<ChoferModel> _choferes = [];
  List<ClienteModel> _clientes = [];
  List<TarifaModel> _tarifas = [];

  bool _cargando = true;
  String _query = '';

  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _lastIndex = widget.initialTabIndex.clamp(0, 3);
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: _lastIndex,
    );
    _tabController.addListener(_onTabChanged);
    _searchCtrl.addListener(_onSearchChanged);
    _cargarTodosLosDatos();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index != _lastIndex) {
      setState(() {
        _lastIndex = _tabController.index;
      });
      _searchCtrl.removeListener(_onSearchChanged);
      _searchCtrl.clear();
      _query = '';
      _searchCtrl.addListener(_onSearchChanged);
      _cargarDatosTabActiva();
    }
  }

  void _onSearchChanged() {
    final text = _searchCtrl.text.trim();
    if (text != _query) {
      setState(() => _query = text);
      _cargarDatosTabActiva();
    }
  }

  Future<void> _cargarTodosLosDatos() async {
    setState(() => _cargando = true);
    try {
      final camiones = await _apiClient.fetchCamiones(query: _query);
      final choferes = await _apiClient.fetchChoferes(query: _query);
      final clientes = await _apiClient.fetchClientes(query: _query);
      final tarifas = await _apiClient.fetchTarifas(query: _query);
      if (mounted) {
        setState(() {
          _camiones = camiones;
          _choferes = choferes;
          _clientes = clientes;
          _tarifas = tarifas;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _cargarDatosTabActiva() async {
    setState(() => _cargando = true);
    try {
      final tab = _tabController.index;
      switch (tab) {
        case 0:
          final res = await _apiClient.fetchCamiones(query: _query);
          if (mounted) setState(() => _camiones = res);
          break;
        case 1:
          final res = await _apiClient.fetchChoferes(query: _query);
          if (mounted) setState(() => _choferes = res);
          break;
        case 2:
          final res = await _apiClient.fetchClientes(query: _query);
          if (mounted) setState(() => _clientes = res);
          break;
        case 3:
          final res = await _apiClient.fetchTarifas(query: _query);
          if (mounted) setState(() => _tarifas = res);
          break;
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _cargarDatos() => _cargarDatosTabActiva();


  String get _searchHint {
    switch (_tabController.index) {
      case 0:
        return 'Buscar en camiones...';
      case 1:
        return 'Buscar en choferes...';
      case 2:
        return 'Buscar en clientes...';
      case 3:
        return 'Buscar en tarifas...';
      default:
        return 'Buscar en catálogo...';
    }
  }

  Future<void> _abrirAlta() async {
    String route;
    switch (_tabController.index) {
      case 0:
        route = AppRoutes.adminAltaCamion;
        break;
      case 1:
        route = AppRoutes.adminAltaChofer;
        break;
      case 2:
        route = AppRoutes.adminAltaCliente;
        break;
      case 3:
        route = AppRoutes.adminAltaTarifa;
        break;
      default:
        route = AppRoutes.adminAltaCamion;
    }

    final resultado = await Navigator.of(context).pushNamed(route);
    if (resultado == true && mounted) {
      _cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text(
          'Catálogos Operativos (RF-05)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              key: const Key('btn_alta_catalogo'),
              onPressed: _abrirAlta,
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: const Text(
                '+ Alta',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: OnlineIndicator(isOnline: true),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryBlue,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Camiones', icon: Icon(Icons.local_shipping_outlined, size: 20)),
            Tab(text: 'Choferes', icon: Icon(Icons.person_outline, size: 20)),
            Tab(text: 'Clientes', icon: Icon(Icons.business_outlined, size: 20)),
            Tab(text: 'Tarifas', icon: Icon(Icons.request_quote_outlined, size: 20)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Buscador superior
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.surfaceDark,
            child: TextField(
              key: const Key('input_buscar_catalogo'),
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: _searchHint,
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.backgroundDark,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                  borderSide: const BorderSide(color: AppTheme.primaryBlue),
                ),
              ),
            ),
          ),

          // Contenido de la pestaña activa
          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCamionesTab(),
                      _buildChoferesTab(),
                      _buildClientesTab(),
                      _buildTarifasTab(),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 2),
    );
  }

  // --- Tab 1: Camiones (A-05) ---
  Widget _buildCamionesTab() {
    if (_camiones.isEmpty) {
      return _buildEmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'No se encontraron unidades',
        subtitle: _query.isNotEmpty
            ? 'Ningún camión coincide con "$_query"'
            : 'Registra un camión con el botón + Alta',
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      color: AppTheme.primaryBlue,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _camiones.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final c = _camiones[index];
          return Card(
            color: AppTheme.surfaceDark,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        c.placas,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                      StatusBadge(label: c.estadoLegible),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c.descripcionCompleta,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.scale_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Capacidad: ${c.capacidadCarga.toStringAsFixed(1)} Ton',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      const Icon(Icons.speed_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${c.kilometraje.toStringAsFixed(0)} km',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Tab 2: Choferes (A-06) ---
  Widget _buildChoferesTab() {
    if (_choferes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_off_outlined,
        title: 'No se encontraron choferes',
        subtitle: _query.isNotEmpty
            ? 'Ningún operador coincide con "$_query"'
            : 'Registra un operador con el botón + Alta',
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      color: AppTheme.primaryBlue,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _choferes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final ch = _choferes[index];
          return Card(
            color: AppTheme.surfaceDark,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          ch.nombre,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      StatusBadge(label: ch.estadoLegible),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.credit_card_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ch.licencia,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 14, color: AppTheme.primaryBlue),
                      const SizedBox(width: 4),
                      Text(
                        ch.telefono,
                        style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue),
                      ),
                      const Spacer(),
                      const Icon(Icons.business_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        ch.empresa,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Tab 3: Clientes (A-07) ---
  Widget _buildClientesTab() {
    if (_clientes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.business_outlined,
        title: 'No se encontraron clientes',
        subtitle: _query.isNotEmpty
            ? 'Ningún cliente coincide con "$_query"'
            : 'Registra un cliente con el botón + Alta',
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      color: AppTheme.primaryBlue,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _clientes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final cl = _clientes[index];
          return Card(
            color: AppTheme.surfaceDark,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          cl.razonSocial,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      StatusBadge(label: cl.estadoLegible),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.receipt_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'RFC: ${cl.rfc}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        'Condición de crédito: ${cl.diasCredito} días',
                        style: const TextStyle(fontSize: 12, color: AppColors.warning),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Tab 4: Tarifas (A-08) ---
  Widget _buildTarifasTab() {
    if (_tarifas.isEmpty) {
      return _buildEmptyState(
        icon: Icons.request_quote_outlined,
        title: 'No se encontraron tarifas',
        subtitle: _query.isNotEmpty
            ? 'Ninguna tarifa pactada coincide con "$_query"'
            : 'Registra una tarifa con el botón + Alta',
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      color: AppTheme.primaryBlue,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tarifas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final t = _tarifas[index];
          return Card(
            color: AppTheme.surfaceDark,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          t.ruta,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.success, width: 1),
                        ),
                        child: Text(
                          '\$${t.montoBase.toStringAsFixed(2)} MXN',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.category_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Carga: ${t.tipoCarga}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      const Icon(Icons.scale_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${t.capacidadTon.toStringAsFixed(1)} Ton',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
