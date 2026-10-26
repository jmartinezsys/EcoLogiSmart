import 'package:flutter/material.dart';

import '../../models/company_account.dart';
import '../../models/operational_records.dart';
import '../../services/workspace_repository.dart';
import '../../shared/components.dart';
import '../company/company_screen.dart';
import '../diagnosis/diagnosis_workspace_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.account,
    required this.onAccountUpdated,
  });

  final CompanyAccount account;
  final ValueChanged<CompanyAccount> onAccountUpdated;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late CompanyAccount _account = widget.account;
  int _inventoryCount = 0;
  int _materialCount = 0;
  int _routeCount = 0;
  bool _loadingActivity = true;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  String get _ownerId => _account.id.isNotEmpty
      ? _account.id
      : _account.email.trim().toLowerCase();

  Future<void> _loadActivity() async {
    try {
      final results = await Future.wait([
        WorkspaceRepository.loadInventory(_account),
        WorkspaceRepository.loadMaterials(),
        WorkspaceRepository.loadRoutes(),
      ]);
      final inventory = results[0] as List<InventoryItem>;
      final materials = results[1] as List<MaterialListing>;
      final routes = results[2] as List<LogisticsRequest>;
      if (!mounted) return;
      setState(() {
        _inventoryCount = inventory.length;
        _materialCount = materials
            .where((item) => item.companyId == _ownerId)
            .length;
        _routeCount = routes.where((item) => item.companyId == _ownerId).length;
        _loadingActivity = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingActivity = false);
    }
  }

  Future<void> _openProfile(BuildContext context) async {
    final updated = await Navigator.push<CompanyAccount>(
      context,
      MaterialPageRoute<CompanyAccount>(
        builder: (_) => CompanyScreen(account: _account),
      ),
    );
    if (updated != null) {
      setState(() => _account = updated);
      widget.onAccountUpdated(updated);
      _loadActivity();
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _account.contactName.trim().split(RegExp(r'\s+')).first;
    return PageFrame(
      title: 'Hola, $firstName',
      subtitle: 'Este es el espacio de ${_account.businessName}.',
      action: IconButton.filledTonal(
        tooltip: 'Perfil de empresa',
        onPressed: () => _openProfile(context),
        icon: const Icon(Icons.person_outline),
      ),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF143A31), Color(0xFF28664D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -24,
                  top: -32,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0x30FFFFFF),
                        width: 24,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'ESPACIO DE EMPRESA',
                              style: TextStyle(
                                color: Color(0xFFC6DCCB),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Image.asset(
                            'assets/images/ecologismart_isotipo.png',
                            width: 36,
                            height: 36,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.eco_rounded,
                              color: Color(0xFFD8E9DC),
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _account.businessName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ProfilePill(
                            icon: Icons.category_outlined,
                            text: _account.sector,
                          ),
                          _ProfilePill(
                            icon: Icons.location_on_outlined,
                            text: _account.city,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle('Tu actividad'),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: 'Recursos',
                value: _loadingActivity ? '…' : '$_inventoryCount',
                icon: Icons.inventory_2_outlined,
                detail: 'registrados por tu empresa',
              ),
            ),
            SizedBox(width: 11),
            Expanded(
              child: MetricTile(
                label: 'Materiales',
                value: _loadingActivity ? '…' : '$_materialCount',
                icon: Icons.recycling_outlined,
                detail: 'publicados por tu empresa',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InfoCard(
          icon: Icons.local_shipping_outlined,
          title: 'Solicitudes de ruta',
          subtitle: _routeCount == 0
              ? 'Aún no hay solicitudes para esta empresa.'
              : 'Solicitudes activas de ${_account.businessName}.',
          trailing: _loadingActivity ? '…' : '$_routeCount',
          color: Color(0xFFFFF0DF),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Herramientas para todas las empresas'),
        const InfoCard(
          icon: Icons.inventory_2_outlined,
          title: 'Inventario y recursos',
          subtitle: 'Organiza existencias y consumos operativos.',
        ),
        const InfoCard(
          icon: Icons.recycling_outlined,
          title: 'Economía circular',
          subtitle: 'Publica materiales para encontrarles un nuevo uso.',
        ),
        const InfoCard(
          icon: Icons.route_outlined,
          title: 'Logística compartida',
          subtitle: 'Coordina pedidos con destinos cercanos.',
          color: Color(0xFFFFF0DF),
        ),
        const InfoCard(
          icon: Icons.query_stats_rounded,
          title: 'Indicadores',
          subtitle: 'Consulta la actividad e impacto de tu empresa.',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _openProfile(context),
          icon: const Icon(Icons.manage_accounts_outlined),
          label: const Text('Administrar perfil de empresa'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DiagnosisWorkspaceScreen(account: _account),
            ),
          ),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Ver diagnóstico operativo'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Los datos de actividad se mostrarán aquí cuando se registren desde tu cuenta.',
          style: TextStyle(fontSize: 11, color: Color(0xFF78847C)),
        ),
      ],
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 220),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0x1FFFFFFF),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: const Color(0x26FFFFFF)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFD0E3D4), size: 14),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ),
      ],
    ),
  );
}
