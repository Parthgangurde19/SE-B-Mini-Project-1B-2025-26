import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/hackathon_model.dart';
import '../../../providers/auth_provider.dart';

/// Screen for students to apply via direct registration form
class HackathonApplyScreen extends StatefulWidget {
  final HackathonModel hackathon;

  const HackathonApplyScreen({super.key, required this.hackathon});

  @override
  State<HackathonApplyScreen> createState() => _HackathonApplyScreenState();
}

class _HackathonApplyScreenState extends State<HackathonApplyScreen> {
  bool _isOpening = false;

  Future<void> _submit() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) return;

    final formUrl = widget.hackathon.registrationFormUrl.trim();
    if (formUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration form is not available for this hackathon.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isOpening = true);
    final uri = Uri.tryParse(formUrl);
    var success = false;
    if (uri != null) {
      success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (mounted) {
      setState(() => _isOpening = false);
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opened registration form.')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open registration form URL.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Register for Hackathon')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Hackathon info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hackathon.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      '${_fmt(widget.hackathon.startDate)} — ${_fmt(widget.hackathon.endDate)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(widget.hackathon.venue,
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[500])),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.link_rounded,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      'Registration via Google Form',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // Applicant info
          Text('Your Details',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              child: Text(
                (user?.fullName.isNotEmpty ?? false)
                    ? user!.fullName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue),
              ),
            ),
            title: Text(user?.fullName ?? 'Student'),
            subtitle: Text(user?.email ?? ''),
            tileColor: isDark ? AppColors.cardDark : AppColors.cardLight,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),

          const SizedBox(height: 24),

          // Registration details
          Text('Registration Details',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.open_in_new_rounded),
            title: const Text('External Form Submission'),
            subtitle: const Text(
              'Tap below to open the hackathon Google Form and complete your registration.',
            ),
            tileColor: isDark ? AppColors.cardDark : AppColors.cardLight,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),

          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isOpening ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isOpening
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Open Registration Form',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
