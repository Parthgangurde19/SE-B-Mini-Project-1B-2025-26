import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/hackathon_model.dart';

/// Legacy form screen kept for compatibility.
class AdminHackathonFormScreen extends StatelessWidget {
  final HackathonModel? hackathon;

  const AdminHackathonFormScreen({super.key, this.hackathon});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (hackathon == null) {
        context.go('/admin/hackathons/create');
      } else {
        context.go('/admin/hackathons/edit', extra: hackathon);
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
