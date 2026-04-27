import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/firebase_service.dart';
import '../models/order.dart';
import '../models/menu_item.dart';


class OrderProvider with ChangeNotifier {
  List<OrderItem> _cart = [];
  List<Order> _orders = [];
  bool _isLoading = false;
  int _orderCounter = 0;
  Map<String, dynamic>? _mostOrderedItem;

  StreamSubscription<List<Order>>? _orderSubscription;

  List<OrderItem> get cart => _cart;
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get mostOrderedItem => _mostOrderedItem;

  double get cartTotal => _cart.fold(0, (sum, item) => sum + item.subtotal);
  int get cartItemCount => _cart.fold(0, (sum, item) => sum + item.quantity);

  /// Active (pending) orders — shown in admin queue
  List<Order> get activeOrders =>
      _orders.where((o) => o.status == 'pending' && o.brewStatus != 'ready').toList();

  // ─── Real-time subscription ───────────────────────────────────

  /// Call this from initState of any screen that shows orders.
  /// Pass [userId] to scope to a single customer; omit for admin (all orders).
  void subscribeToOrders({String? userId}) {
    _orderSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _orderSubscription = FirebaseService.instance
        .streamOrders(userId: userId)
        .listen((orders) {
      _orders = orders;
      _orderCounter = orders.length;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _isLoading = false;
      notifyListeners();
      if (kDebugMode) print('[OrderProvider] stream error: $e');
    });
  }

  /// Call this from dispose() of the screen that called subscribeToOrders().
  void unsubscribeFromOrders() {
    _orderSubscription?.cancel();
    _orderSubscription = null;
  }

  // ─── Cart ─────────────────────────────────────────────────────

  void addToCart(MenuItem menuItem) {
    final existingIndex = _cart.indexWhere((i) => i.menuItemId == menuItem.id);
    if (existingIndex >= 0) {
      _cart[existingIndex] = _cart[existingIndex].copyWith(
        quantity: _cart[existingIndex].quantity + 1,
      );
    } else {
      _cart.add(OrderItem(
        menuItemId: menuItem.id!,
        name: menuItem.name,
        quantity: 1,
        unitPrice: menuItem.price,
      ));
    }
    notifyListeners();
  }

  void removeFromCart(String menuItemId) {
    _cart.removeWhere((i) => i.menuItemId == menuItemId);
    notifyListeners();
  }

  void updateCartItemQty(String menuItemId, int qty) {
    if (qty <= 0) {
      removeFromCart(menuItemId);
      return;
    }
    final idx = _cart.indexWhere((i) => i.menuItemId == menuItemId);
    if (idx >= 0) {
      _cart[idx] = _cart[idx].copyWith(quantity: qty);
      notifyListeners();
    }
  }

  void clearCart() {
    _cart = [];
    notifyListeners();
  }

  // ─── Place Order ──────────────────────────────────────────────

  /// Places an order. Customer orders start as pending; admin orders complete immediately.
  /// [discountAmount] is the coupon discount; [paymentMethod] is 'Cash'/'UPI'/'Card'.
  /// Returns a tuple (docId, order).
  Future<(String, Order)> placeOrder({
    String? userId,
    bool isCustomerOrder = false,
    double discountAmount = 0,
    String? couponCode,
    String? paymentMethod,
  }) async {
    _orderCounter++;
    final now = DateTime.now();
    final orderNumber =
        'ORD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${_orderCounter.toString().padLeft(4, '0')}';

    // Customer orders start pending; direct admin orders complete immediately
    final status = isCustomerOrder ? 'pending' : 'completed';
    final brewStatus = isCustomerOrder ? 'received' : 'ready';
    final finalTotal = (cartTotal - discountAmount).clamp(0, double.infinity).toDouble();

    final order = Order(
      userId: userId,
      orderNumber: orderNumber,
      items: List.from(_cart),
      totalAmount: finalTotal,
      discountAmount: discountAmount,
      couponCode: couponCode,
      paymentMethod: paymentMethod,
      status: status,
      brewStatus: brewStatus,
      createdAt: now,
    );

    final coffeeItems = _cart.where(
      (i) => !['Croissant', 'Chocolate Muffin'].contains(i.name),
    );
    final coffeeItemCount = coffeeItems.fold(0, (sum, i) => sum + i.quantity);

    final docId = await FirebaseService.instance.placeOrderTransaction(
      order: order,
      userId: userId,
      coffeeItemCount: coffeeItemCount,
      coffeeBeansGrams: coffeeItemCount * 18.0,
      milkMl: coffeeItemCount * 150.0,
    );

    _cart = [];
    notifyListeners();
    // The stream will automatically pick up the new order — no manual reload needed.
    return (docId, order);
  }

  // ─── Legacy one-shot load (kept for compatibility) ────────────

  Future<void> loadOrders({String? userId}) async {
    _isLoading = true;
    notifyListeners();
    _orders = await FirebaseService.instance.getOrders(userId: userId);
    _orderCounter = _orders.length;
    _isLoading = false;
    notifyListeners();
  }

  // ─── Misc ─────────────────────────────────────────────────────

  Future<void> loadMostOrderedItem(String userId) async {
    _mostOrderedItem = await FirebaseService.instance.getMostOrderedItem(userId);
    notifyListeners();
  }

  Future<void> updateBrewStatus(String orderId, String brewStatus) async {
    // Optimistic UI update
    final index = _orders.indexWhere((o) => o.id == orderId || o.orderNumber == orderId);
    Order? originalOrder;
    if (index >= 0) {
      originalOrder = _orders[index];
      _orders[index] = originalOrder.copyWith(
        brewStatus: brewStatus,
        status: brewStatus == 'ready' ? 'completed' : originalOrder.status,
      );
      notifyListeners();
    }

    try {
      await FirebaseService.instance.updateBrewStatus(orderId, brewStatus);
      // Stream will reconcile the real state automatically.
    } catch (e) {
      // Revert optimism if it failed
      if (index >= 0 && originalOrder != null) {
        _orders[index] = originalOrder;
        notifyListeners();
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    super.dispose();
  }
}
