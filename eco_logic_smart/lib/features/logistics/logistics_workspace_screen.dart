import 'package:flutter/material.dart';

import '../../models/company_account.dart';
import '../../models/operational_records.dart';
import '../../services/backend_config.dart';
import '../../services/workspace_repository.dart';
import '../../shared/components.dart';
import '../../shared/colombian_city_field.dart';

class LogisticsWorkspaceScreen extends StatefulWidget {
  const LogisticsWorkspaceScreen({super.key, required this.account});

  final CompanyAccount account;

  @override
  State<LogisticsWorkspaceScreen> createState() =>
      _LogisticsWorkspaceScreenState();
}

class _LogisticsWorkspaceScreenState extends State<LogisticsWorkspaceScreen> {
  List<LogisticsRequest> _routes = [];
  List<RouteJoinRequest> _joinRequests = [];
  final _destinationController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        WorkspaceRepository.loadRoutes(),
        WorkspaceRepository.loadRouteJoinRequests(),
      ]);
      final routes = results[0] as List<LogisticsRequest>;
      if (!mounted) return;
      setState(() {
        _routes = routes;
        _joinRequests = results[1] as List<RouteJoinRequest>;
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
    String? origin;
    String? destination;
    final cargo = TextEditingController();
    var deliveryType = 'Materiales';
    var travelDate = DateTime.now().add(const Duration(days: 1));
    final result =
        await showDialog<(String, String, String, String, DateTime)?>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setDialogState) => AlertDialog(
              title: const Text('Publicar una ruta compartida'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ColombianCityField(
                      key: const ValueKey('route-origin'),
                      onChanged: (value) => origin = value,
                    ),
                    const SizedBox(height: 12),
                    ColombianCityField(
                      key: const ValueKey('route-destination'),
                      onChanged: (value) => destination = value,
                    ),
                    const SizedBox(height: 12),
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
                        DropdownMenuItem(
                          value: 'Insumos',
                          child: Text('Insumos'),
                        ),
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cargo,
                      decoration: const InputDecoration(
                        labelText: 'Carga o capacidad disponible',
                        hintText: 'Ej. 2 toneladas de cartón',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Describe la carga o capacidad'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final selected = await showDatePicker(
                          context: dialogContext,
                          initialDate: travelDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (selected != null) {
                          setDialogState(() => travelDate = selected);
                        }
                      },
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text('Fecha: ${_dateLabel(travelDate)}'),
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
                    if (origin == null || destination == null) return;
                    Navigator.pop(dialogContext, (
                      origin!,
                      destination!,
                      deliveryType,
                      cargo.text.trim(),
                      travelDate,
                    ));
                  },
                  child: const Text('Enviar solicitud'),
                ),
              ],
            ),
          ),
        );
    cargo.dispose();
    if (result == null || !mounted) {
      return;
    }
    setState(() => _saving = true);
    try {
      await WorkspaceRepository.requestRoute(
        account: widget.account,
        origin: result.$1,
        destination: result.$2,
        deliveryType: result.$3,
        cargoDescription: result.$4,
        travelDate: result.$5,
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
      title: 'Rutas',
      subtitle: 'Publica una necesidad de transporte o únete a otra ruta.',
      action: IconButton.filledTonal(
        tooltip: 'Solicitar ruta',
        onPressed: _saving ? null : _requestRoute,
        icon: const Icon(Icons.add_road),
      ),
      children: [
        if (BackendConfig.isInitialized &&
            !WorkspaceRepository.hasRouteSharingSchema) ...[
          const InfoCard(
            icon: Icons.warning_amber_rounded,
            title: 'Falta activar las solicitudes para unirse a rutas',
            subtitle:
                'En el SQL Editor ejecuta 20261029000000_marketplace_and_routes.sql. Luego vuelve a comprobar la conexión.',
            color: Color(0xFFFFF0DF),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Comprobar'),
            ),
          ),
          const SizedBox(height: 12),
        ],
        InfoCard(
          icon: BackendConfig.isInitialized
              ? Icons.cloud_done_outlined
              : Icons.phone_android_outlined,
          title: BackendConfig.isInitialized
              ? 'Rutas abiertas compartidas en la red'
              : 'Rutas en demostración local',
          subtitle: BackendConfig.isInitialized
              ? 'Las empresas conectadas pueden ver solicitudes abiertas y buscar destinos en común.'
              : 'Estas solicitudes solo se comparten en este dispositivo. Para conectarlas entre empresas se necesita configurar Supabase.',
          color: const Color(0xFFEAF0F8),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saving ? null : _requestRoute,
            icon: const Icon(Icons.add_road),
            label: const Text('Publicar solicitud de ruta'),
          ),
        ),
        const SizedBox(height: 16),
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
                'Las coincidencias señalan destinos repetidos. La coordinación entre empresas se acuerda por fuera de esta solicitud.',
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
          for (final route in _routes) _routeCard(route),
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

  String get _companyId => widget.account.id.isNotEmpty
      ? widget.account.id
      : widget.account.email.toLowerCase();

  Widget _routeCard(LogisticsRequest route) {
    final own = route.companyId == _companyId;
    final requests = _joinRequests
        .where((request) => request.routeId == route.id)
        .toList();
    final mine = requests
        .where((request) => request.requesterCompanyId == _companyId)
        .toList();
    final date = route.travelDate == null
        ? ''
        : ' · ${_dateLabel(route.travelDate!)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0E6D6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.route_outlined, color: Color(0xFF9B6A32)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${route.origin.isEmpty ? 'Origen pendiente' : route.origin} → ${route.destination}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (_sameDestinationCount(route) > 1)
                const Chip(
                  label: Text('Coincide', style: TextStyle(fontSize: 10)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${route.companyName} · ${route.deliveryType}$date',
            style: const TextStyle(fontSize: 12, color: Color(0xFF59665D)),
          ),
          if (route.cargoDescription.isNotEmpty)
            Text(
              'Carga/capacidad: ${route.cargoDescription}',
              style: const TextStyle(fontSize: 12),
            ),
          Text(
            'Estado: ${route.status}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          if (own &&
              route.status != 'Completada' &&
              route.status != 'Cancelada')
            Wrap(
              spacing: 6,
              children: [
                if (route.status == 'Abierta')
                  TextButton(
                    onPressed: () => _setRouteStatus(route, 'En coordinación'),
                    child: const Text('Iniciar coordinación'),
                  ),
                if (route.status == 'En coordinación')
                  FilledButton.tonal(
                    onPressed: () => _setRouteStatus(route, 'Completada'),
                    child: const Text('Marcar completada'),
                  ),
                TextButton(
                  onPressed: () => _setRouteStatus(route, 'Cancelada'),
                  child: const Text('Cancelar ruta'),
                ),
              ],
            ),
          if (!own && route.status == 'Abierta' && mine.isEmpty)
            Align(
              alignment: Alignment.centerRight,
              child:
                  BackendConfig.isInitialized &&
                      !WorkspaceRepository.hasRouteSharingSchema
                  ? const Text(
                      'Activa la migración de rutas en Supabase para unirte.',
                      textAlign: TextAlign.end,
                      style: TextStyle(fontSize: 11, color: Colors.deepOrange),
                    )
                  : TextButton.icon(
                      onPressed: () => _joinRoute(route),
                      icon: const Icon(Icons.group_add_outlined),
                      label: const Text('Solicitar unirme'),
                    ),
            ),
          if (!own && mine.isNotEmpty)
            for (final request in mine)
              _joinRequestTile(request, allowCancel: true),
          if (own && requests.isNotEmpty) ...[
            const Divider(),
            const Text(
              'Empresas interesadas',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            for (final request in requests) _joinRequestTile(request),
          ],
        ],
      ),
    );
  }

  Widget _joinRequestTile(
    RouteJoinRequest request, {
    bool allowCancel = false,
  }) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            '${request.requesterCompanyName} · ${request.status}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        if (request.status == 'Pendiente' && allowCancel)
          TextButton(
            onPressed: () => _setJoinStatus(request, 'Cancelada'),
            child: const Text('Cancelar'),
          )
        else if (request.status == 'Pendiente') ...[
          TextButton(
            onPressed: () => _setJoinStatus(request, 'Rechazada'),
            child: const Text('Rechazar'),
          ),
          TextButton(
            onPressed: () => _setJoinStatus(request, 'Aceptada'),
            child: const Text('Aceptar'),
          ),
        ],
      ],
    ),
  );

  Future<void> _joinRoute(LogisticsRequest route) async {
    try {
      await WorkspaceRepository.requestToJoinRoute(
        account: widget.account,
        route: route,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud enviada a la empresa.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo solicitar unirse a esta ruta.'),
          ),
        );
      }
    }
  }

  Future<void> _setJoinStatus(RouteJoinRequest request, String status) async {
    try {
      await WorkspaceRepository.updateRouteJoinStatus(request, status);
      if (status == 'Aceptada') {
        final matches = _routes.where((item) => item.id == request.routeId);
        if (matches.isNotEmpty) {
          await WorkspaceRepository.updateRouteStatus(
            matches.first,
            'En coordinación',
          );
        }
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar la solicitud.')),
        );
      }
    }
  }

  Future<void> _setRouteStatus(LogisticsRequest route, String status) async {
    try {
      await WorkspaceRepository.updateRouteStatus(route, status);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar la ruta.')),
        );
      }
    }
  }

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
