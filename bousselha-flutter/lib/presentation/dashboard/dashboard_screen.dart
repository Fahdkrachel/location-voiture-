import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/app_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(carsProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: cars.when(
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              children: [
                _card('Total voitures', data.length.toString(), Colors.blue),
                _card('Disponibles', data.where((e) => e.status == 'AVAILABLE').length.toString(), Colors.green),
                _card('Louees', data.where((e) => e.status == 'RENTED').length.toString(), Colors.orange),
                _card('Maintenance', data.where((e) => e.status == 'MAINTENANCE').length.toString(), Colors.red),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Calendrier locations actives (a connecter a /dashboard/calendar)'),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _card(String title, String value, Color color) {
    return Card(
      child: SizedBox(
        width: 200,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
