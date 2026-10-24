import 'package:flutter/material.dart';

import '../../shared/components.dart';

class DiagnosisScreen extends StatelessWidget {
  const DiagnosisScreen({super.key});

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Diagnóstico operativo',
    subtitle: 'Oportunidades para organizar mejor tus recursos.',
    children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFE4F1E7),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Color(0xFF39815D), size: 30),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '3 oportunidades identificadas',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF254A35),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Basadas en la información operativa de demostración.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF597260)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const SectionTitle('Hallazgos'),
      const _Finding(
        icon: Icons.inventory_2_outlined,
        title: 'Revisar niveles de inventario',
        description:
            '7 productos están por debajo del nivel mínimo configurado.',
        label: 'INVENTARIO',
        color: Color(0xFFFFF0DF),
      ),
      const _Finding(
        icon: Icons.recycling_outlined,
        title: 'Aprovechar materiales recuperables',
        description:
            'Hay cartón y vidrio que podrían conectarse con negocios cercanos.',
        label: 'ECONOMÍA CIRCULAR',
        color: Color(0xFFE4F1E7),
      ),
      const _Finding(
        icon: Icons.route_outlined,
        title: 'Agrupar entregas en el Centro',
        description:
            'Se encontraron pedidos de 3 negocios con destinos próximos.',
        label: 'LOGÍSTICA',
        color: Color(0xFFE7EDF7),
      ),
      const SizedBox(height: 18),
      const SectionTitle('Siguiente paso'),
      const InfoCard(
        icon: Icons.fact_check_outlined,
        title: 'Actualiza tus datos operativos',
        subtitle:
            'Un inventario y una lista de necesidades recientes ayudan a mejorar este diagnóstico.',
        trailing: 'Recomendado',
      ),
      const Text(
        'El diagnóstico es orientativo y no representa una auditoría ni utiliza información financiera.',
        style: TextStyle(fontSize: 11, color: Color(0xFF78847C)),
      ),
    ],
  );
}

class _Finding extends StatelessWidget {
  const _Finding({
    required this.icon,
    required this.title,
    required this.description,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String description;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEBEFEA)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF39815D)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: Color(0xFF26382E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: const TextStyle(fontSize: 11, color: Color(0xFF65736A)),
        ),
        const SizedBox(height: 9),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF39815D),
            fontWeight: FontWeight.w800,
            letterSpacing: .8,
          ),
        ),
      ],
    ),
  );
}
