import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/menu_provider.dart';
import '../models/menu_item.dart' as app;

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<MenuProvider>().loadItems();
    });
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    // All store options for the dropdown
    final storeOptions = <Map<String, String?>>[
      {'id': null, 'name': 'Crema (Default)'},
      ...menuProvider.storeMenus.map((m) => {'id': m['id'], 'name': m['name']}),
    ];
    final currentStoreId = menuProvider.selectedStoreId;

    return Scaffold(
      body: Column(
        children: [
          // ── Store switcher bar ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.store_rounded, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(80),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: colorScheme.primary.withAlpha(60)),
                    ),
                    child: DropdownButton<String?>(
                      value: currentStoreId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: const Color(0xFF2C1A12),
                      style: TextStyle(
                          color: colorScheme.onSurface, fontSize: 14),
                      items: storeOptions
                          .map((s) => DropdownMenuItem<String?>(
                                value: s['id'],
                                child: Text(
                                  s['name'] ?? 'Unknown',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight:
                                        s['id'] == currentStoreId
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (id) =>
                          context.read<MenuProvider>().selectStore(id),
                    ),
                  ),
                ),
                // Delete store button (hidden for Crema)
                if (currentStoreId != null) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Delete "${menuProvider.selectedStoreName}" menu',
                    child: IconButton(
                      icon:
                          const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                      onPressed: () => _confirmDeleteStore(context, menuProvider),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Item list ───────────────────────────────────────────
          Expanded(
            child: menuProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : menuProvider.items.isEmpty
                    ? const Center(child: Text('No menu items yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: menuProvider.items.length,
                        itemBuilder: (_, i) =>
                            _MenuItemCard(item: menuProvider.items[i]),
                      ),
          ),
        ],
      ),

      // ── FABs ────────────────────────────────────────────────────
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Import external store menu
          FloatingActionButton.extended(
            heroTag: 'import',
            onPressed: () => _showImportDialog(context),
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Import Store Menu'),
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: 12),
          // Add single item
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: menuProvider.isLoading
                ? null
                : () => _showItemDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  // ── Confirm delete entire store ────────────────────────────────
  void _confirmDeleteStore(BuildContext context, MenuProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Store Menu',
            style: TextStyle(color: Color(0xFFF5E6D3))),
        content: Text(
          'This will permanently delete "${provider.selectedStoreName}" and ALL its items. This cannot be undone.',
          style: const TextStyle(color: Color(0xFFF5E6D3)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFFD4A574)))),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteStoreMenu(provider.selectedStoreId!);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Import store menu dialog ───────────────────────────────────
  void _showImportDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final csvCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    List<app.MenuItem> _preview = [];
    int _skipped = 0;
    bool _parsed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          void parseCSV() {
            final lines = csvCtrl.text
                .split('\n')
                .map((l) => l.trim())
                .where((l) => l.isNotEmpty)
                .toList();

            final items = <app.MenuItem>[];
            int skipped = 0;
            // Skip header row if first cell is non-numeric
            final startIdx =
                (lines.isNotEmpty && !RegExp(r'^\d').hasMatch(lines.first))
                    ? 1
                    : 0;

            for (var i = startIdx; i < lines.length; i++) {
              final parts = lines[i].split(',').map((p) => p.trim()).toList();
              if (parts.length < 3) {
                skipped++;
                continue;
              }
              final name = parts[0];
              final category = parts[1].isEmpty ? 'Other' : parts[1];
              final price = double.tryParse(parts[2]);
              if (name.isEmpty || price == null || price <= 0) {
                skipped++;
                continue;
              }
              items.add(app.MenuItem(
                name: name,
                category: category,
                price: price,
                iconName:
                    category.toLowerCase() == 'snacks' ? 'bakery_dining' : 'coffee',
                isAvailable: true,
              ));
            }
            setS(() {
              _preview = items;
              _skipped = skipped;
              _parsed = true;
            });
          }

          return AlertDialog(
            title: Row(children: const [
              Icon(Icons.upload_file_rounded, color: Color(0xFFD4A574)),
              SizedBox(width: 10),
              Text('Import Store Menu',
                  style: TextStyle(color: Color(0xFFF5E6D3))),
            ]),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store name
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Store / Cafe Name *',
                          prefixIcon: Icon(Icons.storefront_rounded),
                          border: OutlineInputBorder(),
                          hintText: 'e.g. Yummigoes',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter a store name'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // CSV hint
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C1A12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CSV format (one item per line):\n'
                          'name, category, price\n'
                          'Masala Chai, Hot Drinks, 60\n'
                          'Samosa, Snacks, 30',
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Color(0xFFD4A574)),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // CSV input
                      TextFormField(
                        controller: csvCtrl,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: 'Paste CSV here',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 120),
                            child: Icon(Icons.table_rows_rounded),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Paste CSV data'
                            : null,
                        onChanged: (_) => setS(() => _parsed = false),
                      ),
                      const SizedBox(height: 10),

                      // Parse button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            parseCSV();
                          },
                          icon: const Icon(Icons.preview_rounded),
                          label: const Text('Preview Parsed Items'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD4A574)),
                            foregroundColor: const Color(0xFFD4A574),
                          ),
                        ),
                      ),

                      // Preview
                      if (_parsed) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.green.withAlpha(80)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '✅ ${_preview.length} items ready to import'
                                '${_skipped > 0 ? '  ⚠ $_skipped skipped' : ''}',
                                style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (_preview.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                // Show first 5 as a table preview
                                ..._preview.take(5).map((item) => Padding(
                                      padding:
                                          const EdgeInsets.only(top: 3),
                                      child: Text(
                                        '• ${item.name}  |  ${item.category}  |  ₹${item.price.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFF5E6D3)),
                                      ),
                                    )),
                                if (_preview.length > 5)
                                  Text(
                                    '  … and ${_preview.length - 5} more',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFD4A574)),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: Color(0xFFD4A574))),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD4A574),
                    foregroundColor: const Color(0xFF2C1A12)),
                onPressed: (!_parsed || _preview.isEmpty)
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        context.read<MenuProvider>().createStoreMenu(
                              nameCtrl.text.trim(),
                              _preview,
                            );
                      },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Import',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Add / Edit single item dialog ──────────────────────────────
  void _showItemDialog(BuildContext context, {app.MenuItem? item}) {
    final nameCtrl =
        TextEditingController(text: item?.name ?? '');
    final priceCtrl = TextEditingController(
        text: item?.price.toStringAsFixed(0) ?? '');
    String category = item?.category ?? 'Espresso';
    final categories = ['Espresso', 'Latte', 'Cold', 'Snacks', 'Other'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Add Menu Item' : 'Edit Menu Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.coffee_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue:
                      categories.contains(category) ? category : 'Other',
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: categories
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => category = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price (₹)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text) ?? 0;
                if (name.isEmpty || price <= 0) return;
                final menuItem = app.MenuItem(
                  id: item?.id,
                  name: name,
                  category: category,
                  price: price,
                  iconName: category == 'Snacks'
                      ? 'bakery_dining'
                      : 'coffee',
                  isAvailable: item?.isAvailable ?? true,
                );
                if (item == null) {
                  context.read<MenuProvider>().addItem(menuItem);
                } else {
                  context.read<MenuProvider>().updateItem(menuItem);
                }
                Navigator.pop(ctx);
              },
              child: Text(item == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Item card ──────────────────────────────────────────────────────
class _MenuItemCard extends StatelessWidget {
  final app.MenuItem item;

  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.isAvailable
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          backgroundImage: item.iconName.endsWith('.png')
              ? AssetImage('assets/images/${item.iconName}')
              : null,
          child: item.iconName.endsWith('.png')
              ? null
              : Icon(
                  item.iconName == 'bakery_dining'
                      ? Icons.bakery_dining
                      : Icons.coffee_rounded,
                  color: item.isAvailable
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface.withAlpha(100),
                ),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration:
                item.isAvailable ? null : TextDecoration.lineThrough,
            color: item.isAvailable
                ? null
                : colorScheme.onSurface.withAlpha(100),
          ),
        ),
        subtitle: Text(
          '${item.category} • ₹${item.price.toStringAsFixed(0)}',
          style: TextStyle(
            color: item.isAvailable
                ? colorScheme.primary
                : colorScheme.onSurface.withAlpha(80),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                item.isAvailable
                    ? Icons.toggle_on
                    : Icons.toggle_off_outlined,
                color: item.isAvailable ? Colors.green : Colors.grey,
                size: 32,
              ),
              onPressed: () =>
                  context.read<MenuProvider>().toggleAvailability(item),
              tooltip: item.isAvailable
                  ? 'Mark Unavailable'
                  : 'Mark Available',
            ),
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'edit') {
                  final state =
                      context.findAncestorStateOfType<_MenuScreenState>();
                  state?._showItemDialog(context, item: item);
                } else if (action == 'delete') {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Item'),
                      content:
                          Text('Delete "${item.name}" from the menu?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel')),
                        FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () {
                            context
                                .read<MenuProvider>()
                                .deleteItem(item.id!);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                      leading: Icon(Icons.edit), title: Text('Edit')),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete',
                        style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
