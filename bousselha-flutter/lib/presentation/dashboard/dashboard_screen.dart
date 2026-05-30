import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/car_model.dart';
import '../../data/models/contract_model.dart';
import '../../data/models/dashboard_alert_model.dart';
import '../../shared/providers/app_providers.dart';
import '../cars/car_list_screen.dart';
import 'expense_detail_screen.dart';
import 'income_detail_screen.dart';
import 'financial_chart.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);
    final calendar = ref.watch(dashboardCalendarProvider);
    final alerts = ref.watch(dashboardAlertsProvider);
    final incomesAsync = ref.watch(incomeProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final carsAsync = ref.watch(carsProvider);

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Graphique financier global (en haut, section principale)
            incomesAsync.when(
              data: (incomes) => expensesAsync.when(
                data: (expenses) => FinancialChart(incomes: incomes, expenses: expenses),
                loading: () => const SizedBox(
                  height: 200,
                  child: Card(child: Center(child: CircularProgressIndicator())),
                ),
                error: (err, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Erreur chargement dépenses : $err'),
                  ),
                ),
              ),
              loading: () => const SizedBox(
                height: 200,
                child: Card(child: Center(child: CircularProgressIndicator())),
              ),
              error: (err, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Erreur chargement revenus : $err'),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Cartes d'indicateurs de statistiques globales
            stats.when(
              data: (data) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _card(context, 'Total voitures', data.totalCars.toString(), Colors.blue),
                  _card(context, 'Disponibles', data.available.toString(), Colors.green),
                  _card(context, 'Louées', data.rented.toString(), Colors.orange),
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
                    'Dépenses (Expense)',
                    '${data.totalExpense.toStringAsFixed(2)} MAD',
                    const Color(0xFFDC2626),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ExpenseDetailScreen()),
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erreur stats: $err')),
            ),
            const SizedBox(height: 28),

            // 2. Calendrier des locations actives
            const Text(
              'Calendrier des locations actives',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2B4A),
                letterSpacing: 0.15,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 380, // Hauteur fixe scrollable
              child: _buildCalendar(calendar, carsAsync),
            ),
            const SizedBox(height: 28),

            // 3. Section alertes
            const Text(
              'Section Alertes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2B4A),
                letterSpacing: 0.15,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 380, // Hauteur fixe scrollable
              child: _buildAlerts(alerts),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(AsyncValue<List<ContractModel>> calendar, AsyncValue<List<CarModel>> carsAsync) {
    final cars = carsAsync.value ?? [];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: calendar.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Text(
                  'Aucune location active.',
                  style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                ),
              );
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = items[index];

                // Trouver l'image correspondante de la voiture via cars Provider
                String imageUrl = '';
                final matchingCar = cars.where((c) => c.id == item.carId).toList();
                if (matchingCar.isNotEmpty) {
                  imageUrl = matchingCar.first.imageUrl;
                }

                return ListTile(
                  dense: true,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.isEmpty
                        ? Container(
                            width: 52,
                            height: 52,
                            color: const Color(0xFFE8EEF7),
                            child: const Icon(Icons.directions_car, color: Color(0xFF173A63), size: 24),
                          )
                        : Image.network(
                            toPublicCarImageUrl(imageUrl),
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 52,
                              height: 52,
                              color: const Color(0xFFE8EEF7),
                              child: const Icon(Icons.directions_car, color: Color(0xFF173A63), size: 24),
                            ),
                          ),
                  ),
                  title: Text(
                    '${item.carLabel} — ${item.clientName}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A2B4A)),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Dates: ${item.departureDatetime} -> ${item.expectedReturnDatetime}\nStatut: ${item.status}',
                      style: TextStyle(color: Colors.grey.shade700, height: 1.3),
                    ),
                  ),
                  isThreeLine: true,
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: alerts.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Text(
                  'Aucune alerte.',
                  style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
                ),
              );
            }

            // Trier les alertes par priorité (HIGH en premier) puis par date (dueDate)
            final sortedItems = List<DashboardAlertModel>.from(items);
            sortedItems.sort((a, b) {
              final aHigh = a.severity == 'HIGH';
              final bHigh = b.severity == 'HIGH';
              if (aHigh && !bHigh) return -1;
              if (!aHigh && bHigh) return 1;
              return a.dueDate.compareTo(b.dueDate);
            });

            return ListView.separated(
              itemCount: sortedItems.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = sortedItems[index];
                final color = item.severity == 'HIGH' ? Colors.red : Colors.orange;
                final severityLabel = item.severity == 'HIGH' ? 'HAUTE' : 'MOYENNE';

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(Icons.warning_amber_rounded, color: color, size: 22),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.carLabel} — ${item.type}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A2B4A)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          border: Border.all(color: color),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          severityLabel,
                          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${item.message}\nÉchéance: ${item.dueDate}',
                      style: TextStyle(color: Colors.grey.shade700, height: 1.3),
                    ),
                  ),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54),
                      ),
                    ),
                    if (onTap != null)
                      Icon(Icons.open_in_new, size: 16, color: color.withValues(alpha: 0.7)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
