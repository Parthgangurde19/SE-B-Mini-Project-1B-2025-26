import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/hackathon_model.dart';
import '../../../providers/admin_provider.dart';
import '../widgets/admin_auth_guard.dart';
import '../widgets/status_badge.dart';

class AdminHackathonDetailScreen extends StatelessWidget {
  final HackathonModel hackathon;

  const AdminHackathonDetailScreen({super.key, required this.hackathon});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AdminAuthGuard(
      child: Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Hackathon Details',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              onPressed: () => context.push('/admin/hackathons/edit', extra: hackathon),
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit Hackathon',
            ),
            IconButton(
              onPressed: () async {
                final ok = await _confirmDelete(context);
                if (ok == true && context.mounted) {
                  await context.read<AdminProvider>().deleteHackathon(hackathon.id);
                  if (context.mounted) {
                    context.pop();
                  }
                }
              },
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete Hackathon',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Image
            if (hackathon.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  hackathon.imageUrl!,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 64,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            
            // Title and Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    hackathon.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                StatusBadge(status: hackathon.status),
              ],
            ),
            const SizedBox(height: 20),
            
            // Info Sections
            _InfoSection(
              icon: Icons.description_rounded,
              label: 'Description',
              value: hackathon.description,
            ),
            _InfoSection(
              icon: Icons.location_on_rounded,
              label: 'Venue',
              value: hackathon.venue,
            ),
            _InfoSection(
              icon: Icons.calendar_today_rounded,
              label: 'Start Date',
              value: hackathon.startDate.formattedDateTime,
            ),
            _InfoSection(
              icon: Icons.calendar_today_rounded,
              label: 'End Date',
              value: hackathon.endDate.formattedDateTime,
            ),
            _InfoSection(
              icon: Icons.event_available_rounded,
              label: 'Registration Deadline',
              value: hackathon.registrationDeadline.formattedDateTime,
            ),
            _InfoSection(
              icon: Icons.group_rounded,
              label: 'Team Size',
              value: '${hackathon.minTeamSize}-${hackathon.maxTeamSize} members',
            ),
            
            // Registration Form URL
            _InfoSection(
              icon: Icons.link_rounded,
              label: 'Registration Form',
              value: hackathon.registrationFormUrl.isNotEmpty
                  ? hackathon.registrationFormUrl
                  : 'No form URL provided',
            ),
            
            // Prizes
            if (hackathon.prizes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prizes',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...hackathon.prizes.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryGreen.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: AppColors.secondaryGreen,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(entry.value),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
            
            // Rules
            if ((hackathon.rules ?? const <String>[]).isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rules',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...hackathon.rules!.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: AppColors.info,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(entry.value),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hackathon?'),
        content: Text(
          "This will hide '${hackathon.title}' from all students. Registered teams will not be affected.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoSection({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
