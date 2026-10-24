import 'package:flutter/material.dart';

import '../../models/company_account.dart';
import '../../shared/components.dart';
import '../company/company_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.account,
    required this.onAccountUpdated,
  });

  final CompanyAccount account;
  final ValueChanged<CompanyAccount> onAccountUpdated;

  Future<void> _openProfile(BuildContext context) async {
    final updated = await Navigator.push<CompanyAccount>(
      context,
      MaterialPageRoute<CompanyAccount>(
        builder: (_) => CompanyScreen(account: account),
      ),
    );
    if (updated != null) onAccountUpdated(updated);
  }

  @override
  Widget build(BuildContext context) {
    final firstName = account.contactName.trim().split(RegExp(r'\s+')).first;
    return PageFrame(
      title: 'Hola, $firstName',
      subtitle: 'Este es el espacio de ${account.businessName}.',
      action: IconButton.filledTonal(
        tooltip: 'Perfil de empresa',
        onPressed: () => _openProfile(context),
        icon: const Icon(Icons.person_outline),
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
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
                'TU EMPRESA',
                style: TextStyle(
                  color: Color(0xFFC6DCCB),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                account.businessName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _ProfileLine(icon: Icons.category_outlined, text: account.sector),
              const SizedBox(height: 7),
              _ProfileLine(
                icon: Icons.location_on_outlined,
                text: account.city,
              ),
              const SizedBox(height: 7),
              _ProfileLine(icon: Icons.alternate_email, text: account.email),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionTitle('Tu actividad'),
        const Row(
          children: [
            Expanded(
              child: MetricTile(
                label: 'Recursos',
                value: '0',
                icon: Icons.inventory_2_outlined,
                detail: 'registrados por tu empresa',
              ),
            ),
            SizedBox(width: 11),
            Expanded(
              child: MetricTile(
                label: 'Materiales',
                value: '0',
                icon: Icons.recycling_outlined,
                detail: 'publicados por tu empresa',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const InfoCard(
          icon: Icons.local_shipping_outlined,
          title: 'Solicitudes de ruta',
          subtitle: 'Aún no hay solicitudes para esta empresa.',
          trailing: '0',
          color: Color(0xFFFFF0DF),
        ),
        const SizedBox(height: 20),
        const SectionTitle('Herramientas para todas las empresas'),
        const InfoCard(
          icon: Icons.inventory_2_outlined,
          title: 'Inventario y recursos',
          subtitle: 'Organiza existencias y consumos operativos.',
        ),
        const InfoCard(
          icon: Icons.recycling_outlined,
          title: 'Economía circular',
          subtitle: 'Publica materiales para encontrarles un nuevo uso.',
        ),
        const InfoCard(
          icon: Icons.route_outlined,
          title: 'Logística compartida',
          subtitle: 'Coordina pedidos con destinos cercanos.',
          color: Color(0xFFFFF0DF),
        ),
        const InfoCard(
          icon: Icons.query_stats_rounded,
          title: 'Indicadores',
          subtitle: 'Consulta la actividad e impacto de tu empresa.',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _openProfile(context),
          icon: const Icon(Icons.manage_accounts_outlined),
          label: const Text('Administrar perfil de empresa'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Los datos de actividad se mostrarán aquí cuando se registren desde tu cuenta.',
          style: TextStyle(fontSize: 11, color: Color(0xFF78847C)),
        ),
      ],
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: const Color(0xFFD0E3D4), size: 16),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFFE5F0E7), fontSize: 12),
        ),
      ),
    ],
  );
}
