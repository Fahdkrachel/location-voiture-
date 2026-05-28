import 'package:flutter/material.dart';

class SidebarNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const SidebarNav({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selected,
      onDestinationSelected: onSelect,
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
        NavigationRailDestination(icon: Icon(Icons.directions_car), label: Text('Voitures')),
        NavigationRailDestination(icon: Icon(Icons.person_pin), label: Text('Clients')),
        NavigationRailDestination(icon: Icon(Icons.description), label: Text('Contrats')),
        NavigationRailDestination(icon: Icon(Icons.build), label: Text('Maintenance')),
      ],
    );
  }
}
