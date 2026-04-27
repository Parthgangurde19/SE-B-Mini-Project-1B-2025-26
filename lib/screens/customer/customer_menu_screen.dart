import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/menu_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/brew_animation_overlay.dart';
import 'brew_status_screen.dart';
import 'payment_screen.dart';
import 'package:intl/intl.dart';

class CustomerMenuScreen extends StatefulWidget {
  const CustomerMenuScreen({super.key});

  @override
  State<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
}

class _CustomerMenuScreenState extends State<CustomerMenuScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<MenuProvider>().loadItems();
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<OrderProvider>().loadMostOrderedItem(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final orderProvider = context.watch<OrderProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    final categories = ['All', ...menuProvider.categories];
    final filteredItems = menuProvider.availableItems.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    // Build store options list
    final storeOptions = <Map<String, String?>>[
      {'id': null, 'name': 'Crema'},
      ...menuProvider.storeMenus.map((m) => {'id': m['id'], 'name': m['name']}),
    ];
    final hasMultipleStores = storeOptions.length > 1;

    return Scaffold(
      body: Column(
        children: [
          // Welcome header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '☕ Welcome!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'What would you like to order?',
                        style: TextStyle(color: colorScheme.onSurface.withAlpha(150), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Store switcher — only shown when imported stores exist
                if (hasMultipleStores)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(80),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.primary.withAlpha(60)),
                    ),
                    child: DropdownButton<String?>(
                      value: menuProvider.selectedStoreId,
                      underline: const SizedBox(),
                      dropdownColor: const Color(0xFF2C1A12),
                      icon: const Icon(Icons.storefront_rounded, size: 16),
                      style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                      items: storeOptions
                          .map((s) => DropdownMenuItem<String?>(
                                value: s['id'],
                                child: Text(
                                  s['name'] ?? 'Unknown',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 13,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (id) {
                        setState(() => _selectedCategory = 'All');
                        context.read<MenuProvider>().selectStore(id);
                      },
                    ),
                  ),
              ],
            ),
          ),

          // "Your Usual" Banner
          if (orderProvider.mostOrderedItem != null)
            _YourUsualBanner(
              itemData: orderProvider.mostOrderedItem!,
              menuProvider: menuProvider,
              orderProvider: orderProvider,
            ),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search coffee, snacks...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withAlpha(80),
              ),
            ),
          ),

          // Category Chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = categories[i];
                final isSelected = cat == _selectedCategory;
                return FilterChip(
                  selected: isSelected,
                  label: Text(cat),
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  selectedColor: colorScheme.primaryContainer,
                  showCheckmark: false,
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Menu Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.80,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredItems.length,
              itemBuilder: (_, i) {
                final item = filteredItems[i];
                final inCart = orderProvider.cart.where((c) => c.menuItemId == item.id);
                final qty = inCart.isNotEmpty ? inCart.first.quantity : 0;

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    orderProvider.addToCart(item);
                    if (item.category != 'Snacks') {
                      BrewAnimationOverlay.show(context);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: qty > 0
                          ? colorScheme.primaryContainer.withAlpha(80)
                          : colorScheme.surfaceContainerHighest.withAlpha(100),
                      border: qty > 0 ? Border.all(color: colorScheme.primary, width: 2) : null,
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        item.iconName.endsWith('.png')
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/images/${item.iconName}',
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                item.iconName == 'bakery_dining'
                                    ? Icons.bakery_dining
                                    : Icons.coffee_rounded,
                                size: 36,
                                color: colorScheme.primary,
                              ),
                        const SizedBox(height: 8),
                        Text(
                          item.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(item.price),
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        if (qty > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _QtyBtn(
                                icon: Icons.remove,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  orderProvider.updateCartItemQty(item.id!, qty - 1);
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  qty.toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              _QtyBtn(
                                icon: Icons.add,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  orderProvider.updateCartItemQty(item.id!, qty + 1);
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Bottom Cart Bar
      bottomSheet: orderProvider.cart.isNotEmpty
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 16, offset: const Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${orderProvider.cartItemCount} items',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer.withAlpha(180),
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            currencyFormat.format(orderProvider.cartTotal),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _showPaymentAndOrder(context),
                      icon: const Icon(Icons.payment_rounded),
                      label: const Text('Confirm Order'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  // ── Step 1: open Payment sheet ──────────────────────────────────
  Future<void> _showPaymentAndOrder(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final orderProvider = context.read<OrderProvider>();

    final result = await PaymentScreen.show(
      context,
      cartItems: List.from(orderProvider.cart),
      cartTotal: orderProvider.cartTotal,
    );

    // User dismissed without paying
    if (result == null || !context.mounted) return;

    await _placeOrder(
      context,
      discountAmount: result.discountAmount,
      couponCode: result.couponCode,
      paymentMethod: result.paymentMethod,
    );
  }

  // ── Step 2: submit order to Firestore ────────────────────────────
  Future<void> _placeOrder(
    BuildContext context, {
    double discountAmount = 0,
    String? couponCode,
    String? paymentMethod,
  }) async {
    final orderProvider = context.read<OrderProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    final (docId, order) = await orderProvider.placeOrder(
      userId: userId,
      isCustomerOrder: true,
      discountAmount: discountAmount,
      couponCode: couponCode,
      paymentMethod: paymentMethod,
    );

    if (context.mounted) {
      context.read<InventoryProvider>().loadItems();
      context.read<ReportProvider>().loadReports();
      await authProvider.refreshUser();
      if (userId != null) {
        orderProvider.loadMostOrderedItem(userId);
      }
    }

    if (!context.mounted) return;

    if (order.status == 'pending') {
      await BrewStatusScreen.show(
        context,
        orderId: docId,
        orderNumber: order.orderNumber,
      );
    } else {
      final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green.shade400, size: 28),
              const SizedBox(width: 8),
              const Expanded(child: Text('Order Placed!', overflow: TextOverflow.ellipsis)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order: ${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w600)),
              const Divider(),
              ...order.items.map((i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('${i.name} × ${i.quantity}')),
                        Text(currencyFormat.format(i.subtotal)),
                      ],
                    ),
                  )),
              const Divider(),
              if (order.discountAmount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.local_offer_rounded, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(order.couponCode ?? 'Coupon',
                            style: const TextStyle(color: Colors.green, fontSize: 13)),
                      ]),
                      Text('- ${currencyFormat.format(order.discountAmount)}',
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    currencyFormat.format(order.totalAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (order.paymentMethod != null) ...
                [const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.payment_rounded, size: 14),
                    const SizedBox(width: 4),
                    Text('Paid via ${order.paymentMethod}',
                        style: const TextStyle(fontSize: 13)),
                  ],
                )],
            ],
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
          ],
        ),
      );
    }
  }
}

