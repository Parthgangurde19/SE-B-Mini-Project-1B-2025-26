import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/hackathon_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/hackathon_provider.dart';
import '../../widgets/buttons.dart';

/// Hackathon detail screen
class HackathonDetailScreen extends StatelessWidget {
  final HackathonModel hackathon;

  const HackathonDetailScreen({super.key, required this.hackathon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    context.watch<AuthProvider>();
    final hackathonProvider = context.watch<HackathonProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background gradient
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                  ),
                  // Image overlay
                  if (hackathon.imageUrl != null)
                    Image.network(
                      hackathon.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  // Title
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatusBadge(hackathon: hackathon),
                        const SizedBox(height: 8),
                        Text(
                          hackathon.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info cards
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.calendar_today_rounded,
                          label: 'Start Date',
                          value: hackathon.startDate.formatDateShort,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.event_rounded,
                          label: 'End Date',
                          value: hackathon.endDate.formatDateShort,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.location_on_rounded,
                          label: 'Venue',
                          value: hackathon.venue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.groups_rounded,
                          label: 'Team Size',
                          value:
                              '${hackathon.minTeamSize}-${hackathon.maxTeamSize}',
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                  const SizedBox(height: 24),
                  // Registration deadline
                  Card(
                      margin: EdgeInsets.zero,
                      color: hackathon.isRegistrationOpen
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              hackathon.isRegistrationOpen
                                  ? Icons.timer_rounded
                                  : Icons.timer_off_rounded,
                              color: hackathon.isRegistrationOpen
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hackathon.isRegistrationOpen
                                        ? 'Registration Open'
                                        : 'Registration Closed',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: hackathon.isRegistrationOpen
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                  Text(
                                    'Deadline: ${hackathon.registrationDeadline.formatDateFull}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  const SizedBox(height: 24),
                  // Description
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                  const SizedBox(height: 12),
                  Text(
                    hackathon.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                  const SizedBox(height: 24),
                  // Prizes
                  if (hackathon.prizes.isNotEmpty) ...[                    Text(
                      'Prizes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
                    const SizedBox(height: 12),
                    ...hackathon.prizes.asMap().entries.map((entry) {
                      return _PrizeCard(
                        position: entry.key + 1,
                        prize: entry.value,
                      )
                          .animate(
                            delay: Duration(milliseconds: 400 + (entry.key * 50)),
                          )
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: -0.05, end: 0, duration: 400.ms);
                    }),
                    const SizedBox(height: 24),
                  ],
                  // Rules
                  if (hackathon.rules != null && hackathon.rules!.isNotEmpty) ...[
                    Text(
                      'Rules',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...hackathon.rules!.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primaryBlue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                  Card(
                    margin: EdgeInsets.zero,
                    color: AppColors.info.withValues(alpha: 0.1),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.info,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Registration is handled through the linked Google Form.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: hackathon.isRegistrationOpen
          ? Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Open apply screen that redirects to Google Form
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        '/hackathon-apply',
                        extra: hackathon,
                      ),
                      icon: const Icon(Icons.assignment_outlined, size: 18),
                      label: const Text('Apply'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Open Form',
                      onPressed: () => _openRegistrationForm(context),
                      isLoading: hackathonProvider.isLoading,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Future<void> _openRegistrationForm(BuildContext context) async {
    final formUrl = hackathon.registrationFormUrl.trim();
    if (formUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration form is not available for this hackathon.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final uri = Uri.tryParse(formUrl);
    final success = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!context.mounted || success) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open registration form URL.'),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final HackathonModel hackathon;

  const _StatusBadge({required this.hackathon});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    String text;

    if (hackathon.isOngoing) {
      bgColor = AppColors.success;
      text = 'Ongoing';
    } else if (hackathon.isUpcoming) {
      bgColor = AppColors.primaryBlue;
      text = 'Upcoming';
    } else {
      bgColor = AppColors.textSecondaryLight;
      text = 'Ended';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Info card widget
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primaryBlue,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// Prize card widget
class _PrizeCard extends StatelessWidget {
  final int position;
  final String prize;

  const _PrizeCard({
    required this.position,
    required this.prize,
  });

  Color get _color {
    switch (position) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.primaryBlue;
    }
  }

  String get _positionText {
    switch (position) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${position}th';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.emoji_events_rounded,
              color: _color,
              size: 24,
            ),
          ),
        ),
        title: Text(
          '$_positionText Place',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(prize),
      ),
    );
  }
}
