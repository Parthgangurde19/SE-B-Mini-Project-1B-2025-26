import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Legacy hackathon list screen kept for compatibility.
class AdminHackathonListScreen extends StatelessWidget {
  const AdminHackathonListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.go('/admin/hackathons');
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
