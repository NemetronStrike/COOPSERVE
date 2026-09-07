import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/app_spacing.dart';
import '../../../models/auth_models.dart';
import '../../../models/user_role.dart';
import '../../../navigation/app_router.dart';
import '../../../services/api_client.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import '../widgets/auth_header.dart';

class RegisterScreen extends StatefulWidget {
  final UserRole role;
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _certificationsCtrl = TextEditingController();
  final _cooperativeIdCtrl = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _serverError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _skillsCtrl.dispose();
    _certificationsCtrl.dispose();
    _cooperativeIdCtrl.dispose();
    super.dispose();
  }

  String? _required(String? v, String field) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  String? _validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Full name is required';
    if (v.trim().length < 2) return 'Enter a valid full name';
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Mobile number is required';
    if (!RegExp(r'^\+?[0-9]{10,13}$').hasMatch(v.trim())) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (!v.contains(RegExp(r'[A-Z]'))) return 'Include at least one uppercase letter';
    if (!v.contains(RegExp(r'[0-9]'))) return 'Include at least one number';
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != _passwordCtrl.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _authService.register(RegisterRequest(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
        role: widget.role,
        skills: widget.role == UserRole.worker ? _skillsCtrl.text.trim() : null,
        certifications: widget.role == UserRole.worker
            ? _certificationsCtrl.text.trim()
            : null,
        cooperativeId: widget.role == UserRole.admin
            ? _cooperativeIdCtrl.text.trim()
            : null,
      ));
      if (!mounted) return;
      final route = switch (widget.role) {
        UserRole.customer => AppRouter.customer,
        UserRole.worker => AppRouter.worker,
        UserRole.admin => AppRouter.admin,
      };
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
    } on ApiException catch (e) {
      setState(() => _serverError = e.message);
    } catch (_) {
      setState(() => _serverError = 'Unable to connect. Check your network.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthHeader(
                  title: 'Create Account',
                  subtitle: 'Fill in your details to get started.',
                  role: widget.role,
                ),
                const SizedBox(height: AppSpacing.xl),

                _SectionLabel('Personal Information'),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Full Name',
                  hint: 'As per government ID',
                  controller: _nameCtrl,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  validator: _validateName,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Mobile Number',
                  hint: '9876543210',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _validatePhone,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Email Address',
                  hint: 'you@example.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: _validateEmail,
                ),
                const SizedBox(height: AppSpacing.xl),

                if (widget.role == UserRole.worker) ...[
                  _SectionLabel('Worker Details'),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Skills',
                    hint: 'e.g. Plumbing, Electrical, Cleaning',
                    controller: _skillsCtrl,
                    prefixIcon: const Icon(Icons.build_outlined),
                    validator: (v) => _required(v, 'Skills'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Certifications (optional)',
                    hint: 'e.g. ITI Certificate, NSDC',
                    controller: _certificationsCtrl,
                    prefixIcon: const Icon(Icons.workspace_premium_outlined),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                if (widget.role == UserRole.admin) ...[
                  _SectionLabel('Cooperative Details'),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Cooperative / Organisation ID',
                    hint: 'e.g. COOP-MH-2024-001',
                    controller: _cooperativeIdCtrl,
                    prefixIcon: const Icon(Icons.corporate_fare_rounded),
                    validator: (v) => _required(v, 'Cooperative / Organisation ID'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                _SectionLabel('Security'),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Password',
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Text(
                    'Min. 8 characters, one uppercase letter, one number.',
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Confirm Password',
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirm,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    tooltip: _obscureConfirm ? 'Show password' : 'Hide password',
                  ),
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Server error banner
                if (_serverError != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      _serverError!,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: scheme.onErrorContainer),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                AppButton(
                  label: 'Create Account',
                  onPressed: _isLoading ? null : _submit,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?', style: textTheme.bodyMedium),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        AppRouter.login,
                        arguments: widget.role,
                      ),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: scheme.primary,
            letterSpacing: 0.5,
          ),
    );
  }
}
