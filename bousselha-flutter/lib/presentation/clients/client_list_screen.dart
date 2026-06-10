import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_error_handler.dart';
import '../../data/models/client_model.dart';
import '../../shared/providers/app_providers.dart';

class ClientListScreen extends ConsumerWidget {
  const ClientListScreen({super.key});

  Color _colorFromName(String name) {
    final value = name.trim().toLowerCase();
    int hash = 0;
    for (final unit in value.codeUnits) {
      hash = 0x1fffffff & (hash + unit);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));

    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1, hue, 0.55, 0.50).toColor();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(clientsProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF1D4ED8), size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Les clients sont ajoutés automatiquement lors de la création d’un contrat.',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => ref.invalidate(clientsProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF1D4ED8)),
                  label: const Text(
                    'Rafraîchir',
                    style: TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: clients.when(
            data: (data) {
              if (data.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucun client trouvé.',
                    style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                itemCount: data.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final client = data[index];
                  final avatarColor = _colorFromName(client.fullName);
                  
                  // Calcul des initiales
                  final parts = client.fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
                  String initials = '?';
                  if (parts.isNotEmpty) {
                    final first = parts.first.substring(0, 1).toUpperCase();
                    final last = parts.length > 1 ? parts.last.substring(0, 1).toUpperCase() : '';
                    initials = '$first$last';
                  }

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
                    child: ListTile(
                      hoverColor: const Color(0xFFF8FAFC),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: avatarColor.withValues(alpha: 0.12),
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: avatarColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            client.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: Color(0xFF1A2B4A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#${client.id}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              client.phone.isEmpty ? '—' : client.phone,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                              ),
                            ),
                            if (client.cinNumber.isNotEmpty) ...[
                              const SizedBox(width: 16),
                              const Icon(Icons.credit_card_outlined, size: 13, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                'CIN: ${client.cinNumber}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
                      onTap: () async {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => ClientDetailScreen(clientId: client.id, avatarColor: avatarColor),
                          ),
                        );
                        if (changed == true) {
                          ref.invalidate(clientsProvider);
                        }
                      },
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

}

/// Étape 1 du wizard « Nouveau contrat » — collecte les infos client sans enregistrement API.
Future<ClientFormPayload?> pickClientForNewContract(
  BuildContext context, {
  ClientFormPayload? initial,
}) async {
  final formKey = GlobalKey<FormState>();
  final fullNameCtrl = TextEditingController(text: initial?.fullName ?? '');
  final birthDateCtrl = TextEditingController(text: initial?.birthDate ?? '');
  final addressMoroccoCtrl = TextEditingController(text: initial?.addressMorocco ?? '');
  final addressAbroadCtrl = TextEditingController(text: initial?.addressAbroad ?? '');
  final professionCtrl = TextEditingController(text: initial?.profession ?? '');
  final drivingLicenseNumberCtrl = TextEditingController(text: initial?.drivingLicenseNumber ?? '');
  final drivingLicenseIssuedAtCtrl = TextEditingController(text: initial?.drivingLicenseIssuedAt ?? '');
  final cinCtrl = TextEditingController(text: initial?.cinNumber ?? '');
  final passportNumberCtrl = TextEditingController(text: initial?.passportNumber ?? '');
  final passportIssuedAtCtrl = TextEditingController(text: initial?.passportIssuedAt ?? '');
  final phoneCtrl = TextEditingController(text: initial?.phone ?? '');
  final addFullNameCtrl = TextEditingController(text: initial?.additionalDriverFullName ?? '');
  final addLicenseNumberCtrl = TextEditingController(text: initial?.additionalDriverDrivingLicenseNumber ?? '');
  final addLicenseIssuedAtCtrl = TextEditingController(text: initial?.additionalDriverDrivingLicenseIssuedAt ?? '');
  final addPassportNumberCtrl = TextEditingController(text: initial?.additionalDriverPassportNumber ?? '');

  ClientFormPayload? result;

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Nouveau contrat — Étape 1/2 : Client'),
      content: SizedBox(
        width: 720,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionHeader(titleFr: 'LOCATAIRE', titleAr: 'المكتري'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: fullNameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom & Prénom *'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Téléphone *'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: cinCtrl,
                  decoration: const InputDecoration(labelText: 'CIN — optionnel'),
                ),
                const SizedBox(height: 8),
                TextFormField(controller: birthDateCtrl, decoration: const InputDecoration(labelText: 'Date naissance (YYYY-MM-DD)')),
                const SizedBox(height: 8),
                TextFormField(controller: addressMoroccoCtrl, decoration: const InputDecoration(labelText: 'Adresse Maroc'), maxLines: 2),
                const SizedBox(height: 8),
                TextFormField(controller: addressAbroadCtrl, decoration: const InputDecoration(labelText: 'Adresse Étranger'), maxLines: 2),
                const SizedBox(height: 8),
                TextFormField(controller: professionCtrl, decoration: const InputDecoration(labelText: 'Profession')),
                const SizedBox(height: 8),
                TextFormField(controller: drivingLicenseNumberCtrl, decoration: const InputDecoration(labelText: 'Permis N°')),
                const SizedBox(height: 8),
                TextFormField(controller: drivingLicenseIssuedAtCtrl, decoration: const InputDecoration(labelText: 'Permis délivré à')),
                const SizedBox(height: 8),
                TextFormField(controller: passportNumberCtrl, decoration: const InputDecoration(labelText: 'Passeport N°')),
                const SizedBox(height: 8),
                TextFormField(controller: passportIssuedAtCtrl, decoration: const InputDecoration(labelText: 'Passeport délivré (YYYY-MM-DD)')),
                const SizedBox(height: 16),
                const _SectionHeader(titleFr: 'CONDUCTEUR SUPPLÉMENTAIRE', titleAr: 'السائق المرخص'),
                const SizedBox(height: 8),
                TextFormField(controller: addFullNameCtrl, decoration: const InputDecoration(labelText: 'Nom & Prénom')),
                const SizedBox(height: 8),
                TextFormField(controller: addLicenseNumberCtrl, decoration: const InputDecoration(labelText: 'Permis N°')),
                const SizedBox(height: 8),
                TextFormField(controller: addLicenseIssuedAtCtrl, decoration: const InputDecoration(labelText: 'Délivré le (YYYY-MM-DD)')),
                const SizedBox(height: 8),
                TextFormField(controller: addPassportNumberCtrl, decoration: const InputDecoration(labelText: 'Passeport N°')),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          onPressed: () {
            if (!(formKey.currentState?.validate() ?? false)) return;
            result = ClientFormPayload(
              fullName: fullNameCtrl.text.trim(),
              birthDate: birthDateCtrl.text.trim(),
              addressMorocco: addressMoroccoCtrl.text.trim(),
              addressAbroad: addressAbroadCtrl.text.trim(),
              profession: professionCtrl.text.trim(),
              drivingLicenseNumber: drivingLicenseNumberCtrl.text.trim(),
              drivingLicenseIssuedAt: drivingLicenseIssuedAtCtrl.text.trim(),
              cinNumber: cinCtrl.text.trim(),
              passportNumber: passportNumberCtrl.text.trim(),
              passportIssuedAt: passportIssuedAtCtrl.text.trim(),
              phone: phoneCtrl.text.trim(),
              additionalDriverFullName: addFullNameCtrl.text.trim(),
              additionalDriverDrivingLicenseNumber: addLicenseNumberCtrl.text.trim(),
              additionalDriverDrivingLicenseIssuedAt: addLicenseIssuedAtCtrl.text.trim(),
              additionalDriverPassportNumber: addPassportNumberCtrl.text.trim(),
            );
            Navigator.pop(context);
          },
          child: const Text('Suivant'),
        ),
      ],
    ),
  );

  return result;
}

class ClientDetailScreen extends ConsumerStatefulWidget {
  final int clientId;
  final Color avatarColor;
  const ClientDetailScreen({super.key, required this.clientId, required this.avatarColor});

  @override
  ConsumerState<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends ConsumerState<ClientDetailScreen> {
  ClientModel? _client;
  bool _loading = true;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchClient();
  }

  Future<void> _fetchClient() async {
    setState(() => _loading = true);
    try {
      final client = await ref.read(clientRepositoryProvider).getClientById(widget.clientId);
      if (mounted) {
        setState(() => _client = client);
      }
    } catch (e) {
      if (mounted) AppErrorHandler.showError(context, e);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.length > 1 ? parts.last.substring(0, 1).toUpperCase() : '';
    return '$first$last';
  }

  Future<void> _onEdit() async {
    final client = _client;
    if (client == null) return;
    final changed = await _showClientFormDialog(
      context: context,
      title: 'Modifier client',
      submitLabel: 'Enregistrer',
      successMessage: 'Client modifie avec succes.',
      initial: client,
      onSubmit: (payload) async {
        await ref.read(clientRepositoryProvider).updateClient(
              id: client.id,
              fullName: payload.fullName,
              cinNumber: payload.cinNumber,
              phone: payload.phone,
              birthDate: payload.birthDate,
              addressMorocco: payload.addressMorocco,
              addressAbroad: payload.addressAbroad,
              profession: payload.profession,
              drivingLicenseNumber: payload.drivingLicenseNumber,
              drivingLicenseIssuedAt: payload.drivingLicenseIssuedAt,
              passportNumber: payload.passportNumber,
              passportIssuedAt: payload.passportIssuedAt,
              additionalDriverFullName: payload.additionalDriverFullName,
              additionalDriverDrivingLicenseNumber: payload.additionalDriverDrivingLicenseNumber,
              additionalDriverDrivingLicenseIssuedAt: payload.additionalDriverDrivingLicenseIssuedAt,
              additionalDriverPassportNumber: payload.additionalDriverPassportNumber,
            );
      },
    );
    if (changed == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final client = _client;
    if (client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détail client')),
        body: const Center(child: Text('Client introuvable.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Détail client')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: widget.avatarColor,
                    child: Text(
                      _initials(client.fullName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(client.fullName, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const _SectionHeader(titleFr: 'LOCATAIRE', titleAr: 'المكتري'),
            const SizedBox(height: 10),
            _InfoTile(icon: Icons.person, label: 'Nom & Prénom', value: client.fullName),
            _InfoTile(icon: Icons.cake, label: 'Date de naissance', value: client.birthDate),
            _InfoTile(icon: Icons.home, label: 'Adresse au Maroc', value: client.addressMorocco),
            _InfoTile(icon: Icons.public, label: "Adresse à l'Étranger", value: client.addressAbroad),
            _InfoTile(icon: Icons.work, label: 'Profession', value: client.profession),
            _InfoTile(icon: Icons.badge, label: 'Permis de Conduire N°', value: client.drivingLicenseNumber),
            _InfoTile(icon: Icons.location_city, label: 'Délivré à (ville)', value: client.drivingLicenseIssuedAt),
            _InfoTile(icon: Icons.credit_card, label: 'CIN N°', value: client.cinNumber),
            _InfoTile(icon: Icons.book, label: 'Passeport N°', value: client.passportNumber),
            _InfoTile(icon: Icons.event, label: 'Passeport délivré le', value: client.passportIssuedAt),
            _InfoTile(icon: Icons.phone, label: 'Téléphone', value: client.phone),
            const SizedBox(height: 18),
            const _SectionHeader(titleFr: 'CONDUCTEUR SUPPLÉMENTAIRE', titleAr: 'السائق المرخص'),
            const SizedBox(height: 10),
            _InfoTile(icon: Icons.person_outline, label: 'Nom & Prénom', value: client.additionalDriverFullName),
            _InfoTile(
              icon: Icons.badge_outlined,
              label: 'Permis de Conduire N°',
              value: client.additionalDriverDrivingLicenseNumber,
            ),
            _InfoTile(
              icon: Icons.event_note,
              label: 'Délivré le',
              value: client.additionalDriverDrivingLicenseIssuedAt,
            ),
            _InfoTile(
              icon: Icons.menu_book_outlined,
              label: 'Passeport N°',
              value: client.additionalDriverPassportNumber,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          onPressed: _actionLoading ? null : _onEdit,
          icon: const Icon(Icons.edit),
          label: const Text('Modifier'),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? '-' : value.trim();
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(displayValue),
      ),
    );
  }
}

class ClientFormPayload {
  final String fullName;
  final String birthDate;
  final String addressMorocco;
  final String addressAbroad;
  final String profession;
  final String drivingLicenseNumber;
  final String drivingLicenseIssuedAt;
  final String cinNumber;
  final String passportNumber;
  final String passportIssuedAt;
  final String phone;
  final String additionalDriverFullName;
  final String additionalDriverDrivingLicenseNumber;
  final String additionalDriverDrivingLicenseIssuedAt;
  final String additionalDriverPassportNumber;

  const ClientFormPayload({
    required this.fullName,
    required this.birthDate,
    required this.addressMorocco,
    required this.addressAbroad,
    required this.profession,
    required this.drivingLicenseNumber,
    required this.drivingLicenseIssuedAt,
    required this.cinNumber,
    required this.passportNumber,
    required this.passportIssuedAt,
    required this.phone,
    required this.additionalDriverFullName,
    required this.additionalDriverDrivingLicenseNumber,
    required this.additionalDriverDrivingLicenseIssuedAt,
    required this.additionalDriverPassportNumber,
  });
}

Future<bool?> _showClientFormDialog({
  required BuildContext context,
  required String title,
  required String submitLabel,
  required String successMessage,
  required Future<void> Function(ClientFormPayload payload) onSubmit,
  ClientModel? initial,
}) async {
    final formKey = GlobalKey<FormState>();

    // SECTION 1 — LOCATAIRE
    final fullNameCtrl = TextEditingController(text: initial?.fullName ?? '');
    final birthDateCtrl = TextEditingController(text: initial?.birthDate ?? '');
    final addressMoroccoCtrl = TextEditingController(text: initial?.addressMorocco ?? '');
    final addressAbroadCtrl = TextEditingController(text: initial?.addressAbroad ?? '');
    final professionCtrl = TextEditingController(text: initial?.profession ?? '');
    final drivingLicenseNumberCtrl = TextEditingController(text: initial?.drivingLicenseNumber ?? '');
    final drivingLicenseIssuedAtCtrl = TextEditingController(text: initial?.drivingLicenseIssuedAt ?? '');
    final cinCtrl = TextEditingController(text: initial?.cinNumber ?? '');
    final passportNumberCtrl = TextEditingController(text: initial?.passportNumber ?? '');
    final passportIssuedAtCtrl = TextEditingController(text: initial?.passportIssuedAt ?? '');
    final phoneCtrl = TextEditingController(text: initial?.phone ?? '');

    // SECTION 2 — CONDUCTEUR SUPPLEMENTAIRE
    final addFullNameCtrl = TextEditingController(text: initial?.additionalDriverFullName ?? '');
    final addLicenseNumberCtrl = TextEditingController(text: initial?.additionalDriverDrivingLicenseNumber ?? '');
    final addLicenseIssuedAtCtrl = TextEditingController(text: initial?.additionalDriverDrivingLicenseIssuedAt ?? '');
    final addPassportNumberCtrl = TextEditingController(text: initial?.additionalDriverPassportNumber ?? '');

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 720,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(titleFr: 'LOCATAIRE', titleAr: 'المكتري'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: fullNameCtrl,
                    decoration: const InputDecoration(labelText: 'Nom & Prénom (الاسم و النسب) *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: birthDateCtrl,
                    decoration: const InputDecoration(labelText: 'Date de naissance (تاريخ الإزدياد) — YYYY-MM-DD'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: addressMoroccoCtrl,
                    decoration: const InputDecoration(labelText: 'Adresse au Maroc (العنوان بالمغرب)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: addressAbroadCtrl,
                    decoration: const InputDecoration(labelText: "Adresse à l'Étranger (العنوان بالخارج)"),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: professionCtrl,
                    decoration: const InputDecoration(labelText: 'Profession (المهنة)'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: drivingLicenseNumberCtrl,
                    decoration: const InputDecoration(labelText: 'Permis de Conduire N° (رخصة السياقة رقم)'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: drivingLicenseIssuedAtCtrl,
                    decoration: const InputDecoration(labelText: 'Délivré à (إصدارها في) — ville'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: cinCtrl,
                    decoration: const InputDecoration(labelText: 'CIN N° (البطاقة الوطنية) — optionnel'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: passportNumberCtrl,
                    decoration: const InputDecoration(labelText: 'Passeport N° (رقم جواز السفر)'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: passportIssuedAtCtrl,
                    decoration: const InputDecoration(labelText: 'Passeport délivré le (إصداره في) — YYYY-MM-DD'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Téléphone (الهاتف) *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
                  ),
                  const SizedBox(height: 16),
                  const _SectionHeader(titleFr: 'CONDUCTEUR SUPPLÉMENTAIRE', titleAr: 'السائق المرخص'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: addFullNameCtrl,
                    decoration: const InputDecoration(labelText: 'Nom & Prénom'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: addLicenseNumberCtrl,
                    decoration: const InputDecoration(labelText: 'Permis de Conduire N°'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: addLicenseIssuedAtCtrl,
                    decoration: const InputDecoration(labelText: 'Délivré le — YYYY-MM-DD'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: addPassportNumberCtrl,
                    decoration: const InputDecoration(labelText: 'Passeport N°'),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              if (!(formKey.currentState?.validate() ?? false)) return;

              try {
                await onSubmit(
                  ClientFormPayload(
                    fullName: fullNameCtrl.text.trim(),
                    birthDate: birthDateCtrl.text.trim(),
                    addressMorocco: addressMoroccoCtrl.text.trim(),
                    addressAbroad: addressAbroadCtrl.text.trim(),
                    profession: professionCtrl.text.trim(),
                    drivingLicenseNumber: drivingLicenseNumberCtrl.text.trim(),
                    drivingLicenseIssuedAt: drivingLicenseIssuedAtCtrl.text.trim(),
                    cinNumber: cinCtrl.text.trim(),
                    passportNumber: passportNumberCtrl.text.trim(),
                    passportIssuedAt: passportIssuedAtCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    additionalDriverFullName: addFullNameCtrl.text.trim(),
                    additionalDriverDrivingLicenseNumber: addLicenseNumberCtrl.text.trim(),
                    additionalDriverDrivingLicenseIssuedAt: addLicenseIssuedAtCtrl.text.trim(),
                    additionalDriverPassportNumber: addPassportNumberCtrl.text.trim(),
                  ),
                );
                if (context.mounted) {
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(successMessage),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) AppErrorHandler.showError(context, e);
              }
            },
            child: Text(submitLabel),
          ),
        ],
      ),
    );
}

class _SectionHeader extends StatelessWidget {
  final String titleFr;
  final String titleAr;
  const _SectionHeader({required this.titleFr, required this.titleAr});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$titleFr — $titleAr',
              style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary),
            ),
          ),
        ],
      ),
    );
  }
}