/// "Your Usual" one-tap reorder banner
class _YourUsualBanner extends StatelessWidget {
  final Map<String, dynamic> itemData;
  final MenuProvider menuProvider;
  final OrderProvider orderProvider;

  const _YourUsualBanner({
    required this.itemData,
    required this.menuProvider,
    required this.orderProvider,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final menuItemId = itemData['menuItemId'] as String?;
    final name = itemData['name'] as String? ?? 'Your Usual';

    // Find the live MenuItem from the provider
    final menuItem = menuProvider.items
        .where((m) => m.id == menuItemId)
        .firstOrNull;

    if (menuItem == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          orderProvider.addToCart(menuItem);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name added to cart ☕'),
              duration: const Duration(seconds: 2),
              backgroundColor: colorScheme.primaryContainer,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer.withAlpha(200),
                colorScheme.primary.withAlpha(40),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.primary.withAlpha(60)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.replay_rounded, size: 18, color: Color(0xFFD4A574)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Usual',
                      style: TextStyle(fontSize: 11, color: Color(0xFFD4A574), fontWeight: FontWeight.w600, letterSpacing: 0.5),
                    ),
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Text(
                currencyFormat.format(menuItem.price),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('+ Add', style: TextStyle(color: Color(0xFF2C1A12), fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withAlpha(40),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
