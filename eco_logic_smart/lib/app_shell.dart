import 'package:flutter/material.dart';

import 'features/circular/circular_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/indicators/indicators_screen.dart';
import 'features/logistics/logistics_screen.dart';
import 'features/resources/resources_screen.dart';
import 'models/company_account.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.account});

  final CompanyAccount account;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late CompanyAccount _account;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        account: _account,
        onAccountUpdated: (account) => setState(() => _account = account),
      ),
      const ResourcesScreen(),
      const CircularScreen(),
      const LogisticsScreen(),
      const IndicatorsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE0EEE5),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Recursos',
          ),
          NavigationDestination(
            icon: Icon(Icons.recycling_outlined),
            label: 'Circular',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            label: 'Rutas',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_rounded),
            label: 'Indicadores',
          ),
        ],
      ),
    );
  }
}
