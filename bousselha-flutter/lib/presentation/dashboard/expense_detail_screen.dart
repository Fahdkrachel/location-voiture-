import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/expense_record_model.dart';
import '../../shared/providers/app_providers.dart';

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  const ExpenseDetailScreen({super.key});

  @override
  ConsumerState<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  String? _source;
  List<ExpenseRecordModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(financialRepositoryProvider).getExpenses(
            from: _fromCtrl.text.trim(),
            to: _toCtrl.text.trim(),
            source: _source,
            category: _categoryCtrl.text.trim(),
          );
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _sourceLabel(String source) {
    switch (source) {
      case 'MAINTENANCE':
        return 'Maintenance';
      case 'OTHER':
        return 'Autre';
      default:
        return source;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.fold<double>(0, (s, i) => s + i.amount);
    return Scaffold(
      appBar: AppBar(title: const Text('Détail des dépenses')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: _fromCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Date début',
                              hintText: 'YYYY-MM-DD',
                              isDense: true,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: _toCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Date fin',
                              hintText: 'YYYY-MM-DD',
                              isDense: true,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 170,
                          child: DropdownButtonFormField<String?>(
                            value: _source,
                            decoration: const InputDecoration(labelText: 'Source', isDense: true),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('Toutes')),
                              DropdownMenuItem(value: 'MAINTENANCE', child: Text('Maintenance')),
                              DropdownMenuItem(value: 'OTHER', child: Text('Autre')),
                            ],
                            onChanged: (v) => setState(() => _source = v),
                          ),
                        ),
                        SizedBox(
                          width: 160,
                          child: TextField(
                            controller: _categoryCtrl,
                            decoration: const InputDecoration(labelText: 'Catégorie', isDense: true),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.filter_alt),
                          label: const Text('Filtrer'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Total filtré : ${total.toStringAsFixed(2)} MAD (${_items.length} entrée(s))',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('Aucune dépense enregistrée.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.money_off, color: Color(0xFFDC2626)),
                              title: Text('${item.amount.toStringAsFixed(2)} MAD'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Date : ${item.recordedAt}'),
                                  Text('Source : ${_sourceLabel(item.source)}'),
                                  if (item.category.isNotEmpty) Text('Catégorie : ${item.category}'),
                                  if (item.maintenanceId != null) Text('Maintenance #${item.maintenanceId}'),
                                  if (item.description.isNotEmpty) Text(item.description),
                                  Text('Par : ${item.createdBy}'),
                                ],
                              ),
                              isThreeLine: true,
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
