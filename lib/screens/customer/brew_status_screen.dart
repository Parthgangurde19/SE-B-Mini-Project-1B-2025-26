import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';

class BrewStatusScreen extends StatefulWidget {
  final String orderId;
  final String orderNumber;
  final bool isFreeRedemption;

  const BrewStatusScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    this.isFreeRedemption = false,
  });

  static Future<void> show(BuildContext context, {
    required String orderId,
    required String orderNumber,
    bool isFreeRedemption = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BrewStatusScreen(
        orderId: orderId,
        orderNumber: orderNumber,
        isFreeRedemption: isFreeRedemption,
      ),
    );
  }

  @override
  State<BrewStatusScreen> createState() => _BrewStatusScreenState();
}

class _BrewStatusScreenState extends State<BrewStatusScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  String _prevStatus = '';

  static const _steps = ['received', 'ready'];
  static const _stepLabels = [
    'Order Received',
    'Ready for Pickup',
  ];
  static const _stepIcons = [
    Icons.receipt_long_rounded,
    Icons.check_circle_rounded,
  ];
  static const _stepDesc = [
    'Your order is confirmed',
    'Come grab your coffee!',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseService.instance.streamOrderById(widget.orderId),
      builder: (context, snapshot) {
        String brewStatus = 'received';
        if (snapshot.hasData && snapshot.data!.exists) {
          brewStatus = snapshot.data!.data()?['brewStatus'] as String? ?? 'received';
        }

        // Haptic + animation when status advances
        if (_prevStatus != brewStatus && _prevStatus.isNotEmpty) {
          if (brewStatus == 'ready') {
            HapticFeedback.heavyImpact();
          } else {
            HapticFeedback.mediumImpact();
          }
        }
        _prevStatus = brewStatus;

        final stepIndex = _steps.indexOf(brewStatus).clamp(0, 1);
        final isDone = brewStatus == 'ready';

        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.55,
          maxChildSize: 0.85,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1210),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: colorScheme.primary.withAlpha(60), width: 1),
              ),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Order number
                Center(
                  child: Text(
                    widget.orderNumber,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withAlpha(120),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: widget.isFreeRedemption
                      ? Text(
                          isDone ? 'Your reward is ready! ☕' : 'Your reward is brewing!',
                          style: GoogleFonts.pacifico(
                            fontSize: 20,
                            color: isDone
                                ? const Color(0xFFB8860B)
                                : const Color(0xFFD4A574),
                          ),
                        )
                      : Text(
                          isDone ? 'Ready for Pickup! ☕' : 'Your order is being prepared',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDone ? colorScheme.primary : colorScheme.onSurface,
                          ),
                        ),
                ),
                const SizedBox(height: 32),

                // Stepper
                ...List.generate(_steps.length, (i) {
                  final isActive = i == stepIndex;
                  final isCompleted = i < stepIndex || isDone;
                  final isFuture = i > stepIndex && !isDone;

                  return _StepTile(
                    icon: _stepIcons[i],
                    label: _stepLabels[i],
                    description: _stepDesc[i],
                    isActive: isActive,
                    isCompleted: isCompleted,
                    isFuture: isFuture,
                    isLast: i == _steps.length - 1,
                    pulseAnim: isActive ? _pulseAnim : null,
                  );
                }),

                const SizedBox(height: 24),

                if (isDone)
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Got it!'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Track Later'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StepTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isActive;
  final bool isCompleted;
  final bool isFuture;
  final bool isLast;
  final Animation<double>? pulseAnim;

  const _StepTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.isActive,
    required this.isCompleted,
    required this.isFuture,
    required this.isLast,
    this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color iconColor = isCompleted
        ? colorScheme.primary
        : isActive
            ? colorScheme.primary
            : colorScheme.onSurface.withAlpha(40);
    final Color textColor = isFuture
        ? colorScheme.onSurface.withAlpha(60)
        : colorScheme.onSurface;

    Widget iconWidget = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? colorScheme.primary.withAlpha(30)
            : isActive
                ? colorScheme.primary.withAlpha(20)
                : colorScheme.surfaceContainerHighest.withAlpha(60),
        border: Border.all(
          color: isCompleted || isActive
              ? colorScheme.primary
              : colorScheme.onSurface.withAlpha(30),
          width: isActive ? 2.0 : 1.0,
        ),
      ),
      child: Icon(
        isCompleted ? Icons.check_rounded : icon,
        color: iconColor,
        size: 22,
      ),
    );

    if (isActive && pulseAnim != null) {
      iconWidget = ScaleTransition(scale: pulseAnim!, child: iconWidget);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              iconWidget,
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: isCompleted
                      ? colorScheme.primary.withAlpha(80)
                      : colorScheme.onSurface.withAlpha(20),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isFuture
                          ? colorScheme.onSurface.withAlpha(40)
                          : colorScheme.onSurface.withAlpha(120),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
