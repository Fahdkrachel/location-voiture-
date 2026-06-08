import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/providers/auth_provider.dart';
import 'settings_section_header.dart';

class ProfileInfoPage extends ConsumerStatefulWidget {
  const ProfileInfoPage({super.key});

  @override
  ConsumerState<ProfileInfoPage> createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends ConsumerState<ProfileInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final admin = ref.read(authProvider).admin;
    _nameController = TextEditingController(text: admin?['fullName'] ?? '');
    _emailController = TextEditingController(text: admin?['email'] ?? '');
    _phoneController = TextEditingController();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get('/auth/me');
      final data = resp.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _phoneController.text = data['phone'] ?? '';
          _nameController.text = data['fullName'] ?? '';
          _emailController.text = data['email'] ?? '';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final admin = ref.read(authProvider).admin;
    if (admin == null) return;
    try {
      final updated = await ref.read(adminRepositoryProvider).updateAdmin(
        id: admin['id'],
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        phone: _phoneController.text.trim(),
      );
      ref.read(authProvider.notifier).updateLocalAdminInfo({
        'id': updated.id,
        'fullName': updated.fullName,
        'email': updated.email,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profil mis à jour avec succès.'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSectionHeader(
            icon: Icons.person_outline_rounded,
            title: 'Informations personnelles',
            subtitle: 'Gérez votre nom, email et téléphone.',
          ),
          const SizedBox(height: 28),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField('Nom complet', _nameController,
                        icon: Icons.badge_outlined,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null),
                    const SizedBox(height: 20),
                    _buildField('Adresse Email', _emailController,
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requis';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                            return 'Email invalide';
                          }
                          return null;
                        }),
                    const SizedBox(height: 20),
                    _buildField('Téléphone', _phoneController,
                        icon: Icons.phone_outlined),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A2B4A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _isLoading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Enregistrer les modifications'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {IconData? icon,
      TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 20, color: const Color(0xFF64748B)) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1A2B4A), width: 2)),
          ),
        ),
      ],
    );
  }
}

// Section header is now in settings_section_header.dart
