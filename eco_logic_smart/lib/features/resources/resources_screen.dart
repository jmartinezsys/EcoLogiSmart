import 'package:flutter/material.dart';

import '../../shared/components.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});
  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final _items = <Map<String, String>>[
    {
      'name': 'Suministros de limpieza',
      'detail': 'Insumos · Actualizado hoy',
      'amount': '18 unidades',
    },
    {
      'name': 'Envases de vidrio',
      'detail': 'Reutilizables · Almacén',
      'amount': '42 unidades',
    },
    {
      'name': 'Lencería hotelera',
      'detail': 'Textiles · Bodega',
      'amount': '26 unidades',
    },
    {
      'name': 'Empaques de cartón',
      'detail': 'Embalaje · Bodega',
      'amount': '64 unidades',
    },
  ];
  String _query = '';

  Future<void> _addItem() async {
    final name = TextEditingController();
    final quantity = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar recurso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Nombre del recurso',
              ),
            ),
            TextField(
              controller: quantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad disponible',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (saved == true && name.text.trim().isNotEmpty && mounted) {
      setState(
        () => _items.insert(0, {
          'name': name.text.trim(),
          'detail': 'Recurso · Agregado ahora',
          'amount':
              '${quantity.text.trim().isEmpty ? '0' : quantity.text.trim()} unidades',
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _items
        .where(
          (item) => item['name']!.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return PageFrame(
      title: 'Recursos e inventario',
      subtitle: 'Controla existencias y anticipa necesidades.',
      action: IconButton.filledTonal(
        onPressed: _addItem,
        icon: const Icon(Icons.add),
      ),
      children: [
        Row(
          children: const [
            Expanded(
              child: MetricTile(
                label: 'Productos',
                value: '86',
                icon: Icons.inventory_2_outlined,
                detail: 'en 4 categorías',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                label: 'Por reponer',
                value: '7',
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
        for (final item in visible)
          InfoCard(
            icon: Icons.inventory_2_outlined,
            title: item['name']!,
            subtitle: item['detail']!,
            trailing: item['amount'],
          ),
        const SizedBox(height: 10),
        const SectionTitle('Consumo de recursos'),
        const InfoCard(
          icon: Icons.water_drop_outlined,
          title: 'Agua',
          subtitle: 'Consumo registrado este mes',
          trailing: '1.240 L',
        ),
        const InfoCard(
          icon: Icons.bolt_outlined,
          title: 'Energía',
          subtitle: 'Consumo registrado este mes',
          trailing: '860 kWh',
        ),
        const SizedBox(height: 6),
        const Text(
          'El registro de consumos es opcional y solo usa información operativa.',
          style: TextStyle(fontSize: 11, color: Color(0xFF78847C)),
        ),
      ],
    );
  }
}
