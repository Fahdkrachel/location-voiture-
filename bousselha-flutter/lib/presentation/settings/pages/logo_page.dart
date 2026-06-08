import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/providers/app_providers.dart';
import 'settings_section_header.dart';

class LogoPage extends ConsumerStatefulWidget {
  const LogoPage({super.key});

  @override
  ConsumerState<LogoPage> createState() => _LogoPageState();
}

class _LogoPageState extends ConsumerState<LogoPage> {
  bool _isUploading = false;
  File? _selectedFile;
  String? _previewPath;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _previewPath = result.files.single.path;
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedFile == null) return;
    setState(() => _isUploading = true);
    try {
      await ref.read(settingsRepositoryProvider).uploadLogo(_selectedFile!);
      ref.invalidate(settingsProvider);
      setState(() => _selectedFile = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Logo mis à jour avec succès.'),
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
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SettingsSectionHeader(
            icon: Icons.image_outlined,
            title: 'Logo de la Société',
            subtitle: 'Ce logo apparaît dans l\'en-tête des contrats PDF.',
          ),
          const SizedBox(height: 28),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Logo actuel ────────────────────────────────────────────
                  const Text('Logo actuel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                  const SizedBox(height: 12),
                  settingsAsync.when(
                    data: (s) {
                      final logoUrl = s.logoUrl;
                      if (logoUrl != null && logoUrl.isNotEmpty) {
                        return Container(
                          height: 100,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFFF8FAFC),
                          ),
                          child: Image.network(
                            'http://localhost:8080$logoUrl',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, size: 40, color: Color(0xFFCBD5E1))),
                          ),
                        );
                      }
                      return Container(
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(8),
                          color: const Color(0xFFF8FAFC),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.image_not_supported_outlined, size: 36, color: Color(0xFFCBD5E1)),
                              SizedBox(height: 6),
                              Text('Aucun logo défini', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                    error: (_, __) => const SizedBox(height: 100, child: Center(child: Icon(Icons.error_outline))),
                  ),

                  const SizedBox(height: 28),

                  // ── Nouveau logo ──────────────────────────────────────────
                  const Text('Nouveau logo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569))),
                  const SizedBox(height: 12),

                  // Preview du fichier sélectionné
                  if (_previewPath != null) ...[
                    Container(
                      height: 100,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF1A2B4A).withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFFF0F4FF),
                      ),
                      child: Image.file(File(_previewPath!), fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Zone drag & drop / bouton choisir
                  InkWell(
                    onTap: _isUploading ? null : _pickFile,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFFF8FAFC),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _selectedFile != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                            size: 36,
                            color: _selectedFile != null ? Colors.green : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedFile != null
                                ? _selectedFile!.path.split(Platform.pathSeparator).last
                                : 'Cliquez pour choisir un fichier',
                            style: TextStyle(
                              fontSize: 13,
                              color: _selectedFile != null ? const Color(0xFF1A2B4A) : const Color(0xFF64748B),
                              fontWeight: _selectedFile != null ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          if (_selectedFile == null)
                            const Text('PNG ou JPG — max 5 MB', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          foregroundColor: const Color(0xFF1E293B),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.folder_open_outlined, size: 18),
                        label: const Text('Choisir un fichier'),
                      ),
                      const SizedBox(width: 12),
                      if (_selectedFile != null)
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _upload,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A2B4A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: _isUploading
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.upload_outlined, size: 18),
                          label: Text(_isUploading ? 'Upload en cours…' : 'Uploader le logo'),
                        ),
                      if (_selectedFile != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => setState(() { _selectedFile = null; _previewPath = null; }),
                          child: const Text('Annuler', style: TextStyle(color: Color(0xFF64748B))),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
