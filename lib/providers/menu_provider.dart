import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../models/menu_item.dart';

class MenuProvider with ChangeNotifier {
  // ── Crema default menu ─────────────────────────────────────────
  List<MenuItem> _items = [];
  bool _isLoading = false;

  // ── External store menus ───────────────────────────────────────
  /// List of {id, name} for all imported store menus.
  List<Map<String, String>> _storeMenus = [];

  /// null = Crema (default). A storeId string = external store.
  String? _selectedStoreId;

  // ── Getters ───────────────────────────────────────────────────
  List<MenuItem> get items => _items;
  List<MenuItem> get availableItems => _items.where((i) => i.isAvailable).toList();
  bool get isLoading => _isLoading;
  List<Map<String, String>> get storeMenus => _storeMenus;
  String? get selectedStoreId => _selectedStoreId;

  /// Display name for the currently active menu.
  String get selectedStoreName {
    if (_selectedStoreId == null) return 'Crema';
    return _storeMenus
        .firstWhere((m) => m['id'] == _selectedStoreId,
            orElse: () => {'name': 'Unknown'})['name']!;
  }

  List<String> get categories =>
      _items.map((i) => i.category).toSet().toList()..sort();

  // ── Initialisation ────────────────────────────────────────────
  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();

    // Refresh store-menu list — gracefully ignore permission errors
    // (can happen when Firestore rules haven't been deployed yet)
    try {
      _storeMenus = await FirebaseService.instance.getStoreMenus();
    } catch (_) {
      _storeMenus = [];
    }

    try {
      if (_selectedStoreId == null) {
        // Load Crema default menu
        _items = await FirebaseService.instance.getMenuItems();

        // Auto-seed on first run
        if (_items.isEmpty) {
          await FirebaseService.instance.seedIfEmpty();
          _items = await FirebaseService.instance.getMenuItems();
        }
        // One-shot cleanup of any duplicate inventory docs from previous seed runs
        await FirebaseService.instance.deduplicateInventory();
      } else {
        _items =
            await FirebaseService.instance.getStoreMenuItems(_selectedStoreId!);
      }
    } catch (e) {
      if (kDebugMode) print('MenuProvider.loadItems error: $e');
      _items = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Switch the active menu. Pass null to return to Crema.
  Future<void> selectStore(String? storeId) async {
    _selectedStoreId = storeId;
    await loadItems();
  }

  // ── Store menu operations ─────────────────────────────────────
  /// Creates a new store, imports [items], then selects it.
  Future<void> createStoreMenu(String name, List<MenuItem> items) async {
    _isLoading = true;
    notifyListeners();
    final storeId = await FirebaseService.instance.createStoreMenu(name);
    if (items.isNotEmpty) {
      await FirebaseService.instance.importStoreMenuItems(storeId, items);
    }
    _selectedStoreId = storeId;
    await loadItems(); // refreshes storeMenus + items
  }

  /// Deletes the store and all its items, then falls back to Crema.
  Future<void> deleteStoreMenu(String storeId) async {
    _isLoading = true;
    notifyListeners();
    await FirebaseService.instance.deleteStoreMenu(storeId);
    if (_selectedStoreId == storeId) _selectedStoreId = null;
    await loadItems();
  }

  // ── Item CRUD (routed to the right collection) ─────────────────
  Future<void> addItem(MenuItem item) async {
    if (_selectedStoreId == null) {
      await FirebaseService.instance.insertMenuItem(item);
    } else {
      await FirebaseService.instance.insertStoreMenuItem(_selectedStoreId!, item);
    }
    await loadItems();
  }

  Future<void> updateItem(MenuItem item) async {
    if (_selectedStoreId == null) {
      await FirebaseService.instance.updateMenuItem(item);
    } else {
      await FirebaseService.instance.updateStoreMenuItem(_selectedStoreId!, item);
    }
    await loadItems();
  }

  Future<void> deleteItem(String id) async {
    if (_selectedStoreId == null) {
      await FirebaseService.instance.deleteMenuItem(id);
    } else {
      await FirebaseService.instance.deleteStoreMenuItem(_selectedStoreId!, id);
    }
    await loadItems();
  }

  Future<void> toggleAvailability(MenuItem item) async {
    final updated = item.copyWith(isAvailable: !item.isAvailable);
    if (_selectedStoreId == null) {
      await FirebaseService.instance.updateMenuItem(updated);
    } else {
      await FirebaseService.instance.updateStoreMenuItem(_selectedStoreId!, updated);
    }
    await loadItems();
  }
}
