import 'package:flutter/material.dart';

import '../../models/company_account.dart';
import '../../models/operational_records.dart';
import '../../services/workspace_repository.dart';
import '../../shared/components.dart';

class LogisticsWorkspaceScreen extends StatefulWidget {
  const LogisticsWorkspaceScreen({super.key, required this.account});

  final CompanyAccount account;

  @override
  State<LogisticsWorkspaceScreen> createState() =>
      _LogisticsWorkspaceScreenState();
}

class _LogisticsWorkspaceScreenState extends State<LogisticsWorkspaceScreen> {
  List<LogisticsRequest> _routes = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final routes = await WorkspaceRepository.loadRoutes();
      if (!mounted) return;
      setState(() {
        _routes = routes;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudieron cargar las solicitudes.';
      });
    }
  }

  Future<void> _requestRoute() async {
    final formKey = GlobalKey<FormState>();
    final destination = TextEditingController();
    var deliveryType = 'Materiales';
    final result = await showDialog<(String, String)?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Solicitar ruta'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: destination,
                  decoration: const InputDecoration(
                    labelText: 'Zona de destino',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Escribe una zona de destino'
                      : null,
                ),
                DropdownButtonFormField<String>(
                  initialValue: deliveryType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de entrega',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Paquetes',
                      child: Text('Paquetes'),
                    ),
                    DropdownMenuItem(value: 'Insumos', child: Text('Insumos')),
                    DropdownMenuItem(
                      value: 'Materiales',
                      child: Text('Materiales'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => deliveryType = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(dialogContext, (
                  destination.text.trim(),
                  deliveryType,
                ));
              },
              child: const Text('Enviar solicitud'),
            ),
          ],
        ),
      ),
    );
    destination.dispose();
    if (result == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await WorkspaceRepository.requestRoute(
        account: widget.account,
        destination: result.$1,
        deliveryType: result.$2,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Solicitud registrada.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo registrar la ruta.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, int>{};
    for (final route in _routes) {
      final key = route.destination.trim().toLowerCase();
      grouped.update(key, (count) => count + 1, ifAbsent: () => 1);
    }
    final sharedDestinations = grouped.values
        .where((count) => count > 1)
        .length;
    return PageFrame(
      title: 'Logística compartida',
      subtitle: 'Agrupa entregas y coordina recorridos.',
      action: IconButton.filledTonal(
        tooltip: 'Solicitar ruta',
        onPressed: _saving ? null : _requestRoute,
        icon: const Icon(Icons.add_road),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF173E35),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'OPORTUNIDADES DE CONSOLIDACIÓN',
                style: TextStyle(
                  color: Color(0xFFC6DCCB),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                sharedDestinations == 0
                    ? 'Aún no hay destinos repetidos'
                    : '$sharedDestinations zonas con más de una solicitud',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Las empresas pueden identificar destinos en común y coordinar una entrega.',
                style: TextStyle(color: Color(0xFFD0E3D4), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionTitle('Solicitudes abiertas', trailing: '${_routes.length}'),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: Text(_error!),
          )
        else if (_routes.isEmpty)
          const InfoCard(
            icon: Icons.local_shipping_outlined,
            title: 'Sin solicitudes por ahora',
            subtitle:
                'Registra una ruta para encontrar otros destinos compatibles.',
            color: Color(0xFFFFF0DF),
          )
        else
          for (final route in _routes)
            InfoCard(
              icon: Icons.local_shipping_outlined,
              title: route.destination,
              subtitle: '${route.companyName} · ${route.deliveryType}',
              trailing: _sameDestinationCount(route) > 1
                  ? 'Coincide'
                  : 'Abierta',
              color: const Color(0xFFFFF0DF),
            ),
        const SizedBox(height: 12),
        const SectionTitle('Cómo funciona'),
        const _StepLine(
          number: '1',
          text: 'Registra una necesidad de transporte y su zona de destino.',
        ),
        const _StepLine(
          number: '2',
          text: 'Encuentra empresas con solicitudes en destinos cercanos.',
        ),
        const _StepLine(
          number: '3',
          text: 'Coordina directamente la ruta y el transporte.',
        ),
      ],
    );
  }

  int _sameDestinationCount(LogisticsRequest item) => _routes
      .where(
        (route) =>
            route.destination.trim().toLowerCase() ==
            item.destination.trim().toLowerCase(),
      )
      .length;
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: const Color(0xFFE3EFE6),
          child: Text(
            number,
            style: const TextStyle(
              color: Color(0xFF39815D),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF56665B)),
            ),
          ),
        ),
      ],
    ),
  );
}
