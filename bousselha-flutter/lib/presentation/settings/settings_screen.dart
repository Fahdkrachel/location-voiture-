import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/responsive.dart';
import '../../shared/providers/auth_provider.dart';
import 'pages/profile_info_page.dart';
import 'pages/security_page.dart';
import 'pages/admins_page.dart';
import 'pages/company_info_page.dart';
import 'pages/logo_page.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _selected = 0;

  static const _items = [
    _SettingsItem(icon: Icons.person_outline_rounded, label: 'Mon Profil'),
    _SettingsItem(icon: Icons.lock_outline_rounded, label: 'Sécurité'),
    _SettingsItem(icon: Icons.manage_accounts_outlined, label: 'Administrateurs'),
    _SettingsItem(icon: Icons.business_outlined, label: 'Informations Société'),
    _SettingsItem(icon: Icons.image_outlined, label: 'Logo'),
  ];

  static const _pages = <Widget>[
    ProfileInfoPage(),
    SecurityPage(),
    AdminsPage(),
    CompanyInfoPage(),
    LogoPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(authProvider).admin;
    final initials = (admin?['fullName'] as String?)?.isNotEmpty == true
        ? admin!['fullName'].toString().substring(0, 1).toUpperCase()
        : 'A';
    final adminName = admin?['fullName'] ?? 'Administrateur';
    final isMobile = Responsive.isMobile(context);

    // Contenu du panel gauche (sidebar ou drawer)
    final sidePanel = Container(
      width: isMobile ? double.infinity : 240,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: isMobile
            ? null
            : const Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            AppBar(
              backgroundColor: const Color(0xFF1A2B4A),
              foregroundColor: Colors.white,
              title: const Text('Paramètres', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          if (!isMobile)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2B4A).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.settings_outlined, color: Color(0xFF1A2B4A), size: 22),
                  ),
                  const SizedBox(height: 12),
                  const Text('Paramètres', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const Text('Compte & Configuration', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF1A2B4A),
                  child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(adminName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const Text('Administrateur', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('GÉNÉRAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
          ),
          const SizedBox(height: 4),
          ...List.generate(_items.length, (i) {
            final item = _items[i];
            final isSelected = _selected == i;
            if (i == 3) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('SOCIÉTÉ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
                  ),
                  const SizedBox(height: 4),
                  _buildMenuItem(i, item, isSelected, isMobile: isMobile),
                ],
              );
            }
            return _buildMenuItem(i, item, isSelected, isMobile: isMobile);
          }),
          const Spacer(),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: () => _confirmLogout(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFFEF2F2),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
                    SizedBox(width: 10),
                    Text('Déconnexion', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Paramètres', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          actions: [
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF1A2B4A)),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          ],
        ),
        drawer: Drawer(
          width: 280,
          child: SafeArea(child: sidePanel),
        ),
        body: Container(
          color: Colors.white,
          child: IndexedStack(
            index: _selected,
            children: _pages,
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          sidePanel,
          // ── RIGHT PANEL — Content ─────────────────────────────────────────
          Expanded(
            child: Container(
              color: Colors.white,
              child: IndexedStack(
                index: _selected,
                children: _pages,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, _SettingsItem item, bool isSelected, {bool isMobile = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: () {
          setState(() => _selected = index);
          if (isMobile) Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1A2B4A) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 18,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 10),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  const _SettingsItem({required this.icon, required this.label});
}
