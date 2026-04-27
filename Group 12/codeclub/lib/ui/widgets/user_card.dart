import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../data/models/user_model.dart';

/// User profile card widget
class UserProfileCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final VoidCallback? onMessageTap;
  final bool showActions;
  final bool isCompact;

  const UserProfileCard({
    super.key,
    required this.user,
    this.onTap,
    this.onMessageTap,
    this.showActions = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 16,
        vertical: isCompact ? 4 : 8,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: isCompact ? 24 : 32,
                    backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                    backgroundImage: user.profileImageUrl != null
                      ? CachedNetworkImageProvider(user.profileImageUrl!)
                        : null,
                    child: user.profileImageUrl == null
                        ? Text(
                            user.fullName.initials,
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: isCompact ? 16 : 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Name and role
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _RoleBadge(role: user.role),
                            const SizedBox(width: 8),
                            Text(
                              user.year,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  if (showActions) ...[
                    if (onMessageTap != null)
                      IconButton(
                        icon: Icon(
                          Icons.message_rounded,
                          color: isDark
                              ? AppColors.primaryBlueLight
                              : AppColors.primaryBlue,
                        ),
                        onPressed: onMessageTap,
                      ),
                  ],
                ],
              ),
              if (!isCompact) ...[
                const SizedBox(height: 12),
                // Branch
                Row(
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 16,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        user.branch,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Skills
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: user.skills.take(5).map((skill) {
                    return _SkillChip(skill: skill);
                  }).toList(),
                ),
                if (user.skills.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '+${user.skills.length - 5} more',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
    // Removed per-item animations - they create excessive AnimationControllers
    // when used in ListView.builder, causing performance issues.
    // Consider using flutter_staggered_animations at the list level instead
    // for smoother list animations.
  }
}

/// Role badge widget
class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  Color get _color {
    switch (role.toLowerCase()) {
      case 'developer':
        return AppColors.primaryBlue;
      case 'designer':
        return Colors.purple;
      case 'ml engineer':
        return Colors.orange;
      case 'team leader':
        return AppColors.secondaryGreen;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Skill chip widget
class _SkillChip extends StatelessWidget {
  final String skill;

  const _SkillChip({required this.skill});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryBlue.withValues(alpha: 0.2)
            : AppColors.primaryBlueLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.primaryBlueLight : AppColors.primaryBlue,
        ),
      ),
    );
  }
}

/// User avatar with status
class UserAvatar extends StatelessWidget {
  final UserModel? user;
  final double radius;
  final bool showStatus;
  final bool isOnline;

  const UserAvatar({
    super.key,
    this.user,
    this.radius = 24,
    this.showStatus = false,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
          backgroundImage: user?.profileImageUrl != null
              ? CachedNetworkImageProvider(user!.profileImageUrl!)
              : null,
          child: user?.profileImageUrl == null
              ? Text(
                  user?.fullName.initials ?? '?',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: radius * 0.7,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        if (showStatus)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.4,
              height: radius * 0.4,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.secondaryGreenLight : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
