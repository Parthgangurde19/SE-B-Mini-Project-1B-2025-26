import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory_item.dart';
import 'package:intl/intl.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<InventoryProvider>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (inventoryProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Low Stock Banner
        if (inventoryProvider.lowStockItems.isNotEmpty)
          _LowStockBanner(items: inventoryProvider.lowStockItems),

        // Summary Card

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primaryContainer, colorScheme.primary.withAlpha(60)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventory Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${inventoryProvider.items.length} items tracked',
                      style: TextStyle(color: colorScheme.onPrimaryContainer.withAlpha(180)),
                    ),
                  ],
                ),
              ),
              if (inventoryProvider.lowStockItems.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '${inventoryProvider.lowStockItems.length} Low',
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Inventory List
        ...inventoryProvider.items.map((item) => _InventoryCard(item: item)),
      ],
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final InventoryItem item;

  const _InventoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stockRatio = item.minStock > 0
        ? (item.currentStock / (item.minStock * 5)).clamp(0.0, 1.0)
        : 1.0;
    final stockColor = item.isLowStock ? Colors.red : (stockRatio < 0.4 ? Colors.orange : Colors.green);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: stockColor.withAlpha(40),
                  radius: 22,
                  child: Icon(
                    _getIcon(item.name),
                    color: stockColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        '${item.currentStock.toStringAsFixed(1)} ${item.unit} available',
                        style: TextStyle(
                          color: stockColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (item.isLowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(40),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'LOW STOCK',
                          style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Min: ${item.minStock.toStringAsFixed(1)} ${item.unit}',
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withAlpha(120)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Stock Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: stockRatio,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(stockColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (item.lastRestocked != null)
                  Text(
                    'Last restocked: ${DateFormat('MMM dd').format(item.lastRestocked!)}',
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withAlpha(100)),
                  )
                else
                  const SizedBox(),
                FilledButton.tonalIcon(
                  onPressed: () => _showRestockDialog(context, item),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Restock', style: TextStyle(fontSize: 13)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRestockDialog(BuildContext context, InventoryItem item) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restock ${item.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Amount (${item.unit})',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.inventory_2_rounded),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(ctrl.text) ?? 0;
              if (amount > 0) {
                context.read<InventoryProvider>().restockItem(item, amount);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Restock'),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('coffee') || lower.contains('bean')) return Icons.coffee_rounded;
    if (lower.contains('milk')) return Icons.water_drop_rounded;
    if (lower.contains('sugar')) return Icons.grain_rounded;
    if (lower.contains('cup')) return Icons.local_cafe_rounded;
    if (lower.contains('syrup') || lower.contains('chocolate')) return Icons.water_rounded;
    return Icons.inventory_2_rounded;
  }
}

class _LowStockBanner extends StatefulWidget {
  final List<InventoryItem> items;
  const _LowStockBanner({required this.items});

  @override
  State<_LowStockBanner> createState() => _LowStockBannerState();
}

class _LowStockBannerState extends State<_LowStockBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
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
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade300, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${widget.items.length} item${widget.items.length > 1 ? 's' : ''} need restocking',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade300, fontSize: 14),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: Colors.red.shade300),
                onPressed: () => setState(() => _dismissed = true),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: Colors.red.shade300),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item.name}: ${item.currentStock.toStringAsFixed(1)} ${item.unit} (min ${item.minStock.toStringAsFixed(1)} ${item.unit})',
                        style: TextStyle(fontSize: 12, color: Colors.red.shade200),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

