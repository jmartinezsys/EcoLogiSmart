import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/resource_catalog.dart';
import '../../models/company_account.dart';
import '../../models/operational_records.dart';
import '../../services/backend_config.dart';
import '../../services/workspace_repository.dart';
import '../../shared/components.dart';
import '../../shared/colombian_city_field.dart';

class CircularWorkspaceScreen extends StatefulWidget {
  const CircularWorkspaceScreen({
    super.key,
    required this.account,
    this.onNavigate,
  });

  final CompanyAccount account;
  final ValueChanged<int>? onNavigate;

  @override
  State<CircularWorkspaceScreen> createState() =>
      _CircularWorkspaceScreenState();
}

class _CircularWorkspaceScreenState extends State<CircularWorkspaceScreen> {
  List<MaterialListing> _listings = [];
  List<MaterialExchangeRequest> _exchangeRequests = [];
  String _filter = 'Todos';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      try {
        await WorkspaceRepository.ensureChatIdentity();
      } catch (_) {
        // Missing chat migration or secure storage does not block Circular.
      }
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
    List<InventoryItem> inventory;
    try {
      inventory = await WorkspaceRepository.loadInventory(widget.account);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cargar tu inventario para publicar.'),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    if (inventory.isEmpty) {
      final goToInventory = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Agrega primero un recurso'),
          content: const Text(
            'Circular publica materiales que ya están registrados en el inventario de tu empresa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ir a Recursos'),
            ),
          ],
        ),
      );
      if (goToInventory == true) widget.onNavigate?.call(1);
      return;
    }

    final formKey = GlobalKey<FormState>();
    final description = TextEditingController();
    final quantity = TextEditingController(
      text: inventory.first.quantity.toString(),
    );
    final exchangeFor = TextEditingController();
    var desiredProduct = ResourceCatalog.allProducts.first;
    var customDesiredProduct = false;
    var selectedItem = inventory.first;
    var status = 'Disponible';
    XFile? photo;
    if (!mounted) return;
    final draft = await showDialog<_ListingDraft>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Publicar desde mi inventario'),
          scrollable: true,
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedItem.id,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Material del inventario',
                    ),
                    items: inventory
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(
                              '${item.name} · ${item.quantity} ${item.unit}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id == null) return;
                      final found = inventory.where((item) => item.id == id);
                      if (found.isEmpty) return;
                      setDialogState(() {
                        selectedItem = found.first;
                        quantity.text = selectedItem.quantity.toString();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: quantity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText:
                          'Cantidad que publicarás (${selectedItem.unit})',
                      helperText:
                          'Disponible: ${selectedItem.quantity} ${selectedItem.unit}',
                    ),
                    validator: (value) {
                      final amount = double.tryParse(
                        (value ?? '').trim().replaceAll(',', '.'),
                      );
                      if (amount == null || amount <= 0) {
                        return 'Ingresa una cantidad mayor que cero';
                      }
                      if (amount > selectedItem.quantity) {
                        return 'Supera lo disponible en el inventario';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: description,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                    ),
                    maxLines: 2,
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
                    DropdownButtonFormField<String>(
                      initialValue: desiredProduct,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Producto que deseas recibir',
                      ),
                      items: [
                        ...ResourceCatalog.allProducts.map(
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
                          child: Text('Otro producto…'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          customDesiredProduct = value == '__otro__';
                          if (!customDesiredProduct) desiredProduct = value;
                        });
                      },
                    ),
                    if (customDesiredProduct) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: exchangeFor,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Escribe el producto que buscas',
                        ),
                        validator: (value) =>
                            status == 'Intercambio' &&
                                customDesiredProduct &&
                                (value == null || value.trim().isEmpty)
                            ? 'Escribe el producto que deseas recibir'
                            : null,
                      ),
                    ],
                  ],
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
                      title: selectedItem.name,
                      description: description.text.trim(),
                      quantity: amount,
                      unit: selectedItem.unit,
                      status: status,
                      category: selectedItem.category,
                      exchangeFor: status == 'Intercambio'
                          ? customDesiredProduct
                                ? exchangeFor.text.trim()
                                : desiredProduct
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
    description.dispose();
    quantity.dispose();
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
    return PageFrame(
      title: 'Circular',
      subtitle:
          'Publica excedentes y coordina aprovechamientos e intercambios.',
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
            title: 'Falta activar los intercambios en Supabase',
            subtitle:
                'En el SQL Editor ejecuta la migración 20261029000000_marketplace_and_routes.sql. Después vuelve a comprobar la conexión.',
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
              ? 'Publicaciones visibles para empresas conectadas'
              : 'Modo local de demostración',
          subtitle: BackendConfig.isInitialized
              ? 'El inventario sigue siendo privado. Solo compartes los materiales que publicas aquí.'
              : 'Las publicaciones se guardan en este dispositivo. Para compartirlas entre teléfonos, conecta el proyecto a Supabase.',
          color: const Color(0xFFEAF0F8),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saving ? null : _publish,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Publicar un material'),
          ),
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
                label: 'Publicaciones',
                value: '${_listings.length}',
                icon: Icons.recycling_outlined,
                detail: 'materiales registrados',
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

  Future<void> _deleteListing(MaterialListing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: Text(
          '¿Quieres retirar “${listing.title}” de Circular? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await WorkspaceRepository.deleteMaterial(
        account: widget.account,
        listing: listing,
      );
      if (!mounted) return;
      setState(() {
        _listings.removeWhere((item) => item.id == listing.id);
        _exchangeRequests.removeWhere((item) => item.listingId == listing.id);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Publicación eliminada.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo eliminar. Revisa tu conexión e inténtalo de nuevo.',
          ),
        ),
      );
    }
  }

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
          if (!own)
            Align(
              alignment: Alignment.centerRight,
              child: listing.isLegacyLocal
                  ? const Text(
                      'Vuelve a publicar este material con sesión para abrir el chat.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF65736A)),
                    )
                  : listing.status != 'Disponible' &&
                        listing.status != 'Intercambio'
                  ? const Text(
                      'Esta publicación ya no está disponible.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF65736A)),
                    )
                  : !BackendConfig.isInitialized
                  ? const Text(
                      'El chat cifrado requiere iniciar sesión con Supabase.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF65736A)),
                    )
                  : !WorkspaceRepository.hasSecureChatSchema
                  ? const Text(
                      'Ejecuta la migración de chat cifrado en Supabase.',
                      style: TextStyle(fontSize: 11, color: Colors.deepOrange),
                    )
                  : TextButton.icon(
                      onPressed: () => _contactListing(listing),
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Contactar empresa'),
                    ),
            ),
          if (own && requests.isNotEmpty) ...[
            const Divider(height: 18),
            const Text(
              'Propuestas recibidas',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            for (final request in requests) _exchangeRequestTile(request),
          ],
          if (own)
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: BackendConfig.isInitialized &&
                            !listing.isLegacyLocal
                        ? () => _contactListing(listing)
                        : null,
                    icon: const Icon(Icons.forum_outlined),
                    label: const Text('Conversaciones'),
                  ),
                  TextButton.icon(
                    onPressed: () => _deleteListing(listing),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFB42318),
                    ),
                    label: const Text(
                      'Eliminar publicación',
                      style: TextStyle(color: Color(0xFFB42318)),
                    ),
                  ),
                ],
              ),
            ),
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
          if (!own && listing.status == 'Intercambio' && myRequests.isEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: listing.isLegacyLocal
                  ? const Text(
                      'Vuelve a publicar este material para habilitar propuestas.',
                      textAlign: TextAlign.end,
                      style: TextStyle(fontSize: 11),
                    )
                  : BackendConfig.isInitialized &&
                        !WorkspaceRepository.hasExchangeSchema
                  ? const Text(
                      'Activa la migración de intercambios en Supabase para proponer.',
                      textAlign: TextAlign.end,
                      style: TextStyle(fontSize: 11, color: Colors.deepOrange),
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
    String? listingTitle,
  }) => Padding(
    padding: const EdgeInsets.only(top: 9),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (listingTitle != null)
          Text(
            'Material: $listingTitle',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          )
        else if (allowCancel)
          const Text(
            'El material ya no está disponible en el catálogo.',
            style: TextStyle(fontSize: 11, color: Color(0xFF65736A)),
          ),
        Text(
          '${request.requesterCompanyName} ofrece ${request.offeredProduct}'
          '${request.offeredQuantity > 0 ? ' · ${request.offeredQuantity} ${request.offeredUnit}' : ''}'
          ' · ${request.status}',
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

  Future<void> _contactListing(MaterialListing listing) async {
    try {
      if (listing.companyId == _companyId) {
        final conversations =
            await WorkspaceRepository.loadMaterialConversations(listing);
        if (!mounted) return;
        if (conversations.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aún no hay conversaciones para esta publicación.'),
            ),
          );
          return;
        }
        final selected = await showDialog<MaterialConversation>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Conversaciones de la publicación'),
            content: SizedBox(
              width: 420,
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final conversation in conversations)
                    ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.business_outlined),
                      ),
                      title: Text(conversation.requesterCompanyName),
                      subtitle: Text(
                        'Inició ${_chatTime(conversation.createdAt)}',
                      ),
                      onTap: () => Navigator.pop(context, conversation),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
        if (selected == null || !mounted) return;
        await _showMaterialChat(
          listing: listing,
          conversationId: selected.id,
          partnerCompanyId: selected.requesterCompanyId,
          partnerName: selected.requesterCompanyName,
        );
        return;
      }
      final conversationId = await WorkspaceRepository.openMaterialConversation(
        account: widget.account,
        listing: listing,
      );
      if (!mounted) return;
      await _showMaterialChat(
        listing: listing,
        conversationId: conversationId,
        partnerCompanyId: listing.companyId,
        partnerName: listing.companyName,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo abrir el chat. Revisa que aplicaste la migración de chat cifrado y que ambas empresas hayan iniciado sesión.',
          ),
        ),
      );
    }
  }

  Future<void> _showMaterialChat({
    required MaterialListing listing,
    required String conversationId,
    required String partnerCompanyId,
    required String partnerName,
  }) async {
    final controller = TextEditingController();
    var messages = <MaterialChatMessage>[];
    var loading = true;
    var initialLoadStarted = false;
    var sending = false;
    String? error;

    Future<void> refresh(StateSetter setDialogState) async {
      try {
        final loaded = await WorkspaceRepository.loadMaterialChatMessages(
          conversationId: conversationId,
          account: widget.account,
        );
        setDialogState(() {
          messages = loaded;
          loading = false;
          error = null;
        });
      } catch (_) {
        setDialogState(() {
          loading = false;
          error = 'No se pudieron cargar los mensajes.';
        });
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          if (loading && !initialLoadStarted) {
            initialLoadStarted = true;
            refresh(setDialogState);
          }
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.lock_outline, color: Color(0xFF39815D)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(partnerName, maxLines: 1),
                      Text(listing.title, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar mensajes',
                  onPressed: loading
                      ? null
                      : () {
                          setDialogState(() => loading = true);
                          refresh(setDialogState);
                        },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Mensajes de texto cifrados en este dispositivo. Solo se pueden enviar mensajes escritos.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF65736A)),
                  ),
                  const SizedBox(height: 8),
                  if (error != null)
                    TextButton.icon(
                      onPressed: () {
                        setDialogState(() => loading = true);
                        refresh(setDialogState);
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(error!),
                    )
                  else if (loading)
                    const SizedBox(
                      height: 250,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    SizedBox(
                      height: 270,
                      child: messages.isEmpty
                          ? const Center(
                              child: Text(
                                'Inicia la conversación sobre este material.',
                              ),
                            )
                          : ListView.builder(
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final message = messages[index];
                                final mine =
                                    message.senderCompanyId == _companyId;
                                final bubble = Container(
                                  constraints: const BoxConstraints(
                                    maxWidth: 350,
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: mine
                                        ? const Color(0xFFDDF3E2)
                                        : const Color(0xFFF0F2EF),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(message.body),
                                      const SizedBox(height: 3),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          _chatTime(message.createdAt),
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: Color(0xFF65736A),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                return Align(
                                  alignment: mine
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: mine || listing.companyId != _companyId
                                      ? bubble
                                      : PopupMenuButton<String>(
                                          tooltip: 'Opciones de dirección',
                                          onSelected: (value) {
                                            if (value == 'route') {
                                              _proposeDirectRoute(
                                                listing: listing,
                                                conversationId: conversationId,
                                                partnerCompanyId:
                                                    partnerCompanyId,
                                                partnerName: partnerName,
                                                quotedAddress: message.body,
                                              );
                                            }
                                          },
                                          itemBuilder: (context) => const [
                                            PopupMenuItem(
                                              value: 'route',
                                              child: Text(
                                                'Proponer ruta a este texto',
                                              ),
                                            ),
                                          ],
                                          child: bubble,
                                        ),
                                );
                              },
                            ),
                    ),
                  if (listing.companyId == _companyId) ...[
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () => _proposeDirectRoute(
                        listing: listing,
                        conversationId: conversationId,
                        partnerCompanyId: partnerCompanyId,
                        partnerName: partnerName,
                      ),
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Proponer una ruta directa'),
                    ),
                  ],
                  TextField(
                    controller: controller,
                    onChanged: (_) => setDialogState(() {}),
                    maxLines: 2,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      labelText: 'Mensaje',
                      hintText: 'Escribe tu mensaje',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cerrar'),
              ),
              FilledButton.icon(
                onPressed: sending || controller.text.trim().isEmpty
                    ? null
                    : () async {
                        setDialogState(() => sending = true);
                        try {
                          await WorkspaceRepository.sendMaterialChatMessage(
                            account: widget.account,
                            conversationId: conversationId,
                            recipientCompanyId: partnerCompanyId,
                            body: controller.text,
                          );
                          controller.clear();
                          setDialogState(() => loading = true);
                          await refresh(setDialogState);
                        } catch (_) {
                          setDialogState(() {
                            error = 'No se pudo enviar el mensaje cifrado.';
                          });
                        } finally {
                          setDialogState(() => sending = false);
                        }
                      },
                icon: const Icon(Icons.send_outlined),
                label: Text(sending ? 'Enviando…' : 'Enviar'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
  }

  String _chatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  Future<void> _proposeDirectRoute({
    required MaterialListing listing,
    required String conversationId,
    required String partnerCompanyId,
    required String partnerName,
    String quotedAddress = '',
  }) async {
    if (listing.companyId != _companyId) return;
    final formKey = GlobalKey<FormState>();
    final originAddress = TextEditingController();
    final destinationAddress = TextEditingController(text: quotedAddress);
    String? originCity;
    String? destinationCity;
    var transport = 'Camión';
    final result = await showDialog<(String, String, String, String, String)?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Proponer ruta a $partnerName'),
          scrollable: true,
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ColombianCityField(onChanged: (value) => originCity = value),
                TextFormField(
                  controller: originAddress,
                  decoration: const InputDecoration(
                    labelText: 'Dirección de recogida',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Especifica la recogida'
                      : null,
                ),
                const SizedBox(height: 10),
                ColombianCityField(
                  onChanged: (value) => destinationCity = value,
                ),
                TextFormField(
                  controller: destinationAddress,
                  decoration: const InputDecoration(
                    labelText: 'Dirección indicada en el chat',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Especifica la dirección de entrega'
                      : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: transport,
                  decoration: const InputDecoration(
                    labelText: 'Medio de transporte',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Camión', child: Text('Camión')),
                    DropdownMenuItem(
                      value: 'Tractocamión',
                      child: Text('Tractocamión'),
                    ),
                    DropdownMenuItem(value: 'Furgón', child: Text('Furgón')),
                    DropdownMenuItem(value: 'Tren', child: Text('Tren')),
                    DropdownMenuItem(value: 'Buque', child: Text('Buque')),
                    DropdownMenuItem(value: 'Avión', child: Text('Avión')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => transport = value);
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
                if (!formKey.currentState!.validate() ||
                    originCity == null ||
                    destinationCity == null) {
                  return;
                }
                Navigator.pop(dialogContext, (
                  originCity!,
                  originAddress.text.trim(),
                  destinationCity!,
                  destinationAddress.text.trim(),
                  transport,
                ));
              },
              child: const Text('Enviar propuesta de ruta'),
            ),
          ],
        ),
      ),
    );
    originAddress.dispose();
    destinationAddress.dispose();
    if (result == null || !mounted) return;
    try {
      await WorkspaceRepository.requestRoute(
        account: widget.account,
        origin: result.$1,
        originAddress: result.$2,
        destination: result.$3,
        destinationAddress: result.$4,
        transportType: result.$5,
        recipientCompanyId: partnerCompanyId,
        deliveryType: 'Materiales',
        cargoDescription:
            '${listing.title} · ${listing.quantity} ${listing.unit}',
        travelDate: DateTime.now().add(const Duration(days: 1)),
      );
      await WorkspaceRepository.sendMaterialChatMessage(
        account: widget.account,
        conversationId: conversationId,
        recipientCompanyId: partnerCompanyId,
        body:
            'Te propongo una ruta directa para ${listing.title}: recogida en ${result.$2}, entrega en ${result.$4}. Transporte: ${result.$5}. Revisa la propuesta en Rutas.',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propuesta de ruta enviada.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo enviar la propuesta de ruta.'),
          ),
        );
      }
    }
  }

  Future<void> _proposeExchange(MaterialListing listing) async {
    List<InventoryItem> inventory;
    try {
      inventory = (await WorkspaceRepository.loadInventory(
        widget.account,
      )).where((item) => item.quantity > 0).toList();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo consultar el inventario para proponer.'),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    if (inventory.isEmpty) {
      final goToInventory = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Necesitas un producto para ofrecer'),
          content: const Text(
            'Agrega productos y cantidades en Recursos. Después podrás elegir qué ofrecer a cambio de este material.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ir a Recursos'),
            ),
          ],
        ),
      );
      if (goToInventory == true) widget.onNavigate?.call(1);
      return;
    }

    final formKey = GlobalKey<FormState>();
    final quantity = TextEditingController(
      text: inventory.first.quantity.toString(),
    );
    var selectedItem = inventory.first;
    if (!mounted) return;
    final result = await showDialog<(InventoryItem, double)?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Proponer intercambio'),
          scrollable: true,
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'La empresa busca ${listing.exchangeFor ?? listing.title}. Tú puedes ofrecer:',
                ),
                const SizedBox(height: 6),
                const Text(
                  'Al aceptar, se reserva la publicación; la entrega se coordina entre las empresas.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF65736A)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedItem.id,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Producto de tu inventario',
                  ),
                  items: inventory
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            '${item.name} · ${item.quantity} ${item.unit}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (id) {
                    if (id == null) return;
                    final found = inventory.where((item) => item.id == id);
                    if (found.isEmpty) return;
                    setDialogState(() {
                      selectedItem = found.first;
                      quantity.text = selectedItem.quantity.toString();
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Cantidad ofrecida (${selectedItem.unit})',
                    helperText:
                        'En tu inventario: ${selectedItem.quantity} ${selectedItem.unit}',
                  ),
                  validator: (value) {
                    final offeredAmount = double.tryParse(
                      (value ?? '').trim().replaceAll(',', '.'),
                    );
                    if (offeredAmount == null || offeredAmount <= 0) {
                      return 'Ingresa una cantidad mayor que cero';
                    }
                    if (offeredAmount > selectedItem.quantity) {
                      return 'No puedes ofrecer más de lo inventariado';
                    }
                    return null;
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
                  selectedItem,
                  double.parse(quantity.text.trim().replaceAll(',', '.')),
                ));
              },
              child: const Text('Enviar propuesta'),
            ),
          ],
        ),
      ),
    );
    quantity.dispose();
    if (result == null || !mounted) return;
    try {
      await WorkspaceRepository.requestMaterialExchange(
        account: widget.account,
        listing: listing,
        offeredProduct: result.$1.name,
        offeredQuantity: result.$2,
        offeredUnit: result.$1.unit,
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
