import 'package:flutter/material.dart';

import '../../models/company_account.dart';
import '../../models/operational_records.dart';
import '../../data/resource_catalog.dart';
import '../../services/workspace_repository.dart';
import '../../shared/components.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key, required this.account, this.onNavigate});
  final CompanyAccount account;
  final ValueChanged<int>? onNavigate;
  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  List<InventoryItem> _items = [];
  List<InventoryItem> _recoverableItems = [];
  bool _loading = true;
  bool _saving = false;
  bool _importing = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await WorkspaceRepository.loadInventory(widget.account);
      final recoverable =
          await WorkspaceRepository.loadRecoverableLocalInventory(
            widget.account,
          );
      if (!mounted) return;
      setState(() {
        _items = items;
        _recoverableItems = recoverable;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo cargar el inventario. Revisa tu conexión.';
      });
    }
  }

  Future<void> _importRecoverableInventory() async {
    final count = _recoverableItems.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar productos locales'),
        content: Text(
          'Se copiarán $count productos guardados en este dispositivo al inventario en la nube de ${widget.account.businessName}. La copia local se conservará.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Copiar al inventario'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _importing = true);
    try {
      final imported = await WorkspaceRepository.importRecoverableInventory(
        account: widget.account,
        localItems: _recoverableItems,
        currentItems: _items,
      );
      await _loadItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              imported == 0
                  ? 'Los productos ya estaban en el inventario.'
                  : 'Se recuperaron $imported productos.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron copiar los productos locales.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _addItem() async {
    final saved = await showDialog<InventoryItem>(
      context: context,
      builder: (_) => const _InventoryDialog(),
    );
    if (saved != null && mounted) {
      setState(() => _saving = true);
      try {
        await WorkspaceRepository.saveInventory(widget.account, saved);
        await _loadItems();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo guardar el recurso.')),
          );
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _items
        .where((item) => item.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final lowStock = _items
        .where((item) => item.quantity <= item.lowStockThreshold)
        .length;
    final categoryCount = _items
        .map((item) => item.category.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .length;
    return PageFrame(
      title: 'Recursos e inventario',
      subtitle: 'Controla existencias y anticipa necesidades.',
      action: IconButton.filledTonal(
        tooltip: 'Agregar recurso',
        onPressed: _saving ? null : _addItem,
        icon: const Icon(Icons.add),
      ),
      children: [
        if (_recoverableItems.isNotEmpty) ...[
          InfoCard(
            icon: Icons.cloud_upload_outlined,
            title:
                'Encontramos ${_recoverableItems.length} productos en este dispositivo',
            subtitle:
                'Pueden ser los productos registrados antes de conectar la cuenta a la nube. Cópialos al inventario de esta empresa para verlos desde tus otros dispositivos.',
            color: const Color(0xFFEAF0F8),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: _importing ? null : _importRecoverableInventory,
              icon: _importing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_importing ? 'Copiando…' : 'Recuperar productos'),
            ),
          ),
          const SizedBox(height: 16),
        ],
        InfoCard(
          icon: Icons.lock_outline,
          title: 'Inventario privado de ${widget.account.businessName}',
          subtitle:
              'Aquí ves los recursos de esta empresa. Para consultar productos que otras empresas publicaron para compartir, entra a Economía circular.',
          color: const Color(0xFFEAF0F8),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => widget.onNavigate?.call(2),
            icon: const Icon(Icons.recycling_outlined),
            label: const Text('Ver productos compartidos'),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: 'Productos',
                value: '${_items.length}',
                icon: Icons.inventory_2_outlined,
                detail: 'en $categoryCount categorías',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                label: 'Por reponer',
                value: '$lowStock',
                icon: Icons.notification_important_outlined,
                detail: 'nivel bajo',
              ),
            ),
          ],
        ),
        const SizedBox(height: 23),
        const SectionTitle('Inventario del negocio'),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: 'Buscar recurso',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          TextButton.icon(
            onPressed: _loadItems,
            icon: const Icon(Icons.refresh),
            label: Text(_error!),
          )
        else if (visible.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InfoCard(
                icon: Icons.inventory_2_outlined,
                title: 'Aún no hay recursos',
                subtitle:
                    'Agrega un recurso para iniciar el inventario de tu empresa.',
              ),
              const SizedBox(height: 5),
              FilledButton.icon(
                onPressed: _saving ? null : _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Agregar recurso'),
              ),
            ],
          )
        else
          for (final item in visible)
            InfoCard(
              icon: Icons.inventory_2_outlined,
              title: item.name,
              subtitle: [
                item.category,
                'Nivel mínimo ${item.lowStockThreshold} ${item.unit}',
              ].where((part) => part.isNotEmpty).join(' · '),
              trailing: '${item.quantity} ${item.unit}',
            ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF3EE),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.insights_outlined, color: Color(0xFF39815D)),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Registra cantidades y niveles mínimos para mantener actualizado el inventario de tu empresa.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF52665A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InventoryDialog extends StatefulWidget {
  const _InventoryDialog();

  @override
  State<_InventoryDialog> createState() => _InventoryDialogState();
}

