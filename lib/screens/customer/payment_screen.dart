import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../services/firebase_service.dart';

/// Result returned when the customer taps "Pay Now".
class PaymentResult {
  final double discountAmount;
  final String? couponCode;
  final String paymentMethod;

  const PaymentResult({
    required this.discountAmount,
    required this.couponCode,
    required this.paymentMethod,
  });
}

/// Full-screen payment bottom-sheet.
/// Shows order summary → coupon field → payment method → "Pay Now".
/// Returns a [PaymentResult] on success, null if dismissed.
class PaymentScreen extends StatefulWidget {
  final List<OrderItem> cartItems;
  final double cartTotal;

  const PaymentScreen({
    super.key,
    required this.cartItems,
    required this.cartTotal,
  });

  /// Convenience method: push as a modal bottom sheet and await the result.
  static Future<PaymentResult?> show(
    BuildContext context, {
    required List<OrderItem> cartItems,
    required double cartTotal,
  }) {
    return showModalBottomSheet<PaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentScreen(
        cartItems: cartItems,
        cartTotal: cartTotal,
      ),
    );
  }

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _couponCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _paymentMethod = 'Cash'; // default
  bool _validatingCoupon = false;
  bool _couponApplied = false;
  String? _couponError;
  double _discountAmount = 0;
  String _couponDescription = '';

  static const _paymentMethods = ['Cash', 'UPI', 'Card'];

  double get _finalTotal =>
      (widget.cartTotal - _discountAmount).clamp(0, double.infinity);

  final _currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _validatingCoupon = true;
      _couponError = null;
      _couponApplied = false;
      _discountAmount = 0;
    });

    final result = await FirebaseService.instance.validateCoupon(code);

    if (!mounted) return;

    if (result['valid'] == true) {
      final type = result['discountType'] as String;
      final value = (result['discountValue'] as num).toDouble();
      final discount = type == 'percent'
          ? (widget.cartTotal * value / 100)
          : value;

      setState(() {
        _discountAmount = discount.clamp(0, widget.cartTotal);
        _couponApplied = true;
        _couponDescription = result['description'] as String;
        _validatingCoupon = false;
      });
    } else {
      setState(() {
        _couponError = result['reason'] as String? ?? 'Invalid coupon code';
        _validatingCoupon = false;
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _couponApplied = false;
      _discountAmount = 0;
      _couponDescription = '';
      _couponError = null;
      _couponCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.payment_rounded, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    'Payment',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable body
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Order Summary ──────────────────────────────
                  _SectionTitle('Order Summary'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(60),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        ...widget.cartItems.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.name} × ${item.quantity}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    _currency.format(item.subtotal),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            )),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 15)),
                            Text(_currency.format(widget.cartTotal),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 15)),
                          ],
                        ),
                        if (_couponApplied) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                const Icon(Icons.local_offer_rounded,
                                    size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  _couponDescription,
                                  style: const TextStyle(
                                      color: Colors.green, fontSize: 13),
                                ),
                              ]),
                              Text(
                                '- ${_currency.format(_discountAmount)}',
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Payable',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text(
                                _currency.format(_finalTotal),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: colorScheme.primary),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Coupon ────────────────────────────────────
                  _SectionTitle('Coupon Code'),
                  const SizedBox(height: 8),
                  if (!_couponApplied)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'Enter coupon code',
                              prefixIcon:
                                  const Icon(Icons.local_offer_rounded),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              errorText: _couponError,
                            ),
                            onSubmitted: (_) => _applyCoupon(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed:
                              _validatingCoupon ? null : _applyCoupon,
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                colorScheme.primaryContainer,
                            foregroundColor:
                                colorScheme.onPrimaryContainer,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _validatingCoupon
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Text('Apply',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  else
                    // Coupon applied chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(25),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: Colors.green.withAlpha(100)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _couponCtrl.text.toUpperCase(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green),
                                ),
                                Text(
                                  'Saves ${_currency.format(_discountAmount)}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _removeCoupon,
                            child: const Text('Remove',
                                style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ── Payment Method ────────────────────────────
                  _SectionTitle('Payment Method'),
                  const SizedBox(height: 10),
                  Row(
                    children: _paymentMethods.map((method) {
                      final selected = _paymentMethod == method;
                      IconData icon;
                      switch (method) {
                        case 'UPI':
                          icon = Icons.qr_code_rounded;
                        case 'Card':
                          icon = Icons.credit_card_rounded;
                        default:
                          icon = Icons.payments_rounded;
                      }
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _paymentMethod = method),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin:
                                const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            decoration: BoxDecoration(
                              color: selected
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHighest
                                      .withAlpha(60),
                              borderRadius: BorderRadius.circular(16),
                              border: selected
                                  ? Border.all(
                                      color: colorScheme.primary,
                                      width: 2)
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Icon(icon,
                                    color: selected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface
                                            .withAlpha(140),
                                    size: 28),
                                const SizedBox(height: 6),
                                Text(
                                  method,
                                  style: TextStyle(
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: selected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface
                                            .withAlpha(180),
                                    fontSize: 13,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),

            // ── Pay Now sticky footer ──────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                    top: BorderSide(
                        color: colorScheme.outline.withAlpha(40))),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 10,
                      offset: const Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    PaymentResult(
                      discountAmount: _discountAmount,
                      couponCode:
                          _couponApplied ? _couponCtrl.text.trim().toUpperCase() : null,
                      paymentMethod: _paymentMethod,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    textStyle: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('Pay Now  •  ${_currency.format(_finalTotal)}'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
        letterSpacing: 0.3,
      ),
    );
  }
}
