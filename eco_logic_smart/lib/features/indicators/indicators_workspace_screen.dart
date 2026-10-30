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
  List<MaterialExchangeRequest> _exchanges = [];
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
        WorkspaceRepository.loadExchangeRequests(),
      ]);
      if (!mounted) return;
      setState(() {
        _inventory = data[0] as List<InventoryItem>;
        _materials = data[1] as List<MaterialListing>;
        _routes = data[2] as List<LogisticsRequest>;
        _exchanges = data[3] as List<MaterialExchangeRequest>;
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

  String get _companyId => widget.account.id.isNotEmpty
      ? widget.account.id
      : widget.account.email.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final ownMaterials = _materials
        .where((item) => item.companyId == _companyId && !item.isLegacyLocal)
        .toList();
    final ownRoutes = _routes
        .where((route) => route.companyId == _companyId)
        .toList();
    final activeRoutes = ownRoutes
        .where(
          (route) =>
              route.status == 'Abierta' || route.status == 'En coordinación',
        )
        .length;
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
    final quantitiesByUnit = <String, double>{};
    for (final item in ownMaterials.where(
      (item) => item.status != 'Retirado',
    )) {
      quantitiesByUnit.update(
        item.unit,
        (quantity) => quantity + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }
    final resourcesByCategory = <String, int>{};
    for (final item in _inventory) {
      final category = item.category.trim().isEmpty
          ? 'Sin categoría'
          : item.category;
      resourcesByCategory.update(
        category,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final acceptedExchanges = _exchanges
        .where(
          (request) =>
              request.status == 'Aceptada' &&
              (request.requesterCompanyId == _companyId ||
                  ownMaterials.any(
                    (listing) => listing.id == request.listingId,
                  )),
        )
        .length;
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
                  label: 'Recursos inventariados',
                  value: '${_inventory.length}',
                  icon: Icons.inventory_2_outlined,
                  detail: 'registros de esta empresa',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                  label: 'Intercambios aceptados',
                  value: '$acceptedExchanges',
                  icon: Icons.handshake_outlined,
                  detail: 'acuerdos en la plataforma',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionTitle('Materiales aprovechables'),
          InfoCard(
            icon: Icons.recycling_outlined,
            title: 'Volumen ofrecido por tu empresa',
            subtitle: quantitiesByUnit.isEmpty
                ? 'Aún no has publicado materiales en Circular.'
                : quantitiesByUnit.entries
                      .map(
                        (entry) =>
                            '${entry.value.toStringAsFixed(1)} ${entry.key}',
                      )
                      .join(' · '),
            trailing:
                '${ownMaterials.where((item) => item.status != 'Retirado').length} ofertas',
            color: const Color(0xFFE4F1E7),
          ),
          const SizedBox(height: 12),
          const SectionTitle('Inventario'),
          InfoCard(
            icon: Icons.notification_important_outlined,
            title: 'Recursos para revisar',
            subtitle: 'Existencias iguales o inferiores al umbral configurado.',
            trailing: '$lowStock',
            color: const Color(0xFFFFF0DF),
          ),
          if (resourcesByCategory.isNotEmpty) ...[
            const SectionTitle('Recursos por categoría'),
            for (final entry in resourcesByCategory.entries)
              InfoCard(
                icon: Icons.category_outlined,
                title: entry.key,
                subtitle: 'Recursos registrados en esta categoría.',
                trailing: '${entry.value}',
              ),
          ],
          const SizedBox(height: 12),
          const SectionTitle('Logística'),
          InfoCard(
            icon: Icons.local_shipping_outlined,
            title: 'Tus rutas activas',
            subtitle: 'Solicitudes abiertas o en coordinación de tu empresa.',
            trailing: '$activeRoutes',
          ),
          InfoCard(
            icon: Icons.route_outlined,
            title: 'Destinos coincidentes',
            subtitle: 'Zonas con solicitudes de más de una empresa.',
            trailing: '$sharedRoutes',
            color: const Color(0xFFE7EDF7),
          ),
          const SizedBox(height: 10),
          const Text(
            'El volumen publicado representa ofertas registradas; no equivale a material ya reciclado. El impacto ambiental requiere confirmar la cantidad efectivamente aprovechada.',
            style: TextStyle(fontSize: 11, color: Color(0xFF78847C)),
          ),
        ],
      ],
    );
  }
}
