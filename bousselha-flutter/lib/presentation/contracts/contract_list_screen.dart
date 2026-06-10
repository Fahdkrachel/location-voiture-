import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/app_error_handler.dart';
import '../../data/models/client_model.dart';
import '../../data/models/contract_model.dart';
import '../../shared/providers/app_providers.dart';
import '../clients/client_list_screen.dart';
import '../../shared/widgets/matricule_text.dart';

/// Palette entreprise Contrats BOUSSELHA CARS
abstract final class Cc {
  static const Color navy = Color(0xFF1A2B4A);
  static const Color gold = Color(0xFFC8963E);
  static const Color bgGrey = Color(0xFFF5F7FA);
  static const Color textMain = navy;
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textValue = Color(0xFF374151);
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color border = Color(0xFFE5E8EE);
  static const Color stripeAlt = Color(0xFFF8FAFC);

  /// Hauteur commune des boutons d’action pied de page détail contrat.
  static const double actionButtonHeight = 52;
}

String _contractStatusLabel(String status) {
  switch (status) {
    case 'IN_PROGRESS': return 'En préparation';
    case 'ACTIVE': return 'En location';
    case 'COMPLETED': return 'Terminé';
    case 'CANCELLED': return 'Annulé';
    default: return status;
  }
}

Widget _contractStatusBadge(String status) {
  Color bg;
  Color fg;
  Color br;
  switch (status) {
    case 'IN_PROGRESS':
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
      br = const Color(0xFFF59E0B);
    case 'ACTIVE':
      bg = const Color(0xFFD1FAE5);
      fg = const Color(0xFF065F46);
      br = Cc.success;
    case 'COMPLETED':
      bg = const Color(0xFFDBEAFE);
      fg = const Color(0xFF1E40AF);
      br = const Color(0xFF3B82F6);
    case 'CANCELLED':
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
      br = Cc.danger;
    default:
      bg = Colors.grey.shade200;
      fg = Colors.grey.shade800;
      br = Colors.grey;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: br),
    ),
    child: Text(
      _contractStatusLabel(status),
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg, letterSpacing: 0.2),
    ),
  );
}

String _dash(String value) => value.trim().isEmpty ? '—' : value.trim();

String _fmtMoneyDh(num value) => '${value.toStringAsFixed(2)} DH';

String _fmtFrDate(String iso) {
  if (iso.trim().isEmpty) return '—';
  try {
    return DateFormat('dd/MM/yyyy').format(DateTime.parse(iso));
  } catch (_) {
    return '—';
  }
}

List<String> _isoPartsFive(String iso) {
  if (iso.isEmpty) return ['-', '-', '-', '-', '-'];
  try {
    final dt = DateTime.parse(iso);
    return [dt.day.toString(), dt.month.toString(), dt.year.toString(), dt.hour.toString(), dt.minute.toString()];
  } catch (_) {
    return ['-', '-', '-', '-', '-'];
  }
}

class ContractListScreen extends ConsumerWidget {
  const ContractListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsync = ref.watch(contractsProvider);
    return Scaffold(
      backgroundColor: Cc.bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        surfaceTintColor: Colors.white,
        titleSpacing: 24,
        title: Row(
          children: [
            Image.asset(
              'assets/branding/bousselha_logo.png',
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.directions_car_rounded,
                color: Color(0xFF1A2B4A),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              height: 24,
              width: 1,
              color: const Color(0xFFE2E8F0),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contrats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2B4A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Création, activation et historique des contrats de location',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final ok = await _showUnifiedContractSheet(context, ref, existing: null) == true;
              if (!context.mounted) return;
              if (ok == true) {
                invalidateAllBoushelhaProviders(ref);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Cc.success,
                    content: Text('Contrat créé avec succès', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                );
              }
            },
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFF7A00)),
            label: const Text('Nouveau contrat'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1A2B4A),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Rafraîchir',
            onPressed: () => ref.invalidate(contractsProvider),
            icon: const Icon(Icons.refresh, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: contractsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('Aucun contrat enregistré.', style: TextStyle(color: Cc.textMuted, fontWeight: FontWeight.w500)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _ContractListCard(
              contract: items[index],
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => ContractDetailScreen(contractId: items[index].id)),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(AppErrorHandler.getMessage(e), style: const TextStyle(color: Cc.danger))),
      ),
    );
  }
}

class _ContractListCard extends StatelessWidget {
  final ContractModel contract;
  final VoidCallback onTap;