class _InventoryDialogState extends State<_InventoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _customProduct = TextEditingController();
  final _customCategory = TextEditingController();
  final _threshold = TextEditingController(text: '0');
  String _category = ResourceCatalog.categories.first;
  String _unit = ResourceCatalog.units.first;
  String? _product = ResourceCatalog.productsFor(
    ResourceCatalog.categories.first,
  ).first;
  bool _otherProduct = false;

  @override
  void dispose() {
    _quantity.dispose();
    _customProduct.dispose();
    _customCategory.dispose();
    _threshold.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final category = _category == 'Otro'
        ? _customCategory.text.trim()
        : _category;
    final name = _otherProduct ? _customProduct.text.trim() : _product!;
    Navigator.pop(
      context,
      InventoryItem(
        id: '',
        name: name,
        quantity: double.parse(_quantity.text.trim().replaceAll(',', '.')),
        unit: _unit,
        category: category,
        lowStockThreshold: double.parse(
          _threshold.text.trim().replaceAll(',', '.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Agregar recurso'),
    scrollable: true,
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _category,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: ResourceCatalog.categories
                .map(
                  (category) => DropdownMenuItem(
                    value: category,
                    child: Text(category, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (category) {
              if (category == null) return;
              setState(() {
                _category = category;
                final products = ResourceCatalog.productsFor(category);
                _product = products.isEmpty ? null : products.first;
                _otherProduct = products.isEmpty;
              });
            },
          ),
          if (_category == 'Otro') ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _customCategory,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Escribe la categoría',
              ),
              validator: (value) =>
                  _category == 'Otro' && (value == null || value.trim().isEmpty)
                  ? 'Escribe la categoría del recurso'
                  : null,
            ),
          ],
          if (ResourceCatalog.productsFor(_category).isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _otherProduct ? '__other__' : _product,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Nombre del recurso',
              ),
              items: [
                ...ResourceCatalog.productsFor(_category).map(
                  (product) => DropdownMenuItem(
                    value: product,
                    child: Text(product, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const DropdownMenuItem(
                  value: '__other__',
                  child: Text('Otro (escribir)'),
                ),
              ],
              onChanged: (product) {
                if (product == null) return;
                setState(() {
                  _otherProduct = product == '__other__';
                  _product = _otherProduct ? null : product;
                });
              },
              validator: (value) =>
                  !_otherProduct && (value == null || value.isEmpty)
                  ? 'Selecciona un recurso'
                  : null,
            ),
          ],
          if (_otherProduct) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _customProduct,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: ResourceCatalog.productsFor(_category).isEmpty
                    ? 'Nombre del recurso'
                    : '¿Qué recurso es?',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Escribe el nombre del recurso'
                  : null,
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Cantidad disponible'),
            validator: _validateNumber,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _unit,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Unidad'),
            items: ResourceCatalog.units
                .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                .toList(),
            onChanged: (unit) {
              if (unit != null) setState(() => _unit = unit);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _threshold,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Nivel mínimo para alerta',
            ),
            validator: _validateNumber,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _save, child: const Text('Guardar')),
    ],
  );

  String? _validateNumber(String? value) {
    final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    return number == null || number < 0
        ? 'Ingresa un número igual o mayor que cero'
        : null;
  }
}
