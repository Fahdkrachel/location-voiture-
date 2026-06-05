import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/car_availability_model.dart';
import '../cars/car_list_screen.dart' show toPublicCarImageUrl;
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/matricule_text.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  List<CarAvailabilityModel> _allAvailable = [];
  List<CarAvailabilityModel> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_applySearch);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applySearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _dateIso => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(carRepositoryProvider).getAvailableOnDate(_dateIso);
      if (mounted) {
        setState(() {
          _allAvailable = items;
          _applySearch();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  void _applySearch() {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) {
      _filtered = List.from(_allAvailable);
    } else {
      _filtered = _allAvailable
          .where((c) => c.brand.toLowerCase().contains(query))
          .toList();
    }
    if (mounted) setState(() {});
  }

  Widget _calendarCarPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      color: Colors.green.withValues(alpha: 0.12),
      child: const Icon(Icons.directions_car, color: Colors.green),
    );
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
          const SizedBox(height: 12),
          Text(
            'Véhicules disponibles — ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom du véhicule…',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_filtered.length} véhicule(s) disponible(s)',
            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          _allAvailable.isEmpty
                              ? 'Aucun véhicule disponible à cette date.'
                              : 'Aucun résultat pour cette recherche.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _filtered[index];
                          return Card(
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: item.imageUrl.isNotEmpty
                                    ? Image.network(
                                        toPublicCarImageUrl(item.imageUrl),
                                        width: 52,
                                        height: 52,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _calendarCarPlaceholder(),
                                      )
                                    : _calendarCarPlaceholder(),
                              ),
                              title: Text(
                                item.brand,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              subtitle: Text(
                                preserveBidiOrder(item.matricule),
                                style: const TextStyle(fontSize: 15, letterSpacing: 0.5),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
