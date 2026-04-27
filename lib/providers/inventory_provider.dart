import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../models/inventory_item.dart';

class InventoryProvider with ChangeNotifier {
  List<InventoryItem> _items = [];
  bool _isLoading = false;

  List<InventoryItem> get items => _items;
  List<InventoryItem> get lowStockItems => _items.where((i) => i.isLowStock).toList();
  bool get isLoading => _isLoading;

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();
    _items = await FirebaseService.instance.getInventoryItems();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> restockItem(InventoryItem item, double amount) async {
    final updated = item.copyWith(
      currentStock: item.currentStock + amount,
      lastRestocked: DateTime.now(),
    );
    await FirebaseService.instance.updateInventoryItem(updated);
    await loadItems();
  }

  Future<void> updateItem(InventoryItem item) async {
    await FirebaseService.instance.updateInventoryItem(item);
    await loadItems();
  }
}
