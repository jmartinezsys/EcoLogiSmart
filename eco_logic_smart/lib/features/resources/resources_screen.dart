import 'package:flutter/material.dart';

import '../../models/company_account.dart';
import '../../models/operational_records.dart';
import '../../services/workspace_repository.dart';
import '../../shared/components.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key, required this.account});
  final CompanyAccount account;
  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  List<InventoryItem> _items = [];
  bool _loading = true;
  bool _saving = false;
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
      if (!mounted) return;
      setState(() {
        _items = items;
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
          const InfoCard(
            icon: Icons.inventory_2_outlined,
            title: 'Aún no hay recursos',
            subtitle:
                'Agrega un recurso para iniciar el inventario de tu empresa.',
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
  final _name = TextEditingController();
  final _quantity = TextEditingController();
  final _unit = TextEditingController(text: 'unidades');
  final _category = TextEditingController();
  final _threshold = TextEditingController(text: '0');

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _unit.dispose();
    _category.dispose();
    _threshold.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      InventoryItem(
        id: '',
        name: _name.text.trim(),
        quantity: double.parse(_quantity.text.trim().replaceAll(',', '.')),
        unit: _unit.text.trim().isEmpty ? 'unidades' : _unit.text.trim(),
        category: _category.text.trim(),
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
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre del recurso'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Escribe el nombre del recurso'
                : null,
          ),
          TextFormField(
            controller: _quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Cantidad disponible'),
            validator: _validateNumber,
          ),
          TextFormField(
            controller: _unit,
            decoration: const InputDecoration(labelText: 'Unidad'),
          ),
          TextFormField(
            controller: _category,
            decoration: const InputDecoration(labelText: 'Categoría'),
          ),
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
