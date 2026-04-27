import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/application_model.dart';

/// Screen for students to view their hackathon application status
class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  List<ApplicationModel> _apps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadApps());
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);
    // Application tracking is disabled in the direct Google Form flow.
    _apps = <ApplicationModel>[];
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _apps.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 56, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text('Applications are now submitted via Google Forms.',
                          style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadApps,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _apps.length,
                    itemBuilder: (context, index) {
                      return _MyApplicationCard(application: _apps[index])
                          .animate()
                          .fadeIn(
                            duration: 350.ms,
                            delay: Duration(
                                milliseconds: 40 * index.clamp(0, 15)),
                          );
                    },
                  ),
                ),
    );
  }
}

class _MyApplicationCard extends StatelessWidget {
  final ApplicationModel application;

  const _MyApplicationCard({required this.application});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = switch (application.status) {
      ApplicationStatus.pending => AppColors.accentOrange,
      ApplicationStatus.approved => AppColors.secondaryGreen,
      ApplicationStatus.rejected => AppColors.error,
    };
    final statusIcon = switch (application.status) {
      ApplicationStatus.pending => Icons.hourglass_top_rounded,
      ApplicationStatus.approved => Icons.check_circle_rounded,
      ApplicationStatus.rejected => Icons.cancel_rounded,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hackathon Application',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      Text(
                        'Applied: ${_fmt(application.appliedAt)}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    application.statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (application.isTeamApplication) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.groups_outlined,
                      size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    'Team application${application.teamName != null ? ': ${application.teamName}' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
            if (application.remarks != null &&
                application.remarks!.isNotEmpty) ...[
              const Divider(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.message_outlined,
                      size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      application.remarks!,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
