import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Legacy admin dashboard kept for compatibility.
/// New flow is under lib/ui/admin/screens.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This is a legacy admin entry. Use the updated admin module.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/admin/dashboard'),
                child: const Text('Open Updated Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
