import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/utils/app_error_handler.dart';
import '../../data/models/car_model.dart';
import '../../data/models/contract_model.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/matricule_text.dart';

/// Tag Hero stable pour transitions liste → détail.
String carHeroTag(int carId) => 'car-cover-$carId';

String _carActionErrorMessage(Object e) {
  final raw = e.toString();
  if (raw.contains('MAINTENANCE_NOT_FINISHED')) {
    return 'Terminez la maintenance via le module Maintenance avant de remettre le véhicule disponible.';
  }
  if (raw.contains('CAR_HAS_ACTIVE_CONTRACT')) {
    return 'Impossible : un contrat en cours ou actif est lié à ce véhicule.';
  }
  if (raw.contains('ONLY_RENTED_OR_MAINTENANCE')) {
    return 'Seuls les véhicules loués ou en maintenance peuvent être remis disponibles.';
  }
  return 'Erreur : $e';
}

Future<bool> markCarAvailable(BuildContext context, WidgetRef ref, CarModel car) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Remettre disponible'),
      content: Text(
        'Confirmer la remise en disponibilité de ${car.brand} (${car.matricule}) ?',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmer')),
      ],
    ),
  );
  if (ok != true) return false;
  try {
    await ref.read(carRepositoryProvider).markCarAvailable(id: car.id);
    _invalidateVehicleLists(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Véhicule remis en disponibilité.')),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) AppErrorHandler.showError(context, e);
    return false;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'AVAILABLE':
      return 'Disponible';
    case 'RENTED':
      return 'Louée';
    case 'MAINTENANCE':
      return 'En maintenance';
    default:
      return status;
  }
}

String _formatMileage(int mileage) {
  final raw = mileage.toString();
  return raw.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ' ');
}

String _formatMileageUpdatedAt(String value) {
  if (value.isEmpty) return '—';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final year = parsed.year.toString();
  return '$day/$month/$year';
}

void _invalidateVehicleLists(WidgetRef ref) {
  invalidateAllBoushelhaProviders(ref);
}