  const _ContractListCard({required this.contract, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = '${contract.carBrand} - ${preserveBidiOrder(contract.carMatricule)} — ${_dash(contract.clientName)}';
    final sub = 'Départ : ${_fmtFrDate(contract.departureDatetime)} → Retour : ${_fmtFrDate(contract.expectedReturnDatetime)}';
    final amount = '${contract.totalGeneral.toStringAsFixed(2)} MAD';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.045), blurRadius: 12, offset: const Offset(0, 6))],
            border: Border.all(color: Cc.border.withValues(alpha: 0.7)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(color: Cc.navy, shape: BoxShape.circle),
                child: Icon(Icons.article_rounded, color: Cc.gold.withValues(alpha: 0.95), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Cc.textMain)),
                    const SizedBox(height: 6),
                    Text(sub, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Cc.textMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _contractStatusBadge(contract.status),
                  const SizedBox(height: 8),
                  Text(amount, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Cc.gold)),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContractDetailScreen extends ConsumerStatefulWidget {
  final int contractId;
  const ContractDetailScreen({super.key, required this.contractId});

  @override
  ConsumerState<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends ConsumerState<ContractDetailScreen> {
  bool _loading = true;
  ContractModel? _contract;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final c = await ref.read(contractRepositoryProvider).getContractById(widget.contractId);
      if (mounted) setState(() => _contract = c);
    } catch (e) {
      if (mounted) AppErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateContractStatus(BuildContext scaffoldContext, ContractModel c, String newStatus, {required String confirmTitle, required String confirmMessage, required String successMessage}) async {
    final ok = await showDialog<bool>(
      context: scaffoldContext,
      builder: (ctx) => AlertDialog(
        title: Text(confirmTitle),
        content: Text(confirmMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Cc.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (!scaffoldContext.mounted || ok != true) return;
    final messenger = ScaffoldMessenger.of(scaffoldContext);
    try {
      await ref.read(contractRepositoryProvider).updateContractStatus(c.id, newStatus);
      await _fetch();
      invalidateAllBoushelhaProviders(ref);
      if (scaffoldContext.mounted) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Cc.success,
            content: Text(successMessage, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        );
      }
    } catch (e) {
      if (scaffoldContext.mounted) AppErrorHandler.showError(scaffoldContext, e);
    }
  }

  Future<void> _maybeDelete(BuildContext scaffoldContext, ContractModel c) async {
    final messenger = ScaffoldMessenger.of(scaffoldContext);
    if (c.status == 'ACTIVE') {
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: Cc.danger,
          content: Text(
            'Impossible : terminez le contrat avant de le supprimer.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    final isCancelInProgress = c.status == 'IN_PROGRESS';
    final ok = await showDialog<bool>(
      context: scaffoldContext,
      builder: (ctx) => AlertDialog(
        title: Text(isCancelInProgress ? 'Annuler le contrat' : 'Suppression'),
        content: Text(
          isCancelInProgress
              ? 'Annuler ce contrat en préparation ?\n'
                  'Le client lié sera supprimé s’il n’a aucun autre contrat.\n'
                  'Aucun revenu n’a été enregistré pour ce contrat.'
              : 'Supprimer définitivement ce contrat ?\nCette action est irréversible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Cc.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isCancelInProgress ? 'Oui, annuler' : 'Supprimer'),
          ),
        ],
      ),
    );

    if (!scaffoldContext.mounted || ok != true) return;
    try {
      await ref.read(contractRepositoryProvider).deleteContract(c.id);
      invalidateAllBoushelhaProviders(ref);
      if (!scaffoldContext.mounted) return;
      Navigator.of(scaffoldContext).pop();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Cc.danger,
          content: Text(
            isCancelInProgress ? 'Contrat annulé' : 'Contrat supprimé',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    } catch (e) {
      if (scaffoldContext.mounted) AppErrorHandler.showError(scaffoldContext, e);
    }
  }

  String _money(num value) => '${value.toStringAsFixed(2)} DH';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: Cc.bgGrey, body: Center(child: CircularProgressIndicator()));
    }
    final c = _contract;
    if (c == null) return const Scaffold(body: Center(child: Text('Contrat introuvable.')));

    final dep = _isoPartsFive(c.departureDatetime);
    final prev = _isoPartsFive(c.expectedReturnDatetime);
    final ret = _isoPartsFive(c.actualReturnDatetime);
    final hourLine = c.pricePerHour * c.durationDays;
    final dayLine = c.pricePerDay * c.durationDays;
    final weekLine = c.pricePerWeek;
    final monthLine = c.pricePerMonth;
    final insuranceLine = c.withInsurance ? c.supplement : 0.0;

    final repo = ref.read(contractRepositoryProvider);
    final canDownloadPdf = c.status == 'ACTIVE' || c.status == 'COMPLETED';

    return Scaffold(
      backgroundColor: Cc.bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Cc.navy,
        elevation: 0,
        surfaceTintColor: Colors.white,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Cc.navy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.article_rounded, color: Cc.navy, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Contrat #${c.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Cc.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_dash(c.clientName)} — ${_dash(c.carBrand)}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Cc.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            _contractStatusBadge(c.status),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
        actions: [
          if (canDownloadPdf)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final path = await repo.downloadContractPdf(c.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('PDF téléchargé : $path')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      AppErrorHandler.showError(context, e);
                    }
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Télécharger PDF', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Cc.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _EnterpriseSectionCard(
                    title: 'SECTION 1 — VÉHICULE',
                    icon: Icons.directions_car_filled_rounded,
                    child: _enterpriseTwoColTable(context, [
                      ['Marque', _dash(c.carBrand)],
                      ['Immatriculation', _dash(preserveBidiOrder(c.carMatricule))],
                      ['Type', _dash(c.carFuelType)],
                      ['Lieu livraison', _dash(c.departurePlace)],
                      ['Lieu reprise', _dash(c.returnPlace)],
                    ]),
                  ),
                  _EnterpriseSectionCard(
                    title: 'SECTION 2 — DATES',
                    icon: Icons.calendar_month_rounded,
                    child: _enterpriseDateGrid(context, [
                      ('Départ', dep),
                      ('Retour Prévu', prev),
                      ('Retour Définitif', ret),
                      ('Durée', [c.durationDays.toString(), '0', '0', '0', '0']),
                    ]),
                  ),
                  _EnterpriseSectionCard(
                    title: 'SECTION 3 — LOCATAIRE (المكتري)',
                    icon: Icons.person_rounded,
                    child: _enterpriseTwoColTable(context, [
                      ['Nom & Prénom', _dash(c.clientName)],
                      ['Date naissance', _dash(c.clientBirthDate)],
                      ['Adresse Maroc', _dash(c.clientAddressMorocco)],
                      ['Adresse Étranger', _dash(c.clientAddressAbroad)],
                      ['Profession', _dash(c.clientProfession)],
                      ['Permis N°', _dash(c.clientDrivingLicenseNumber)],
                      ['Délivré à', _dash(c.clientDrivingLicenseIssuedAt)],
                      ['CIN N°', _dash(c.clientCinNumber)],
                      ['Passeport N°', _dash(c.clientPassportNumber)],
                      ['Téléphone', _dash(c.clientPhone)],
                    ]),
                  ),
                  _EnterpriseSectionCard(
                    title: 'SECTION 4 — CONDUCTEUR SUPPLÉMENTAIRE',
                    icon: Icons.badge_rounded,
                    child: _enterpriseTwoColTable(context, [
                      ['Nom & Prénom', _dash(c.additionalDriverName)],
                      ['Permis N°', _dash(c.additionalDriverLicense)],
                      ['Délivré le', _dash(c.additionalDriverLicenseIssuedAt)],
                      ['Passeport N°', _dash(c.additionalDriverPassport)],
                    ]),
                  ),
                  _EnterpriseSectionCard(
                    title: 'SECTION 5 — GRILLE TARIFAIRE',
                    icon: Icons.calculate_rounded,
                    child: _enterprisePriceTable(
                      context,
                      c,
                      hourLine,
                      dayLine,
                      weekLine,
                      monthLine,
                      insuranceLine,
                    ),
                  ),
                  _EnterpriseSectionCard(
                    title: 'SECTION 6 — PAIEMENT (الأداء)',
                    icon: Icons.payments_rounded,
                    child: _enterpriseTwoColTable(context, [
                      ['Espèces (نقدا)', _money(c.paymentCash)],
                      ['Chèque (شيكا)', _money(c.paymentCheck)],
                      ['Caution (ضمانة)', _money(c.paymentDeposit)],
                    ]),
                  ),
                ],
              ),
            ),
          ),
          _ContractFooterActions(
            contract: c,
            onActivate: () => _updateContractStatus(
              context,
              c,
              'ACTIVE',
              confirmTitle: 'Activer le contrat',
              confirmMessage: 'Confirmer la livraison du véhicule ?\nLe contrat passera en ACTIVE et la voiture en location.',
              successMessage: 'Contrat activé — revenu enregistré',
            ),
            onComplete: () => _updateContractStatus(
              context,
              c,
              'COMPLETED',
              confirmTitle: 'Terminer le contrat',
              confirmMessage: 'Confirmer la fin de ce contrat ?\nLa voiture repassera en AVAILABLE.',
              successMessage: 'Contrat terminé avec succès',
            ),
            onEdit: () async {
              if (c.status == 'ACTIVE' || c.status == 'COMPLETED') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Cc.danger,
                    content: Text(
                      'Modification impossible : contrat en location ou déjà terminé.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                );
                return;
              }
              final changed = await _showUnifiedContractSheet(context, ref, existing: c) == true;
              if (!context.mounted || changed != true) return;
              await _fetch();
              invalidateAllBoushelhaProviders(ref);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF2563EB),
                    content: Text('Contrat modifié avec succès', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                );
              }
            },
            onDelete: () => _maybeDelete(context, c),
          ),
        ],
      ),
    );
  }
}

