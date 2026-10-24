import 'package:flutter/material.dart';

import '../../shared/components.dart';

class IndicatorsScreen extends StatelessWidget {
  const IndicatorsScreen({super.key});

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Indicadores',
    subtitle: 'Observa avances y oportunidades operativas.',
    children: [
      const Row(
        children: [
          Expanded(
            child: MetricTile(
              label: 'Ahorro potencial',
              value: '\$ 840 mil',
              icon: Icons.savings_outlined,
              detail: 'estimado este mes',
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: MetricTile(
              label: 'Entregas agrupadas',
              value: '12',
              icon: Icons.route_outlined,
              detail: 'en el periodo',
            ),
          ),
        ],
      ),
      const SizedBox(height: 23),
      const SectionTitle('Desempeño mensual', trailing: 'Octubre 2026'),
      const _ProgressPanel(
        title: 'Materiales aprovechados',
        value: '128 kg',
        progress: .68,
        hint: 'Meta: 190 kg',
      ),
      const _ProgressPanel(
        title: 'Pedidos agrupados',
        value: '12 pedidos',
        progress: .75,
        hint: 'Meta: 16 pedidos',
      ),
      const _ProgressPanel(
        title: 'Entregas a tiempo',
        value: '94%',
        progress: .94,
        hint: 'Meta: 90%',
      ),
      const SizedBox(height: 12),
      const SectionTitle('Impacto estimado'),
      const InfoCard(
        icon: Icons.delete_outline,
        title: 'Residuos desviados',
        subtitle: 'Materiales que pueden volver a usarse',
        trailing: '128 kg',
      ),
      const InfoCard(
        icon: Icons.directions_car_outlined,
        title: 'Recorridos consolidados',
        subtitle: 'Distancia potencialmente evitada',
        trailing: '46 km',
      ),
      const InfoCard(
        icon: Icons.query_stats_rounded,
        title: 'Negocios participantes',
        subtitle: 'Empresas activas en el prototipo',
        trailing: '18',
      ),
      const SizedBox(height: 10),
      const Text(
        'Las cifras de ahorro e impacto son estimaciones de demostración, no resultados medidos.',
        style: TextStyle(fontSize: 11, color: Color(0xFF78847C)),
      ),
    ],
  );
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({
    required this.title,
    required this.value,
    required this.progress,
    required this.hint,
  });
  final String title;
  final String value;
  final double progress;
  final String hint;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEBEFEA)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF35463A),
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF173E35),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: const Color(0xFFE7ECE7),
            color: const Color(0xFF4B956C),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            hint,
            style: const TextStyle(fontSize: 10, color: Color(0xFF849087)),
          ),
        ),
      ],
    ),
  );
}
