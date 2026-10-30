import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/resource_catalog.dart';
import '../../models/company_account.dart';
import '../../models/operational_records.dart';
import '../../services/backend_config.dart';
import '../../services/workspace_repository.dart';
import '../../shared/components.dart';

class CircularWorkspaceScreen extends StatefulWidget {
  const CircularWorkspaceScreen({super.key, required this.account});

  final CompanyAccount account;

  @override
  State<CircularWorkspaceScreen> createState() =>
      _CircularWorkspaceScreenState();
}

class _CircularWorkspaceScreenState extends State<CircularWorkspaceScreen> {
  List<MaterialListing> _listings = [];
  List<MaterialExchangeRequest> _exchangeRequests = [];
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController(text: 'kg');
  String _filter = 'Todos';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
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
        WorkspaceRepository.loadMaterials(),
        WorkspaceRepository.loadExchangeRequests(),
      ]);
      final listings = results[0] as List<MaterialListing>;
      if (!mounted) return;
      setState(() {
        _listings = listings;
        _exchangeRequests = results[1] as List<MaterialExchangeRequest>;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudieron cargar los materiales.';
      });
    }
  }

  Future<void> _publish() async {
    final formKey = GlobalKey<FormState>();
    final title = _titleController..clear();
    final description = _descriptionController..clear();
    final quantity = _quantityController..clear();
    final unit = _unitController..text = 'kg';
    final exchangeFor = TextEditingController();
    final customTitle = TextEditingController();
    var category = ResourceCatalog.categories.first;
    var product = ResourceCatalog.productsFor(category).first;
    var otherProduct = false;
    var status = 'Disponible';
    XFile? photo;
    final draft = await showDialog<_ListingDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Publicar material'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: title,
                    readOnly: !otherProduct,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del material',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Escribe el material'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: ResourceCatalog.categories
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        category = value;
                        final products = ResourceCatalog.productsFor(value);
                        product = products.isEmpty ? '' : products.first;
                        otherProduct = products.isEmpty;
                        title.text = otherProduct ? customTitle.text : product;
                      });
                    },
                  ),
                  if (ResourceCatalog.productsFor(category).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: product,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Producto'),
                      items: [
                        ...ResourceCatalog.productsFor(category).map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        const DropdownMenuItem(
                          value: '__other__',
                          child: Text('Otro (escribir)'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          otherProduct = value == '__other__';
                          product = otherProduct ? '' : value;
                          title.text = otherProduct
                              ? customTitle.text
                              : product;
                        });
                      },
                    ),
                  ],
                  if (otherProduct) ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: customTitle,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Escribe el producto',
                      ),
                      onChanged: (value) => title.text = value,
                      validator: (value) =>
                          otherProduct &&
                              (value == null || value.trim().isEmpty)
                          ? 'Escribe el producto'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: description,
                    decoration: const InputDecoration(
                      labelText: 'Descripción y estado',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: unit.text,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Unidad'),
                    items: ResourceCatalog.units
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) unit.text = value;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(labelText: 'Modalidad'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Disponible',
                        child: Text('Disponible para aprovechamiento'),
                      ),
                      DropdownMenuItem(
                        value: 'Intercambio',
                        child: Text('Disponible para intercambio'),
                      ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => status = value ?? 'Disponible'),
                  ),
                  if (status == 'Intercambio') ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: exchangeFor,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: '¿Qué producto deseas recibir?',
                      ),
                      validator: (value) =>
                          status == 'Intercambio' &&
                              (value == null || value.trim().isEmpty)
                          ? 'Indica qué deseas recibir'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: quantity,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Cantidad',
                          ),
                          validator: (value) {
                            final parsed = double.tryParse(
                              (value ?? '').replaceAll(',', '.'),
                            );
                            return parsed == null || parsed <= 0
                                ? 'Usa un valor mayor que cero'
                                : null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 82,
                        maxWidth: 1600,
                      );
                      if (picked == null) return;
                      if (await picked.length() > 5 * 1024 * 1024) {
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'La imagen debe pesar máximo 5 MB.',
                              ),
                            ),
                          );
                        }
                        return;
                      }
                      photo = picked;
                      setDialogState(() {});
                    },
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(photo?.name ?? 'Agregar foto'),
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
                final amount = double.parse(
                  quantity.text.trim().replaceAll(',', '.'),
                );
                Navigator.pop(
                  dialogContext,
                  _ListingDraft(
                    listing: MaterialListing(
                      id: '',
                      companyId: widget.account.id,
                      title: title.text.trim(),
                      description: description.text.trim(),
                      quantity: amount,
                      unit: unit.text.trim().isEmpty ? 'kg' : unit.text.trim(),
                      status: status,
                      category: category,
                      exchangeFor: status == 'Intercambio'
                          ? exchangeFor.text.trim()
                          : null,
                      companyName: widget.account.businessName,
                      city: widget.account.city,
                    ),
                    photo: photo,
                  ),
                );
              },
              child: const Text('Publicar'),
            ),
          ],
        ),
      ),
    );
    exchangeFor.dispose();
    customTitle.dispose();
    if (draft == null || !mounted) return;

    setState(() => _saving = true);
    try {
      await WorkspaceRepository.publishMaterial(
        account: widget.account,
        listing: draft.listing,
        photo: draft.photo,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material publicado correctamente.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo publicar. Revisa tu conexión e inténtalo de nuevo.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _listings
        .where((item) => _filter == 'Todos' || item.status == _filter)
        .toList();
    final totalQuantity = _listings.fold<double>(
      0,
      (total, listing) => total + listing.quantity,
    );
    return PageFrame(
      title: 'Economía circular',
      subtitle: 'Comparte excedentes y explora ofertas de otras empresas.',
      action: IconButton.filledTonal(
        tooltip: 'Publicar material',
        onPressed: _saving ? null : _publish,
        icon: const Icon(Icons.add),
      ),
      children: [
        if (BackendConfig.isInitialized &&
            !WorkspaceRepository.hasExchangeSchema) ...[
          const InfoCard(
            icon: Icons.warning_amber_rounded,
            title: 'Falta actualizar el esquema de Supabase',
            subtitle:
                'Las publicaciones ya se pueden consultar. Para enviar, aceptar o cancelar intercambios, ejecuta la migración marketplace_and_routes en el SQL Editor de Supabase.',
            color: Color(0xFFFFF0DF),
          ),
          const SizedBox(height: 12),
        ],
        InfoCard(
          icon: BackendConfig.isInitialized
              ? Icons.cloud_done_outlined
              : Icons.phone_android_outlined,
          title: BackendConfig.isInitialized
              ? 'Publicaciones visibles para empresas conectadas'
              : 'Modo local de demostración',
          subtitle: BackendConfig.isInitialized
              ? 'El inventario sigue siendo privado. Solo compartes los materiales que publicas aquí.'
              : 'Las publicaciones se guardan en este dispositivo. Para compartirlas entre teléfonos, conecta el proyecto a Supabase.',
          color: const Color(0xFFEAF0F8),
        ),
        if (BackendConfig.isInitialized &&
            _listings.any((listing) => listing.isLegacyLocal)) ...[
          const SizedBox(height: 12),
          const InfoCard(
            icon: Icons.phone_android_outlined,
            title: 'Publicaciones recuperadas de este dispositivo',
            subtitle:
                'Se muestran los materiales guardados en la versión anterior de este navegador. Para intercambiar, vuelve a publicarlos con la sesión conectada.',
            color: Color(0xFFFFF4DE),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFE4F1E7),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            children: [
              Icon(Icons.eco_outlined, color: Color(0xFF39815D), size: 30),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dale una segunda vida a tus materiales',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF254A35),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Solo las publicaciones de este espacio se ofrecen a otros negocios; tu inventario permanece privado.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF597260)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: 'Material disponible',
                value: totalQuantity.toStringAsFixed(1),
                icon: Icons.recycling_outlined,
                detail: 'en ${_listings.length} publicaciones',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                label: 'Ofertas externas',
                value:
                    '${_listings.where((item) => item.companyId != (widget.account.id.isNotEmpty ? widget.account.id : widget.account.email.toLowerCase())).length}',
                icon: Icons.handshake_outlined,
                detail: 'de otras empresas',
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const SectionTitle('Materiales publicados'),
        Wrap(
          spacing: 8,
          children: ['Todos', 'Disponible', 'Intercambio']
              .map(
                (value) => ChoiceChip(
                  label: Text(value),
                  selected: _filter == value,
                  onSelected: (_) => setState(() => _filter = value),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 13),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: Text(_error!),
          )
        else if (visible.isEmpty)
          const InfoCard(
            icon: Icons.recycling_outlined,
            title: 'Aún no hay materiales publicados',
            subtitle: 'Agrega un material para encontrar empresas interesadas.',
          )
        else
          for (final item in visible) _buildMaterialCard(item),
      ],
    );
  }

  String get _companyId => widget.account.id.isNotEmpty
      ? widget.account.id
      : widget.account.email.toLowerCase();

  Widget _buildMaterialCard(MaterialListing listing) {
    final own = listing.companyId == _companyId;
    final requests = _exchangeRequests
        .where((request) => request.listingId == listing.id)
        .toList();
    final myRequests = requests
        .where((request) => request.requesterCompanyId == _companyId)
        .toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEFEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MaterialCard(listing: listing),
          if (listing.exchangeFor?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Busca: ${listing.exchangeFor}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF39815D),
                ),
              ),
            ),
          if (own && requests.isNotEmpty) ...[
            const Divider(height: 24),
            const Text(
              'Propuestas recibidas',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            for (final request in requests) _exchangeRequestTile(request),
          ],
          if (!own && listing.status == 'Intercambio' && myRequests.isEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: listing.isLegacyLocal
                  ? const Text(
                      'Vuelve a publicar este material para habilitar propuestas.',
                      textAlign: TextAlign.end,
                      style: TextStyle(fontSize: 11),
                    )
                  : TextButton.icon(
                      onPressed: () => _proposeExchange(listing),
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Proponer intercambio'),
                    ),
            ),
          if (!own && myRequests.isNotEmpty)
            for (final request in myRequests)
              _exchangeRequestTile(request, allowCancel: true),
        ],
      ),
    );
  }

  Widget _exchangeRequestTile(
    MaterialExchangeRequest request, {
    bool allowCancel = false,
  }) => Padding(
    padding: const EdgeInsets.only(top: 9),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${request.requesterCompanyName} ofrece ${request.offeredProduct} · ${request.status}',
          style: const TextStyle(fontSize: 12),
        ),
        if (request.message.isNotEmpty)
          Text(request.message, style: const TextStyle(fontSize: 11)),
        if (request.status == 'Pendiente' && allowCancel)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _setExchangeStatus(request, 'Cancelada'),
              child: const Text('Cancelar propuesta'),
            ),
          )
        else if (request.status == 'Pendiente')
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => _setExchangeStatus(request, 'Rechazada'),
                child: const Text('Rechazar'),
              ),
              FilledButton.tonal(
                onPressed: () => _setExchangeStatus(request, 'Aceptada'),
                child: const Text('Aceptar'),
              ),
            ],
          ),
      ],
    ),
  );

  Future<void> _proposeExchange(MaterialListing listing) async {
    final formKey = GlobalKey<FormState>();
    final offered = TextEditingController();
    final message = TextEditingController();
    var category = ResourceCatalog.categories.first;
    var product = ResourceCatalog.productsFor(category).first;
    var custom = false;
    final result = await showDialog<(String, String)?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Proponer intercambio'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'La empresa busca: ${listing.exchangeFor ?? listing.title}',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Categoría que ofreces',
                  ),
                  items: ResourceCatalog.categories
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() {
                      category = value;
                      final products = ResourceCatalog.productsFor(value);
                      custom = products.isEmpty;
                      product = products.isEmpty ? '' : products.first;
                      offered.text = custom ? '' : product;
                    });
                  },
                ),
                if (ResourceCatalog.productsFor(category).isNotEmpty) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: product,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Producto ofrecido',
                    ),
                    items: [
                      ...ResourceCatalog.productsFor(category).map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const DropdownMenuItem(
                        value: '__other__',
                        child: Text('Otro (escribir)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        custom = value == '__other__';
                        product = custom ? '' : value;
                        offered.text = custom ? '' : value;
                      });
                    },
                  ),
                ],
                if (custom) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: offered,
                    decoration: const InputDecoration(
                      labelText: 'Producto ofrecido',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Escribe el producto'
                        : null,
                  ),
                ],
                const SizedBox(height: 10),
                TextFormField(
                  controller: message,
                  decoration: const InputDecoration(
                    labelText: 'Mensaje (opcional)',
                  ),
                  maxLines: 2,
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
                if (!custom) offered.text = product;
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(dialogContext, (
                  offered.text.trim(),
                  message.text.trim(),
                ));
              },
              child: const Text('Enviar propuesta'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) {
      offered.dispose();
      message.dispose();
      return;
    }
    try {
      await WorkspaceRepository.requestMaterialExchange(
        account: widget.account,
        listing: listing,
        offeredProduct: result.$1,
        message: result.$2,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Propuesta enviada.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo enviar la propuesta.')),
        );
      }
    } finally {
      offered.dispose();
      message.dispose();
    }
  }

  Future<void> _setExchangeStatus(
    MaterialExchangeRequest request,
    String status,
  ) async {
    try {
      await WorkspaceRepository.updateExchangeStatus(request, status);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo actualizar el intercambio.'),
          ),
        );
      }
    }
  }
}

class _ListingDraft {
  const _ListingDraft({required this.listing, this.photo});

  final MaterialListing listing;
  final XFile? photo;
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({required this.listing});

  final MaterialListing listing;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEBEFEA)),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: listing.imageUrl != null
              ? Image.network(
                  listing.imageUrl!,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 64,
                    height: 64,
                    color: const Color(0xFFEAF2EA),
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                )
              : listing.localImageBytes != null
              ? Image.memory(
                  listing.localImageBytes!,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 64,
                  height: 64,
                  color: const Color(0xFFEAF2EA),
                  child: const Icon(Icons.inventory_2_outlined),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                listing.title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (listing.description.isNotEmpty)
                Text(
                  listing.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF65736A),
                  ),
                ),
              Text(
                '${listing.companyName} · ${listing.city}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF78847C)),
              ),
              Text(
                '${listing.quantity} ${listing.unit} · ${listing.status}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF39815D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
