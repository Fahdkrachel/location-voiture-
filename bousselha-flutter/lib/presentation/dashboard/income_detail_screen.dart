import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/income_record_model.dart';
import '../../shared/providers/app_providers.dart';

class IncomeDetailScreen extends ConsumerStatefulWidget {
  const IncomeDetailScreen({super.key});

  @override
  ConsumerState<IncomeDetailScreen> createState() => _IncomeDetailScreenState();
}

class _IncomeDetailScreenState extends ConsumerState<IncomeDetailScreen> {
  List<IncomeRecordModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await ref.read(financialRepositoryProvider).getIncome();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
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
      appBar: AppBar(
        title: const Text('Revenus (Income)'),
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
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF059669), fontSize: 16),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('Aucun revenu enregistré.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final clientName = item.clientName.isNotEmpty
                              ? item.clientName
                              : (item.description.contains('—')
                                  ? item.description.split('—').last.trim()
                                  : '—');
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDate(item.recordedAt),
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${item.amount.toStringAsFixed(2)} MAD',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (item.contractId != null)
                                    Text(
                                      'Contrat #${item.contractId}',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                    ),
                                  const SizedBox(height: 4),
                                  Text('Client : $clientName', style: const TextStyle(fontSize: 15)),
                                  if (item.clientId != null)
                                    Text('ID Client : ${item.clientId}', style: const TextStyle(fontSize: 14)),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Source : ${_sourceLabel(item.source)}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
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
