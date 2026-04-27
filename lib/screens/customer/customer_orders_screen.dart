import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/order.dart';
import 'brew_status_screen.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  // Track which free-redemption order IDs have already fired haptic so we
  // only trigger once per card appearance.
  final Set<String> _hapticFiredIds = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final userId = context.read<AuthProvider>().currentUser?.id;
      context.read<OrderProvider>().subscribeToOrders(userId: userId);
    });
  }

  @override
  void dispose() {
    context.read<OrderProvider>().unsubscribeFromOrders();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fire heavy haptic the first time a free-redemption card appears in list.
    final orders = context.watch<OrderProvider>().orders;
    for (final order in orders) {
      final key = order.id ?? order.orderNumber;
      if (order.isFreeRedemption && !_hapticFiredIds.contains(key)) {
        _hapticFiredIds.add(key);
        HapticFeedback.heavyImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final colorScheme = Theme.of(context).colorScheme;

    if (orderProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orderProvider.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.coffee_rounded, size: 64, color: colorScheme.onSurface.withAlpha(60)),
            const SizedBox(height: 12),
            Text('No orders yet',
                style: TextStyle(fontSize: 18, color: colorScheme.onSurface.withAlpha(120))),
            const SizedBox(height: 4),
            Text('Your orders will appear here',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withAlpha(80))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 400));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orderProvider.orders.length,
        itemBuilder: (context, index) {
          final order = orderProvider.orders[index];

          if (order.isFreeRedemption) {
            return _FreeDrinkCard(order: order, currencyFormat: currencyFormat);
          }

          return _StandardOrderCard(
            order: order,
            currencyFormat: currencyFormat,
            colorScheme: colorScheme,
          );
        },
      ),
    );
  }
}

// ─── Free Drink Card ──────────────────────────────────────────────────────────

class _FreeDrinkCard extends StatelessWidget {
  final Order order;
  final NumberFormat currencyFormat;

  const _FreeDrinkCard({required this.order, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final isActive = order.status == 'pending' && order.brewStatus != 'ready';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        // Override expansion tile colours so they respect the amber background
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: const Color(0xFFFFD700).withAlpha(30),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD700).withAlpha(50),
              border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
            ),
            child: const Center(
              child: Text('✦', style: TextStyle(fontSize: 18, color: Color(0xFFB8860B))),
            ),
          ),
          title: Text(
            '☕ Free Drink Redeemed!',
            style: GoogleFonts.pacifico(
              fontSize: 18,
              color: const Color(0xFFB8860B),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                order.items.isNotEmpty ? order.items.first.name : 'Reward Drink',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF795548),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                style: const TextStyle(fontSize: 11, color: Color(0xFFA1887F)),
              ),
            ],
          ),
          trailing: isActive
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withAlpha(60),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFB8860B).withAlpha(100)),
                  ),
                  child: Text(
                    _brewLabel(order.brewStatus),
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFFB8860B),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
              : null,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Divider(color: const Color(0xFFFFD700).withAlpha(120)),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.name} × ${item.quantity}',
                              style: const TextStyle(color: Color(0xFF5D4037)),
                            ),
                            Text(
                              item.unitPrice == 0 ? 'FREE' : currencyFormat.format(item.subtotal),
                              style: const TextStyle(
                                color: Color(0xFFB8860B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )),
                  Divider(color: const Color(0xFFFFD700).withAlpha(120)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
                      Text(
                        order.totalAmount == 0 ? 'FREE' : currencyFormat.format(order.totalAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB8860B)),
                      ),
                    ],
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => BrewStatusScreen.show(
                          context,
                          orderId: order.id ?? order.orderNumber,
                          orderNumber: order.orderNumber,
                          isFreeRedemption: true,
                        ),
                        icon: const Icon(Icons.local_cafe_rounded, size: 18),
                        label: const Text('Track Your Reward'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFB8860B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
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

  String _brewLabel(String brewStatus) {
    switch (brewStatus) {
      case 'received': return 'ORDER RECEIVED';
      case 'ready':    return 'READY';
      default:         return brewStatus.toUpperCase();
    }
  }
}

// ─── Standard Order Card ──────────────────────────────────────────────────────

class _StandardOrderCard extends StatelessWidget {
  final Order order;
  final NumberFormat currencyFormat;
  final ColorScheme colorScheme;

  const _StandardOrderCard({
    required this.order,
    required this.currencyFormat,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = order.status == 'pending' && order.brewStatus != 'ready';
    final brewLabel = _brewLabel(order.brewStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: isActive
                  ? colorScheme.primary.withAlpha(40)
                  : colorScheme.primaryContainer,
              child: Icon(
                isActive ? Icons.local_cafe_rounded : Icons.receipt,
                color: isActive ? colorScheme.primary : colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    order.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      brewLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withAlpha(150)),
            ),
            trailing: Text(
              currencyFormat.format(order.totalAmount),
              style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    const Divider(),
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item.name} × ${item.quantity}'),
                              Text(currencyFormat.format(item.subtotal)),
                            ],
                          ),
                        )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          currencyFormat.format(order.totalAmount),
                          style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                        ),
                      ],
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => BrewStatusScreen.show(
                            context,
                            orderId: order.id ?? order.orderNumber,
                            orderNumber: order.orderNumber,
                          ),
                          icon: const Icon(Icons.local_cafe_rounded, size: 18),
                          label: const Text('Track Order'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _brewLabel(String brewStatus) {
    switch (brewStatus) {
      case 'received': return 'ORDER RECEIVED';
      case 'ready':    return 'READY';
      default:         return brewStatus.toUpperCase();
    }
  }
}
