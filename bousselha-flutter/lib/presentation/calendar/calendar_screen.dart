import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/car_availability_model.dart';
import '../../shared/providers/app_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  AsyncValue<List<CarAvailabilityModel>> _availability = const AsyncValue.loading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _dateIso => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _load() async {
    setState(() => _availability = const AsyncValue.loading());
    try {
      final items = await ref.read(carRepositoryProvider).getAvailabilityOnDate(_dateIso);
      if (mounted) setState(() => _availability = AsyncValue.data(items));
    } catch (e, st) {
      if (mounted) setState(() => _availability = AsyncValue.error(e, st));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _load();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return Colors.green;
      case 'RENTED':
        return Colors.orange;
      case 'MAINTENANCE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FilledButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualiser'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Disponibilité des véhicules au ${_dateIso}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _availability.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('Aucune voiture enregistrée.'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final color = _statusColor(item.currentStatus);
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Icon(Icons.directions_car, color: color),
                        ),
                        title: Text('${item.brand} — ${item.matricule}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('${item.fuelType} · ${item.availabilityLabel}'),
                        trailing: Chip(
                          label: Text(item.availabilityLabel, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                          side: BorderSide(color: color),
                          backgroundColor: color.withValues(alpha: 0.08),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e')),
            ),
          ),
        ],
      ),
    );
  }
}
