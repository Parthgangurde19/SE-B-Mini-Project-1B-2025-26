import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/report_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/order_provider.dart';
import '../services/firebase_service.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ReportProvider>().loadReports();
      context.read<InventoryProvider>().loadItems();
      // Subscribe to real-time order stream (no userId = admin sees all orders)
      context.read<OrderProvider>().subscribeToOrders();
    });
  }

  @override
  void dispose() {
    context.read<OrderProvider>().unsubscribeFromOrders();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final report = context.watch<ReportProvider>();
    final inventory = context.watch<InventoryProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        await report.loadReports();
        await inventory.loadItems();
        // Orders are already live; just refresh reports & inventory
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Greeting
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '☕ Good ${_greeting()}!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                "Here's your coffee shop summary",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withAlpha(153),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sprint 0: Error Banner
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseService.instance.streamUnresolvedErrors(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox.shrink();
              // Sort newest-first in memory (avoids composite index requirement)
              final errors = [...snap.data!.docs]
                ..sort((a, b) {
                  final aTs = a.data()['timestamp'] as String? ?? '';
                  final bTs = b.data()['timestamp'] as String? ?? '';
                  return bTs.compareTo(aTs);
                });
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withAlpha(60),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade700.withAlpha(120)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_rounded, color: Colors.red.shade300, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${errors.length} Unresolved Error${errors.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade300,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            try {
                              await FirebaseService.instance
                                  .resolveAllErrors(errors.map((e) => e.id).toList());
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Could not dismiss errors: $e'),
                                    backgroundColor: Colors.red.shade800,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Dismiss All', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    ...errors.take(3).map((e) {
                      final data = e.data();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '• Order ${data['orderId']} — ${data['errorType']}',
                          style: TextStyle(fontSize: 12, color: Colors.red.shade200),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),

          // Revenue Cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: "Today's Revenue",
                  value: currencyFormat.format(report.todayRevenue),
                  icon: Icons.monetization_on_rounded,
                  gradient: const [Color(0xFFD4A574), Color(0xFFB8860B)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: "Today's Orders",
                  value: report.todayOrders.toString(),
                  icon: Icons.receipt_long_rounded,
                  gradient: const [Color(0xFF8B6F47), Color(0xFF6B4226)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'This Week',
                  value: currencyFormat.format(report.weekRevenue),
                  icon: Icons.date_range_rounded,
                  gradient: const [Color(0xFF5C4033), Color(0xFF3E2723)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'This Month',
                  value: currencyFormat.format(report.monthRevenue),
                  icon: Icons.calendar_month_rounded,
                  gradient: const [Color(0xFF4E342E), Color(0xFF2C1A12)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Low Stock Alert
          if (inventory.lowStockItems.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade900.withAlpha(60),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade700.withAlpha(100)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade300, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Low Stock Alert',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade300,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...inventory.lowStockItems.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 6, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Text(
                              '${item.name}: ${item.currentStock.toStringAsFixed(1)} ${item.unit} remaining',
                              style: TextStyle(color: Colors.red.shade200),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],

          // Active Orders Queue (Sprint 1)
          if (orderProvider.activeOrders.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Active Orders',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${orderProvider.activeOrders.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...orderProvider.activeOrders.map(
              (order) => _ActiveOrderCard(order: order, orderProvider: orderProvider),
            ),
            const SizedBox(height: 20),
          ],

          // Recent Orders
          Text(
            'Recent Orders',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (orderProvider.orders.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.coffee_rounded, size: 48, color: colorScheme.onSurface.withAlpha(80)),
                    const SizedBox(height: 8),
                    Text(
                      'No orders yet. Start by placing an order!',
                      style: TextStyle(color: colorScheme.onSurface.withAlpha(128)),
                    ),
                  ],
                ),
              ),
            )
          else
            ...orderProvider.orders.take(5).map((order) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(Icons.receipt, color: colorScheme.onPrimaryContainer, size: 20),
                    ),
                    title: Text(order.orderNumber,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(
                      '${order.items.length} items • ${DateFormat('MMM dd, hh:mm a').format(order.createdAt)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      currencyFormat.format(order.totalAmount),
                      style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _ActiveOrderCard extends StatelessWidget {
  final dynamic order;
  final OrderProvider orderProvider;

  const _ActiveOrderCard({required this.order, required this.orderProvider});

  static const _brewSteps = ['received', 'ready'];
  static const _brewLabels = ['Received', 'Ready'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final currentStepIdx = _brewSteps.indexOf(order.brewStatus).clamp(0, 1);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.orderNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Text(
                  currencyFormat.format(order.totalAmount),
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              order.items.map((i) => '${i.name} ×${i.quantity}').join(', '),
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withAlpha(150)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Brew Status Selector
            Row(
              children: List.generate(_brewSteps.length, (i) {
                final isActive = i == currentStepIdx;
                final isCompleted = i < currentStepIdx;
                return Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      try {
                        final orderId = order.id ?? order.orderNumber;
                        await orderProvider.updateBrewStatus(orderId, _brewSteps[i]);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update status. Please try again.'),
                              backgroundColor: Colors.red.shade800,
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? colorScheme.primary
                            : isCompleted
                                ? colorScheme.primary.withAlpha(40)
                                : colorScheme.surfaceContainerHighest.withAlpha(60),
                        borderRadius: BorderRadius.circular(8),
                        border: isActive
                            ? null
                            : Border.all(color: colorScheme.onSurface.withAlpha(20)),
                      ),
                      child: Text(
                        _brewLabels[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive
                              ? const Color(0xFF2C1A12)
                              : isCompleted
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withAlpha(80),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: gradient.last.withAlpha(80), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withAlpha(200), size: 28),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(180))),
        ],
      ),
    );
  }
}
