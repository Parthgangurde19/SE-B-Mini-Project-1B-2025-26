import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/loyalty_provider.dart';
import '../models/order.dart';

class LoyaltyCardWidget extends StatefulWidget {
  const LoyaltyCardWidget({super.key});

  @override
  State<LoyaltyCardWidget> createState() => _LoyaltyCardWidgetState();
}

class _LoyaltyCardWidgetState extends State<LoyaltyCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final loyalty = context.read<LoyaltyProvider>();
    final points = auth.loyaltyPoints;
    final maxRedeemable = points ~/ 10; // how many free coffees available
    final canRedeem = points >= 10;
    // Stamps show progress within the current cycle (remainder)
    final stampsEarned = (points % 10 == 0 && points > 0) ? 10 : points % 10;
    final remaining = canRedeem ? 0 : (10 - points).clamp(0, 10);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF3E2723), Color(0xFF5C4033), Color(0xFF8B6F47)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4A574).withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background texture dots
            Positioned.fill(
              child: CustomPaint(painter: _CardTexturePainter()),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.coffee_rounded, color: Color(0xFFD4A574), size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Crema Rewards',
                        style: TextStyle(
                          color: Color(0xFFD4A574),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      // Points badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4A574).withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD4A574).withAlpha(80)),
                        ),
                        child: Text(
                          '$points pts',
                          style: const TextStyle(
                            color: Color(0xFFD4A574),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      // Free coffees badge (only when redeemable)
                      if (canRedeem) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(50),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withAlpha(120)),
                          ),
                          child: Text(
                            '🎁 $maxRedeemable free',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stamp Grid — shows current cycle progress (0–10)
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(10, (i) {
                      final earned = i < stampsEarned;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.elasticOut,
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: earned
                              ? const Color(0xFFD4A574)
                              : Colors.white.withAlpha(15),
                          border: Border.all(
                            color: earned
                                ? const Color(0xFFD4A574)
                                : Colors.white.withAlpha(40),
                            width: 1.5,
                          ),
                          boxShadow: earned
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFD4A574).withAlpha(80),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.local_cafe_rounded,
                            size: 18,
                            color: earned
                                ? const Color(0xFF2C1A12)
                                : Colors.white.withAlpha(40),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Progress text
                  Text(
                    canRedeem
                        ? 'You have $maxRedeemable free ${maxRedeemable == 1 ? 'coffee' : 'coffees'} to redeem! ☕'
                        : '$remaining more ${remaining == 1 ? 'coffee' : 'coffees'} to earn a free drink!',
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 13,
                    ),
                  ),

                  // Claim Button — visible whenever points >= 10
                  if (canRedeem) ...[
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: _glowAnim,
                      builder: (_, child) => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4A574)
                                  .withAlpha((_glowAnim.value * 150).toInt()),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: loyalty.isRedeeming
                              ? null
                              : () => _showRedeemDialog(
                                    context,
                                    auth,
                                    loyalty,
                                    points,
                                    maxRedeemable,
                                  ),
                          icon: const Icon(Icons.redeem_rounded),
                          label: loyalty.isRedeeming
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Claim Free Coffee'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD4A574),
                            foregroundColor: const Color(0xFF2C1A12),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRedeemDialog(
    BuildContext context,
    AuthProvider auth,
    LoyaltyProvider loyalty,
    int points,
    int maxRedeemable,
  ) async {
    int selected = 1; // default selection

    final confirmed = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.redeem_rounded, color: Color(0xFFD4A574)),
              SizedBox(width: 10),
              Text('Redeem Points', style: TextStyle(color: Color(0xFFF5E6D3))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have $points points — enough for $maxRedeemable free ${maxRedeemable == 1 ? 'coffee' : 'coffees'}.',
                style: TextStyle(color: const Color(0xFFF5E6D3).withAlpha(200), fontSize: 13),
              ),
              const SizedBox(height: 20),
              const Text(
                'How many free coffees would you like to redeem?',
                style: TextStyle(color: Color(0xFFF5E6D3), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              // Stepper row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: selected > 1
                        ? () => setDialogState(() => selected--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: const Color(0xFFD4A574),
                    iconSize: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      Text(
                        '$selected',
                        style: const TextStyle(
                          color: Color(0xFFD4A574),
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '= ${selected * 10} pts',
                        style: TextStyle(
                          color: const Color(0xFFF5E6D3).withAlpha(160),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: selected < maxRedeemable
                        ? () => setDialogState(() => selected++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: const Color(0xFFD4A574),
                    iconSize: 32,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Remaining balance preview
              Center(
                child: Text(
                  'Remaining after: ${points - selected * 10} pts',
                  style: TextStyle(
                    color: const Color(0xFFF5E6D3).withAlpha(140),
                    fontSize: 12,
                  ),
                ),
              ),
              if (maxRedeemable > 1) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => setDialogState(() => selected = maxRedeemable),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD4A574)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Redeem All ($maxRedeemable coffees · ${maxRedeemable * 10} pts)',
                      style: const TextStyle(color: Color(0xFFD4A574), fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFFD4A574))),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD4A574),
                foregroundColor: const Color(0xFF2C1A12),
              ),
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == null || !context.mounted) return;

    final userId = auth.currentUser?.id;
    if (userId == null) return;

    final pointsToRedeem = confirmed * 10;
    final now = DateTime.now();
    final orderNumber =
        'RWD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';

    final rewardOrder = Order(
      userId: userId,
      orderNumber: orderNumber,
      items: [
        OrderItem(
          menuItemId: 'free_reward',
          name: confirmed == 1 ? 'Free Reward Drink' : 'Free Reward Drinks x$confirmed',
          quantity: confirmed,
          unitPrice: 0,
        ),
      ],
      totalAmount: 0,
      status: 'pending',
      brewStatus: 'received',
      isFreeRedemption: true,
      createdAt: now,
    );

    await loyalty.redeemFreeItem(userId, rewardOrder, pointsToRedeem: pointsToRedeem);
    await auth.refreshUser();

    if (context.mounted) {
      final msg = confirmed == 1
          ? '🎉 Free coffee redeemed! Show this to your barista.'
          : '🎉 $confirmed free coffees redeemed! Show this to your barista.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFF4E342E),
        ),
      );
    }
  }
}

class _CardTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(8)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CardTexturePainter oldDelegate) => false;
}