class _EnterpriseSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _EnterpriseSectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black26,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Cc.navy,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(icon, color: Cc.gold, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _enterpriseTwoColTable(BuildContext context, List<List<String>> rows) {
  return Table(
    border: TableBorder.all(color: Cc.border, width: 1),
    columnWidths: const {0: FlexColumnWidth(2.05), 1: FlexColumnWidth(3.4)},
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    children: rows.asMap().entries.map((e) {
      final stripe = e.key.isEven ? Colors.white : Cc.stripeAlt;
      final r = e.value;
      return TableRow(
        decoration: BoxDecoration(color: stripe),
        children: [
          _EntCell(Text(r[0], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Cc.textMain))),
          _EntCell(
            Text(
              r[1] == '-' || r[1].trim().isEmpty ? '—' : r[1],
              style: TextStyle(fontSize: 14, color: r[1].trim().isEmpty || r[1] == '—' ? Cc.textMuted : Cc.textValue, fontWeight: FontWeight.w400),
            ),
          ),
        ],
      );
    }).toList(),
  );
}

class _EntCell extends StatelessWidget {
  final Widget child;
  const _EntCell(this.child);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      child: child,
    );
  }
}

Widget _enterpriseDateGrid(BuildContext context, List<(String label, List<String> values)> rows) {
  return Table(
    border: TableBorder.all(color: Cc.border, width: 1),
    columnWidths: const {
      0: FlexColumnWidth(2.4),
      1: FlexColumnWidth(1.0),
      2: FlexColumnWidth(1.0),
      3: FlexColumnWidth(1.35),
      4: FlexColumnWidth(1.0),
      5: FlexColumnWidth(1.0),
    },
    children: [
      TableRow(
        decoration: const BoxDecoration(color: Cc.stripeAlt),
        children: const [
          _EntCell(Text('')), _EntCell(Text('J', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Cc.textMain))),
          _EntCell(Text('M', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Cc.textMain))),
          _EntCell(Text('A', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Cc.textMain))),
          _EntCell(Text('H', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Cc.textMain))),
          _EntCell(Text('mn', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Cc.textMain))),
        ],
      ),
      ...rows.asMap().entries.map((e) {
        final label = e.value.$1;
        final vals = e.value.$2;
        final stripe = e.key.isEven ? Colors.white : Cc.stripeAlt;
        return TableRow(
          decoration: BoxDecoration(color: stripe),
          children: [
            _EntCell(Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Cc.textMain))),
            _EntCell(Text(vals[0], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Cc.textValue))),
            _EntCell(Text(vals[1], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Cc.textValue))),
            _EntCell(Text(vals[2], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Cc.textValue))),
            _EntCell(Text(vals[3], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Cc.textValue))),
            _EntCell(Text(vals[4], textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Cc.textValue))),
          ],
        );
      }),
    ],
  );
}

