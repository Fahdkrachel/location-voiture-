import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/responsive.dart';
import '../../data/models/car_model.dart';
import '../../data/models/contract_model.dart';
import '../../data/models/dashboard_alert_model.dart';
import '../../shared/providers/app_providers.dart';
import '../cars/car_list_screen.dart';
import '../contracts/contract_list_screen.dart';
import '../../shared/widgets/matricule_text.dart';
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
    final futureReservations = ref.watch(dashboardFutureReservationsProvider);
    final incomesAsync = ref.watch(incomeProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final carsAsync = ref.watch(carsProvider);

    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final pagePadding = isMobile ? 10.0 : (isTablet ? 14.0 : 16.0);
    final sectionHeight = isMobile ? 280.0 : 380.0;

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.all(pagePadding),
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
              data: (data) {
                final cards = [
                  _card(context, 'Total voitures', data.totalCars.toString(), const Color(0xFF1A2B4A)),
                  _card(context, 'Disponibles', data.available.toString(), const Color(0xFF10B981)),
                  _card(context, 'Louées', data.rented.toString(), const Color(0xFFF97316)),
                  _card(context, 'Maintenance', data.maintenance.toString(), const Color(0xFFEF4444)),
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
                ];
                if (isMobile || isTablet) {
                  // Grille 2 colonnes mobile, 3 tablette
                  final cols = isMobile ? 2 : 3;
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: isMobile ? 1.3 : 1.5,
                    children: cards,
                  );
                }
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: cards,
                );
              },
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
              height: sectionHeight,
              child: _buildCalendar(calendar, carsAsync),
            ),
            const SizedBox(height: 28),

            // 3. Réservations à venir (Réservations futures)
            const Text(
              'Réservations à venir',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2B4A),
                letterSpacing: 0.15,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: sectionHeight,
              child: _buildFutureReservations(futureReservations, carsAsync),
            ),
            const SizedBox(height: 28),

            // 4. Section alertes
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
              height: sectionHeight,
              child: _buildAlerts(alerts),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(String iso) {
    if (iso.isEmpty) return '—';
    try {
      final parsed = DateTime.tryParse(iso);
      if (parsed == null) return iso;
      final day = parsed.day.toString().padLeft(2, '0');
      final month = parsed.month.toString().padLeft(2, '0');
      final year = parsed.year.toString();
      return '$day/$month/$year';
    } catch (_) {
      return iso;
    }
  }

  Widget _buildCalendar(AsyncValue<List<ContractModel>> calendar, AsyncValue<List<CarModel>> carsAsync) {
    final cars = carsAsync.value ?? [];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: calendar.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Text(
                  'Aucune location active.',
                  style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final item = items[index];

                // Trouver l'image correspondante de la voiture via cars Provider
                String imageUrl = '';
                final matchingCar = cars.where((c) => c.id == item.carId).toList();
                if (matchingCar.isNotEmpty) {
                  imageUrl = matchingCar.first.imageUrl;
                }

                return ListTile(
                  hoverColor: const Color(0xFFF8FAFC),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ContractDetailScreen(contractId: item.id),
                      ),
                    ).then((_) {
                      invalidateAllBoushelhaProviders(ref);
                    });
                  },
                  leading: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: imageUrl.isEmpty
                          ? Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Icon(Icons.directions_car_rounded, color: Color(0xFF1A2B4A), size: 24),
                            )
                          : Image.network(
                              toPublicCarImageUrl(imageUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Icon(Icons.directions_car_rounded, color: Color(0xFF1A2B4A), size: 24),
                              ),
                            ),
                    ),
                  ),
                  title: Text(
                    '${item.carBrand} (${preserveBidiOrder(item.carMatricule)})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A2B4A)),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          item.clientName,
                          style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.calendar_month_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          '${_fmtDate(item.departureDatetime)} → ${_fmtDate(item.expectedReturnDatetime)}',
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Text(
                      'Actif',
                      style: TextStyle(
                        color: Color(0xFF065F46),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
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

  Widget _buildFutureReservations(AsyncValue<List<ContractModel>> futureReservations, AsyncValue<List<CarModel>> carsAsync) {
    final cars = carsAsync.value ?? [];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: futureReservations.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Text(
                  'Aucune réservation à venir.',
                  style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final item = items[index];

                // Trouver l'image correspondante de la voiture via cars Provider
                String imageUrl = '';
                final matchingCar = cars.where((c) => c.id == item.carId).toList();
                if (matchingCar.isNotEmpty) {
                  imageUrl = matchingCar.first.imageUrl;
                }

                // Calculer les jours restants
                final departureDate = DateTime.tryParse(item.departureDatetime);
                String daysLeftStr = '';
                if (departureDate != null) {
                  final now = DateTime.now();
                  final diff = departureDate.difference(now);
                  final daysLeft = diff.inDays;
                  if (daysLeft <= 0) {
                    daysLeftStr = "Aujourd'hui";
                  } else if (daysLeft == 1) {
                    daysLeftStr = "Demain";
                  } else {
                    daysLeftStr = "Dans $daysLeft j.";
                  }
                }

                return ListTile(
                  hoverColor: const Color(0xFFF8FAFC),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ContractDetailScreen(contractId: item.id),
                      ),
                    ).then((_) {
                      invalidateAllBoushelhaProviders(ref);
                    });
                  },
                  leading: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: imageUrl.isEmpty
                          ? Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Icon(Icons.directions_car_rounded, color: Color(0xFF1A2B4A), size: 24),
                            )
                          : Image.network(
                              toPublicCarImageUrl(imageUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Icon(Icons.directions_car_rounded, color: Color(0xFF1A2B4A), size: 24),
                              ),
                            ),
                    ),
                  ),
                  title: Text(
                    '${item.carBrand} (${preserveBidiOrder(item.carMatricule)})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A2B4A)),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          item.clientName,
                          style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.calendar_month_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          _fmtDate(item.departureDatetime),
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      daysLeftStr,
                      style: const TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Erreur réservations: $err')),
        ),
      ),
    );
  }

  Widget _buildAlerts(AsyncValue<List<DashboardAlertModel>> alerts) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: alerts.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Text(
                  'Aucune alerte.',
                  style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              );
            }

            final sortedItems = List<DashboardAlertModel>.from(items);
            sortedItems.sort((a, b) {
              final aHigh = a.severity == 'HIGH';
              final bHigh = b.severity == 'HIGH';
              if (aHigh && !bHigh) return -1;
              if (!aHigh && bHigh) return 1;
              return a.dueDate.compareTo(b.dueDate);
            });

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sortedItems.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final item = sortedItems[index];
                final color = item.severity == 'HIGH' ? const Color(0xFFEF4444) : const Color(0xFFF97316);
                final severityLabel = item.severity == 'HIGH' ? 'HAUTE' : 'MOYENNE';
                final alertBg = item.severity == 'HIGH' ? const Color(0xFFFEF2F2) : const Color(0xFFFFF7ED);
                final alertBorder = item.severity == 'HIGH' ? const Color(0xFFFCA5A5) : const Color(0xFFFED7AA);
                final alertText = item.severity == 'HIGH' ? const Color(0xFF991B1B) : const Color(0xFF9A3412);

                return ListTile(
                  hoverColor: const Color(0xFFF8FAFC),
                  onTap: (item.type == 'RETURN' && item.contractId != null)
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ContractDetailScreen(contractId: item.contractId!),
                            ),
                          ).then((_) {
                            invalidateAllBoushelhaProviders(ref);
                          });
                        }
                      : null,
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Icon(Icons.warning_amber_rounded, color: color, size: 20),
                  ),
                  title: Text(
                    '${item.carLabel} — ${item.type}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A2B4A)),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${item.message}  •  Échéance : ${_fmtDate(item.dueDate)}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: alertBg,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: alertBorder),
                    ),
                    child: Text(
                      severityLabel,
                      style: TextStyle(
                        color: alertText,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
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
    IconData icon;
    if (title.contains('voitures')) {
      icon = Icons.directions_car_rounded;
    } else if (title.contains('Disponibles')) {
      icon = Icons.check_circle_outline_rounded;
    } else if (title.contains('Louées')) {
      icon = Icons.key_rounded;
    } else if (title.contains('Maintenance')) {
      icon = Icons.build_rounded;
    } else if (title.contains('Revenus')) {
      icon = Icons.trending_up_rounded;
    } else if (title.contains('Dépenses')) {
      icon = Icons.trending_down_rounded;
    } else {
      icon = Icons.analytics_rounded;
    }

    return Container(
      // Sur mobile, les cartes s'étendent sur toute la largeur de leur cellule de grille
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    if (onTap != null)
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF94A3B8)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
