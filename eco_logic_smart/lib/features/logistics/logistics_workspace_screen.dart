import 'package:flutter/material.dart';

import '../../models/company_account.dart';
import '../../models/operational_records.dart';
import '../../data/resource_catalog.dart';
import '../../services/backend_config.dart';
import '../../services/osm_routing_service.dart';
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
    var inventory = <InventoryItem>[];
    try {
      inventory = await WorkspaceRepository.loadInventory(widget.account);
    } catch (_) {
      // A route can still be described from the catalog when no inventory loads.
    }
    final formKey = GlobalKey<FormState>();
    String? origin;
    String? destination;
    final cargoQuantity = TextEditingController(text: '1');
    final customCargoProduct = TextEditingController();
    final originAddress = TextEditingController();
    final destinationAddress = TextEditingController();
    var selectedCargoProduct = inventory.isEmpty
        ? ResourceCatalog.allProducts.first
        : inventory.first.name;
    var customCargo = false;
    var cargoUnit = inventory.isEmpty
        ? ResourceCatalog.unitsForCategory(
            ResourceCatalog.categoryForProduct(
              ResourceCatalog.allProducts.first,
            ),
          ).first
        : inventory.first.unit;

    List<String> cargoUnits() {
      final matched = inventory.where(
        (item) => item.name == selectedCargoProduct,
      );
      final category = matched.isNotEmpty && matched.first.category.isNotEmpty
          ? matched.first.category
          : ResourceCatalog.categoryForProduct(selectedCargoProduct);
      final units = ResourceCatalog.unitsForCategory(category).toList();
      if (matched.isNotEmpty && !units.contains(matched.first.unit)) {
        units.insert(0, matched.first.unit);
      }
      return units;
    }

    String cargoCategory() {
      if (customCargo) return 'Otro';
      final matched = inventory.where(
        (item) => item.name == selectedCargoProduct,
      );
      if (matched.isNotEmpty && matched.first.category.isNotEmpty) {
        return matched.first.category;
      }
      return ResourceCatalog.categoryForProduct(selectedCargoProduct);
    }

    var deliveryType = 'Materiales';
    var transportType = 'Camión';
    var travelDate = DateTime.now().add(const Duration(days: 1));
    var routeOptions = <RouteEstimate>[];
    RouteEstimate? selectedRoute;
    var calculatingRoute = false;
    String? routeError;
    if (!mounted) return;
    final result =
        await showDialog<
          (
            String,
            String,
            String,
            String,
            String,
            String,
            String,
            DateTime,
            RouteEstimate?,
          )?
        >(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setDialogState) => AlertDialog(
              title: const Text('Publicar una ruta compartida'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ColombianCityField(
                        key: const ValueKey('route-origin'),
                        onChanged: (value) {
                          origin = value;
                          setDialogState(() {
                            selectedRoute = null;
                            routeOptions = [];
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: originAddress,
                        decoration: const InputDecoration(
                          labelText: 'Dirección exacta de origen',
                          hintText: 'Vía, número, barrio, bodega o muelle',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Especifica la dirección de recogida'
                            : null,
                        onChanged: (_) => setDialogState(() {
                          selectedRoute = null;
                          routeOptions = [];
                        }),
                      ),
                      const SizedBox(height: 12),
                      ColombianCityField(
                        key: const ValueKey('route-destination'),
                        onChanged: (value) {
                          destination = value;
                          setDialogState(() {
                            selectedRoute = null;
                            routeOptions = [];
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: destinationAddress,
                        decoration: const InputDecoration(
                          labelText: 'Dirección exacta de entrega',
                          hintText: 'Vía, número, barrio, bodega o terminal',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Especifica la dirección de entrega'
                            : null,
                        onChanged: (_) => setDialogState(() {
                          selectedRoute = null;
                          routeOptions = [];
                        }),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed:
                            calculatingRoute ||
                                origin == null ||
                                destination == null ||
                                originAddress.text.trim().isEmpty ||
                                destinationAddress.text.trim().isEmpty ||
                                !{
                                  'Camión',
                                  'Tractocamión',
                                  'Furgón',
                                }.contains(transportType)
                            ? null
                            : () async {
                                setDialogState(() {
                                  calculatingRoute = true;
                                  routeError = null;
                                });
                                try {
                                  final options =
                                      await OsmRoutingService.findRoadRoutes(
                                        originCity: origin!,
                                        originAddress: originAddress.text
                                            .trim(),
                                        destinationCity: destination!,
                                        destinationAddress: destinationAddress
                                            .text
                                            .trim(),
                                      );
                                  setDialogState(() {
                                    routeOptions = options;
                                    selectedRoute = options.first;
                                  });
                                } catch (error) {
                                  setDialogState(() {
                                    routeError = error.toString().replaceFirst(
                                      'Bad state: ',
                                      '',
                                    );
                                  });
                                } finally {
                                  setDialogState(
                                    () => calculatingRoute = false,
                                  );
                                }
                              },
                        icon: calculatingRoute
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.alt_route),
                        label: Text(
                          calculatingRoute
                              ? 'Calculando rutas…'
                              : 'Calcular rutas y ETA',
                        ),
                      ),
                      if (routeError != null)
                        Text(
                          routeError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      if (routeOptions.isNotEmpty)
                        DropdownButtonFormField<int>(
                          initialValue: selectedRoute?.option,
                          decoration: const InputDecoration(
                            labelText: 'Ruta terrestre',
                          ),
                          items: routeOptions
                              .map(
                                (option) => DropdownMenuItem(
                                  value: option.option,
                                  child: Text(
                                    'Opción ${option.option} · ${option.distanceLabel} · ${option.durationLabel}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setDialogState(() {
                              selectedRoute = routeOptions.firstWhere(
                                (option) => option.option == value,
                              );
                            });
                          },
                        ),
                      if (selectedRoute != null)
                        Text(
                          'Llegada aprox.: ${_arrivalLabel(travelDate.add(Duration(seconds: selectedRoute!.durationSeconds)))} · estimación sin tráfico en vivo.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF39815D),
                          ),
                        ),
                      const Text(
                        'Perfil vial estándar: no incluye tráfico en vivo ni restricciones de peso/altura del vehículo. Tren, buque y avión no tienen ETA aquí.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF65736A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: transportType,
                        decoration: const InputDecoration(
                          labelText: 'Medio de transporte',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Camión',
                            child: Text('Camión'),
                          ),
                          DropdownMenuItem(
                            value: 'Tractocamión',
                            child: Text('Tractocamión'),
                          ),
                          DropdownMenuItem(
                            value: 'Furgón',
                            child: Text('Furgón'),
                          ),
                          DropdownMenuItem(value: 'Tren', child: Text('Tren')),
                          DropdownMenuItem(
                            value: 'Buque',
                            child: Text('Buque'),
                          ),
                          DropdownMenuItem(
                            value: 'Avión',
                            child: Text('Avión'),
                          ),
                          DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              transportType = value;
                              if (!{
                                'Camión',
                                'Tractocamión',
                                'Furgón',
                              }.contains(value)) {
                                selectedRoute = null;
                                routeOptions = [];
                              }
                            });
                          }
                        },
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
                      DropdownButtonFormField<String>(
                        initialValue: customCargo
                            ? '__otro__'
                            : selectedCargoProduct,
                        decoration: const InputDecoration(
                          labelText: 'Material de la carga',
                        ),
                        items: [
                          ...{
                            ...ResourceCatalog.allProducts,
                            ...inventory.map((item) => item.name),
                          }.map(
                            (product) => DropdownMenuItem(
                              value: product,
                              child: Text(
                                product,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const DropdownMenuItem(
                            value: '__otro__',
                            child: Text('Otro material…'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            customCargo = value == '__otro__';
                            if (customCargo) {
                              cargoUnit = ResourceCatalog.unitsForCategory(
                                'Otro',
                              ).first;
                            } else {
                              selectedCargoProduct = value;
                              final matched = inventory.where(
                                (item) => item.name == value,
                              );
                              cargoUnit = matched.isNotEmpty
                                  ? matched.first.unit
                                  : cargoUnits().first;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      if (customCargo)
                        TextFormField(
                          controller: customCargoProduct,
                          decoration: const InputDecoration(
                            labelText: 'Escribe el material',
                          ),
                          validator: (value) =>
                              customCargo &&
                                  (value == null || value.trim().isEmpty)
                              ? 'Escribe el material'
                              : null,
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Categoría: ${cargoCategory()}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF65736A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: cargoQuantity,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Cantidad',
                              ),
                              validator: (value) {
                                final amount = double.tryParse(
                                  (value ?? '').trim().replaceAll(',', '.'),
                                );
                                return amount == null || amount <= 0
                                    ? 'Usa una cantidad mayor que cero'
                                    : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: cargoUnit,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Unidad',
                              ),
                              items: cargoUnits()
                                  .map(
                                    (unit) => DropdownMenuItem(
                                      value: unit,
                                      child: Text(
                                        unit,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(() => cargoUnit = value);
                                }
                              },
                            ),
                          ),
                        ],
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
                            setDialogState(
                              () => travelDate = DateTime(
                                selected.year,
                                selected.month,
                                selected.day,
                                travelDate.hour,
                                travelDate.minute,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text('Fecha: ${_dateLabel(travelDate)}'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final selected = await showTimePicker(
                            context: dialogContext,
                            initialTime: TimeOfDay.fromDateTime(travelDate),
                          );
                          if (selected != null) {
                            setDialogState(
                              () => travelDate = DateTime(
                                travelDate.year,
                                travelDate.month,
                                travelDate.day,
                                selected.hour,
                                selected.minute,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.schedule_outlined),
                        label: Text(
                          'Salida: ${TimeOfDay.fromDateTime(travelDate).format(dialogContext)}',
                        ),
                      ),
                    ],
                  ),
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
                    if ({
                          'Camión',
                          'Tractocamión',
                          'Furgón',
                        }.contains(transportType) &&
                        selectedRoute == null) {
                      setDialogState(
                        () => routeError = 'Calcula y selecciona una ruta.',
                      );
                      return;
                    }
                    final cargoAmount = double.parse(
                      cargoQuantity.text.trim().replaceAll(',', '.'),
                    );
                    final cargoName = customCargo
                        ? customCargoProduct.text.trim()
                        : selectedCargoProduct;
                    Navigator.pop(dialogContext, (
                      origin!,
                      originAddress.text.trim(),
                      destination!,
                      destinationAddress.text.trim(),
                      transportType,
                      deliveryType,
                      '$cargoAmount $cargoUnit de $cargoName (${cargoCategory()})',
                      travelDate,
                      selectedRoute,
                    ));
                  },
                  child: const Text('Enviar solicitud'),
                ),
              ],
            ),
          ),
        );
    cargoQuantity.dispose();
    customCargoProduct.dispose();
    originAddress.dispose();
    destinationAddress.dispose();
    if (result == null || !mounted) {
      return;
    }
    setState(() => _saving = true);
    try {
      await WorkspaceRepository.requestRoute(
        account: widget.account,
        origin: result.$1,
        originAddress: result.$2,
        destination: result.$3,
        destinationAddress: result.$4,
        transportType: result.$5,
        deliveryType: result.$6,
        cargoDescription: result.$7,
        travelDate: result.$8,
        estimatedDistanceMeters: result.$9?.distanceMeters,
        estimatedDurationSeconds: result.$9?.durationSeconds,
        routeOption: result.$9?.option,
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
        if (BackendConfig.isInitialized &&
            !WorkspaceRepository.hasRouteEtaSchema) ...[
          const InfoCard(
            icon: Icons.schedule_outlined,
            title: 'Falta activar los campos de ETA en Supabase',
            subtitle:
                'Ejecuta 20261106000000_route_eta_and_delivery_stops.sql después de las migraciones anteriores.',
            color: Color(0xFFFFF0DF),
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
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            'Geocodificación y mapa: © OpenStreetMap contributors · rutas: OSRM',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Color(0xFF65736A)),
          ),
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
    final activeMine = mine
        .where(
          (request) =>
              request.status == 'Pendiente' || request.status == 'Aceptada',
        )
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
            '${route.companyName} · ${route.transportType} · ${route.deliveryType}$date',
            style: const TextStyle(fontSize: 12, color: Color(0xFF59665D)),
          ),
          if (route.estimatedDurationSeconds != null)
            Text(
              'Ruta ${route.routeOption ?? 1} · ${_durationLabel(route.estimatedDurationSeconds!)} · ${_distanceLabel(route.estimatedDistanceMeters)} · llegada aprox. ${_arrivalLabel((route.travelDate ?? DateTime.now()).add(Duration(seconds: route.estimatedDurationSeconds!)))}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF39815D),
                fontWeight: FontWeight.w700,
              ),
            ),
          if (route.originAddress.isNotEmpty)
            Text(
              'Recogida: ${route.originAddress}',
              style: const TextStyle(fontSize: 12),
            ),
          if (route.destinationAddress.isNotEmpty)
            Text(
              'Entrega: ${route.destinationAddress}',
              style: const TextStyle(fontSize: 12),
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
          if (route.recipientCompanyId == _companyId &&
              route.status == 'Abierta') ...[
            const SizedBox(height: 6),
            const Text(
              'Esta propuesta de ruta se envió directamente a tu empresa.',
              style: TextStyle(fontSize: 12, color: Color(0xFF39815D)),
            ),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () => _setRouteStatus(route, 'En coordinación'),
                  child: const Text('Aceptar propuesta'),
                ),
                TextButton(
                  onPressed: () => _setRouteStatus(route, 'Cancelada'),
                  child: const Text('Rechazar'),
                ),
              ],
            ),
          ],
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
          if (!own &&
              route.recipientCompanyId == null &&
              route.status == 'Abierta' &&
              activeMine.isEmpty)
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
              _joinRequestTile(
                request,
                allowCancel: true,
                routeDeparture: route.travelDate,
              ),
          if (own && requests.isNotEmpty) ...[
            const Divider(),
            const Text(
              'Empresas interesadas',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            for (final request in requests)
              _joinRequestTile(request, routeDeparture: route.travelDate),
          ],
        ],
      ),
    );
  }

  Widget _joinRequestTile(
    RouteJoinRequest request, {
    bool allowCancel = false,
    DateTime? routeDeparture,
  }) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            '${request.requesterCompanyName} · ${request.status}'
            '${request.deliveryCity.isEmpty ? '' : '\nEntrega: ${request.deliveryCity}, ${request.deliveryAddress}'}'
            '${request.estimatedDurationSeconds == null ? '' : '\nETA aprox. (ruta ${request.routeOption ?? 1}): ${_arrivalLabel((routeDeparture ?? DateTime.now()).add(Duration(seconds: request.estimatedDurationSeconds!)))} · ${_durationLabel(request.estimatedDurationSeconds!)}'}',
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
    final formKey = GlobalKey<FormState>();
    final deliveryAddress = TextEditingController();
    String? deliveryCity;
    var routeOptions = <RouteEstimate>[];
    RouteEstimate? estimate;
    var calculating = false;
    String? estimateError;
    final result = await showDialog<(String, String, RouteEstimate?)?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Unirte a la ruta hacia ${route.destination}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Indica tu dirección de entrega. El propietario verá tu destino y ambos podrán consultar la ETA estimada de tu tramo.',
                ),
                const SizedBox(height: 12),
                ColombianCityField(
                  onChanged: (value) {
                    deliveryCity = value;
                    setDialogState(() => estimate = null);
                  },
                ),
                TextFormField(
                  controller: deliveryAddress,
                  decoration: const InputDecoration(
                    labelText: 'Dirección de entrega de mi empresa',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Especifica tu dirección de entrega'
                      : null,
                  onChanged: (_) => setDialogState(() => estimate = null),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed:
                      calculating ||
                          route.origin.isEmpty ||
                          route.originAddress.isEmpty ||
                          deliveryCity == null ||
                          deliveryAddress.text.trim().isEmpty ||
                          !{
                            'Camión',
                            'Tractocamión',
                            'Furgón',
                          }.contains(route.transportType)
                      ? null
                      : () async {
                          setDialogState(() {
                            calculating = true;
                            estimateError = null;
                          });
                          try {
                            final options =
                                await OsmRoutingService.findRoadRoutes(
                                  originCity: route.origin,
                                  originAddress: route.originAddress,
                                  destinationCity: deliveryCity!,
                                  destinationAddress: deliveryAddress.text
                                      .trim(),
                                );
                            setDialogState(() {
                              routeOptions = options;
                              estimate = options.first;
                            });
                          } catch (error) {
                            setDialogState(() {
                              estimateError = error.toString().replaceFirst(
                                'Bad state: ',
                                '',
                              );
                            });
                          } finally {
                            setDialogState(() => calculating = false);
                          }
                        },
                  icon: calculating
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.schedule_outlined),
                  label: Text(
                    calculating ? 'Calculando ETA…' : 'Calcular mi ETA',
                  ),
                ),
                if (estimateError != null)
                  Text(
                    estimateError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                if (routeOptions.isNotEmpty)
                  DropdownButtonFormField<int>(
                    initialValue: estimate?.option,
                    decoration: const InputDecoration(
                      labelText: 'Alternativa de ruta compartida',
                    ),
                    items: routeOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option.option,
                            child: Text(
                              'Opción ${option.option} · ${option.distanceLabel} · ${option.durationLabel}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        estimate = routeOptions.firstWhere(
                          (option) => option.option == value,
                        );
                      });
                    },
                  ),
                if (estimate != null)
                  Text(
                    'Tu tramo: ${estimate!.distanceLabel} · ${estimate!.durationLabel}. Estimación individual desde el origen, sin tráfico en vivo.',
                    style: const TextStyle(
                      color: Color(0xFF39815D),
                      fontSize: 12,
                    ),
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
                if (!formKey.currentState!.validate() || deliveryCity == null) {
                  return;
                }
                Navigator.pop(dialogContext, (
                  deliveryCity!,
                  deliveryAddress.text.trim(),
                  estimate,
                ));
              },
              child: const Text('Enviar solicitud'),
            ),
          ],
        ),
      ),
    );
    deliveryAddress.dispose();
    if (result == null || !mounted) return;
    try {
      await WorkspaceRepository.requestToJoinRoute(
        account: widget.account,
        route: route,
        deliveryCity: result.$1,
        deliveryAddress: result.$2,
        estimatedDistanceMeters: result.$3?.distanceMeters,
        estimatedDurationSeconds: result.$3?.durationSeconds,
        routeOption: result.$3?.option,
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

  String _arrivalLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  String _durationLabel(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours == 0) return '$minutes min';
    return minutes == 0 ? '$hours h' : '$hours h $minutes min';
  }

  String _distanceLabel(double? meters) {
    if (meters == null) return 'distancia no disponible';
    return meters >= 1000
        ? '${(meters / 1000).toStringAsFixed(1)} km'
        : '${meters.round()} m';
  }
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
