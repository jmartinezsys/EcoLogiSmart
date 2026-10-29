import 'package:flutter/material.dart';

import 'features/circular/circular_workspace_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/indicators/indicators_workspace_screen.dart';
import 'features/logistics/logistics_workspace_screen.dart';
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
  final List<int> _refreshVersions = List<int>.filled(5, 0);
  late CompanyAccount _account;

  @override
  void initState() {
    super.initState();
    _account = widget.account;
  }

  void _selectTab(int index) {
    setState(() {
      _index = index;
      _refreshVersions[index]++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        key: ValueKey('dashboard-${_refreshVersions[0]}'),
        account: _account,
        onAccountUpdated: (account) => setState(() => _account = account),
        onNavigate: _selectTab,
      ),
      ResourcesScreen(
        key: ValueKey('resources-${_refreshVersions[1]}'),
        account: _account,
        onNavigate: _selectTab,
      ),
      CircularWorkspaceScreen(
        key: ValueKey('circular-${_refreshVersions[2]}'),
        account: _account,
      ),
      LogisticsWorkspaceScreen(
        key: ValueKey('logistics-${_refreshVersions[3]}'),
        account: _account,
      ),
      IndicatorsWorkspaceScreen(
        key: ValueKey('indicators-${_refreshVersions[4]}'),
        account: _account,
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _selectTab,
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
