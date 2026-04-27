import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../providers/admin_provider.dart';

class AdminAuthGuard extends StatefulWidget {
  final Widget child;

  const AdminAuthGuard({super.key, required this.child});

  @override
  State<AdminAuthGuard> createState() => _AdminAuthGuardState();
}

class _AdminAuthGuardState extends State<AdminAuthGuard> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await context.read<AdminProvider>().initializeAdminState();
        if (!mounted) {
          return;
        }

        if (!context.read<AdminProvider>().isAuthenticated) {
          context.go('/admin/login');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    if (provider.isLoading && !provider.isAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return widget.child;
  }
}
