import 'package:flutter/material.dart';

import '../../shared/components.dart';
import '../company/company_screen.dart';
import '../diagnosis/diagnosis_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => PageFrame(
    title: '¡Buenos días, Andrea!',
    subtitle: 'Hotel Bahía Verde · Cartagena',
    action: IconButton.filledTonal(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const CompanyScreen()),
      ),
      icon: const Icon(Icons.person_outline),
    ),
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFF173E35), Color(0xFF28664D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'IMPACTO ESTE MES',
              style: TextStyle(
                color: Color(0xFFC6DCCB),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '128',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 4),
                  child: Text(
                    'kg recuperados',
                    style: TextStyle(color: Color(0xFFD0E3D4), fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(
                value: .68,
                minHeight: 6,
                backgroundColor: Color(0xFF416F5B),
                color: Color(0xFFB6DB8C),
              ),
            ),
            const SizedBox(height: 9),
            const Row(
              children: [
                Text(
                  'Meta mensual: 190 kg',
                  style: TextStyle(color: Color(0xFFD0E3D4), fontSize: 11),
                ),
                Spacer(),
                Text(
                  '68%',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 23),
      const SectionTitle('Tu operación hoy'),
      const Row(
        children: [
          Expanded(
            child: MetricTile(
              label: 'Inventario',
              value: '86',
              icon: Icons.inventory_2_outlined,
              detail: 'productos registrados',
            ),
          ),
          SizedBox(width: 11),
          Expanded(
            child: MetricTile(
              label: 'Entregas',
              value: '12',
              icon: Icons.local_shipping_outlined,
              detail: 'por coordinar',
            ),
          ),
        ],
      ),
      const SizedBox(height: 25),
      OutlinedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const DiagnosisScreen()),
        ),
        icon: const Icon(Icons.fact_check_outlined),
        label: const Text('Consultar diagnóstico operativo'),
      ),
      const SizedBox(height: 18),
      const SectionTitle('Oportunidades para tu negocio'),
      const InfoCard(
        icon: Icons.recycling_rounded,
        title: 'Cartón limpio disponible',
        subtitle: '24 kg · Centro Histórico',
        trailing: 'Circular',
      ),
      const InfoCard(
        icon: Icons.route_outlined,
        title: 'Ruta compartida cercana',
        subtitle: 'Centro Histórico · 3 negocios',
        trailing: 'Hoy 2:30',
        color: Color(0xFFFFF0DF),
      ),
      const SizedBox(height: 14),
      const SectionTitle('Actividad reciente'),
      const InfoCard(
        icon: Icons.inventory_2_outlined,
        title: 'Inventario actualizado',
        subtitle: 'Suministros de limpieza · hace 2 h',
      ),
      const InfoCard(
        icon: Icons.eco_outlined,
        title: 'Nuevo material publicado',
        subtitle: 'Vidrio reutilizable · hace 5 h',
      ),
      const SizedBox(height: 7),
      OutlinedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const CompanyScreen()),
        ),
        icon: const Icon(Icons.business_outlined),
        label: const Text('Completar perfil de empresa'),
      ),
    ],
  );
}
