import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/app_providers.dart';

class MaintenanceListScreen extends ConsumerWidget {
  const MaintenanceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenance = ref.watch(maintenanceProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAddMaintenanceDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter maintenance'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(maintenanceProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Rafraichir'),
              ),
            ],
          ),
        ),
        Expanded(
          child: maintenance.when(
            data: (data) {
              if (data.isEmpty) {
                return const Center(child: Text('Aucune maintenance trouvee.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: data.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = data[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.build),
                      title: Text('${item.type} - ${item.carLabel}'),
                      subtitle: Text('Debut: ${item.startDate}  |  Fin: ${item.endDate}'),
                      trailing: Text('${item.cost.toStringAsFixed(2)} MAD'),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Erreur maintenance: $err')),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddMaintenanceDialog(BuildContext context, WidgetRef ref) async {
    final typeCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    final startDateCtrl = TextEditingController();
    final endDateCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final cars = await ref.read(carRepositoryProvider).getCars();
    if (!context.mounted) return;
    if (cars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoute d abord une voiture avant maintenance.')),
      );
      return;
    }
    int? selectedCarId = cars.isNotEmpty ? cars.first.id : null;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ajouter maintenance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedCarId,
                items: cars
                    .map(
                      (car) => DropdownMenuItem<int>(
                        value: car.id,
                        child: Text('${car.brand} (${car.matricule})'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => selectedCarId = value),
                decoration: const InputDecoration(labelText: 'Voiture *'),
              ),
              TextField(
                controller: typeCtrl,
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              TextField(
                controller: startDateCtrl,
                decoration: const InputDecoration(labelText: 'Date debut (YYYY-MM-DD)'),
              ),
              TextField(
                controller: endDateCtrl,
                decoration: const InputDecoration(labelText: 'Date fin (YYYY-MM-DD)'),
              ),
              TextField(
                controller: descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: costCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Cout (optionnel)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                final type = typeCtrl.text.trim();
                final startDate = startDateCtrl.text.trim();
                final endDate = endDateCtrl.text.trim();
                final description = descriptionCtrl.text.trim();
                final cost = double.tryParse(costCtrl.text.trim());
                if (selectedCarId == null || type.isEmpty || startDate.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Voiture, type et date debut sont obligatoires.')),
                  );
                  return;
                }
                try {
                  await ref.read(maintenanceRepositoryProvider).createMaintenance(
                        carId: selectedCarId!,
                        type: type,
                        startDate: startDate,
                        endDate: endDate.isEmpty ? null : endDate,
                        description: description.isEmpty ? null : description,
                        cost: cost,
                      );
                  ref.invalidate(maintenanceProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Maintenance ajoutee avec succes.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur ajout maintenance: $e')),
                    );
                  }
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
