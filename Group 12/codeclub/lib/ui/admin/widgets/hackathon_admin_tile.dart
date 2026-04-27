import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/hackathon_model.dart';
import 'status_badge.dart';

class HackathonAdminTile extends StatelessWidget {
  final HackathonModel hackathon;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<HackathonStatus> onStatusChange;

  const HackathonAdminTile({
    super.key,
    required this.hackathon,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image/Icon
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: hackathon.imageUrl != null
                      ? Image.network(
                          hackathon.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hackathon.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hackathon.venue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hackathon.startDate.formattedDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Status Badge and Menu
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(status: hackathon.status),
                  const SizedBox(height: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      } else {
                        onStatusChange(hackathonStatusFromString(value));
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: 'published', child: Text('Mark Published')),
                      const PopupMenuItem(value: 'ongoing', child: Text('Mark Ongoing')),
                      const PopupMenuItem(value: 'completed', child: Text('Mark Completed')),
                      const PopupMenuItem(value: 'cancelled', child: Text('Mark Cancelled')),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
