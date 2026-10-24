import 'package:flutter/material.dart';

import '../../shared/components.dart';

class LogisticsScreen extends StatefulWidget {
  const LogisticsScreen({super.key});

  @override
  State<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends State<LogisticsScreen> {
  void _requestRoute() {
    final destination = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Solicitar ruta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: destination,
              decoration: const InputDecoration(labelText: 'Zona de destino'),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Tipo de entrega'),
              items: const [
                DropdownMenuItem(value: 'Paquetes', child: Text('Paquetes')),
                DropdownMenuItem(value: 'Insumos', child: Text('Insumos')),
                DropdownMenuItem(
                  value: 'Materiales',
                  child: Text('Materiales'),
                ),
              ],
              onChanged: (_) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Solicitud guardada en el prototipo'),
                ),
              );
            },
            child: const Text('Enviar solicitud'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Logística compartida',
    subtitle: 'Agrupa entregas y coordina recorridos.',
    action: IconButton.filledTonal(
      onPressed: _requestRoute,
      icon: const Icon(Icons.add_road),
    ),
    children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF173E35),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OPORTUNIDAD DE HOY',
              style: TextStyle(
                color: Color(0xFFC6DCCB),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 10),
            Text(
              '3 negocios van hacia el Centro Histórico',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 7),
            Text(
              'Consolida pedidos y coordina una entrega compartida.',
              style: TextStyle(color: Color(0xFFD0E3D4), fontSize: 12),
            ),
            SizedBox(height: 14),
            Row(
              children: [
                Icon(Icons.route_outlined, color: Color(0xFFB6DB8C), size: 18),
                SizedBox(width: 6),
                Text(
                  '4,2 km · Hoy, 2:30 p. m.',
                  style: TextStyle(color: Color(0xFFD0E3D4), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const SectionTitle('Rutas y pedidos cercanos'),
      const InfoCard(
        icon: Icons.local_shipping_outlined,
        title: 'Centro Histórico',
        subtitle: '3 negocios · Insumos y paquetes · 4,2 km',
        trailing: 'Hoy 2:30',
        color: Color(0xFFFFF0DF),
      ),
      const InfoCard(
        icon: Icons.local_shipping_outlined,
        title: 'Bocagrande',
        subtitle: '2 negocios · Entrega de suministros · 6,8 km',
        trailing: 'Mañana',
        color: Color(0xFFFFF0DF),
      ),
      const InfoCard(
        icon: Icons.inventory_2_outlined,
        title: 'Pedido por coordinar',
        subtitle: 'Materiales de empaque · Zona Manga',
        trailing: 'Pendiente',
      ),
      const SizedBox(height: 12),
      const SectionTitle('Cómo funciona'),
      const _StepLine(
        number: '1',
        text: 'Registra una necesidad de transporte y su zona de destino.',
      ),
      const _StepLine(
        number: '2',
        text: 'Encuentra negocios con pedidos en zonas cercanas.',
      ),
      const _StepLine(
        number: '3',
        text: 'Coordina directamente la ruta y el transporte.',
      ),
    ],
  );
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
