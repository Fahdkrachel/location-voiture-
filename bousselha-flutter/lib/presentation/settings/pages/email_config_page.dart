import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../data/models/settings_model.dart';
import '../../../shared/providers/app_providers.dart';
import 'settings_section_header.dart';

class EmailConfigPage extends ConsumerStatefulWidget {
  const EmailConfigPage({super.key});

  @override
  ConsumerState<EmailConfigPage> createState() => _EmailConfigPageState();
}

class _EmailConfigPageState extends ConsumerState<EmailConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  
  bool _auth = true;
  bool _starttls = true;
  bool _active = false;
  
  bool _isLoading = false;
  bool _initialized = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _populate(SettingsModel s) {
    if (_initialized) return;
    _initialized = true;
    _hostCtrl.text = s.smtpHost ?? '';
    _portCtrl.text = s.smtpPort?.toString() ?? '587';
    _userCtrl.text = s.smtpUsername ?? '';
    _passCtrl.text = s.smtpPassword ?? '';
    _auth = s.smtpAuth ?? true;
    _starttls = s.smtpStarttls ?? true;
    _active = s.smtpActive ?? false;
  }

  Future<void> _save(SettingsModel currentSettings) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(settingsRepositoryProvider).updateCompanyInfo(
        companyName: currentSettings.companyName,
        address: currentSettings.address,
        phone: currentSettings.phone,
        fax: currentSettings.fax,
        gsm: currentSettings.gsm,
        email: currentSettings.email,
        website: currentSettings.website,
        smtpHost: _hostCtrl.text.trim(),
        smtpPort: int.tryParse(_portCtrl.text.trim()),
        smtpUsername: _userCtrl.text.trim(),
        smtpPassword: _passCtrl.text,
        smtpAuth: _auth,
        smtpStarttls: _starttls,
        smtpActive: _active,
      );
      ref.invalidate(settingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Configuration email enregistrée avec succès.'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) AppErrorHandler.showError(context, e);
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
        return _buildForm(s);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(AppErrorHandler.getMessage(e))),
    );
  }

  Widget _buildForm(SettingsModel currentSettings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSectionHeader(
            icon: Icons.mail_outline_rounded,
            title: 'Configuration Email (SMTP)',
            subtitle: 'Configurez le serveur SMTP utilisé pour l\'envoi des codes de vérification en cas d\'oubli de mot de passe.',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 20, color: Color(0xFF1D4ED8)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _active 
                      ? 'L\'envoi d\'e-mail personnalisé est ACTIVÉ. L\'application utilisera les coordonnées ci-dessous.' 
                      : 'L\'envoi d\'e-mail personnalisé est DÉSACTIVÉ. L\'application utilisera les coordonnées système par défaut.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
                    SwitchListTile(
                      title: const Text('Activer ce serveur email SMTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Si coché, les emails d\'oubli de mot de passe utiliseront ce serveur.', style: TextStyle(fontSize: 12)),
                      value: _active,
                      activeColor: const Color(0xFF1A2B4A),
                      onChanged: (val) => setState(() => _active = val),
                    ),
                    const Divider(height: 32, color: Color(0xFFE2E8F0)),
                    _field('Serveur SMTP *', _hostCtrl, Icons.dns_outlined, 
                        hint: 'smtp.gmail.com', 
                        validator: (v) => _active && (v == null || v.trim().isEmpty) ? 'Requis' : null),
                    const SizedBox(height: 18),
                    _field('Port SMTP *', _portCtrl, Icons.numbers_outlined, 
                        hint: '587', 
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (!_active) return null;
                          if (v == null || v.trim().isEmpty) return 'Requis';
                          if (int.tryParse(v) == null) return 'Port invalide';
                          return null;
                        }),
                    const SizedBox(height: 18),
                    _field('Nom d\'utilisateur / Adresse e-mail *', _userCtrl, Icons.alternate_email_rounded, 
                        hint: 'contact@bousselhacars.com', 
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => _active && (v == null || v.trim().isEmpty) ? 'Requis' : null),
                    const SizedBox(height: 18),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mot de passe / Clé d\'application *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscurePassword,
                          validator: (v) => _active && (v == null || v.isEmpty) ? 'Requis' : null,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20, color: Color(0xFF64748B)),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF64748B)),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1A2B4A), width: 2)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('Authentification SMTP', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                            value: _auth,
                            activeColor: const Color(0xFF1A2B4A),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (val) => setState(() => _auth = val ?? true),
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('STARTTLS / SSL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                            value: _starttls,
                            activeColor: const Color(0xFF1A2B4A),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (val) => setState(() => _starttls = val ?? true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _save(currentSettings),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A2B4A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _isLoading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Enregistrer la configuration Email'),
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
    String? hint,
    TextInputType keyboardType = TextInputType.text,
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
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
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
