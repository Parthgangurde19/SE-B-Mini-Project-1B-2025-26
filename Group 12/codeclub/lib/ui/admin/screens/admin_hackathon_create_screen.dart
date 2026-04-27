import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../providers/admin_provider.dart';
import '../widgets/admin_auth_guard.dart';
import '../widgets/hackathon_form.dart';

class AdminHackathonCreateScreen extends StatelessWidget {
  const AdminHackathonCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminAuthGuard(
      child: Scaffold(
        appBar: AppBar(title: const Text('Create Hackathon')),
        body: HackathonForm(
          submitLabel: 'Create Hackathon',
          onSubmit: (draft, banner) async {
            await context.read<AdminProvider>().createHackathon(draft, banner);
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hackathon created successfully.')),
            );
            context.pop();
          },
        ),
      ),
    );
  }
}
