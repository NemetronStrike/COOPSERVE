import 'package:flutter/material.dart';
import '../../../core/app_spacing.dart';
import '../../../navigation/app_router.dart';

class SplashScreen extends StatefulWidget {
  /// Delay before navigating to role selection.
  /// Override in tests to avoid pending-timer failures.
  final Duration delay;
  const SplashScreen({super.key, this.delay = const Duration(seconds: 2)});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(widget.delay, () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.roleSelection);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.primary,
      body: FadeTransition(
        opacity: _fadeIn,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: scheme.onPrimary.withAlpha(26),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Icon(
                  Icons.handshake_rounded,
                  size: 52,
                  color: scheme.onPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'COOPSERVE',
                style: textTheme.headlineLarge?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Cooperative Workforce · Community Services',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimary.withAlpha(204),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: scheme.onPrimary.withAlpha(153),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
