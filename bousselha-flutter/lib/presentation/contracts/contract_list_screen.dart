import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/app_providers.dart';

class ContractListScreen extends ConsumerWidget {
  const ContractListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contracts = ref.watch(contractsProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Formulaire contrat detaille: prochaine etape.'),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Nouveau contrat'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(contractsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Rafraichir'),
              ),
            ],
          ),
        ),
        Expanded(
          child: contracts.when(
            data: (data) {
              if (data.isEmpty) {
                return const Center(child: Text('Aucun contrat trouve.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: data.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final contract = data[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.description),
                      title: Text('${contract.carLabel} - ${contract.clientName}'),
                      subtitle: Text(
                        'Depart: ${contract.departureDatetime}\nRetour prevu: ${contract.expectedReturnDatetime}',
                      ),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(contract.status),
                          Text('${contract.totalGeneral.toStringAsFixed(2)} MAD'),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Erreur contrats: $err')),
          ),
        ),
      ],
    );
  }
}
