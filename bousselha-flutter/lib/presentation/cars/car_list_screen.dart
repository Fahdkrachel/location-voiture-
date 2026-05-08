import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/app_providers.dart';

class CarListScreen extends ConsumerWidget {
  const CarListScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(carsProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAddCarDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter voiture'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(carsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Rafraichir'),
              ),
            ],
          ),
        ),
        Expanded(
          child: cars.when(
            data: (data) {
              if (data.isEmpty) {
                return const Center(child: Text('Aucune voiture trouvee.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: data.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final car = data[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: Text('${car.brand} - ${car.matricule}'),
                      trailing: Chip(
                        label: Text(car.status),
                        backgroundColor: _statusColor(car.status).withValues(alpha: 0.15),
                        side: BorderSide(color: _statusColor(car.status)),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Erreur voitures: $err')),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddCarDialog(BuildContext context, WidgetRef ref) async {
    final brandCtrl = TextEditingController();
    final matriculeCtrl = TextEditingController();
    String fuelType = 'ESSENCE';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter une voiture'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: brandCtrl,
                    decoration: const InputDecoration(labelText: 'Marque'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: matriculeCtrl,
                    decoration: const InputDecoration(labelText: 'Matricule'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: fuelType,
                    items: const [
                      DropdownMenuItem(value: 'ESSENCE', child: Text('Essence')),
                      DropdownMenuItem(value: 'DIESEL', child: Text('Diesel')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => fuelType = value);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Carburant'),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                final brand = brandCtrl.text.trim();
                final matricule = matriculeCtrl.text.trim();
                if (brand.isEmpty || matricule.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marque et matricule sont obligatoires.')),
                  );
                  return;
                }
                try {
                  await ref.read(carRepositoryProvider).createCar(
                        brand: brand,
                        fuelType: fuelType,
                        matricule: matricule,
                      );
                  ref.invalidate(carsProvider);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Voiture ajoutee avec succes.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur ajout voiture: $e')),
                    );
                  }
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }
}
