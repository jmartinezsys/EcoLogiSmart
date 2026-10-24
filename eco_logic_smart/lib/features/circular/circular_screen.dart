import 'package:flutter/material.dart';

import '../../shared/components.dart';

class CircularScreen extends StatefulWidget {
  const CircularScreen({super.key});
  @override
  State<CircularScreen> createState() => _CircularScreenState();
}

class _CircularScreenState extends State<CircularScreen> {
  String _filter = 'Todos';
  final _materials = const [
    _Material(
      'Cartón limpio',
      '24 kg · Centro Histórico',
      'Disponible',
      Icons.inventory_2_outlined,
    ),
    _Material(
      'Frascos de vidrio',
      '36 unidades · Getsemaní',
      'Disponible',
      Icons.wine_bar_outlined,
    ),
    _Material(
      'Retazos textiles',
      '8 kg · Manga',
      'Intercambio',
      Icons.checkroom_outlined,
    ),
    _Material(
      'Estibas de madera',
      '5 unidades · Bocagrande',
      'Disponible',
      Icons.inventory_2_outlined,
    ),
  ];
  void _publish() {
    final material = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publicar material'),
        content: TextField(
          controller: material,
          decoration: const InputDecoration(
            labelText: '¿Qué material puedes compartir?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(this.context).showSnackBar(
                const SnackBar(
                  content: Text('Publicación agregada al prototipo'),
                ),
              );
            },
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final materials = _filter == 'Todos'
        ? _materials
        : _materials.where((item) => item.status == _filter).toList();
    return PageFrame(
      title: 'Economía circular',
      subtitle: 'Conecta materiales con nuevos usos.',
      action: IconButton.filledTonal(
        onPressed: _publish,
        icon: const Icon(Icons.add),
      ),
      children: [
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
                      'Publica excedentes para que otros negocios puedan aprovecharlos.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF597260)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Row(
          children: [
            Expanded(
              child: MetricTile(
                label: 'Material recuperado',
                value: '128 kg',
                icon: Icons.recycling_outlined,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                label: 'Conexiones',
                value: '9',
                icon: Icons.handshake_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const SectionTitle('Materiales cerca de ti'),
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
        for (final item in materials)
          InfoCard(
            icon: item.icon,
            title: item.name,
            subtitle: item.location,
            trailing: item.status,
            color: const Color(0xFFEAF2EA),
          ),
      ],
    );
  }
}

class _Material {
  const _Material(this.name, this.location, this.status, this.icon);
  final String name;
  final String location;
  final String status;
  final IconData icon;
}
