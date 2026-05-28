import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/contract_model.dart';
import '../../data/models/dashboard_alert_model.dart';
import '../../shared/providers/app_providers.dart';
import 'expense_detail_screen.dart';
import 'income_detail_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final calendar = ref.watch(dashboardCalendarProvider);
    final alerts = ref.watch(dashboardAlertsProvider);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: stats.when(
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _card(context, 'Total voitures', data.totalCars.toString(), Colors.blue),
                _card(context, 'Disponibles', data.available.toString(), Colors.green),
                _card(context, 'Louees', data.rented.toString(), Colors.orange),
                _card(context, 'Maintenance', data.maintenance.toString(), Colors.red),
                _card(
                  context,
                  'Revenus (Income)',
                  '${data.totalIncome.toStringAsFixed(2)} MAD',
                  const Color(0xFF059669),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const IncomeDetailScreen()),
                  ),
                ),
                _card(
                  context,
                  'Depenses (Expense)',
                  '${data.totalExpense.toStringAsFixed(2)} MAD',
                  const Color(0xFFDC2626),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ExpenseDetailScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Calendrier des locations actives'),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildCalendar(calendar)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildAlerts(alerts)),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildCalendar(AsyncValue<List<ContractModel>> calendar) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: calendar.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('Aucune location active.'));
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.event),
                  title: Text('${item.carLabel} - ${item.clientName}'),
                  subtitle: Text('${item.departureDatetime} -> ${item.expectedReturnDatetime}'),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Erreur calendrier: $err')),
        ),
      ),
    );
  }

  Widget _buildAlerts(AsyncValue<List<DashboardAlertModel>> alerts) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: alerts.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('Aucune alerte.'));
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = items[index];
                final color = item.severity == 'HIGH' ? Colors.red : Colors.orange;
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.warning_amber, color: color),
                  title: Text('${item.carLabel} (${item.type})'),
                  subtitle: Text('${item.message}\nEcheance: ${item.dueDate}'),
                  isThreeLine: true,
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Erreur alertes: $err')),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, String title, String value, Color color, {VoidCallback? onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 200,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontSize: 13))),
                    if (onTap != null) Icon(Icons.open_in_new, size: 16, color: color.withValues(alpha: 0.7)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
