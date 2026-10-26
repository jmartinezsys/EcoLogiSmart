import 'package:flutter/material.dart';

import '../../models/company_account.dart';
import '../../models/operational_records.dart';
import '../../services/workspace_repository.dart';
import '../../shared/components.dart';

class IndicatorsWorkspaceScreen extends StatefulWidget {
  const IndicatorsWorkspaceScreen({super.key, required this.account});

  final CompanyAccount account;

  @override
  State<IndicatorsWorkspaceScreen> createState() =>
      _IndicatorsWorkspaceScreenState();
}

class _IndicatorsWorkspaceScreenState extends State<IndicatorsWorkspaceScreen> {
  List<InventoryItem> _inventory = [];
  List<MaterialListing> _materials = [];
  List<LogisticsRequest> _routes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await Future.wait([
        WorkspaceRepository.loadInventory(widget.account),
        WorkspaceRepository.loadMaterials(),
        WorkspaceRepository.loadRoutes(),
      ]);
      if (!mounted) return;
      setState(() {
        _inventory = data[0] as List<InventoryItem>;
        _materials = data[1] as List<MaterialListing>;
        _routes = data[2] as List<LogisticsRequest>;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudieron actualizar los indicadores.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowStock = _inventory
        .where((item) => item.quantity <= item.lowStockThreshold)
        .length;
    final repeatedDestinations = <String, Set<String>>{};
    for (final route in _routes) {
      repeatedDestinations
          .putIfAbsent(route.destination.trim().toLowerCase(), () => {})
          .add(route.companyId);
    }
    final sharedRoutes = repeatedDestinations.values
        .where((companies) => companies.length > 1)
        .length;
    final sharedMaterialWeight = _materials.fold<double>(
      0,
      (total, item) => total + item.quantity,
    );
    return PageFrame(
      title: 'Indicadores',
      subtitle: 'Resumen de actividad registrada por las empresas.',
      action: IconButton.filledTonal(
        tooltip: 'Actualizar',
        onPressed: _load,
        icon: const Icon(Icons.refresh),
      ),
      children: [
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: Text(_error!),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  label: 'Recursos registrados',
                  value: '${_inventory.length}',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                  label: 'Material disponible',
                  value: sharedMaterialWeight.toStringAsFixed(1),
                  icon: Icons.recycling_outlined,
                  detail: 'cantidad publicada',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionTitle('Actividad operativa'),
          InfoCard(
            icon: Icons.notification_important_outlined,
            title: 'Recursos en nivel mínimo',
            subtitle: 'Existencias iguales o inferiores al umbral configurado.',
            trailing: '$lowStock',
            color: const Color(0xFFFFF0DF),
          ),
          InfoCard(
            icon: Icons.local_shipping_outlined,
            title: 'Solicitudes de logística',
            subtitle: 'Solicitudes abiertas registradas en la plataforma.',
            trailing: '${_routes.length}',
          ),
          InfoCard(
            icon: Icons.route_outlined,
            title: 'Destinos compartidos',
            subtitle: 'Zonas con solicitudes de varias empresas.',
            trailing: '$sharedRoutes',
            color: const Color(0xFFE7EDF7),
          ),
          InfoCard(
            icon: Icons.handshake_outlined,
            title: 'Publicaciones circulares',
            subtitle:
                'Materiales disponibles para conectar con otras empresas.',
            trailing: '${_materials.length}',
            color: const Color(0xFFE4F1E7),
          ),
          const SizedBox(height: 10),
          const Text(
            'El ahorro, la distancia evitada y el impacto ambiental no se estiman hasta contar con datos medidos de costos, recorridos y aprovechamiento.',
            style: TextStyle(fontSize: 11, color: Color(0xFF78847C)),
          ),
        ],
      ],
    );
  }
}
