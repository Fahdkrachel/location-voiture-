import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_error_handler.dart';
import '../../data/models/maintenance_model.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/matricule_text.dart';

class MaintenanceListScreen extends ConsumerWidget {
  const MaintenanceListScreen({super.key});

  InputDecoration _dialogInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B), size: 18),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1A2B4A), width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenance = ref.watch(maintenanceProvider);
    return Column(
      children: [
        // Barre d'actions modernisée
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suivi des Maintenances',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2B4A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Planifiez et suivez les réparations de votre parc',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showAddMaintenanceDialog(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'Ajouter maintenance',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2B4A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: IconButton(
                      onPressed: () => invalidateAllBoushelhaProviders(ref),
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
                      tooltip: 'Rafraîchir',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        Expanded(
          child: maintenance.when(
            data: (data) {
              if (data.isEmpty) {
                // État vide professionnel
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(
                          Icons.build_rounded,
                          size: 44,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Aucune maintenance enregistrée',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Toutes les révisions et réparations s\'afficheront ici.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showAddMaintenanceDialog(context, ref),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text(
                          'Planifier une maintenance',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A2B4A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              // Liste des maintenances
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                itemCount: data.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = data[index];
                  final isCompleted = item.status == "COMPLETED";
                  
                  final statusBg = isCompleted ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED);
                  final statusBorder = isCompleted ? const Color(0xFFA7F3D0) : const Color(0xFFFED7AA);
                  final statusText = isCompleted ? const Color(0xFF065F46) : const Color(0xFF9A3412);
                  final statusLabel = isCompleted ? 'Terminée' : 'En cours';

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Icône de maintenance
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A2B4A).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.build_circle_rounded,
                              color: Color(0xFF1A2B4A),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Détails
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item.type,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(99),
                                        border: Border.all(color: statusBorder),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                          color: statusText,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.directions_car_rounded, size: 14, color: Color(0xFF64748B)),
                                    const SizedBox(width: 6),
                                    Text(
                                      item.carLabel,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF475569),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.calendar_month_outlined, size: 14, color: Color(0xFF64748B)),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${item.startDate.isEmpty ? "—" : item.startDate}  →  ${item.endDate.isEmpty ? "—" : item.endDate}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                if (item.description.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    item.description,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          // Coût
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${item.cost.toStringAsFixed(2)} MAD',
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFC8963E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          
                          // Actions
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isCompleted)
                                Tooltip(
                                  message: 'Marquer comme terminée',
                                  child: IconButton(
                                    icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981)),
                                    onPressed: () => _completeMaintenance(context, ref, item),
                                  ),
                                )
                              else
                                Tooltip(
                                  message: 'Supprimer',
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                                    onPressed: () => _deleteMaintenance(context, ref, item),
                                  ),
                                ),
                              Tooltip(
                                message: 'Modifier',
                                child: IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF1A2B4A)),
                                  onPressed: () => _showEditMaintenanceDialog(context, ref, item),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text(AppErrorHandler.getMessage(err))),
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
        const SnackBar(content: Text('Ajoutez d\'abord une voiture avant de planifier une maintenance.')),
      );
      return;
    }
    int? selectedCarId = cars.isNotEmpty ? cars.first.id : null;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Ajouter une maintenance',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2B4A)),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedCarId,
                    items: cars
                        .map(
                          (car) => DropdownMenuItem<int>(
                            value: car.id,
                            child: Text('${car.brand} (${preserveBidiOrder(car.matricule)})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => selectedCarId = value),
                    decoration: _dialogInputDecoration(
                      labelText: 'Voiture *',
                      prefixIcon: Icons.directions_car_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: typeCtrl,
                    decoration: _dialogInputDecoration(
                      labelText: 'Type de maintenance *',
                      prefixIcon: Icons.build_circle_rounded,
                      hintText: 'ex: Vidange, Révision, Pneus',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startDateCtrl,
                          decoration: _dialogInputDecoration(
                            labelText: 'Date début (AAAA-MM-JJ)',
                            prefixIcon: Icons.date_range_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: endDateCtrl,
                          decoration: _dialogInputDecoration(
                            labelText: 'Date fin (AAAA-MM-JJ)',
                            prefixIcon: Icons.event_available_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionCtrl,
                    maxLines: 2,
                    decoration: _dialogInputDecoration(
                      labelText: 'Description / Observations',
                      prefixIcon: Icons.notes_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: costCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _dialogInputDecoration(
                      labelText: 'Coût total (MAD) *',
                      prefixIcon: Icons.payments_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2B4A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                final type = typeCtrl.text.trim();
                final startDate = startDateCtrl.text.trim();
                final endDate = endDateCtrl.text.trim();
                final description = descriptionCtrl.text.trim();
                final cost = double.tryParse(costCtrl.text.trim().replaceAll(',', '.'));
                if (selectedCarId == null || type.isEmpty || cost == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La voiture, le type et le coût sont obligatoires.')),
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
                  invalidateAllBoushelhaProviders(ref);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Maintenance ajoutée avec succès.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) AppErrorHandler.showError(context, e);
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
      invalidateAllBoushelhaProviders(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maintenance terminée. Véhicule disponible si applicable.')),
        );
      }
    } catch (e) {
      if (context.mounted) AppErrorHandler.showError(context, e);
    }
  }

  Future<void> _deleteMaintenance(
    BuildContext context,
    WidgetRef ref,
    MaintenanceModel item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la maintenance'),
        content: Text(
          'Supprimer définitivement la maintenance « ${item.type} » (${item.carLabel}) ?\n'
          'Cette maintenance ne sera plus visible dans la liste, mais sa dépense financière restera conservée dans l\'historique.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(maintenanceRepositoryProvider).deleteMaintenance(item.id);
      invalidateAllBoushelhaProviders(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maintenance supprimée avec succès.')),
        );
      }
    } catch (e) {
      if (context.mounted) AppErrorHandler.showError(context, e);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Modifier la maintenance',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A2B4A)),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedCarId,
                    items: cars
                        .map(
                          (car) => DropdownMenuItem<int>(
                            value: car.id,
                            child: Text('${car.brand} (${preserveBidiOrder(car.matricule)})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => selectedCarId = value),
                    decoration: _dialogInputDecoration(
                      labelText: 'Voiture *',
                      prefixIcon: Icons.directions_car_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: typeCtrl,
                    decoration: _dialogInputDecoration(
                      labelText: 'Type de maintenance *',
                      prefixIcon: Icons.build_circle_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startDateCtrl,
                          decoration: _dialogInputDecoration(
                            labelText: 'Date début (AAAA-MM-JJ)',
                            prefixIcon: Icons.date_range_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: endDateCtrl,
                          decoration: _dialogInputDecoration(
                            labelText: 'Date fin (AAAA-MM-JJ)',
                            prefixIcon: Icons.event_available_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionCtrl,
                    maxLines: 2,
                    decoration: _dialogInputDecoration(
                      labelText: 'Description / Observations',
                      prefixIcon: Icons.notes_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: costCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _dialogInputDecoration(
                      labelText: 'Montant (MAD) *',
                      prefixIcon: Icons.payments_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Statut actuel :',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isCompleted ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: isCompleted ? const Color(0xFFA7F3D0) : const Color(0xFFFED7AA)),
                          ),
                          child: Text(
                            isCompleted ? 'Terminée' : 'En cours',
                            style: TextStyle(
                              color: isCompleted ? const Color(0xFF065F46) : const Color(0xFF9A3412),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isCompleted) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Pour clôturer cette maintenance, utilisez le bouton « Terminer » directement dans la liste.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A2B4A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                final type = typeCtrl.text.trim();
                final startDate = startDateCtrl.text.trim();
                final endDate = endDateCtrl.text.trim();
                final description = descriptionCtrl.text.trim();
                final cost = double.tryParse(costCtrl.text.trim().replaceAll(',', '.'));
                if (selectedCarId == null || type.isEmpty || cost == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La voiture, le type et le coût sont obligatoires.')),
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
                  invalidateAllBoushelhaProviders(ref);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Maintenance modifiée avec succès.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) AppErrorHandler.showError(context, e);
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
