import 'package:flutter/material.dart';

import '../core/utils/responsive.dart';
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
    SettingsScreen(), // index 6
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

  // Items de navigation visibles dans la BottomNavBar mobile (max 5)
  // On exclut Paramètres (géré en drawer / via icône dans AppBar)
  static const _bottomNavItems = [
    BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
    BottomNavigationBarItem(icon: Icon(Icons.directions_car_outlined), activeIcon: Icon(Icons.directions_car), label: 'Voitures'),
    BottomNavigationBarItem(icon: Icon(Icons.description_outlined), activeIcon: Icon(Icons.description), label: 'Contrats'),
    BottomNavigationBarItem(icon: Icon(Icons.build_outlined), activeIcon: Icon(Icons.build), label: 'Maintenance'),
    BottomNavigationBarItem(icon: Icon(Icons.more_horiz_rounded), activeIcon: Icon(Icons.more_horiz_rounded), label: 'Plus'),
  ];

  // Correspondance index BottomNav → index _pages
  static const _bottomNavPageMap = [0, 1, 3, 4, -1]; // -1 = drawer

  // Correspondance inverse : _pages index → BottomNav index (pour mettre en valeur)
  int get _bottomNavSelectedIndex {
    const map = [0, 1, -1, 2, 3, -1, -1]; // dashboard, voitures, clients→-1, contrats, maint, cal, settings
    final idx = _selected < map.length ? map[_selected] : -1;
    return idx < 0 ? 4 : idx; // -1 → onglet "Plus"
  }

  Widget _buildUnifiedHeader(BuildContext context, String title, String subtitle) {
    final isTabletOrLarger = Responsive.isTabletOrLarger(context);
    return Container(
      height: isTabletOrLarger ? 70 : 60,
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
            height: isTabletOrLarger ? 36 : 30,
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
                  style: TextStyle(
                    fontSize: isTabletOrLarger ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A2B4A),
                  ),
                ),
                if (subtitle.isNotEmpty && isTabletOrLarger) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Drawer pour mobile — inclut Clients, Calendrier, Paramètres
  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF1A2B4A),
      child: SafeArea(
        child: Column(
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/branding/bousselha_logo.png',
                  height: 56,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, size: 40),
                ),
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 12),

            // Items de navigation complets
            _drawerItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0),
            _drawerItem(Icons.directions_car_outlined, Icons.directions_car, 'Voitures', 1),
            _drawerItem(Icons.person_pin_outlined, Icons.person_pin, 'Clients', 2),
            _drawerItem(Icons.description_outlined, Icons.description, 'Contrats', 3),
            _drawerItem(Icons.build_outlined, Icons.build, 'Maintenance', 4),
            _drawerItem(Icons.calendar_month_outlined, Icons.calendar_month, 'Calendrier', 5),

            const Spacer(),
            const Divider(color: Colors.white24, height: 1),
            _drawerItem(Icons.settings_outlined, Icons.settings, 'Paramètres', 6),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _selected == index;
    return ListTile(
      leading: Icon(
        isSelected ? activeIcon : icon,
        color: isSelected ? Colors.white : Colors.white60,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          fontSize: 15,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.white.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: () {
        setState(() => _selected = index);
        Navigator.pop(context); // fermer le drawer
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    // Contrats & Paramètres n'ont pas de header global dans le Shell (ils gèrent leur propre layout)
    final hideAppBar = _selected == 3 || _selected == 6;

    if (isMobile) {
      // ── LAYOUT MOBILE ──────────────────────────────────────────────────────
      return Scaffold(
        drawer: _buildMobileDrawer(),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
          title: Row(
            children: [
              Image.asset(
                'assets/branding/bousselha_logo.png',
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.directions_car_rounded, color: Color(0xFF1A2B4A), size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                _titles[_selected],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2B4A),
                ),
              ),
            ],
          ),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF1A2B4A)),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ),
        body: IndexedStack(
          index: _selected,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _bottomNavSelectedIndex,
          selectedItemColor: const Color(0xFF1A2B4A),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          backgroundColor: Colors.white,
          elevation: 12,
          onTap: (i) {
            final pageIdx = _bottomNavPageMap[i];
            if (pageIdx == -1) {
              // Ouvrir le drawer pour "Plus"
              Scaffold.of(context).openDrawer();
            } else {
              setState(() => _selected = pageIdx);
            }
          },
          items: _bottomNavItems,
        ),
      );
    }

    // ── LAYOUT TABLET & DESKTOP ───────────────────────────────────────────────
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
                _buildUnifiedHeader(context, _titles[_selected], isTablet ? '' : _subtitles[_selected]),
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