Widget _enterprisePriceTable(
  BuildContext context,
  ContractModel c,
  double hourLine,
  double dayLine,
  double weekLine,
  double monthLine,
  double insuranceLine,
) {
  TextStyle amt(bool bold) => TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w800 : FontWeight.w400, color: Cc.textMain);
  Widget cell(Widget child, Color bg, {Alignment align = Alignment.center}) {
    return ColoredBox(
      color: bg,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), child: Align(alignment: align, child: child)),
    );
  }

  List<Widget> headerRow(Color bg) {
    return [
      cell(const Text('', style: TextStyle(fontWeight: FontWeight.w600)), bg, align: Alignment.centerLeft),
      cell(const Text('Q', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Cc.textMain)), bg),
      cell(const Text('Prix', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Cc.textMain)), bg),
      cell(const Text('Prix Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Cc.textMain)), bg),
    ];
  }

  List<Widget> bodyRow(Color bg, String label, String q, String p, String total, bool boldTotal) {
    return [
      cell(Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Cc.textMain)), bg, align: Alignment.centerLeft),
      cell(Text(q, style: const TextStyle(fontSize: 14, color: Cc.textValue)), bg),
      cell(Text(p, style: const TextStyle(fontSize: 14, color: Cc.textValue)), bg),
      cell(Text(total, style: amt(boldTotal)), bg),
    ];
  }

  final rowsColors = [
    Colors.white,
    Cc.stripeAlt,
    Colors.white,
    Cc.stripeAlt,
    Colors.white,
    Cc.stripeAlt,
    Colors.white,
    Cc.stripeAlt,
    Cc.stripeAlt,
  ];

  int i = -1;
  Color nextStripe() => rowsColors[++i % rowsColors.length];

  List<Widget> children = [];

  Widget buildRow(List<Widget> cellsContent) => Row(
      children: [
        Expanded(flex: 35, child: cellsContent[0]),
        Expanded(flex: 12, child: cellsContent[1]),
        Expanded(flex: 26, child: cellsContent[2]),
        Expanded(flex: 27, child: cellsContent[3]),
      ],
    );

  children.add(
    DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: Cc.border)),
      child: ColoredBox(
        color: Cc.stripeAlt,
        child: buildRow(headerRow(nextStripe())),
      ),
    ),
  );

  var bg = nextStripe();
  children.add(DecoratedBox(
    decoration: BoxDecoration(border: Border(left: BorderSide(color: Cc.border), right: BorderSide(color: Cc.border), bottom: BorderSide(color: Cc.border))),
    child: buildRow(bodyRow(bg, 'Heures', '${c.durationDays}', _fmtMoneyDh(c.pricePerHour), _fmtMoneyDh(hourLine), false)),
  ));

  bg = nextStripe();
  children.add(DecoratedBox(
    decoration: const BoxDecoration(border: Border(left: BorderSide(color: Cc.border), right: BorderSide(color: Cc.border), bottom: BorderSide(color: Cc.border))),
    child: buildRow(bodyRow(bg, 'Jours', '${c.durationDays}', _fmtMoneyDh(c.pricePerDay), _fmtMoneyDh(dayLine), false)),
  ));

  bg = nextStripe();
  children.add(DecoratedBox(
    decoration: const BoxDecoration(border: Border(left: BorderSide(color: Cc.border), right: BorderSide(color: Cc.border), bottom: BorderSide(color: Cc.border))),
    child: buildRow(bodyRow(bg, 'Semaines', '1', _fmtMoneyDh(c.pricePerWeek), _fmtMoneyDh(weekLine), false)),
  ));

  bg = nextStripe();
  children.add(DecoratedBox(
    decoration: const BoxDecoration(border: Border(left: BorderSide(color: Cc.border), right: BorderSide(color: Cc.border), bottom: BorderSide(color: Cc.border))),
    child: buildRow(bodyRow(bg, 'Mois', '1', _fmtMoneyDh(c.pricePerMonth), _fmtMoneyDh(monthLine), false)),
  ));

  bg = nextStripe();
  children.add(DecoratedBox(
    decoration: const BoxDecoration(border: Border(left: BorderSide(color: Cc.border), right: BorderSide(color: Cc.border), bottom: BorderSide(color: Cc.border))),
    child: buildRow(
      bodyRow(
        bg,
        'Avec Assurance',
        c.withInsurance ? '1' : '0',
        c.withInsurance ? _fmtMoneyDh(c.supplement) : _fmtMoneyDh(0),
        _fmtMoneyDh(insuranceLine),
        false,
      ),
    ),
  ));

  bg = nextStripe();
  children.add(DecoratedBox(
    decoration: const BoxDecoration(border: Border(left: BorderSide(color: Cc.border), right: BorderSide(color: Cc.border), bottom: BorderSide(color: Cc.border))),
    child: buildRow(bodyRow(bg, 'TOTAL', '', '', _fmtMoneyDh(c.totalPrice), true)),
  ));

  bg = nextStripe();
  children.add(DecoratedBox(
    decoration: const BoxDecoration(border: Border(left: BorderSide(color: Cc.border), right: BorderSide(color: Cc.border), bottom: BorderSide(color: Cc.border))),
    child: buildRow(bodyRow(bg, 'Supplément', '', '', _fmtMoneyDh(c.supplement), false)),
  ));

  bg = nextStripe();
  children.add(DecoratedBox(
    decoration: const BoxDecoration(border: Border(left: BorderSide(color: Cc.border), right: BorderSide(color: Cc.border), bottom: BorderSide(color: Cc.border))),
    child: buildRow(bodyRow(bg, 'TOTAL GÉNÉRAL', '', '', _fmtMoneyDh(c.totalGeneral), true)),
  ));

  return Column(children: children);
}

