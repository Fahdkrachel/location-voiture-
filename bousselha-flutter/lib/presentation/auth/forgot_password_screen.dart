import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_error_handler.dart';
import '../../shared/providers/app_providers.dart';

enum _ResetStep { email, code, password, success }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _ResetStep _step = _ResetStep.email;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _message;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_validateEmailStep()) return;
    await _runAction(() async {
      final msg = await ref
          .read(passwordResetRepositoryProvider)
          .requestReset(_emailController.text.trim());
      _message = msg;
      _step = _ResetStep.code;
    });
  }

  Future<void> _verifyCode() async {
    if (!(_codeFormKey.currentState?.validate() ?? false)) return;
    await _runAction(() async {
      final msg = await ref.read(passwordResetRepositoryProvider).verifyCode(
            email: _emailController.text.trim(),
            code: _codeController.text.trim(),
          );
      _message = msg;
      _step = _ResetStep.password;
    });
  }

  Future<void> _confirmReset() async {
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;
    await _runAction(() async {
      _message = await ref.read(passwordResetRepositoryProvider).confirmReset(
            email: _emailController.text.trim(),
            code: _codeController.text.trim(),
            newPassword: _passwordController.text,
            confirmNewPassword: _confirmPasswordController.text,
          );
      _step = _ResetStep.success;
    });
  }

  bool _validateEmailStep() {
    final visibleForm = _emailFormKey.currentState;
    if (visibleForm != null) {
      return visibleForm.validate();
    }

    final error = _validateEmail(_emailController.text);
    if (error == null) {
      return true;
    }

    setState(() {
      _errorMessage = error;
    });
    return false;
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _message = null;
    });

    try {
      await action();
    } catch (e) {
      _errorMessage = AppErrorHandler.getMessage(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 800;

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isDesktop) ...[
            const Icon(Icons.directions_car_rounded,
                size: 48, color: Color(0xFF1A2B4A)),
            const SizedBox(height: 10),
            const Text(
              'BOUSSELHA CARS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A2B4A),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 30),
          ],
          Row(
            children: [
              IconButton(
                tooltip: 'Retour',
                onPressed:
                    _isLoading ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: const Color(0xFF1A2B4A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _subtitle,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF64748b), height: 1.45),
          ),
          const SizedBox(height: 24),
          _StepIndicator(step: _step),
          const SizedBox(height: 24),
          if (_errorMessage != null) ...[
            _StatusBanner(message: _errorMessage!, isError: true),
            const SizedBox(height: 18),
          ],
          if (_message != null && _step != _ResetStep.success) ...[
            _StatusBanner(message: _message!, isError: false),
            const SizedBox(height: 18),
          ],
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (_step) {
              _ResetStep.email => _EmailStep(
                  key: const ValueKey('email'),
                  formKey: _emailFormKey,
                  controller: _emailController,
                  isLoading: _isLoading,
                  onSubmit: _requestCode,
                ),
              _ResetStep.code => _CodeStep(
                  key: const ValueKey('code'),
                  formKey: _codeFormKey,
                  controller: _codeController,
                  email: _emailController.text.trim(),
                  isLoading: _isLoading,
                  onSubmit: _verifyCode,
                  onResend: _requestCode,
                ),
              _ResetStep.password => _PasswordStep(
                  key: const ValueKey('password'),
                  formKey: _passwordFormKey,
                  passwordController: _passwordController,
                  confirmPasswordController: _confirmPasswordController,
                  obscurePassword: _obscurePassword,
                  obscureConfirmPassword: _obscureConfirmPassword,
                  isLoading: _isLoading,
                  onSubmit: _confirmReset,
                  onTogglePassword: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onToggleConfirmPassword: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                  onChanged: () => setState(() {}),
                ),
              _ResetStep.success => _SuccessStep(
                  key: const ValueKey('success'),
                  message: _message ?? 'Mot de passe réinitialisé avec succès.',
                  onLogin: () => Navigator.of(context).pop(),
                ),
            },
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF111c30), Color(0xFF1A2B4A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(60),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_reset_rounded,
                          size: 72, color: Colors.white),
                      SizedBox(height: 24),
                      Text(
                        'Sécurité du compte',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Récupération sécurisée par code à usage unique, expiration rapide et validation renforcée du nouveau mot de passe.',
                        style: TextStyle(
                            fontSize: 16, color: Colors.white70, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Container(
                color: Colors.white,
                child: Center(child: SingleChildScrollView(child: content)),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(child: SingleChildScrollView(child: content)),
    );
  }

  String get _title {
    return switch (_step) {
      _ResetStep.email => 'Mot de passe oublié',
      _ResetStep.code => 'Code de vérification',
      _ResetStep.password => 'Nouveau mot de passe',
      _ResetStep.success => 'Réinitialisation réussie',
    };
  }

  String get _subtitle {
    return switch (_step) {
      _ResetStep.email =>
        'Saisissez votre adresse email administrateur pour recevoir un code de vérification.',
      _ResetStep.code =>
        'Entrez le code à 6 chiffres reçu par email. Il expire après 10 minutes.',
      _ResetStep.password =>
        'Choisissez un mot de passe robuste pour sécuriser votre accès administrateur.',
      _ResetStep.success =>
        'Vous pouvez maintenant vous reconnecter avec votre nouveau mot de passe.',
    };
  }
}

class _EmailStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _EmailStep({
    super.key,
    required this.formKey,
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FieldLabel('Adresse email'),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            decoration: _inputDecoration(
              hintText: 'admin@bousselha.ma',
              icon: Icons.mail_outline_rounded,
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 28),
          _PrimaryButton(
            label: 'Envoyer le code',
            icon: Icons.send_outlined,
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _CodeStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final String email;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onResend;

  const _CodeStep({
    super.key,
    required this.formKey,
    required this.controller,
    required this.email,
    required this.isLoading,
    required this.onSubmit,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            email,
            style: const TextStyle(
                color: Color(0xFF1A2B4A), fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Code de vérification'),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onFieldSubmitted: (_) => onSubmit(),
            decoration: _inputDecoration(
              hintText: '582741',
              icon: Icons.pin_outlined,
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez saisir le code reçu';
              }
              if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
                return 'Le code doit contenir 6 chiffres';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: isLoading ? null : onResend,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Renvoyer le code'),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFF1A2B4A)),
          ),
          const SizedBox(height: 18),
          _PrimaryButton(
            label: 'Vérifier le code',
            icon: Icons.verified_outlined,
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _PasswordStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onChanged;

  const _PasswordStep({
    super.key,
    required this.formKey,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.isLoading,
    required this.onSubmit,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FieldLabel('Nouveau mot de passe'),
          const SizedBox(height: 6),
          TextFormField(
            controller: passwordController,
            obscureText: obscurePassword,
            onChanged: (_) => onChanged(),
            decoration: _inputDecoration(
              hintText: '••••••••',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
              ),
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: 12),
          _PasswordChecklist(password: passwordController.text),
          const SizedBox(height: 18),
          const _FieldLabel('Confirmation du mot de passe'),
          const SizedBox(height: 6),
          TextFormField(
            controller: confirmPasswordController,
            obscureText: obscureConfirmPassword,
            onFieldSubmitted: (_) => onSubmit(),
            decoration: _inputDecoration(
              hintText: '••••••••',
              icon: Icons.lock_person_outlined,
              suffixIcon: IconButton(
                onPressed: onToggleConfirmPassword,
                icon: Icon(obscureConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez confirmer le mot de passe';
              }
              if (value != passwordController.text) {
                return 'La confirmation ne correspond pas';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          _PrimaryButton(
            label: 'Réinitialiser',
            icon: Icons.lock_reset_rounded,
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _SuccessStep extends StatelessWidget {
  final String message;
  final VoidCallback onLogin;

  const _SuccessStep({
    super.key,
    required this.message,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFecfdf5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFbbf7d0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xFF16a34a), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF166534),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _PrimaryButton(
          label: 'Retour à la connexion',
          icon: Icons.login_rounded,
          isLoading: false,
          onPressed: onLogin,
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final _ResetStep step;

  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    final currentIndex = _ResetStep.values.indexOf(step);
    return Row(
      children: List.generate(4, (index) {
        final active = index <= currentIndex;
        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF1A2B4A) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const _StatusBanner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFfef2f2) : const Color(0xFFeff6ff),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isError ? const Color(0xFFfecaca) : const Color(0xFFbfdbfe)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: isError ? const Color(0xFFdc2626) : const Color(0xFF1d4ed8),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color:
                    isError ? const Color(0xFF991b1b) : const Color(0xFF1e3a8a),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordChecklist extends StatelessWidget {
  final String password;

  const _PasswordChecklist({required this.password});

  @override
  Widget build(BuildContext context) {
    final checks = [
      ('8 caractères', password.length >= 8),
      ('Majuscule', RegExp(r'[A-Z]').hasMatch(password)),
      ('Minuscule', RegExp(r'[a-z]').hasMatch(password)),
      ('Chiffre', RegExp(r'\d').hasMatch(password)),
      ('Spécial', RegExp(r'[^A-Za-z0-9]').hasMatch(password)),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: checks.map((check) {
        final valid = check.$2;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: valid ? const Color(0xFFecfdf5) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color:
                    valid ? const Color(0xFFbbf7d0) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                valid
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 15,
                color:
                    valid ? const Color(0xFF16a34a) : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Text(
                check.$1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      valid ? const Color(0xFF166534) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Colors.white),
            )
          : Icon(icon, size: 19),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A2B4A),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFF94A3B8),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF475569),
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required String hintText,
  required IconData icon,
  Widget? suffixIcon,
  String? counterText,
}) {
  return InputDecoration(
    hintText: hintText,
    counterText: counterText,
    prefixIcon: Icon(icon, color: const Color(0xFF64748b), size: 20),
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFcbd5e1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFcbd5e1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF1A2B4A), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFef4444)),
    ),
  );
}

String? _validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Veuillez saisir votre adresse email';
  }
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value.trim())) {
    return 'Format d\'adresse email invalide';
  }
  return null;
}

String? _validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Veuillez saisir un nouveau mot de passe';
  }
  if (value.length < 8) {
    return 'Le mot de passe doit contenir au moins 8 caractères';
  }
  if (!RegExp(r'[A-Z]').hasMatch(value)) {
    return 'Ajoutez au moins une majuscule';
  }
  if (!RegExp(r'[a-z]').hasMatch(value)) {
    return 'Ajoutez au moins une minuscule';
  }
  if (!RegExp(r'\d').hasMatch(value)) {
    return 'Ajoutez au moins un chiffre';
  }
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
    return 'Ajoutez au moins un caractère spécial';
  }
  return null;
}
