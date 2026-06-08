import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/app_error_handler.dart';
import '../../data/models/expense_record_model.dart';
import '../../shared/providers/app_providers.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  const ExpenseDetailScreen({super.key});

  @override
  ConsumerState<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  List<ExpenseRecordModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(financialRepositoryProvider).getExpenses();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) AppErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.fold<double>(0, (s, i) => s + i.amount);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dépenses (Expense)'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'Actualiser'),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Total : ${total.toStringAsFixed(2)} MAD — ${_items.length} entrée(s)',
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFDC2626), fontSize: 16),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('Aucune dépense enregistrée.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDate(item.recordedAt),
                                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${item.amount.toStringAsFixed(2)} MAD',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                  if (item.category.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      'Catégorie : ${item.category}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                    ),
                                  ],
                                  if (item.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(item.description, style: const TextStyle(fontSize: 14)),
                                  ],
                                  if (item.carName.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      'Véhicule : ${item.carName}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                    ),
                                  ],
                                  if (item.maintenanceId != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Maintenance #${item.maintenanceId}',
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                    ),
                                  ],
                                ],
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
