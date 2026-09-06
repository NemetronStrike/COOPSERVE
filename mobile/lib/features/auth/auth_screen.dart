import 'package:flutter/material.dart';
import '../../navigation/app_router.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('COOPSERVE')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Select your role', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.customer),
              child: const Text('Customer'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.worker),
              child: const Text('Worker'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.admin),
              child: const Text('Cooperative Admin'),
            ),
          ],
        ),
      ),
    );
  }
}