/// Ouverture du formulaire voiture depuis la liste ou l’écran détail.
Future<bool?> showCarFormDialog(BuildContext context, WidgetRef ref, {CarModel? car}) async {
  final brandCtrl = TextEditingController(text: car?.brand ?? '');
  final matriculeCtrl = BidiMatriculeEditingController(text: car?.matricule ?? '');
  final mileageCtrl = TextEditingController(text: car == null ? '' : car.mileage.toString());
  final inspectionCtrl = TextEditingController(text: car?.nextInspectionDate ?? '');
  final oilCtrl = TextEditingController(text: car?.lastOilChangeDate ?? '');
  final insuranceCtrl = TextEditingController(text: car?.insuranceExpiryDate ?? '');

  String fuelType = car?.fuelType.isNotEmpty == true ? car!.fuelType : 'ESSENCE';
  String? imagePath;
  String? imageName;
  String existingImageUrl = car?.imageUrl ?? '';

  return showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(car == null ? 'Ajouter une voiture' : 'Modifier voiture'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Marque *')),
                  const SizedBox(height: 8),
                  TextField(controller: matriculeCtrl, decoration: const InputDecoration(labelText: 'Matricule *')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: mileageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Kilométrage actuel *', suffixText: 'km'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: fuelType,
                    items: const [
                      DropdownMenuItem(value: 'ESSENCE', child: Text('Essence')),
                      DropdownMenuItem(value: 'DIESEL', child: Text('Diesel')),
                    ],
                    onChanged: (value) => setState(() => fuelType = value ?? 'ESSENCE'),
                    decoration: const InputDecoration(labelText: 'Carburant *'),
                  ),
                  if (car != null) ...[
                    const SizedBox(height: 8),
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Statut (lecture seule)'),
                      child: Text(
                        _statusLabel(car.status),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (car.status == 'RENTED' || car.status == 'MAINTENANCE') ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Pour remettre le véhicule disponible, utilisez l’action « Remettre disponible » dans la liste.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: inspectionCtrl,
                    decoration: const InputDecoration(labelText: 'Prochaine visite (YYYY-MM-DD)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: oilCtrl,
                    decoration: const InputDecoration(labelText: 'Derniere vidange (YYYY-MM-DD)'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: insuranceCtrl,
                    decoration: const InputDecoration(labelText: 'Expiration assurance (YYYY-MM-DD)'),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: const ['jpg', 'jpeg', 'png'],
                          withData: false,
                        );
                        if (result == null || result.files.isEmpty) return;
                        final file = result.files.single;
                        if (file.path == null) return;
                        setState(() {
                          imagePath = file.path!;
                          imageName = file.name;
                        });
                      },
                      icon: const Icon(Icons.photo_camera),
                      label: const Text('Choisir une photo'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (imagePath != null || existingImageUrl.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imagePath != null
                                    ? Image.file(
                                        File(imagePath!),
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        toPublicCarImageUrl(existingImageUrl),
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const SizedBox(
                                          width: 120,
                                          height: 120,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(color: Color(0xFFEAEAEA)),
                                            child: Icon(Icons.directions_car),
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(imageName ?? existingImageUrl.split('/').last),
                                    const SizedBox(height: 8),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          imagePath = null;
                                          imageName = null;
                                          existingImageUrl = '';
                                        });
                                      },
                                      icon: const Icon(Icons.close),
                                      tooltip: 'Retirer la photo',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                final brand = brandCtrl.text.trim();
                final matricule = matriculeCtrl.cleanText.trim();
                final mileageText = mileageCtrl.text.replaceAll(RegExp(r'\s+'), '').trim();
                final mileage = int.tryParse(mileageText);
                final nextInspectionDate = inspectionCtrl.text.trim();
                final lastOilChangeDate = oilCtrl.text.trim();
                final insuranceExpiryDate = insuranceCtrl.text.trim();

                if (brand.isEmpty || matricule.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marque et matricule sont obligatoires.')),
                  );
                  return;
                }
                if (mileage == null || mileage < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Le kilométrage actuel est obligatoire et doit être positif.')),
                  );
                  return;
                }
                if (car != null && mileage < car.mileage) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Le kilométrage ne peut pas diminuer.')),
                  );
                  return;
                }

                try {
                  if (car == null) {
                    await ref.read(carRepositoryProvider).createCar(
                          brand: brand,
                          fuelType: fuelType,
                          matricule: matricule,
                          mileage: mileage,
                          nextInspectionDate: nextInspectionDate.isEmpty ? null : nextInspectionDate,
                          lastOilChangeDate: lastOilChangeDate.isEmpty ? null : lastOilChangeDate,
                          insuranceExpiryDate: insuranceExpiryDate.isEmpty ? null : insuranceExpiryDate,
                          imagePath: imagePath,
                          status: 'AVAILABLE',
                        );
                  } else {
                    await ref.read(carRepositoryProvider).updateCar(
                          id: car.id,
                          brand: brand,
                          fuelType: fuelType,
                          matricule: matricule,
                          mileage: mileage,
                          nextInspectionDate: nextInspectionDate.isEmpty ? null : nextInspectionDate,
                          lastOilChangeDate: lastOilChangeDate.isEmpty ? null : lastOilChangeDate,
                          insuranceExpiryDate: insuranceExpiryDate.isEmpty ? null : insuranceExpiryDate,
                          imagePath: imagePath,
                          status: car.status,
                        );
                  }

                  if (context.mounted) {
                    _invalidateVehicleLists(ref);
                    Navigator.pop(context, true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(car == null ? 'Voiture ajoutee avec succes.' : 'Voiture modifiee avec succes.'),
                      ),
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
      );
    },
  );
}

String toPublicCarImageUrl(String imageUrl) {
  if (imageUrl.isEmpty) return '';
  if (imageUrl.startsWith('http')) return imageUrl;
  return 'http://localhost:8080$imageUrl';
}

