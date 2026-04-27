import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/menu_provider.dart';
import '../providers/order_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/report_provider.dart';
import '../widgets/brew_animation_overlay.dart';
import 'package:intl/intl.dart';

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<MenuProvider>().loadItems();
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

    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search menu items...',
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
              separatorBuilder: (context, index) => const SizedBox(width: 8),
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
                childAspectRatio: 0.9,
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
                      border: qty > 0
                          ? Border.all(color: colorScheme.primary, width: 2)
                          : null,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        item.iconName.endsWith('.png')
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset('assets/images/${item.iconName}', width: 60, height: 60, fit: BoxFit.cover),
                              )
                            : Icon(
                                item.iconName == 'bakery_dining' ? Icons.bakery_dining : Icons.coffee_rounded,
                                size: 40,
                                color: colorScheme.primary,
                              ),
                        const SizedBox(height: 10),
                        Text(
                          item.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(item.price),
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (qty > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _QtyButton(
                                icon: Icons.remove,
                                onTap: () => orderProvider.updateCartItemQty(item.id!, qty - 1),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  qty.toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              _QtyButton(
                                icon: Icons.add,
                                onTap: () => orderProvider.updateCartItemQty(item.id!, qty + 1),
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
                            style: TextStyle(color: colorScheme.onPrimaryContainer.withAlpha(180), fontSize: 13),
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
                      onPressed: () => _placeOrder(context),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Place Order'),
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

  Future<void> _placeOrder(BuildContext context) async {
    final orderProvider = context.read<OrderProvider>();
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    // Admin-placed orders are not customer orders (handled via isCustomerOrder: false)
    final (_, order) = await orderProvider.placeOrder(isCustomerOrder: false);

    if (context.mounted) {
      context.read<InventoryProvider>().loadItems();
      context.read<ReportProvider>().loadReports();
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green.shade400, size: 28),
            const SizedBox(width: 8),
            const Text('Order Placed!'),
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
                      Text('${i.name} × ${i.quantity}'),
                      Text(currencyFormat.format(i.subtotal)),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

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
        child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
