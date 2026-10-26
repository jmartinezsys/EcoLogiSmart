import 'package:flutter/material.dart';

import '../../models/company_account.dart';
import '../../models/operational_records.dart';
import '../../services/workspace_repository.dart';
import '../../shared/components.dart';

class DiagnosisWorkspaceScreen extends StatefulWidget {
  const DiagnosisWorkspaceScreen({super.key, required this.account});

  final CompanyAccount account;

  @override
  State<DiagnosisWorkspaceScreen> createState() =>
      _DiagnosisWorkspaceScreenState();
}

class _DiagnosisWorkspaceScreenState extends State<DiagnosisWorkspaceScreen> {
  bool _loading = true;
  String? _error;
  int _lowInventory = 0;
  int _otherMaterials = 0;
  int _matchingRoutes = 0;

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
      final inventory = data[0] as List<InventoryItem>;
      final materials = data[1] as List<MaterialListing>;
      final routes = data[2] as List<LogisticsRequest>;
      final ownerId = widget.account.id.isNotEmpty
          ? widget.account.id
          : widget.account.email.toLowerCase();
      final routeCounts = <String, Set<String>>{};
      for (final route in routes) {
        routeCounts
            .putIfAbsent(route.destination.trim().toLowerCase(), () => {})
            .add(route.companyId);
      }
      if (!mounted) return;
      setState(() {
        _lowInventory = inventory
            .where((item) => item.quantity <= item.lowStockThreshold)
            .length;
        _otherMaterials = materials
            .where((item) => item.companyId != ownerId)
            .length;
        _matchingRoutes = routeCounts.values
            .where((companies) => companies.length > 1)
            .length;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo generar el diagnóstico. Revisa tu conexión.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Diagnóstico operativo',
    subtitle: 'Oportunidades calculadas con los datos actuales.',
    action: IconButton.filledTonal(
      tooltip: 'Actualizar diagnóstico',
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
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFE4F1E7),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: Color(0xFF39815D),
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _lowInventory + _otherMaterials + _matchingRoutes == 0
                      ? 'No encontramos alertas con la información actual.'
                      : 'Hay ${_lowInventory + _otherMaterials + _matchingRoutes} oportunidades para revisar.',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF254A35),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionTitle('Hallazgos'),
        if (_lowInventory > 0)
          InfoCard(
            icon: Icons.inventory_2_outlined,
            title: 'Revisar niveles de inventario',
            subtitle:
                '$_lowInventory recursos están en el nivel mínimo o por debajo.',
            trailing: '$_lowInventory',
            color: const Color(0xFFFFF0DF),
          ),
        if (_otherMaterials > 0)
          InfoCard(
            icon: Icons.recycling_outlined,
            title: 'Materiales publicados por otras empresas',
            subtitle: '$_otherMaterials materiales disponibles para explorar.',
            trailing: '$_otherMaterials',
            color: const Color(0xFFE4F1E7),
          ),
        if (_matchingRoutes > 0)
          InfoCard(
            icon: Icons.route_outlined,
            title: 'Destinos compartidos',
            subtitle:
                '$_matchingRoutes destinos tienen solicitudes de más de una empresa.',
            trailing: '$_matchingRoutes',
            color: const Color(0xFFE7EDF7),
          ),
        if (_lowInventory + _otherMaterials + _matchingRoutes == 0)
          const InfoCard(
            icon: Icons.check_circle_outline,
            title: 'Sin alertas pendientes',
            subtitle:
                'Registra inventario y actividad para generar nuevos hallazgos.',
          ),
        const SizedBox(height: 18),
        const Text(
          'Este diagnóstico es orientativo y usa únicamente inventarios, publicaciones y rutas registradas.',
          style: TextStyle(fontSize: 11, color: Color(0xFF78847C)),
        ),
      ],
    ],
  );
}