/// Boutons pied de page (sticky visuel avec `Material` dans `Column`).
class _ContractFooterActions extends StatelessWidget {
  final ContractModel contract;
  final VoidCallback onActivate;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContractFooterActions({
    required this.contract,
    required this.onActivate,
    required this.onComplete,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Widget statusActionBtn() {
      if (contract.status == 'COMPLETED' || contract.status == 'CANCELLED') {
        return SizedBox(
          height: Cc.actionButtonHeight,
          child: FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: Text(
              contract.status == 'COMPLETED' ? 'Contrat terminé' : 'Contrat clos',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              disabledBackgroundColor: const Color(0xFFE5E8EE),
              disabledForegroundColor: Cc.textMuted,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );
      }
      if (contract.status == 'IN_PROGRESS') {
        return SizedBox(
          height: Cc.actionButtonHeight,
          child: FilledButton.icon(
            onPressed: onActivate,
            icon: const Icon(Icons.directions_car_rounded, size: 18),
            label: const Text('Activer (livraison)', style: TextStyle(fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );
      }
      if (contract.status == 'ACTIVE') {
        return SizedBox(
          height: Cc.actionButtonHeight,
          child: FilledButton.icon(
            onPressed: onComplete,
            icon: const Icon(Icons.task_alt_rounded, size: 18),
            label: const Text('Terminer le contrat', style: TextStyle(fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              backgroundColor: Cc.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black12,
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 14 + MediaQuery.paddingOf(context).bottom),
          child: Row(
            children: [
              Expanded(child: statusActionBtn()),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: Cc.actionButtonHeight,
                  child: FilledButton.icon(
                    onPressed: (contract.status == 'ACTIVE' || contract.status == 'COMPLETED') ? null : onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 17),
                    label: const Text('Modifier', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: Cc.navy,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE5E8EE),
                      disabledForegroundColor: Cc.textMuted,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: Cc.actionButtonHeight,
                  child: OutlinedButton.icon(
                    onPressed: contract.status == 'ACTIVE' ? null : onDelete,
                    icon: Icon(
                      contract.status == 'IN_PROGRESS' ? Icons.cancel_outlined : Icons.delete_outline_rounded,
                      size: 17,
                    ),
                    label: Text(
                      contract.status == 'IN_PROGRESS' ? 'Annuler' : 'Supprimer',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Cc.danger,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Cc.danger, width: 1.25),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      disabledForegroundColor: Cc.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Formulaire nouveau / modifier contrat + helpers partagés
// ═══════════════════════════════════════════════════════════════════════════

Future<Object?> _showUnifiedContractSheet(
  BuildContext context,
  WidgetRef ref, {
  ContractModel? existing,
  ClientFormPayload? pendingClient,
}) async {
  if (existing != null && (existing.status == 'ACTIVE' || existing.status == 'COMPLETED')) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Cc.danger,
        content: Text('Modification impossible : contrat en location ou déjà terminé.'),
      ),
    );
    return false;
  }

  if (existing == null && pendingClient == null) {
    final picked = await pickClientForNewContract(context);
    if (!context.mounted || picked == null) return false;
    final created = await _showUnifiedContractSheet(context, ref, pendingClient: picked);
    if (created == '__PREV__') {
      if (!context.mounted) return false;
      final edited = await pickClientForNewContract(context, initial: picked);
      if (!context.mounted || edited == null) return false;
      final retry = await _showUnifiedContractSheet(context, ref, pendingClient: edited);
      return retry == true;
    }
    return created == true;
  }

  final carRepo = ref.read(carRepositoryProvider);
  final allCars = await carRepo.getCars();
  final selectableCars = existing == null
      ? await carRepo.getAvailableCars()
      : allCars.where((c) => c.id == existing.carId || c.status == 'AVAILABLE').toList();

  if (!context.mounted) return false;

  if (selectableCars.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Cc.danger,
        content: Text(
          existing == null
              ? 'Il faut au moins une voiture disponible.'
              : 'Liste voitures indisponible pour l’édition.',
        ),
      ),
    );
    return false;
  }

  List<ClientModel> clients = [];
  if (existing != null) {
    clients = await ref.read(clientRepositoryProvider).getClients();
    if (!context.mounted) return false;
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Cc.danger, content: Text('Aucun client enregistré.')),
      );
      return false;
    }
  }

  final now = DateTime.now();
  final tomorrow = now.add(const Duration(days: 1));

  int selectedCarId = existing?.carId ?? selectableCars.first.id;
  int? selectedClientId = existing?.clientId ?? (clients.isNotEmpty ? clients.first.id : null);
  if (!selectableCars.any((c) => c.id == selectedCarId)) selectedCarId = selectableCars.first.id;
  if (selectedClientId != null && clients.isNotEmpty && !clients.any((c) => c.id == selectedClientId)) {
    selectedClientId = clients.first.id;
  }

  final dep =
      existing != null ? _isoPartsFive(existing.departureDatetime) : [now.day, now.month, now.year, now.hour, now.minute].map((e) => e.toString()).toList();
  final prev = existing != null
      ? _isoPartsFive(existing.expectedReturnDatetime)
      : [tomorrow.day, tomorrow.month, tomorrow.year, tomorrow.hour, tomorrow.minute].map((e) => e.toString()).toList();
  List<String> retParts;
  if (existing == null || existing.actualReturnDatetime.trim().isEmpty) {
    retParts = ['', '', '', '', ''];
  } else {
    retParts = _isoPartsFive(existing.actualReturnDatetime);
  }

  final depJ = TextEditingController(text: dep[0] == '-' ? '' : dep[0]);
  final depM = TextEditingController(text: dep[1] == '-' ? '' : dep[1]);
  final depA = TextEditingController(text: dep[2] == '-' ? '' : dep[2]);
  final depH = TextEditingController(text: dep[3] == '-' ? '' : dep[3]);
  final depMn = TextEditingController(text: dep[4] == '-' ? '' : dep[4]);

  final prevJ = TextEditingController(text: prev[0] == '-' ? '' : prev[0]);
  final prevM = TextEditingController(text: prev[1] == '-' ? '' : prev[1]);
  final prevA = TextEditingController(text: prev[2] == '-' ? '' : prev[2]);
  final prevH = TextEditingController(text: prev[3] == '-' ? '' : prev[3]);
  final prevMn = TextEditingController(text: prev[4] == '-' ? '' : prev[4]);

  final retJ = TextEditingController(text: retParts[0] == '-' ? '' : retParts[0]);
  final retM = TextEditingController(text: retParts[1] == '-' ? '' : retParts[1]);
  final retA = TextEditingController(text: retParts[2] == '-' ? '' : retParts[2]);
  final retH = TextEditingController(text: retParts[3] == '-' ? '' : retParts[3]);
  final retMn = TextEditingController(text: retParts[4] == '-' ? '' : retParts[4]);

  final durDays = existing?.durationDays ?? 0;
  final durJ = TextEditingController(text: durDays.toString());
  final durM = TextEditingController(text: '0');
  final durA = TextEditingController(text: '0');
  final durH = TextEditingController(text: '0');
  final durMn = TextEditingController(text: '0');

  final qHour = TextEditingController(text: existing == null ? '0' : existing.durationDays.toString());
  final pHour = TextEditingController(text: existing == null ? '0' : existing.pricePerHour.toString());
  final qDay = TextEditingController(text: existing == null ? '0' : existing.durationDays.toString());
  final pDay = TextEditingController(text: existing == null ? '0' : existing.pricePerDay.toString());
  final qWeek = TextEditingController(text: '1');
  final pWeek = TextEditingController(text: existing == null ? '0' : existing.pricePerWeek.toString());
  final qMonth = TextEditingController(text: '1');
  final pMonth = TextEditingController(text: existing == null ? '0' : existing.pricePerMonth.toString());
  final qInsurance = TextEditingController(text: existing != null && existing.withInsurance ? '1' : '0');
  final pInsurance =
      TextEditingController(text: existing != null && existing.withInsurance ? existing.supplement.toString() : '0');

  final supplementCtrl = TextEditingController(text: '0');
  final paymentCashCtrl = TextEditingController(text: existing == null ? '0' : existing.paymentCash.toString());
  final paymentCheckCtrl = TextEditingController(text: existing == null ? '0' : existing.paymentCheck.toString());
  final paymentDepositCtrl = TextEditingController(text: existing == null ? '0' : existing.paymentDeposit.toString());
  final departurePlaceCtrl = TextEditingController(text: existing?.departurePlace ?? '');
  final returnPlaceCtrl = TextEditingController(text: existing?.returnPlace ?? '');

  final lockCarPick = existing != null && (existing.status == 'ACTIVE' || existing.status == 'IN_PROGRESS');

  var isSaving = false;
  final outcome = await showDialog<Object?>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(
          pendingClient != null
              ? 'Nouveau contrat — Étape 2/2 : Contrat'
              : existing == null
                  ? 'Nouveau contrat'
                  : 'Modifier le contrat #${existing.id}',
        ),
        content: SizedBox(
          width: 980,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedCarId,
                  items: selectableCars.map((car) => DropdownMenuItem<int>(value: car.id, child: Text('${car.brand} (${preserveBidiOrder(car.matricule)})'))).toList(),
                  onChanged: lockCarPick ? null : (value) => setState(() => selectedCarId = value ?? selectedCarId),
                  decoration: InputDecoration(labelText: lockCarPick ? 'Voiture (verrouillée — contrat actif)' : 'Voiture *'),
                ),
                const SizedBox(height: 8),
                if (pendingClient != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Cc.stripeAlt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Cc.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Client : ${pendingClient.fullName}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('Tél. : ${pendingClient.phone}'),
                        if (pendingClient.cinNumber.isNotEmpty) Text('CIN : ${pendingClient.cinNumber}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ] else ...[
                  DropdownButtonFormField<int>(
                    initialValue: selectedClientId,
                    items: clients
                        .map(
                          (client) => DropdownMenuItem<int>(
                            value: client.id,
                            child: Text('${client.fullName} — ${client.phone}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => selectedClientId = value ?? selectedClientId),
                    decoration: const InputDecoration(labelText: 'Client *'),
                  ),
                  const SizedBox(height: 14),
                ],
                _formSectionTitle(context, 'Dates (J | M | A | H | mn)'),
                const SizedBox(height: 8),
                Table(
                  border: TableBorder.all(color: Theme.of(context).dividerColor),
                  columnWidths: const {
                    0: FlexColumnWidth(3.3),
                    1: FlexColumnWidth(1.2),
                    2: FlexColumnWidth(1.2),
                    3: FlexColumnWidth(1.6),
                    4: FlexColumnWidth(1.2),
                    5: FlexColumnWidth(1.2),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    _formHeaderRow(),
                    _formDateRow('Départ', depJ, depM, depA, depH, depMn),
                    _formDateRow('Retour Prévu', prevJ, prevM, prevA, prevH, prevMn),
                    _formDateRow('Retour Définitif', retJ, retM, retA, retH, retMn),
                    _formDateRow('Durée', durJ, durM, durA, durH, durMn),
                  ],
                ),
                const SizedBox(height: 14),
                _formSectionTitle(context, 'Grille tarifaire'),
                const SizedBox(height: 8),
                Table(
                  border: TableBorder.all(color: Theme.of(context).dividerColor),
                  columnWidths: const {
                    0: FlexColumnWidth(4.5),
                    1: FlexColumnWidth(1.6),
                    2: FlexColumnWidth(2.0),
                    3: FlexColumnWidth(2.2),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    _formPriceHeaderRow(),
                    _formPriceRow(context, 'Heures (الساعات)', qHour, pHour, () => setState(() {})),
                    _formPriceRow(context, 'Jours (الأيام)', qDay, pDay, () => setState(() {})),
                    _formPriceRow(context, 'Semaines (الأسابيع)', qWeek, pWeek, () => setState(() {})),
                    _formPriceRow(context, 'Mois (الشهور)', qMonth, pMonth, () => setState(() {})),
                    _formPriceRow(context, 'Avec Assurance (مع التأمين)', qInsurance, pInsurance, () => setState(() {})),
                  ],
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    final lineHour = _formCalcLine(qHour.text, pHour.text);
                    final lineDay = _formCalcLine(qDay.text, pDay.text);
                    final lineWeek = _formCalcLine(qWeek.text, pWeek.text);
                    final lineMonth = _formCalcLine(qMonth.text, pMonth.text);
                    final lineInsurance = _formCalcLine(qInsurance.text, pInsurance.text);
                    final total = lineHour + lineDay + lineWeek + lineMonth + lineInsurance;
                    final supplement = _formParseDouble(supplementCtrl.text);
                    final totalGeneral = total + supplement;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TOTAL: ${total.toStringAsFixed(2)} DH', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Expanded(child: Text('Supplément (زيادة)')),
                              SizedBox(width: 140, child: _formNumField(supplementCtrl, onChanged: (_) => setState(() {}))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'TOTAL Général (Au Retour): ${totalGeneral.toStringAsFixed(2)} DH',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _formSectionTitle(context, 'Paiement (الأداء)'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _formLabeledNumField('Espèces (نقدا) DH', paymentCashCtrl)),
                    const SizedBox(width: 8),
                    Expanded(child: _formLabeledNumField('Chèque (شيكا)', paymentCheckCtrl)),
                    const SizedBox(width: 8),
                    Expanded(child: _formLabeledNumField('Caution (ضمانة)', paymentDepositCtrl)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: departurePlaceCtrl, decoration: const InputDecoration(labelText: 'Lieu depart')),
                const SizedBox(height: 8),
                TextField(controller: returnPlaceCtrl, decoration: const InputDecoration(labelText: 'Lieu retour')),
              ],
            ),
          ),
        ),
        actions: [
          if (pendingClient != null)
            TextButton.icon(
              onPressed: isSaving ? null : () => Navigator.pop(context, '__PREV__'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Précédent'),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: isSaving
                ? null
                : () async {
              setState(() => isSaving = true);
              final departureDatetime = _formBuildIsoDateTime(depJ.text, depM.text, depA.text, depH.text, depMn.text);
              final expectedReturnDatetime = _formBuildIsoDateTime(prevJ.text, prevM.text, prevA.text, prevH.text, prevMn.text);
              if (departureDatetime == null || expectedReturnDatetime == null) {
                setState(() => isSaving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dates depart/retour prevu invalides.')),
                );
                return;
              }

              final actualReturnDatetime = _formBuildIsoDateTime(retJ.text, retM.text, retA.text, retH.text, retMn.text);
              final lineHour = _formCalcLine(qHour.text, pHour.text);
              final lineDay = _formCalcLine(qDay.text, pDay.text);
              final lineWeek = _formCalcLine(qWeek.text, pWeek.text);
              final lineMonth = _formCalcLine(qMonth.text, pMonth.text);
              final lineInsurance = _formCalcLine(qInsurance.text, pInsurance.text);
              final total = lineHour + lineDay + lineWeek + lineMonth + lineInsurance;
              final supplement = _formParseDouble(supplementCtrl.text);
              final totalGeneral = total + supplement;

              try {
                if (pendingClient != null) {
                  final createdClient = await ref.read(clientRepositoryProvider).createClient(
                        fullName: pendingClient.fullName,
                        cinNumber: pendingClient.cinNumber.isEmpty ? null : pendingClient.cinNumber,
                        phone: pendingClient.phone,
                        birthDate: pendingClient.birthDate.isEmpty ? null : pendingClient.birthDate,
                        addressMorocco: pendingClient.addressMorocco.isEmpty ? null : pendingClient.addressMorocco,
                        addressAbroad: pendingClient.addressAbroad.isEmpty ? null : pendingClient.addressAbroad,
                        profession: pendingClient.profession.isEmpty ? null : pendingClient.profession,
                        drivingLicenseNumber:
                            pendingClient.drivingLicenseNumber.isEmpty ? null : pendingClient.drivingLicenseNumber,
                        drivingLicenseIssuedAt:
                            pendingClient.drivingLicenseIssuedAt.isEmpty ? null : pendingClient.drivingLicenseIssuedAt,
                        passportNumber: pendingClient.passportNumber.isEmpty ? null : pendingClient.passportNumber,
                        passportIssuedAt: pendingClient.passportIssuedAt.isEmpty ? null : pendingClient.passportIssuedAt,
                        additionalDriverFullName:
                            pendingClient.additionalDriverFullName.isEmpty ? null : pendingClient.additionalDriverFullName,
                        additionalDriverDrivingLicenseNumber: pendingClient.additionalDriverDrivingLicenseNumber.isEmpty
                            ? null
                            : pendingClient.additionalDriverDrivingLicenseNumber,
                        additionalDriverDrivingLicenseIssuedAt: pendingClient.additionalDriverDrivingLicenseIssuedAt.isEmpty
                            ? null
                            : pendingClient.additionalDriverDrivingLicenseIssuedAt,
                        additionalDriverPassportNumber: pendingClient.additionalDriverPassportNumber.isEmpty
                            ? null
                            : pendingClient.additionalDriverPassportNumber,
                      );
                  await ref.read(contractRepositoryProvider).createContract(
                        carId: selectedCarId,
                        clientId: createdClient.id,
                        departureDatetime: departureDatetime,
                        expectedReturnDatetime: expectedReturnDatetime,
                        actualReturnDatetime: actualReturnDatetime,
                        durationDays: _formParseInt(durJ.text),
                        pricePerHour: _formParseDouble(pHour.text),
                        pricePerDay: _formParseDouble(pDay.text),
                        pricePerWeek: _formParseDouble(pWeek.text),
                        pricePerMonth: _formParseDouble(pMonth.text),
                        withInsurance: _formParseDouble(qInsurance.text) > 0,
                        totalPrice: total,
                        supplement: supplement,
                        totalGeneral: totalGeneral,
                        paymentCash: _formParseDouble(paymentCashCtrl.text),
                        paymentCheck: _formParseDouble(paymentCheckCtrl.text),
                        paymentDeposit: _formParseDouble(paymentDepositCtrl.text),
                        departurePlace: departurePlaceCtrl.text.trim(),
                        returnPlace: returnPlaceCtrl.text.trim(),
                      );
                  ref.invalidate(clientsProvider);
                } else if (existing == null) {
                  await ref.read(contractRepositoryProvider).createContract(
                        carId: selectedCarId,
                        clientId: selectedClientId!,
                        departureDatetime: departureDatetime,
                        expectedReturnDatetime: expectedReturnDatetime,
                        actualReturnDatetime: actualReturnDatetime,
                        durationDays: _formParseInt(durJ.text),
                        pricePerHour: _formParseDouble(pHour.text),
                        pricePerDay: _formParseDouble(pDay.text),
                        pricePerWeek: _formParseDouble(pWeek.text),
                        pricePerMonth: _formParseDouble(pMonth.text),
                        withInsurance: _formParseDouble(qInsurance.text) > 0,
                        totalPrice: total,
                        supplement: supplement,
                        totalGeneral: totalGeneral,
                        paymentCash: _formParseDouble(paymentCashCtrl.text),
                        paymentCheck: _formParseDouble(paymentCheckCtrl.text),
                        paymentDeposit: _formParseDouble(paymentDepositCtrl.text),
                        departurePlace: departurePlaceCtrl.text.trim(),
                        returnPlace: returnPlaceCtrl.text.trim(),
                      );
                } else {
                  await ref.read(contractRepositoryProvider).updateContract(
                        id: existing.id,
                        carId: selectedCarId,
                        clientId: selectedClientId!,
                        departureDatetime: departureDatetime,
                        expectedReturnDatetime: expectedReturnDatetime,
                        actualReturnDatetime: actualReturnDatetime,
                        durationDays: _formParseInt(durJ.text),
                        pricePerHour: _formParseDouble(pHour.text),
                        pricePerDay: _formParseDouble(pDay.text),
                        pricePerWeek: _formParseDouble(pWeek.text),
                        pricePerMonth: _formParseDouble(pMonth.text),
                        withInsurance: _formParseDouble(qInsurance.text) > 0,
                        totalPrice: total,
                        supplement: supplement,
                        totalGeneral: totalGeneral,
                        paymentCash: _formParseDouble(paymentCashCtrl.text),
                        paymentCheck: _formParseDouble(paymentCheckCtrl.text),
                        paymentDeposit: _formParseDouble(paymentDepositCtrl.text),
                        departurePlace: departurePlaceCtrl.text.trim(),
                        returnPlace: returnPlaceCtrl.text.trim(),
                        additionalDriverName: existing.additionalDriverName,
                        additionalDriverLicense: existing.additionalDriverLicense,
                        additionalDriverPassport: existing.additionalDriverPassport,
                        vehicleConditionDeparture: existing.vehicleConditionDeparture,
                        vehicleConditionReturn: existing.vehicleConditionReturn,
                        damagesIdentified: existing.damagesIdentified,
                      );
                }
                if (!context.mounted) return;
                Navigator.pop(context, true);
              } catch (e) {
                if (context.mounted) {
                  AppErrorHandler.showError(context, e);
                  setState(() => isSaving = false);
                }
              }
            },
            child: isSaving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );

  return outcome;
}

TableRow _formHeaderRow() => const TableRow(
      children: [
        _ContractFormHeaderCell(''),
        _ContractFormHeaderCell('J'),
        _ContractFormHeaderCell('M'),
        _ContractFormHeaderCell('A'),
        _ContractFormHeaderCell('H'),
        _ContractFormHeaderCell('mn'),
      ],
    );

TableRow _formDateRow(
  String label,
  TextEditingController j,
  TextEditingController m,
  TextEditingController a,
  TextEditingController h,
  TextEditingController mn,
) {
  return TableRow(
    children: [
      _ContractFormBodyCell(Text(label)),
      _ContractFormBodyCell(_formNumField(j)),
      _ContractFormBodyCell(_formNumField(m)),
      _ContractFormBodyCell(_formNumField(a)),
      _ContractFormBodyCell(_formNumField(h)),
      _ContractFormBodyCell(_formNumField(mn)),
    ],
  );
}

TableRow _formPriceHeaderRow() => const TableRow(
      children: [
        _ContractFormHeaderCell('Type'),
        _ContractFormHeaderCell('Q'),
        _ContractFormHeaderCell('Prix'),
        _ContractFormHeaderCell('Prix Total'),
      ],
    );

TableRow _formPriceRow(
  BuildContext context,
  String label,
  TextEditingController qCtrl,
  TextEditingController pCtrl,
  VoidCallback onChanged,
) {
  final rowTotal = _formCalcLine(qCtrl.text, pCtrl.text);
  return TableRow(
    children: [
      _ContractFormBodyCell(Text(label)),
      _ContractFormBodyCell(_formNumField(qCtrl, onChanged: (_) => onChanged())),
      _ContractFormBodyCell(_formNumField(pCtrl, onChanged: (_) => onChanged())),
      _ContractFormBodyCell(
        Text(
          '${rowTotal.toStringAsFixed(2)} DH',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

Widget _formNumField(TextEditingController controller, {void Function(String)? onChanged}) {
  return TextField(
    controller: controller,
    onChanged: onChanged,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    textAlign: TextAlign.center,
    decoration: const InputDecoration(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      border: OutlineInputBorder(),
    ),
  );
}

Widget _formLabeledNumField(String label, TextEditingController controller) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      const SizedBox(height: 6),
      _formNumField(controller),
    ],
  );
}

Widget _formSectionTitle(BuildContext context, String title) {
  return Text(
    title,
    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  );
}

double _formCalcLine(String q, String p) => _formParseDouble(q) * _formParseDouble(p);

double _formParseDouble(String value) => double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;

int _formParseInt(String value) => int.tryParse(value.trim()) ?? 0;

String? _formBuildIsoDateTime(String j, String m, String a, String h, String mn) {
  if (j.trim().isEmpty && m.trim().isEmpty && a.trim().isEmpty && h.trim().isEmpty && mn.trim().isEmpty) {
    return null;
  }
  final day = int.tryParse(j.trim());
  final month = int.tryParse(m.trim());
  final year = int.tryParse(a.trim());
  final hour = int.tryParse(h.trim());
  final minute = int.tryParse(mn.trim());
  if (day == null || month == null || year == null || hour == null || minute == null) return null;
  try {
    final dt = DateTime(year, month, day, hour, minute);
    if (dt.year != year || dt.month != month || dt.day != day || dt.hour != hour || dt.minute != minute) {
      return null;
    }
    final mm = month.toString().padLeft(2, '0');
    final dd = day.toString().padLeft(2, '0');
    final hh = hour.toString().padLeft(2, '0');
    final mnn = minute.toString().padLeft(2, '0');
    return '$year-$mm-$dd' 'T$hh:$mnn:00';
  } catch (_) {
    return null;
  }
}

class _ContractFormHeaderCell extends StatelessWidget {
  final String text;
  const _ContractFormHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ContractFormBodyCell extends StatelessWidget {
  final Widget child;
  const _ContractFormBodyCell(this.child);

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(6), child: child);
}
