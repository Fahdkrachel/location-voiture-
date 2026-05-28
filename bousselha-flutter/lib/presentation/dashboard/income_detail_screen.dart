import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/income_record_model.dart';
import '../../shared/providers/app_providers.dart';

class IncomeDetailScreen extends ConsumerStatefulWidget {
  const IncomeDetailScreen({super.key});

  @override
  ConsumerState<IncomeDetailScreen> createState() => _IncomeDetailScreenState();
}

class _IncomeDetailScreenState extends ConsumerState<IncomeDetailScreen> {
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  String? _source;
  List<IncomeRecordModel> _items = [];
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
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(financialRepositoryProvider).getIncome(
            from: _fromCtrl.text.trim(),
            to: _toCtrl.text.trim(),
            source: _source,
            minAmount: double.tryParse(_minCtrl.text.trim().replaceAll(',', '.')),
            maxAmount: double.tryParse(_maxCtrl.text.trim().replaceAll(',', '.')),
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
      case 'CONTRACT':
        return 'Contrat';
      case 'PAYMENT':
        return 'Paiement';
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
      appBar: AppBar(title: const Text('Détail des revenus (Income)')),
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
                          width: 160,
                          child: DropdownButtonFormField<String?>(
                            value: _source,
                            decoration: const InputDecoration(labelText: 'Source', isDense: true),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('Toutes')),
                              DropdownMenuItem(value: 'CONTRACT', child: Text('Contrat')),
                              DropdownMenuItem(value: 'PAYMENT', child: Text('Paiement')),
                              DropdownMenuItem(value: 'OTHER', child: Text('Autre')),
                            ],
                            onChanged: (v) => setState(() => _source = v),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _minCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Montant min', isDense: true),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _maxCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Montant max', isDense: true),
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
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF059669)),
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
                    ? const Center(child: Text('Aucun revenu enregistré.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.payments, color: Color(0xFF059669)),
                              title: Text('${item.amount.toStringAsFixed(2)} MAD'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Date : ${item.recordedAt}'),
                                  Text('Source : ${_sourceLabel(item.source)}'),
                                  if (item.contractId != null) Text('Contrat #${item.contractId}'),
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
