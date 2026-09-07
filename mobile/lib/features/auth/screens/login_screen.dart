import 'package:flutter/material.dart';
import '../../../core/app_spacing.dart';
import '../../../models/user_role.dart';
import '../../../navigation/app_router.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import '../widgets/auth_header.dart';

class LoginScreen extends StatefulWidget {
  final UserRole role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String? _validateIdentifier(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email or phone is required';
    final isEmail = v.contains('@');
    if (isEmail) {
      final emailRe = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
      if (!emailRe.hasMatch(v.trim())) return 'Enter a valid email address';
    } else {
      final phoneRe = RegExp(r'^\+?[0-9]{10,13}$');
      if (!phoneRe.hasMatch(v.trim())) return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Mock: simulate network delay then navigate to role destination.
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _navigateToDestination();
    });
  }

  void _navigateToDestination() {
    final route = switch (widget.role) {
      UserRole.customer => AppRouter.customer,
      UserRole.worker => AppRouter.worker,
      UserRole.admin => AppRouter.admin,
    };
    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthHeader(
                  title: 'Sign In',
                  subtitle: 'Enter your credentials to continue.',
                  role: widget.role,
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Email / Phone ──────────────────────────────────────────
                AppTextField(
                  label: 'Email or Phone Number',
                  hint: 'you@example.com or 9876543210',
                  controller: _identifierCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  validator: _validateIdentifier,
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Password ───────────────────────────────────────────────
                AppTextField(
                  label: 'Password',
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── Forgot password ────────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showForgotPasswordSheet(context),
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Login button ───────────────────────────────────────────
                AppButton(
                  label: 'Sign In',
                  onPressed: _isLoading ? null : _submit,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Divider ────────────────────────────────────────────────
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: Text('or',
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: AppSpacing.lg),

                // ── Register link ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?",
                        style: textTheme.bodyMedium),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        AppRouter.register,
                        arguments: widget.role,
                      ),
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordSheet(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.lg,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding +
              MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reset Password', style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Password reset will be available once the backend is connected.',
              style: textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