void showCarImageFullscreen(BuildContext context, {required String imageUrl, String? heroTag}) {
  if (imageUrl.isEmpty) return;
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (ctx, _, __) => _FullscreenCarImagePage(
        imageUrl: toPublicCarImageUrl(imageUrl),
        heroTag: heroTag,
      ),
    ),
  );
}

Widget buildCarCoverImage({
  required String imageUrl,
  required double height,
  BoxFit fit = BoxFit.cover,
  String? heroTag,
}) {
  final child = imageUrl.isEmpty
      ? DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFFE8EEF7)),
          child: Icon(Icons.directions_car_rounded, size: height * 0.45, color: Color(0xFF173A63)),
        )
      : Image.network(
          toPublicCarImageUrl(imageUrl),
          fit: fit,
          width: double.infinity,
          height: height,
          errorBuilder: (_, __, ___) => DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFFE8EEF7)),
            child: Icon(Icons.directions_car_rounded, size: height * 0.45, color: Color(0xFF173A63)),
          ),
        );
  final sized = SizedBox(height: height, width: double.infinity, child: child);
  if (heroTag != null) {
    return Hero(tag: heroTag, child: Material(color: Colors.transparent, child: sized));
  }
  return sized;
}

class _FullscreenCarImagePage extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;

  const _FullscreenCarImagePage({required this.imageUrl, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final image = InteractiveViewer(
      minScale: 0.5,
      maxScale: 4,
      child: Center(
        child: heroTag != null
            ? Hero(
                tag: heroTag!,
                child: Image.network(imageUrl, fit: BoxFit.contain),
              )
            : Image.network(imageUrl, fit: BoxFit.contain),
      ),
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: image),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Route animée vers le détail voiture (fade + slide).
Route<bool> carDetailRoute(CarModel car) {
  return PageRouteBuilder<bool>(
    fullscreenDialog: false,
    settings: RouteSettings(name: 'car-detail-${car.id}', arguments: car),
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, animation, secondaryAnimation) => CarDetailScreen(car: car),
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class CarListScreen extends ConsumerStatefulWidget {
  const CarListScreen({super.key});

  @override
  ConsumerState<CarListScreen> createState() => _CarListScreenState();
}

class _CarListScreenState extends ConsumerState<CarListScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final cars = ref.watch(carsProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final changed = await showCarFormDialog(context, ref);
                  if (changed == true) ref.invalidate(carsProvider);
                },
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
              return Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: data.map((car) {
                        return _HorizontalCarCard(
                          car: car,
                          statusColor: _statusColor(car.status),
                          onOpen: () async {
                            final changed = await Navigator.of(context).push<bool>(carDetailRoute(car));
                            if (changed == true) ref.invalidate(carsProvider);
                          },
                          onEdit: () async {
                            final changed = await showCarFormDialog(context, ref, car: car);
                            if (changed == true) ref.invalidate(carsProvider);
                          },
                          onAvailable: () async {
                            final ok = await markCarAvailable(context, ref, car);
                            if (ok) ref.invalidate(carsProvider);
                          },
                          onDelete: () => _deleteCar(context, ref, car),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text(AppErrorHandler.getMessage(err))),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteCar(BuildContext context, WidgetRef ref, CarModel car) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer suppression'),
        content: Text('Supprimer ${car.brand} (${car.matricule}) ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(carRepositoryProvider).deleteCar(car.id);
      ref.invalidate(carsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voiture supprimee.')));
      }
    } catch (e) {
      if (context.mounted) AppErrorHandler.showError(context, e);
    }
  }

}

class _HorizontalCarCard extends StatelessWidget {
  final CarModel car;
  final Color statusColor;
  final VoidCallback onOpen;
  final Future<void> Function() onEdit;
  final Future<void> Function() onAvailable;
  final Future<void> Function() onDelete;

  const _HorizontalCarCard({
    required this.car,
    required this.statusColor,
    required this.onOpen,
    required this.onEdit,
    required this.onAvailable,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 272,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          onTap: onOpen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  buildCarCoverImage(
                    imageUrl: car.imageUrl,
                    height: 156,
                    heroTag: carHeroTag(car.id),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 22),
                        padding: EdgeInsets.zero,
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await onEdit();
                          } else if (value == 'available') {
                            await onAvailable();
                          } else if (value == 'delete') {
                            await onDelete();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                          if (car.status == 'RENTED' || car.status == 'MAINTENANCE')
                            const PopupMenuItem(value: 'available', child: Text('Remettre disponible')),
                          const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.brand,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    MatriculeText(
                      car.matricule,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14, letterSpacing: 0.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Carburant: ${car.fuelType}',
                      style: const TextStyle(fontSize: 12.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Kilométrage: ${_formatMileage(car.mileage)} km',
                      style: const TextStyle(fontSize: 12.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Mis à jour le: ${_formatMileageUpdatedAt(car.mileageUpdatedAt)}',
                      style: const TextStyle(fontSize: 12.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Prochaine visite: ${car.nextInspectionDate.isEmpty ? '—' : car.nextInspectionDate}',
                      style: const TextStyle(fontSize: 12.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        label: Text(_statusLabel(car.status)),
                        backgroundColor: statusColor.withValues(alpha: 0.14),
                        side: BorderSide(color: statusColor),
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CarDetailScreen extends ConsumerStatefulWidget {
  final CarModel car;
  const CarDetailScreen({super.key, required this.car});

  @override
  ConsumerState<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends ConsumerState<CarDetailScreen> with SingleTickerProviderStateMixin {
  late CarModel _car;
  List<ContractModel> _contracts = const [];
  bool _loading = true;
  late final AnimationController _introController;

  @override
  void initState() {
    super.initState();
    _car = widget.car;
    _introController = AnimationController(vsync: this, duration: const Duration(milliseconds: 620))
      ..addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool animate = true}) async {
    setState(() => _loading = true);
    try {
      final car =
          await ref.read(carRepositoryProvider).getCars().then((cars) => cars.firstWhere((c) => c.id == _car.id, orElse: () => _car));
      final contracts = await ref.read(contractRepositoryProvider).getContracts(carId: _car.id, history: true);
      if (mounted) {
        setState(() {
          _car = car;
          _contracts = contracts;
          _loading = false;
        });
        if (animate) {
          _introController.forward(from: 0);
        }
      }
    } finally {
      if (mounted && _loading) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return const Color(0xFF2E7D32);
      case 'RENTED':
        return const Color(0xFFE65100);
      case 'MAINTENANCE':
        return const Color(0xFFC62828);
      default:
        return Colors.grey.shade700;
    }
  }

  Color _contractStatusChipColor(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return Colors.amber;
      case 'ACTIVE':
        return Colors.green;
      case 'COMPLETED':
        return Colors.blue;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool _isSoon(String dateStr) {
    if (dateStr.isEmpty) return false;
    try {
      final d = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = d.difference(now).inDays;
      return diff >= 0 && diff <= 30;
    } catch (_) {
      return false;
    }
  }

  List<ContractModel> _sortedContractsForTimeline() {
    final list = List<ContractModel>.from(_contracts);
    list.sort((a, b) {
      try {
        return DateTime.parse(b.departureDatetime).compareTo(DateTime.parse(a.departureDatetime));
      } catch (_) {
        return b.departureDatetime.compareTo(a.departureDatetime);
      }
    });
    return list;
  }

  Future<void> _onEdit() async {
    final changed = await showCarFormDialog(context, ref, car: _car);
    if (changed == true) {
      await _loadData(animate: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voiture mise à jour.')));
      }
    }
  }

  Future<void> _onDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer suppression'),
        content: const Text('Supprimer cette voiture ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(carRepositoryProvider).deleteCar(_car.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voiture supprimée.')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppErrorHandler.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: Color(0xFFF4F6FA), body: Center(child: CircularProgressIndicator()));
    }

    final curve = CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic);
    final sc = Theme.of(context).colorScheme;

    Widget coverImage() {
      Widget imageChild;
      if (_car.imageUrl.isEmpty) {
        imageChild = const DecoratedBox(
          decoration: BoxDecoration(color: Color(0xFFE8ECF5)),
          child: Center(child: Icon(Icons.directions_car_rounded, size: 96)),
        );
      } else {
        imageChild = Image.network(
          toPublicCarImageUrl(_car.imageUrl),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => const DecoratedBox(
            decoration: BoxDecoration(color: Color(0xFFE8ECF5)),
            child: Center(child: Icon(Icons.directions_car_rounded, size: 96)),
          ),
        );
      }
      return Hero(
        tag: carHeroTag(_car.id),
        child: Material(color: Colors.transparent, child: imageChild),
      );
    }

    final body = FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero).animate(curve),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 248,
              pinned: true,
              stretch: true,
              backgroundColor: const Color(0xFF173A63),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                stretchModes: const [StretchMode.zoomBackground],
                background: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _car.imageUrl.isEmpty
                      ? null
                      : () => showCarImageFullscreen(
                            context,
                            imageUrl: _car.imageUrl,
                            heroTag: carHeroTag(_car.id),
                          ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      coverImage(),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black.withValues(alpha: 0.08), Colors.black.withValues(alpha: 0.55)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 72,
                        bottom: 52,
                        child: IgnorePointer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _car.brand,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  shadows: [Shadow(offset: Offset(0, 1), blurRadius: 6, color: Colors.black54)],
                                ),
                              ),
                              const SizedBox(height: 6),
                              MatriculeText(
                                _car.matricule,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.94), fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 4),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _statusPill(_car.status),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 112),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isSoon(_car.nextInspectionDate))
                      _alertChip(Colors.orange.shade800, '🛠️', 'Visite technique prochaine — moins de 30 jours'),
                    if (_isSoon(_car.insuranceExpiryDate))
                      _alertChip(Colors.red.shade900, '🛡️', 'Expiration assurance — moins de 30 jours'),
                    const SizedBox(height: 12),
                    _premiumSection(
                      title: 'Informations véhicule',
                      icon: Icons.info_outline_rounded,
                      accent: const Color(0xFF173A63),
                      child: _premiumInfoRows([
                        (_iconLabel(Icons.directions_car_outlined, 'Marque'), _car.brand),
                        (_iconLabel(Icons.confirmation_number_outlined, 'Matricule'), preserveBidiOrder(_car.matricule)),
                        (_iconLabel(Icons.local_gas_station_rounded, 'Carburant'), _car.fuelType),
                        (_iconLabel(Icons.speed_rounded, 'Kilométrage'), '${_formatMileage(_car.mileage)} km'),
                        (_iconLabel(Icons.update_rounded, 'Mis à jour le'), _formatMileageUpdatedAt(_car.mileageUpdatedAt)),
                        (_iconLabel(Icons.event_available_rounded, 'Prochaine visite'), _dash(_car.nextInspectionDate)),
                        (_iconLabel(Icons.build_circle_outlined, 'Dernière vidange'), _dash(_car.lastOilChangeDate)),
                        (_iconLabel(Icons.health_and_safety_outlined, 'Expiration assurance'), _dash(_car.insuranceExpiryDate)),
                      ]),
                    ),
                    const SizedBox(height: 22),
                    _sectionDivider(sc),
                    Text(
                      'Historique locations',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.3),
                    ),
                    const SizedBox(height: 10),
                    _contractsTimeline(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: body,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_car.status == 'RENTED' || _car.status == 'MAINTENANCE') ...[
            FloatingActionButton.extended(
              heroTag: 'fab-car-available',
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Remettre disponible'),
              onPressed: () async {
                final ok = await markCarAvailable(context, ref, _car);
                if (ok) await _loadData(animate: true);
              },
            ),
            const SizedBox(height: 12),
          ],
          FloatingActionButton.small(
            heroTag: 'fab-car-delete',
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
            elevation: 4,
            onPressed: _onDelete,
            child: const Icon(Icons.delete_outline_rounded),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'fab-car-edit',
            elevation: 4,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Modifier'),
            onPressed: _onEdit,
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    final c = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 8))],
      ),
      child: Text(
        _statusLabel(status),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.8, fontSize: 12),
      ),
    );
  }

  Widget _alertChip(Color color, String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withValues(alpha: 0.09), Colors.white]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 8))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: TextStyle(color: color.darken01, fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }

  Widget _sectionDivider(ColorScheme sc) =>
      Divider(height: 32, thickness: 1, color: sc.outlineVariant.withValues(alpha: 0.45));

  Widget _premiumSection({
    required String title,
    required IconData icon,
    required Color accent,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.065), blurRadius: 26, offset: const Offset(0, 14))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  accent,
                  Color.lerp(accent, Colors.black, 0.14)!,
                ]),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(color: Colors.white),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _premiumInfoRows(List<(Widget, String)> rows) {
    return Column(
      children: rows.asMap().entries.map((e) {
        final i = e.key;
        final row = e.value;
        final label = row.$1;
        final value = row.$2;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: i.isEven ? const Color(0xFFF8FAFF) : Colors.white,
            border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.04))),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 180, child: label),
                Expanded(
                  child: Text(
                    value.isEmpty ? '—' : value,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _iconLabel(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF173A63)),
          const SizedBox(width: 10),
          Flexible(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      );

  Widget _contractsTimeline(BuildContext context) {
    final items = _sortedContractsForTimeline();
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: const Text(
          'Aucun contrat enregistré pour cette voiture.',
          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
        ),
      );
    }

    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: List.generate(items.length, (i) {
        final c = items[i];
        final isLast = i == items.length - 1;

        final cardContent = AnimatedOpacity(
          duration: Duration(milliseconds: 220 + (i.clamp(0, 9) * 26)),
          opacity: _introController.isCompleted ? 1 : curveValue(_introController.value, delay: i * 0.04),
          child: AnimatedSlide(
            duration: Duration(milliseconds: 300 + i * 30),
            offset: _introController.isCompleted ? Offset.zero : const Offset(0, 0.04),
            curve: Curves.easeOutCubic,
            child: _timelineContractCard(c),
          ),
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 36,
                  child: Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary,
                          boxShadow: [
                            BoxShadow(color: primary.withValues(alpha: 0.45), blurRadius: 12, spreadRadius: 1),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 3,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [primary.withValues(alpha: 0.35), primary.withValues(alpha: 0.08)],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(child: cardContent),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _timelineContractCard(ContractModel c) {
    final chipColor = c.deleted ? Colors.grey : _contractStatusChipColor(c.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 14, left: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: c.deleted ? Colors.grey.shade50 : Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: c.deleted ? 0.12 : 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 10)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.clientName,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: chipColor.withValues(alpha: 0.55)),
                  ),
                  child: Text(
                    c.deleted ? 'SUPPRIMÉ' : c.status,
                    style: TextStyle(color: chipColor, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            if (c.deleted)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Contrat archivé (conservé dans l’historique)',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '${_dash(c.departureDatetime)}  →  ${_dash(c.expectedReturnDatetime)}',
              style: TextStyle(color: Colors.blueGrey.shade600, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.payments_rounded, size: 18, color: Colors.blueGrey.shade400),
                    const SizedBox(width: 6),
                    Text('Total', style: TextStyle(color: Colors.blueGrey.shade500, fontWeight: FontWeight.w600)),
                  ],
                ),
                Text(
                  '${c.totalGeneral.toStringAsFixed(2)} MAD',
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double curveValue(double t, {required double delay}) => (t - delay).clamp(0.0, 1.0);

  String _dash(String value) => value.isEmpty ? '—' : value;
}

extension on Color {
  Color get darken01 => Color.lerp(this, Colors.black, 0.12)!;
}
