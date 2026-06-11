import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/responsive.dart';

class SidebarNav extends ConsumerWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const SidebarNav({super.key, required this.selected, required this.onSelect});

  static const _mainItems = [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(icon: Icons.directions_car_outlined, activeIcon: Icons.directions_car, label: 'Voitures'),
    _NavItem(icon: Icons.person_pin_outlined, activeIcon: Icons.person_pin, label: 'Clients'),
    _NavItem(icon: Icons.description_outlined, activeIcon: Icons.description, label: 'Contrats'),
    _NavItem(icon: Icons.build_outlined, activeIcon: Icons.build, label: 'Maintenance'),
    _NavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Calendrier'),
  ];

  static const int _settingsIndex = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTablet = Responsive.isTablet(context);
    // Sur mobile, la sidebar ne s'affiche pas (elle est remplacée par la BottomNav)
    // Sur tablette, elle est plus étroite (icônes seulement)
    final width = isTablet ? 60.0 : 80.0;
    final showLabels = !isTablet;

    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: Color(0xFF1A2B4A),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(2, 0))],
      ),
      child: Column(
        children: [
          // ── Logo / App Icon ─────────────────────────────────────────────
          Container(
            height: isTablet ? 60 : 72,
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 10, vertical: 8),
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/branding/bousselha_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          const Divider(height: 1, color: Colors.white12),
          const SizedBox(height: 8),

          // ── Main Navigation Items ────────────────────────────────────────
          ...List.generate(_mainItems.length, (i) {
            final item = _mainItems[i];
            final isSelected = selected == i;
            return _NavButton(
              icon: isSelected ? item.activeIcon : item.icon,
              label: item.label,
              isSelected: isSelected,
              showLabel: showLabels,
              onTap: () => onSelect(i),
            );
          }),

          // ── Spacer + Separator ───────────────────────────────────────────
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          ),
          const SizedBox(height: 8),

          // ── Paramètres ───────────────────────────────────────────────────
          _NavButton(
            icon: selected == _settingsIndex ? Icons.settings : Icons.settings_outlined,
            label: 'Paramètres',
            isSelected: selected == _settingsIndex,
            showLabel: showLabels,
            onTap: () => onSelect(_settingsIndex),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── NavButton Widget ─────────────────────────────────────────────────────────
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool showLabel;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Tooltip(
        message: label,
        preferBelow: false,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: Colors.white.withValues(alpha: 0.2))
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.65),
                ),
                if (showLabel) ...[
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.65),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}
