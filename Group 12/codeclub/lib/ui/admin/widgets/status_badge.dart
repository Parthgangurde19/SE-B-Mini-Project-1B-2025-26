import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/hackathon_model.dart';

class StatusBadge extends StatelessWidget {
  final HackathonStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      HackathonStatus.draft => Colors.grey,
      HackathonStatus.published => AppColors.success,
      HackathonStatus.ongoing => AppColors.info,
      HackathonStatus.completed => AppColors.secondaryGreen,
      HackathonStatus.cancelled => AppColors.error,
    };

    final icon = switch (status) {
      HackathonStatus.draft => Icons.edit_rounded,
      HackathonStatus.published => Icons.check_circle_rounded,
      HackathonStatus.ongoing => Icons.play_circle_filled_rounded,
      HackathonStatus.completed => Icons.done_all_rounded,
      HackathonStatus.cancelled => Icons.cancel_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
