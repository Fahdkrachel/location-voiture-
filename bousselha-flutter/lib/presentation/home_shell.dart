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

  static const _subtitles = <String>[
    "Vue d'ensemble de l'activité de location et statistiques de la flotte",
    "Gestion du parc automobile et état des véhicules",
    "Répertoire et fiches de renseignements clients",
    "Création, activation et historique des contrats de location",
    "Suivi des révisions, vidanges et réparations des véhicules",
    "Planning et disponibilité des réservations et locations actives",
    "Configuration de l'application et gestion du compte",
  ];

  Widget _buildUnifiedHeader(String title, String subtitle) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Image.asset(
            'assets/branding/bousselha_logo.png',
            height: 36,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.directions_car_rounded,
              color: Color(0xFF1A2B4A),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            height: 24,
            width: 1,
            color: const Color(0xFFE2E8F0),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2B4A),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Contrats & Paramètres n'ont pas de header global dans le Shell (ils gèrent leur propre layout)
    final hideAppBar = _selected == 3 || _selected == 6;

    final bodyRow = Row(
      children: [
        SidebarNav(
          selected: _selected,
          onSelect: (i) => setState(() => _selected = i),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Column(
            children: [
              if (!hideAppBar)
                _buildUnifiedHeader(_titles[_selected], _subtitles[_selected]),
              Expanded(
                child: IndexedStack(
                  index: _selected,
                  children: _pages,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      body: bodyRow,
    );
  }
}
