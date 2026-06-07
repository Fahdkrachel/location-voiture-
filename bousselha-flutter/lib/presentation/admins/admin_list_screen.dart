import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/admin_model.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/providers/auth_provider.dart';

class AdminListScreen extends ConsumerStatefulWidget {
  const AdminListScreen({super.key});

  @override
  ConsumerState<AdminListScreen> createState() => _AdminListScreenState();
}

class _AdminListScreenState extends ConsumerState<AdminListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddAdminDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _AddAdminDialog(),
    );
  }

  void _showEditAdminDialog(BuildContext context, AdminModel admin) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EditAdminDialog(admin: admin),
    );
  }

  Future<void> _toggleAdminStatus(AdminModel admin) async {
    final newStatus = admin.status == 'ACTIVE' ? 'DISABLED' : 'ACTIVE';
    final currentAdminId = ref.read(authProvider).admin?['id'];

    if (admin.id == currentAdminId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez pas désactiver votre propre compte.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await ref.read(adminRepositoryProvider).toggleStatus(admin.id, newStatus);
      ref.invalidate(adminsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut de ${admin.fullName} mis à jour (${newStatus}).'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminsAsync = ref.watch(adminsProvider);
    final currentAdminId = ref.watch(authProvider).admin?['id'];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestion des Administrateurs',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2B4A),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Créez, modifiez et contrôlez les accès des administrateurs à la plateforme.',
                      style: TextStyle(color: Color(0xFF64748b)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddAdminDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2B4A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter un Administrateur'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher un administrateur par nom ou email...',
                    prefixIcon: Icon(Icons.search, color: Color(0xFF64748b)),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: adminsAsync.when(
                data: (admins) {
                  final filtered = admins.where((admin) {
                    return admin.fullName.toLowerCase().contains(_searchQuery) ||
                        admin.email.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text('Aucun administrateur trouvé.'),
                    );
                  }

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columnSpacing: 32,
                          headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                          columns: const [
                            DataColumn(label: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Téléphone', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Création', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Dernière Connexion', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filtered.map((admin) {
                            final bool isActive = admin.status == 'ACTIVE';
                            final bool isSelf = admin.id == currentAdminId;
                            final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(admin.createdAt);
                            final formattedLogin = admin.lastLogin != null
                                ? DateFormat('dd/MM/yyyy HH:mm').format(admin.lastLogin!)
                                : 'Jamais';

                            return DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(0xFFE2E8F0),
                                        child: Text(
                                          admin.fullName.substring(0, 1).toUpperCase(),
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${admin.fullName}${isSelf ? " (Vous)" : ""}',
                                        style: TextStyle(fontWeight: isSelf ? FontWeight.bold : FontWeight.normal),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(Text(admin.email)),
                                DataCell(Text(admin.phone ?? '-')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isActive ? 'Actif' : 'Désactivé',
                                      style: TextStyle(
                                        color: isActive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(formattedDate)),
                                DataCell(Text(formattedLogin)),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF64748b)),
                                        tooltip: 'Modifier',
                                        onPressed: () => _showEditAdminDialog(context, admin),
                                      ),
                                      if (!isSelf)
                                        IconButton(
                                          icon: Icon(
                                            isActive ? Icons.toggle_on : Icons.toggle_off_outlined,
                                            color: isActive ? Colors.green : Colors.grey,
                                            size: 32,
                                          ),
                                          tooltip: isActive ? 'Désactiver' : 'Activer',
                                          onPressed: () => _toggleAdminStatus(admin),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Une erreur s\'est produite lors du chargement : ${e.toString()}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAdminDialog extends ConsumerStatefulWidget {
  const _AddAdminDialog();

  @override
  ConsumerState<_AddAdminDialog> createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends ConsumerState<_AddAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(adminRepositoryProvider).createAdmin(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      ref.invalidate(adminsProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nouvel administrateur créé avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un Administrateur'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nom complet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'ex: Fahd Krachel'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                const Text('Adresse Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'ex: admin2@bousselha.ma'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requis';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('Téléphone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'ex: 0689124889'),
                ),
                const SizedBox(height: 16),
                const Text('Mot de passe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'Minimum 8 caractères',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if (v.length < 8) return 'Minimum 8 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('Confirmer le mot de passe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Saisir à nouveau'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if (v != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A2B4A), foregroundColor: Colors.white),
          child: _isLoading
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Créer'),
        ),
      ],
    );
  }
}

class _EditAdminDialog extends ConsumerStatefulWidget {
  final AdminModel admin;
  const _EditAdminDialog({required this.admin});

  @override
  ConsumerState<_EditAdminDialog> createState() => _EditAdminDialogState();
}

class _EditAdminDialogState extends ConsumerState<_EditAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.admin.fullName);
    _emailController = TextEditingController(text: widget.admin.email);
    _phoneController = TextEditingController(text: widget.admin.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedAdmin = await ref.read(adminRepositoryProvider).updateAdmin(
        id: widget.admin.id,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        phone: _phoneController.text.trim(),
      );

      final currentAdminId = ref.read(authProvider).admin?['id'];
      if (widget.admin.id == currentAdminId) {
        // Update local auth state if modifying oneself
        ref.read(authProvider.notifier).updateLocalAdminInfo({
          'id': updatedAdmin.id,
          'fullName': updatedAdmin.fullName,
          'email': updatedAdmin.email,
        });
      }

      ref.invalidate(adminsProvider);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Administrateur mis à jour.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier l\'Administrateur'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nom complet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              const Text('Adresse Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requis';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Téléphone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A2B4A), foregroundColor: Colors.white),
          child: _isLoading
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
