import 'package:flutter/material.dart';

import 'cars/car_list_screen.dart';
import 'clients/client_list_screen.dart';
import 'contracts/contract_list_screen.dart';
import '../shared/widgets/sidebar_nav.dart';
import 'dashboard/dashboard_screen.dart';
import 'maintenance/maintenance_list_screen.dart';
import 'calendar/calendar_screen.dart';
import 'settings/settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selected = 0;

  static const _pages = <Widget>[
    DashboardScreen(),
    CarListScreen(),
    ClientListScreen(),
    ContractListScreen(),
    MaintenanceListScreen(),
    CalendarScreen(),
    SettingsScreen(),   // index 6
  ];

  static const _titles = <String>[
    'Dashboard',
    'Voitures',
    'Clients',
    'Contrats',
    'Maintenance',
    'Calendrier',
    'Paramètres',
  ];

  @override
  Widget build(BuildContext context) {
    // Contrats & Paramètres n'ont pas d'AppBar (ils gèrent leur propre layout)
    final hideAppBar = _selected == 3 || _selected == 6;

    final bodyRow = Row(
      children: [
        SidebarNav(
          selected: _selected,
          onSelect: (i) => setState(() => _selected = i),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: IndexedStack(
            index: _selected,
            children: _pages,
          ),
        ),
      ],
    );

    if (hideAppBar) {
      return Scaffold(body: bodyRow);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('BOUSSELHA CARS — ${_titles[_selected]}'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        surfaceTintColor: Colors.white,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: bodyRow,
    );
  }
}
