import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  static const _sections = ['Resumen', 'Recursos', 'Circular', 'Rutas'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _topBar(),
                  const SizedBox(height: 28),
                  _greeting(),
                  const SizedBox(height: 22),
                  _impactCard(),
                  const SizedBox(height: 24),
                  _sectionHeading('Tu operación hoy', 'Ver indicadores'),
                  const SizedBox(height: 14),
                  _metricGrid(),
                  const SizedBox(height: 26),
                  _sectionHeading('Oportunidades para tu negocio', 'Ver todas'),
                  const SizedBox(height: 14),
                  _opportunity(
                    icon: Icons.recycling_rounded,
                    color: const Color(0xFFE4F2E9),
                    iconColor: const Color(0xFF37805C),
                    title: 'Materiales disponibles',
                    subtitle: 'Cartón limpio · 24 kg disponibles',
                    tag: 'ECONOMÍA CIRCULAR',
                  ),
                  const SizedBox(height: 10),
                  _opportunity(
                    icon: Icons.local_shipping_outlined,
                    color: const Color(0xFFFFF0DC),
                    iconColor: const Color(0xFFB4752A),
                    title: 'Ruta compartida cercana',
                    subtitle: 'Centro Histórico · 3 negocios',
                    tag: 'LOGÍSTICA',
                  ),
                  const SizedBox(height: 26),
                  _sectionHeading('Actividad reciente', 'Ver actividad'),
                  const SizedBox(height: 14),
                  _activityItem(
                    icon: Icons.inventory_2_outlined,
                    title: 'Inventario actualizado',
                    subtitle: 'Suministros de limpieza · hace 2 h',
                  ),
                  const Divider(height: 24, color: Color(0xFFE8ECE7)),
                  _activityItem(
                    icon: Icons.eco_outlined,
                    title: 'Nuevo material publicado',
                    subtitle: 'Vidrio reutilizable · hace 5 h',
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Datos de demostración · EcoLogiSmart',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF87938A), fontSize: 11),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE0EEE5),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Recursos'),
          NavigationDestination(icon: Icon(Icons.recycling_outlined), label: 'Circular'),
          NavigationDestination(icon: Icon(Icons.route_outlined), label: 'Rutas'),
        ],
      ),
    );
  }

  Widget _topBar() => Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF173E35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EcoLogiSmart', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF173E35))),
              Text('GESTIÓN SOSTENIBLE', style: TextStyle(fontSize: 9, letterSpacing: 1.2, color: Color(0xFF718077))),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            tooltip: 'Notificaciones',
            style: IconButton.styleFrom(backgroundColor: Colors.white),
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF173E35)),
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 19,
            backgroundColor: const Color(0xFFDCE9DF),
            child: const Text('AM', style: TextStyle(color: Color(0xFF285A43), fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      );

  Widget _greeting() => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SÁBADO, 24 DE OCTUBRE', style: TextStyle(fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w700, color: Color(0xFF738078))),
          SizedBox(height: 7),
          Text('¡Buenos días, Andrea!', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: Color(0xFF1B3027))),
          SizedBox(height: 5),
          Text('Aquí tienes el resumen de tu operación.', style: TextStyle(fontSize: 13, color: Color(0xFF78847C))),
        ],
      );

  Widget _impactCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(colors: [Color(0xFF173E35), Color(0xFF28664D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Expanded(child: Text('IMPACTO ESTE MES', style: TextStyle(color: Color(0xFFC6DCCB), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)), child: const Row(children: [Icon(Icons.trending_up, color: Color(0xFFB8E3C3), size: 13), SizedBox(width: 4), Text('+12.8%', style: TextStyle(color: Color(0xFFD8F1DE), fontWeight: FontWeight.w700, fontSize: 10))])),
            ]),
            const SizedBox(height: 14),
            const Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('128', style: TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, height: 1)),
              Padding(padding: EdgeInsets.only(left: 8, bottom: 4), child: Text('kg recuperados', style: TextStyle(color: Color(0xFFD0E3D4), fontSize: 13))),
            ]),
            const SizedBox(height: 16),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: const LinearProgressIndicator(value: .68, minHeight: 6, backgroundColor: Color(0xFF416F5B), color: Color(0xFFB6DB8C))),
            const SizedBox(height: 9),
            const Row(children: [Text('Meta mensual: 190 kg', style: TextStyle(color: Color(0xFFD0E3D4), fontSize: 11)), Spacer(), Text('68%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))]),
          ],
        ),
      );

  Widget _sectionHeading(String title, String action) => Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF21352B)))),
          Text(action, style: const TextStyle(fontSize: 11, color: Color(0xFF39815D), fontWeight: FontWeight.w700)),
        ],
      );

  Widget _metricGrid() => const Row(
        children: [
          Expanded(child: _MetricCard(icon: Icons.inventory_2_outlined, label: 'Inventario', value: '86', detail: 'productos', tint: Color(0xFFE6F0E8), accent: Color(0xFF3B8058))),
          SizedBox(width: 11),
          Expanded(child: _MetricCard(icon: Icons.local_shipping_outlined, label: 'Entregas', value: '12', detail: 'por coordinar', tint: Color(0xFFFFF0DF), accent: Color(0xFFB77932))),
        ],
      );

  Widget _opportunity({required IconData icon, required Color color, required Color iconColor, required String title, required String subtitle, required String tag}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFEBEFEA))),
        child: Row(children: [
          Container(width: 43, height: 43, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: iconColor, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(tag, style: TextStyle(color: iconColor, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: .8)), const SizedBox(height: 4), Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF26382E))), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF7A867E)))])),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AA59C)),
        ]),
      );

  Widget _activityItem({required IconData icon, required String title, required String subtitle}) => Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFEAF1EB), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFF4F8062), size: 19)),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2A3B31))), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF818C84)))])),
        const Icon(Icons.more_horiz, color: Color(0xFF9AA59C)),
      ]);
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.icon, required this.label, required this.value, required this.detail, required this.tint, required this.accent});

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color tint;
  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFEBEFEA))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(width: 31, height: 31, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 17, color: accent)), const Spacer(), const Icon(Icons.north_east_rounded, size: 14, color: Color(0xFF9BA69E))]),
          const SizedBox(height: 13),
          Text(value, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Color(0xFF26382E))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4B5D51))),
          const SizedBox(height: 2),
          Text(detail, style: const TextStyle(fontSize: 9, color: Color(0xFF89948C))),
        ]),
      );
}

