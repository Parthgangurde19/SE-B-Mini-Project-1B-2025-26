import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/ai_mentor_theme.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AIMentorTheme.aiBubble(context),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(
              color: AIMentorTheme.primaryBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              _dot(AIMentorTheme.accentGreen, 0.ms),
              const SizedBox(width: 5),
              _dot(AIMentorTheme.primaryBlue, 200.ms),
              const SizedBox(width: 5),
              _dot(AIMentorTheme.accentGreen, 400.ms),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dot(Color color, Duration delay) {
    return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
          delay: delay,
          duration: 600.ms,
          begin: const Offset(1, 1),
          end: const Offset(1.5, 1.5),
          curve: Curves.easeInOut,
        )
        .then()
        .scale(
          duration: 600.ms,
          begin: const Offset(1.5, 1.5),
          end: const Offset(1, 1),
        );
  }
}
