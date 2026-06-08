import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../data/models/admin_model.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/providers/auth_provider.dart';
import 'settings_section_header.dart';

class AdminsPage extends ConsumerStatefulWidget {
  const AdminsPage({super.key});

  @override
  ConsumerState<AdminsPage> createState() => _AdminsPageState();
}

class _AdminsPageState extends ConsumerState<AdminsPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleStatus(AdminModel admin) async {
    final newStatus = admin.status == 'ACTIVE' ? 'DISABLED' : 'ACTIVE';
    final selfId = ref.read(authProvider).admin?['id'];
    if (admin.id == selfId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vous ne pouvez pas désactiver votre propre compte.'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    try {
      await ref.read(adminRepositoryProvider).toggleStatus(admin.id, newStatus);
      ref.invalidate(adminsProvider);
    } catch (e) {
      if (mounted) AppErrorHandler.showError(context, e);
    }
  }

  void _showAdd() => showDialog(context: context, barrierDismissible: false, builder: (_) => const _AddAdminDialog());
  void _showEdit(AdminModel a) => showDialog(context: context, barrierDismissible: false, builder: (_) => _EditAdminDialog(admin: a));

  @override
  Widget build(BuildContext context) {
    final adminsAsync = ref.watch(adminsProvider);
    final selfId = ref.watch(authProvider).admin?['id'];

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SettingsSectionHeader(
                icon: Icons.manage_accounts_outlined,
                title: 'Gestion des Administrateurs',
                subtitle: 'Créez et gérez les accès à la plateforme.',
              ),
              ElevatedButton.icon(
                onPressed: _showAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2B4A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFE2E8F0))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Rechercher par nom ou email…',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF64748B)),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: adminsAsync.when(
              data: (admins) {
                final filtered = admins.where((a) =>
                  a.fullName.toLowerCase().contains(_query) ||
                  a.email.toLowerCase().contains(_query)).toList();
                if (filtered.isEmpty) return const Center(child: Text('Aucun administrateur trouvé.'));
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columnSpacing: 24,
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                      columns: const [
                        DataColumn(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Téléphone', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Créé le', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: filtered.map((a) {
                        final isActive = a.status == 'ACTIVE';
                        final isSelf = a.id == selfId;
                        return DataRow(cells: [
                          DataCell(Row(children: [
                            CircleAvatar(backgroundColor: const Color(0xFFE2E8F0), child: Text(a.fullName[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                            const SizedBox(width: 10),
                            Text('${a.fullName}${isSelf ? " (Vous)" : ""}', style: TextStyle(fontWeight: isSelf ? FontWeight.bold : FontWeight.normal)),
                          ])),
                          DataCell(Text(a.email)),
                          DataCell(Text(a.phone ?? '-')),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(isActive ? 'Actif' : 'Désactivé',
                              style: TextStyle(color: isActive ? const Color(0xFF15803D) : const Color(0xFFB91C1C), fontSize: 12, fontWeight: FontWeight.bold)),
                          )),
                          DataCell(Text(DateFormat('dd/MM/yyyy').format(a.createdAt))),
                          DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(icon: const Icon(Icons.edit_outlined, color: Color(0xFF64748B)), tooltip: 'Modifier', onPressed: () => _showEdit(a)),
                            if (!isSelf)
                              IconButton(
                                icon: Icon(isActive ? Icons.toggle_on : Icons.toggle_off_outlined, color: isActive ? Colors.green : Colors.grey, size: 28),
                                tooltip: isActive ? 'Désactiver' : 'Activer',
                                onPressed: () => _toggleStatus(a),
                              ),
                          ])),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(AppErrorHandler.getMessage(e))),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Admin Dialog ─────────────────────────────────────────────────────────
class _AddAdminDialog extends ConsumerStatefulWidget {
  const _AddAdminDialog();
  @override
  ConsumerState<_AddAdminDialog> createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends ConsumerState<_AddAdminDialog> {
  final _fk = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pwd = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() { _name.dispose(); _email.dispose(); _phone.dispose(); _pwd.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_fk.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(adminRepositoryProvider).createAdmin(
        fullName: _name.text.trim(), email: _email.text.trim().toLowerCase(),
        phone: _phone.text.trim(), password: _pwd.text, confirmPassword: _confirm.text,
      );
      ref.invalidate(adminsProvider);
      if (mounted) { Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Administrateur créé.'), backgroundColor: Colors.green)); }
    } catch (e) {
      if (mounted) AppErrorHandler.showError(context, e);
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Ajouter un Administrateur'),
    content: SizedBox(width: 480, child: SingleChildScrollView(child: Form(key: _fk, child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nom complet', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null),
      const SizedBox(height: 14),
      TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null),
      const SizedBox(height: 14),
      TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder())),
      const SizedBox(height: 14),
      TextFormField(controller: _pwd, obscureText: _obscure, decoration: InputDecoration(labelText: 'Mot de passe', border: const OutlineInputBorder(), suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure = !_obscure))), validator: (v) { if (v == null || v.isEmpty) return 'Requis'; if (v.length < 8) return 'Min. 8 chars'; return null; }),
      const SizedBox(height: 14),
      TextFormField(controller: _confirm, obscureText: _obscure, decoration: const InputDecoration(labelText: 'Confirmer mot de passe', border: OutlineInputBorder()), validator: (v) => v != _pwd.text ? 'Ne correspond pas' : null),
    ])))),
    actions: [
      TextButton(onPressed: _loading ? null : () => Navigator.of(context).pop(), child: const Text('Annuler')),
      ElevatedButton(onPressed: _loading ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A2B4A), foregroundColor: Colors.white), child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Créer')),
    ],
  );
}

// ── Edit Admin Dialog ─────────────────────────────────────────────────────────
class _EditAdminDialog extends ConsumerStatefulWidget {
  final AdminModel admin;
  const _EditAdminDialog({required this.admin});
  @override
  ConsumerState<_EditAdminDialog> createState() => _EditAdminDialogState();
}

class _EditAdminDialogState extends ConsumerState<_EditAdminDialog> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  bool _loading = false;

  @override
  void initState() { super.initState(); _name = TextEditingController(text: widget.admin.fullName); _email = TextEditingController(text: widget.admin.email); _phone = TextEditingController(text: widget.admin.phone ?? ''); }
  @override
  void dispose() { _name.dispose(); _email.dispose(); _phone.dispose(); super.dispose(); }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await ref.read(adminRepositoryProvider).updateAdmin(id: widget.admin.id, fullName: _name.text.trim(), email: _email.text.trim().toLowerCase(), phone: _phone.text.trim());
      ref.invalidate(adminsProvider);
      if (mounted) { Navigator.of(context).pop(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Administrateur mis à jour.'), backgroundColor: Colors.green)); }
    } catch (e) {
      if (mounted) AppErrorHandler.showError(context, e);
    } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Modifier l\'Administrateur'),
    content: SizedBox(width: 440, child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nom complet', border: OutlineInputBorder())),
      const SizedBox(height: 14),
      TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
      const SizedBox(height: 14),
      TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder())),
    ])),
    actions: [
      TextButton(onPressed: _loading ? null : () => Navigator.of(context).pop(), child: const Text('Annuler')),
      ElevatedButton(onPressed: _loading ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A2B4A), foregroundColor: Colors.white), child: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Enregistrer')),
    ],
  );
}
