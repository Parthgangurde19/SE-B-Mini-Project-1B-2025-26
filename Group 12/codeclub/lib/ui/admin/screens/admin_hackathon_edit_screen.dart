import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/models/hackathon_model.dart';
import '../../../providers/admin_provider.dart';
import '../widgets/admin_auth_guard.dart';
import '../widgets/hackathon_form.dart';

class AdminHackathonEditScreen extends StatelessWidget {
  final HackathonModel hackathon;

  const AdminHackathonEditScreen({super.key, required this.hackathon});

  @override
  Widget build(BuildContext context) {
    return AdminAuthGuard(
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Hackathon')),
        body: HackathonForm(
          initial: hackathon,
          submitLabel: 'Save Changes',
          onSubmit: (draft, banner) async {
            await context.read<AdminProvider>().updateHackathon(
              hackathon.id,
              {
                'title': draft.title,
                'description': draft.description,
                'startDate': draft.startDate,
                'endDate': draft.endDate,
                'registrationDeadline': draft.registrationDeadline,
                'minTeamSize': draft.minTeamSize,
                'maxTeamSize': draft.maxTeamSize,
                'venue': draft.venue,
                'website': draft.website,
                'registrationFormUrl': draft.registrationFormUrl,
                'prizes': draft.prizes,
                'rules': draft.rules,
                'tags': draft.tags,
                'status': draft.status,
              },
              banner,
            );
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hackathon updated successfully.')),
            );
            context.pop();
          },
        ),
      ),
    );
  }
}
