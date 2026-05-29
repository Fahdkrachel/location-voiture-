import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/maintenance_model.dart';
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
                      subtitle: Text(
                        'Début: ${item.startDate.isEmpty ? "—" : item.startDate}  |  Fin: ${item.endDate.isEmpty ? "—" : item.endDate}\n'
                        'Statut: ${item.status == "COMPLETED" ? "Terminée" : "En cours"}',
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${item.cost.toStringAsFixed(2)} MAD'),
                          if (item.status != 'COMPLETED')
                            FilledButton.tonal(
                              onPressed: () => _completeMaintenance(context, ref, item),
                              child: const Text('Terminer'),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showEditMaintenanceDialog(context, ref, item),
                          ),
                        ],
                      ),
                      onTap: () => _showEditMaintenanceDialog(context, ref, item),
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
                decoration: const InputDecoration(labelText: 'Date debut (YYYY-MM-DD) — optionnel'),
              ),
              TextField(
                controller: endDateCtrl,
                decoration: const InputDecoration(labelText: 'Date fin (YYYY-MM-DD) — optionnel'),
              ),
              TextField(
                controller: descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: costCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Cout (MAD) *'),
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
                final cost = double.tryParse(costCtrl.text.trim().replaceAll(',', '.'));
                if (selectedCarId == null || type.isEmpty || cost == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Voiture, type et cout sont obligatoires.')),
                  );
                  return;
                }
                try {
                  await ref.read(maintenanceRepositoryProvider).createMaintenance(
                        carId: selectedCarId!,
                        type: type,
                        startDate: startDate.isEmpty ? null : startDate,
                        endDate: endDate.isEmpty ? null : endDate,
                        description: description.isEmpty ? null : description,
                        cost: cost,
                      );
                  ref.invalidate(carsProvider);
                  ref.invalidate(maintenanceProvider);
                  ref.invalidate(dashboardStatsProvider);
                  ref.invalidate(contractsProvider);
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

  Future<void> _completeMaintenance(
    BuildContext context,
    WidgetRef ref,
    MaintenanceModel item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminer la maintenance'),
        content: Text(
          'Marquer la maintenance « ${item.type} » (${item.carLabel}) comme terminée ?\n'
          'Le véhicule redeviendra disponible si aucune autre maintenance n’est en cours.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Terminer')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(maintenanceRepositoryProvider).completeMaintenance(item.id);
      ref.invalidate(carsProvider);
      ref.invalidate(maintenanceProvider);
      ref.invalidate(dashboardStatsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maintenance terminée. Véhicule disponible si applicable.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  Future<void> _showEditMaintenanceDialog(
    BuildContext context,
    WidgetRef ref,
    MaintenanceModel item,
  ) async {
    final typeCtrl = TextEditingController(text: item.type);
    final descriptionCtrl = TextEditingController(text: item.description);
    final startDateCtrl = TextEditingController(text: item.startDate);
    final endDateCtrl = TextEditingController(text: item.endDate);
    final costCtrl = TextEditingController(text: item.cost.toString());
    final cars = await ref.read(carRepositoryProvider).getCars();
    if (!context.mounted) return;
    int? selectedCarId = item.carId;
    final isCompleted = item.status == 'COMPLETED';

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Modifier maintenance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedCarId,
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
                TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Type de coût *')),
                TextField(
                  controller: startDateCtrl,
                  decoration: const InputDecoration(labelText: 'Date début (YYYY-MM-DD) — optionnel'),
                ),
                TextField(
                  controller: endDateCtrl,
                  decoration: const InputDecoration(labelText: 'Date fin (YYYY-MM-DD) — optionnel'),
                ),
                TextField(
                  controller: descriptionCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                TextField(
                  controller: costCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Montant (MAD) *'),
                ),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Statut'),
                  child: Text(
                    isCompleted ? 'Terminée' : 'En cours',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (!isCompleted) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Pour clôturer, utilisez le bouton « Terminer » dans la liste.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                final type = typeCtrl.text.trim();
                final startDate = startDateCtrl.text.trim();
                final endDate = endDateCtrl.text.trim();
                final description = descriptionCtrl.text.trim();
                final cost = double.tryParse(costCtrl.text.trim().replaceAll(',', '.'));
                if (selectedCarId == null || type.isEmpty || cost == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Voiture, type et montant sont obligatoires.')),
                  );
                  return;
                }
                try {
                  await ref.read(maintenanceRepositoryProvider).updateMaintenance(
                        id: item.id,
                        carId: selectedCarId!,
                        type: type,
                        startDate: startDate.isEmpty ? null : startDate,
                        endDate: endDate.isEmpty ? null : endDate,
                        description: description.isEmpty ? null : description,
                        cost: cost,
                        status: item.status.isNotEmpty ? item.status : 'IN_PROGRESS',
                      );
                  ref.invalidate(carsProvider);
                  ref.invalidate(maintenanceProvider);
                  ref.invalidate(dashboardStatsProvider);
                  ref.invalidate(contractsProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Maintenance modifiée avec succès.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur modification: $e')),
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
