import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/settings_model.dart';
import '../../../shared/providers/app_providers.dart';
import 'settings_section_header.dart';

class CompanyInfoPage extends ConsumerStatefulWidget {
  const CompanyInfoPage({super.key});

  @override
  ConsumerState<CompanyInfoPage> createState() => _CompanyInfoPageState();
}

class _CompanyInfoPageState extends ConsumerState<CompanyInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _faxCtrl = TextEditingController();
  final _gsmCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _addressCtrl.dispose(); _phoneCtrl.dispose();
    _faxCtrl.dispose(); _gsmCtrl.dispose(); _emailCtrl.dispose(); _websiteCtrl.dispose();
    super.dispose();
  }

  void _populate(SettingsModel s) {
    if (_initialized) return;
    _initialized = true;
    _nameCtrl.text = s.companyName;
    _addressCtrl.text = s.address ?? '';
    _phoneCtrl.text = s.phone ?? '';
    _faxCtrl.text = s.fax ?? '';
    _gsmCtrl.text = s.gsm ?? '';
    _emailCtrl.text = s.email ?? '';
    _websiteCtrl.text = s.website ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(settingsRepositoryProvider).updateCompanyInfo(
        companyName: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        fax: _faxCtrl.text.trim(),
        gsm: _gsmCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        website: _websiteCtrl.text.trim(),
      );
      ref.invalidate(settingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Informations société mises à jour.'),
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
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (s) {
        _populate(s);
        return _buildForm();
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur : $e')),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSectionHeader(
            icon: Icons.business_outlined,
            title: 'Informations Société',
            subtitle: 'Ces données apparaissent dans vos contrats PDF.',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9C4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF9C40A).withValues(alpha: 0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFF92400E)),
                SizedBox(width: 8),
                Expanded(child: Text(
                  'Ces informations sont utilisées automatiquement pour générer les en-têtes de contrats PDF.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                )),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field('Nom de la société *', _nameCtrl, Icons.business_outlined,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null),
                    const SizedBox(height: 18),
                    _field('Adresse', _addressCtrl, Icons.location_on_outlined, maxLines: 2),
                    const SizedBox(height: 18),
                    Row(children: [
                      Expanded(child: _field('Téléphone', _phoneCtrl, Icons.phone_outlined)),
                      const SizedBox(width: 16),
                      Expanded(child: _field('Fax', _faxCtrl, Icons.fax_outlined)),
                    ]),
                    const SizedBox(height: 18),
                    _field('GSM / Mobile', _gsmCtrl, Icons.smartphone_outlined),
                    const SizedBox(height: 18),
                    _field('Email', _emailCtrl, Icons.mail_outline_rounded, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 18),
                    _field('Site Web', _websiteCtrl, Icons.language_outlined, keyboardType: TextInputType.url),
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
                        label: const Text('Enregistrer les informations'),
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

  Widget _field(String label, TextEditingController ctrl, IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
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
