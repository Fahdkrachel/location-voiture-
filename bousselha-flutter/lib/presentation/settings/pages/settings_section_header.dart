import 'package:flutter/material.dart';

/// Widget d'en-tête de section réutilisé dans toutes les sous-pages Paramètres.
class SettingsSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const SettingsSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2B4A).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF1A2B4A), size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            Text(subtitle,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          ],
        ),
      ],
    );
  }
}
