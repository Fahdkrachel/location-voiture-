import 'package:flutter/material.dart';

import 'cars/car_list_screen.dart';
import 'clients/client_list_screen.dart';
import 'contracts/contract_list_screen.dart';
import '../shared/widgets/sidebar_nav.dart';
import 'dashboard/dashboard_screen.dart';
import 'maintenance/maintenance_list_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const DashboardScreen(),
      const CarListScreen(),
      const ClientListScreen(),
      const ContractListScreen(),
      const MaintenanceListScreen(),
    ];

    final titles = <String>['Dashboard', 'Voitures', 'Clients', 'Contrats', 'Maintenance'];

    final bodyRow = Row(
      children: [
        SidebarNav(
          selected: _selected,
          onSelect: (index) => setState(() => _selected = index),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: IndexedStack(
            index: _selected,
            children: pages,
          ),
        ),
      ],
    );

    if (_selected == 3) {
      return Scaffold(body: bodyRow);
    }

    return Scaffold(
      appBar: AppBar(title: Text('BOUSSELHA CARS - ${titles[_selected]}')),
      body: bodyRow,
    );
  }
}
