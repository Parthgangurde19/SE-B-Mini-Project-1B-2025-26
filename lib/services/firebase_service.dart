import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item.dart';
import '../models/order.dart' as app;
import '../models/inventory_item.dart';
import '../models/user.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseService._init();

  // ─── Seed ─────────────────────────────────────────────────────
  Future<void> seedIfEmpty() async {
    // Check BOTH collections — seeding only when neither has data
    // prevents duplicate docs if one collection was reset independently.
    final menuSnap = await _db.collection('menu_items').limit(1).get();
    final invSnap  = await _db.collection('inventory').limit(1).get();
    if (menuSnap.docs.isNotEmpty || invSnap.docs.isNotEmpty) return;

    final batch = _db.batch();

    final menuItems = [
      {'name': 'Espresso',         'category': 'Espresso', 'price': 80,  'iconName': 'espresso.png',         'isAvailable': true},
      {'name': 'Double Espresso',  'category': 'Espresso', 'price': 120, 'iconName': 'double_espresso.png',  'isAvailable': true},
      {'name': 'Americano',        'category': 'Espresso', 'price': 100, 'iconName': 'americano.png',        'isAvailable': true},
      {'name': 'Cappuccino',       'category': 'Latte',    'price': 150, 'iconName': 'cappuccino.png',       'isAvailable': true},
      {'name': 'Caffe Latte',      'category': 'Latte',    'price': 160, 'iconName': 'caffe_latte.png',      'isAvailable': true},
      {'name': 'Caramel Macchiato','category': 'Latte',    'price': 180, 'iconName': 'caramel_macchiato.png','isAvailable': true},
      {'name': 'Cold Brew',        'category': 'Cold',     'price': 180, 'iconName': 'cold_brew.png',        'isAvailable': true},
      {'name': 'Iced Mocha',       'category': 'Cold',     'price': 200, 'iconName': 'iced_mocha.png',       'isAvailable': true},
      {'name': 'Croissant',        'category': 'Snacks',   'price': 90,  'iconName': 'croissant.png',        'isAvailable': true},
      {'name': 'Chocolate Muffin', 'category': 'Snacks',   'price': 80,  'iconName': 'chocolate_muffin.png', 'isAvailable': true},
    ];
    for (final item in menuItems) {
      batch.set(_db.collection('menu_items').doc(), item);
    }

    final now = DateTime.now().toIso8601String();
    final inventoryItems = [
      {'name': 'Coffee Beans', 'unit': 'kg',  'currentStock': 5.0,   'minStock': 1.0,  'lastRestocked': now},
      {'name': 'Milk',         'unit': 'L',   'currentStock': 10.0,  'minStock': 2.0,  'lastRestocked': now},
      {'name': 'Sugar',        'unit': 'kg',  'currentStock': 3.0,   'minStock': 0.5,  'lastRestocked': now},
      {'name': 'Cups (Small)', 'unit': 'pcs', 'currentStock': 200.0, 'minStock': 50.0, 'lastRestocked': now},
      {'name': 'Cups (Large)', 'unit': 'pcs', 'currentStock': 150.0, 'minStock': 30.0, 'lastRestocked': now},
      {'name': 'Cream',        'unit': 'L',   'currentStock': 2.0,   'minStock': 0.5,  'lastRestocked': now},
    ];
    for (final item in inventoryItems) {
      batch.set(_db.collection('inventory').doc(), item);
    }

    await batch.commit();
  }

  // ─── Coupons ──────────────────────────────────────────────────

  /// One-shot cleanup: removes duplicate inventory docs that share the same name.
  /// Keeps the first document found for each name and deletes the rest.
  /// Safe to call repeatedly — a no-op if no duplicates exist.
  Future<void> deduplicateInventory() async {
    final snap = await _db.collection('inventory').get();
    final seen = <String, String>{}; // name → first docId kept
    final toDelete = <String>[];

    for (final doc in snap.docs) {
      final name = doc.data()['name'] as String? ?? doc.id;
      if (seen.containsKey(name)) {
        toDelete.add(doc.id);
      } else {
        seen[name] = doc.id;
      }
    }

    if (toDelete.isEmpty) return;

    const batchSize = 500;
    for (var i = 0; i < toDelete.length; i += batchSize) {
      final chunk = toDelete.skip(i).take(batchSize);
      final batch = _db.batch();
      for (final id in chunk) {
        batch.delete(_db.collection('inventory').doc(id));
      }
      await batch.commit();
    }
  }


  /// Returns ALL coupon docs (for admin management screen).
  Future<List<Map<String, dynamic>>> getAllCoupons() async {
    final snap = await _db.collection('coupons').orderBy('code').get();
    return snap.docs.map((d) {
      final data = Map<String, dynamic>.from(d.data());
      data['id'] = d.id;
      return data;
    }).toList();
  }

  /// Creates or overwrites a coupon doc (admin use).
  Future<void> createCoupon(Map<String, dynamic> data) async {
    final code = data['code'] as String;
    await _db.collection('coupons').doc(code).set(data, SetOptions(merge: true));
  }

  /// Deletes a coupon doc (admin use).
  Future<void> deleteCoupon(String code) async {
    await _db.collection('coupons').doc(code).delete();
  }

  /// Validates a coupon code. Returns a map with keys:
  ///   'valid': bool
  ///   'discountType': 'percent' | 'flat'  (only when valid)
  ///   'discountValue': double              (only when valid)
  ///   'description': String               (only when valid)
  /// When valid, atomically increments usedCount (single-use enforcement).
  Future<Map<String, dynamic>> validateCoupon(String code) async {
    if (code.trim().isEmpty) return {'valid': false};
    try {
      final snap = await _db
          .collection('coupons')
          .where('code', isEqualTo: code.trim().toUpperCase())
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return {'valid': false};
      final docRef = snap.docs.first.reference;
      final data = snap.docs.first.data();

      // Check expiry
      final expiry = data['expiresAt'] as String?;
      if (expiry != null && DateTime.parse(expiry).isBefore(DateTime.now())) {
        return {'valid': false, 'reason': 'Coupon expired'};
      }
      // Check single-use: maxUses=1 and usedCount>=1 means already spent
      final maxUses = data['maxUses'] as int?;
      final usedCount = (data['usedCount'] as num?)?.toInt() ?? 0;
      if (maxUses != null && usedCount >= maxUses) {
        return {'valid': false, 'reason': 'Coupon already used'};
      }

      // Mark as used atomically — prevents double-use on slow networks.
      // For admin-generated (single-use) coupons, also deactivate so the
      // coupon is immediately hidden from the Active tab in Firestore without
      // requiring an admin refresh. Existing coupons (no isGenerated flag)
      // keep their old behaviour — only usedCount is touched.
      final isGenerated = data['isGenerated'] == true;
      final newUsedCount = usedCount + 1;
      final isLastUse = maxUses != null && newUsedCount >= maxUses;

      await docRef.update({
        'usedCount': FieldValue.increment(1),
        if (isGenerated && isLastUse) 'active': false,
      });

      return {
        'valid': true,
        'discountType': data['discountType'] as String? ?? 'flat',
        'discountValue': (data['discountValue'] as num?)?.toDouble() ?? 0,
        'description': data['description'] as String? ?? code,
      };
    } catch (e) {
      return {'valid': false, 'reason': 'Error: ${e.toString()}'};
    }
  }

  /// Generates a new random 8-char alphanumeric code.
  String _generateCouponCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = DateTime.now().microsecondsSinceEpoch;
    return List.generate(
        8, (i) => chars[(rnd ~/ (i + 1) + i * 97) % chars.length]).join();
  }

  /// Called when admin copies a coupon code.
  /// The old code is marked [active:false] so it no longer appears in the
  /// Active tab, but it still exists in Firestore so the customer can redeem it —
  /// [validateCoupon] will expire it atomically once [usedCount] reaches [maxUses].
  /// A brand-new code with the same discount/expiry is created and becomes the
  /// next active coupon ready for distribution.
  /// Returns the new code.
  Future<String> rotateCouponCode(String oldCode, Map<String, dynamic> couponData) async {
    final newCode = _generateCouponCode();
    final newData = Map<String, dynamic>.from(couponData)
      ..['code'] = newCode
      ..['usedCount'] = 0
      ..['active'] = true
      ..remove('id');

    final batch = _db.batch();
    // Keep old doc alive so the customer can still redeem the copied code;
    // just hide it from the Active tab by setting active:false.
    batch.update(
      _db.collection('coupons').doc(oldCode),
      {'active': false},
    );
    // Create the next fresh code.
    batch.set(_db.collection('coupons').doc(newCode), newData);
    await batch.commit();
    return newCode;
  }

  // ─── Menu Items ───────────────────────────────────────────────
  Future<List<MenuItem>> getMenuItems() async {
    final snapshot = await _db.collection('menu_items').get();
    final items = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return MenuItem.fromMap(data);
    }).toList();
    items.sort((a, b) {
      final cat = a.category.compareTo(b.category);
      return cat != 0 ? cat : a.name.compareTo(b.name);
    });
    return items;
  }

  Future<String> insertMenuItem(MenuItem item) async {
    final docRef = await _db.collection('menu_items').add(item.toMap()..remove('id'));
    return docRef.id;
  }

  Future<void> updateMenuItem(MenuItem item) async {
    if (item.id != null) {
      await _db.collection('menu_items').doc(item.id).update(item.toMap()..remove('id'));
    }
  }

  Future<void> deleteMenuItem(String id) async {
    await _db.collection('menu_items').doc(id).delete();
  }

  // ─── Store Menus (External Cafes) ─────────────────────────────
  /// Returns all named store menus as [{id, name}] maps.
  Future<List<Map<String, String>>> getStoreMenus() async {
    final snap = await _db
        .collection('store_menus')
        .orderBy('createdAt', descending: false)
        .get();
    return snap.docs
        .map((d) => {'id': d.id, 'name': d.data()['name'] as String})
        .toList();
  }

  /// Creates a new store menu document. Returns the new storeId.
  Future<String> createStoreMenu(String name) async {
    final ref = await _db.collection('store_menus').add({
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    });
    return ref.id;
  }

  /// Deletes a store menu and all its items (batch up to 500).
  Future<void> deleteStoreMenu(String storeId) async {
    final itemsSnap =
        await _db.collection('store_menus').doc(storeId).collection('items').get();
    final batch = _db.batch();
    for (final d in itemsSnap.docs) {
      batch.delete(d.reference);
    }
    batch.delete(_db.collection('store_menus').doc(storeId));
    await batch.commit();
  }

  /// Fetches all items for a given store menu.
  Future<List<MenuItem>> getStoreMenuItems(String storeId) async {
    final snap = await _db
        .collection('store_menus')
        .doc(storeId)
        .collection('items')
        .get();
    final items = snap.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return MenuItem.fromMap(data);
    }).toList();
    items.sort((a, b) {
      final cat = a.category.compareTo(b.category);
      return cat != 0 ? cat : a.name.compareTo(b.name);
    });
    return items;
  }

  /// Bulk-imports a list of MenuItems into a store menu (batch write).
  Future<void> importStoreMenuItems(String storeId, List<MenuItem> items) async {
    const batchSize = 400;
    for (var i = 0; i < items.length; i += batchSize) {
      final chunk = items.skip(i).take(batchSize);
      final batch = _db.batch();
      for (final item in chunk) {
        final ref = _db
            .collection('store_menus')
            .doc(storeId)
            .collection('items')
            .doc();
        batch.set(ref, item.toMap()..remove('id'));
      }
      await batch.commit();
    }
  }

  Future<String> insertStoreMenuItem(String storeId, MenuItem item) async {
    final ref = await _db
        .collection('store_menus')
        .doc(storeId)
        .collection('items')
        .add(item.toMap()..remove('id'));
    return ref.id;
  }

  Future<void> updateStoreMenuItem(String storeId, MenuItem item) async {
    if (item.id == null) return;
    await _db
        .collection('store_menus')
        .doc(storeId)
        .collection('items')
        .doc(item.id)
        .update(item.toMap()..remove('id'));
  }

  Future<void> deleteStoreMenuItem(String storeId, String itemId) async {
    await _db
        .collection('store_menus')
        .doc(storeId)
        .collection('items')
        .doc(itemId)
        .delete();
  }

  // ─── Orders (Transactional) ───────────────────────────────────
  /// Places an order atomically: deducts inventory + increments loyalty + updates orderFrequency.
  /// Returns the new order document ID.
  Future<String> placeOrderTransaction({
    required app.Order order,
    required String? userId,
    required int coffeeItemCount,
    required double coffeeBeansGrams,
    required double milkMl,
  }) async {
    String orderId = '';

    try {
      await _db.runTransaction((txn) async {
        // ── 1. Read inventory docs ───────────────────────────────
        final beansSnap = await _db
            .collection('inventory')
            .where('name', isEqualTo: 'Coffee Beans')
            .limit(1)
            .get();
        final milkSnap = await _db
            .collection('inventory')
            .where('name', isEqualTo: 'Milk')
            .limit(1)
            .get();
        final cupsSnap = await _db
            .collection('inventory')
            .where('name', isEqualTo: 'Cups (Small)')
            .limit(1)
            .get();

        // ── 2. Read user doc (for loyalty) ──────────────────────
        DocumentSnapshot? userDoc;
        if (userId != null) {
          userDoc = await txn.get(_db.collection('users').doc(userId));
        }

        // ── 3. Write new order doc ───────────────────────────────
        final orderRef = _db.collection('orders').doc();
        orderId = orderRef.id;
        final orderData = order.toMap()..remove('id');
        final itemsData = order.items
            .map((i) => i.toMap()..remove('id')..remove('orderId'))
            .toList();
        orderData['items'] = itemsData;
        txn.set(orderRef, orderData);

        // ── 4. Deduct inventory ──────────────────────────────────
        if (coffeeItemCount > 0) {
          if (beansSnap.docs.isNotEmpty) {
            final doc = beansSnap.docs.first;
            final current = (doc.data()['currentStock'] as num).toDouble();
            final deduction = coffeeBeansGrams / 1000;
            txn.update(doc.reference, {
              'currentStock': (current - deduction) < 0 ? 0.0 : current - deduction,
            });
          }
          if (milkMl > 0 && milkSnap.docs.isNotEmpty) {
            final doc = milkSnap.docs.first;
            final current = (doc.data()['currentStock'] as num).toDouble();
            final deduction = milkMl / 1000;
            txn.update(doc.reference, {
              'currentStock': (current - deduction) < 0 ? 0.0 : current - deduction,
            });
          }
          if (cupsSnap.docs.isNotEmpty) {
            txn.update(cupsSnap.docs.first.reference, {
              'currentStock': FieldValue.increment(-coffeeItemCount.toDouble()),
            });
          }
        }

        // ── 5. Loyalty + orderFrequency (customer orders only) ──
        if (userId != null && coffeeItemCount > 0) {
          final userRef = _db.collection('users').doc(userId);
          final now = DateTime.now().toIso8601String();

          // Build frequency updates for each coffee item
          final Map<String, dynamic> freqUpdates = {};
          for (final item in order.items) {
            if (['Croissant', 'Chocolate Muffin'].contains(item.name)) continue;
            final key = 'orderFrequency.${item.menuItemId}';
            // We can't use FieldValue.increment inside a nested map key in a transaction
            // so we read the current count from userDoc and compute the new value
            int currentCount = 0;
            if (userDoc != null && userDoc.exists) {
              final data = userDoc.data() as Map<String, dynamic>?;
              final freq = data?['orderFrequency'] as Map<String, dynamic>?;
              currentCount = (freq?[item.menuItemId]?['count'] as num?)?.toInt() ?? 0;
            }
            freqUpdates[key] = {
              'count': currentCount + item.quantity,
              'lastOrderedAt': now,
              'name': item.name,
            };
          }

          txn.update(userRef, {
            'loyaltyPoints': FieldValue.increment(coffeeItemCount),
            'freeItemReady': ((userDoc?.data() as Map<String, dynamic>?)?['loyaltyPoints'] as num? ?? 0) + coffeeItemCount >= 10,
            ...freqUpdates,
          });
        }
      });
    } catch (e) {
      // Log error to Firestore errors collection
      await logError(order.orderNumber, e.toString());
      rethrow;
    }

    return orderId;
  }

  /// Returns a live stream of orders, optionally scoped to a single user.
  Stream<List<app.Order>> streamOrders({String? userId}) {
    Query<Map<String, dynamic>> query = _db.collection('orders');
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        final itemsList = (data['items'] as List<dynamic>? ?? []).map((itemData) {
          final iData = Map<String, dynamic>.from(itemData as Map<String, dynamic>);
          iData['orderId'] = doc.id;
          return app.OrderItem.fromMap(iData);
        }).toList();
        return app.Order.fromMap(data, itemsList);
      }).toList();
    });
  }

  Future<List<app.Order>> getOrders({int? limit, String? userId}) async {
    Query query = _db.collection('orders');
    
    // Server-side filter to satisfy Firestore security rules
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    
    query = query.orderBy('createdAt', descending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    var orders = snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
      data['id'] = doc.id;
      final itemsList = (data['items'] as List<dynamic>? ?? []).map((itemData) {
        final iData = Map<String, dynamic>.from(itemData as Map<String, dynamic>);
        iData['orderId'] = doc.id;
        return app.OrderItem.fromMap(iData);
      }).toList();
      return app.Order.fromMap(data, itemsList);
    }).toList();

    return orders;
  }

  // ─── Brew Status ──────────────────────────────────────────────
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamOrderById(String orderId) {
    return _db.collection('orders').doc(orderId).snapshots();
  }

  /// Gets the most recent pending order for a user (for initial TrackOrder load).
  Future<String?> getLatestPendingOrderId(String userId) async {
    final snap = await _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  Future<void> updateBrewStatus(String orderId, String brewStatus) async {
    try {
      final isComplete = brewStatus == 'ready';
      await _db.collection('orders').doc(orderId).update({
        'brewStatus': brewStatus,
        if (isComplete) 'status': 'completed',
      });
    } on FirebaseException catch (e) {
      await logError(orderId, 'brew_status_update_failed: ${e.code}');
      rethrow;
    } catch (e) {
      // Don't log generic non-Firebase errors to avoid noise
      rethrow;
    }
  }

  // ─── Loyalty ──────────────────────────────────────────────────
  /// Atomically: subtracts [pointsToRedeem] loyalty points, updates freeItemReady,
  /// and writes a reward order document with isFreeRedemption:true.
  /// [pointsToRedeem] must be a multiple of 10. Defaults to 10 (one free coffee).
  /// Returns the new order document ID.
  Future<String> redeemFreeItem(String userId, app.Order rewardOrder,
      {int pointsToRedeem = 10}) async {
    String orderId = '';

    await _db.runTransaction((txn) async {
      final userRef = _db.collection('users').doc(userId);
      final userDoc = await txn.get(userRef);
      final currentPoints =
          (userDoc.data()?['loyaltyPoints'] as num?)?.toInt() ?? 0;
      final remainingPoints = currentPoints - pointsToRedeem;

      // Write the reward order document
      final orderRef = _db.collection('orders').doc();
      orderId = orderRef.id;

      final orderData = rewardOrder.toMap()..remove('id');
      final itemsData = rewardOrder.items
          .map((i) => i.toMap()..remove('id')..remove('orderId'))
          .toList();
      orderData['items'] = itemsData;
      orderData['isFreeRedemption'] = true;

      txn.set(orderRef, orderData);

      // Deduct points; freeItemReady reflects whether enough remain for another
      txn.update(userRef, {
        'loyaltyPoints': FieldValue.increment(-pointsToRedeem),
        'freeItemReady': remainingPoints >= 10,
      });
    });

    return orderId;
  }

  /// Reads orderFrequency from user doc and returns the most recently ordered
  /// item within the last 30 days. Falls back to 2nd most frequent if the
  /// most frequent is stale.
  Future<Map<String, dynamic>?> getMostOrderedItem(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    final rawFreq = data['orderFrequency'] as Map<String, dynamic>?;
    if (rawFreq == null || rawFreq.isEmpty) return null;

    final cutoff = DateTime.now().subtract(const Duration(days: 30));

    final entries = rawFreq.entries.map((e) {
      final v = e.value as Map<String, dynamic>;
      final lastStr = v['lastOrderedAt'] as String?;
      final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
      return {
        'menuItemId': e.key,
        'name': v['name'] as String? ?? '',
        'count': (v['count'] as num?)?.toInt() ?? 0,
        'lastOrderedAt': last,
        'isFresh': last != null && last.isAfter(cutoff),
      };
    }).toList();

    // Sort by count descending
    entries.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    // Return first fresh entry
    for (final e in entries) {
      if (e['isFresh'] == true) return e;
    }
    return null;
  }

  // ─── Users ─────────────────────────────────────────────────────
  Future<String> insertUser(User user) async {
    final docRef = await _db.collection('users').add(user.toMap()..remove('id'));
    return docRef.id;
  }

  Future<User?> getUser(String email, String password) async {
    final snapshot = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final data = snapshot.docs.first.data();
    data['id'] = snapshot.docs.first.id;
    return User.fromMap(data);
  }

  Future<User?> getUserByEmail(String email) async {
    final snapshot = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final data = snapshot.docs.first.data();
    data['id'] = snapshot.docs.first.id;
    return User.fromMap(data);
  }

  Future<List<User>> getAllUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return User.fromMap(data);
    }).toList();
  }

  // ─── Inventory ────────────────────────────────────────────────
  Future<List<InventoryItem>> getInventoryItems() async {
    final snapshot = await _db.collection('inventory').get();
    final items = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return InventoryItem.fromMap(data);
    }).toList();
    items.sort((a, b) => a.name.compareTo(b.name));
    return items;
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    if (item.id != null) {
      await _db.collection('inventory').doc(item.id).update(item.toMap()..remove('id'));
    }
  }

  // Legacy client-side deduction (kept for backwards-compat, prefer placeOrderTransaction)
  Future<void> deductInventory(double coffeeBeansGrams, double milkMl) async {
    final batch = _db.batch();

    Future<void> deduct(String name, double amount) async {
      final snap = await _db.collection('inventory').where('name', isEqualTo: name).limit(1).get();
      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        final current = (doc.data()['currentStock'] as num).toDouble();
        final updatedStock = (current - amount) < 0 ? 0.0 : (current - amount);
        batch.update(doc.reference, {'currentStock': updatedStock});
      }
    }

    await deduct('Coffee Beans', coffeeBeansGrams / 1000);
    if (milkMl > 0) await deduct('Milk', milkMl / 1000);
    await deduct('Cups (Small)', 1.0);
    await batch.commit();
  }

  // ─── Error Logging (Sprint 0) ─────────────────────────────────
  Future<void> logError(String orderId, String errorType) async {
    // Strip verbose Dart runtime wrapper text for readability
    final cleaned = errorType
        .replaceAll('Error: Dart exception thrown from converted Future. '
            "Use the properties 'error' to fetch the boxed error and "
            "'stack' to recover the stack trace.", '[runtime error]')
        .replaceAll('Error: ', '')
        .trim();
    try {
      await _db.collection('errors').add({
        'orderId': orderId,
        'errorType': cleaned,
        'timestamp': DateTime.now().toIso8601String(),
        'resolved': false,
      });
    } catch (_) {
      // Best-effort — don't throw if error logging itself fails
      if (kDebugMode) print('Failed to log error: $orderId / $errorType');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamUnresolvedErrors() {
    return _db
        .collection('errors')
        .where('resolved', isEqualTo: false)
        .snapshots();
  }

  Future<void> resolveError(String errorId) async {
    await _db.collection('errors').doc(errorId).update({'resolved': true});
  }

  /// Batch-resolves all provided error docs in a single Firestore commit.
  Future<void> resolveAllErrors(List<String> errorIds) async {
    if (errorIds.isEmpty) return;
    // Firestore batch limit is 500 writes
    const batchSize = 500;
    for (var i = 0; i < errorIds.length; i += batchSize) {
      final chunk = errorIds.skip(i).take(batchSize);
      final batch = _db.batch();
      for (final id in chunk) {
        batch.update(_db.collection('errors').doc(id), {'resolved': true});
      }
      await batch.commit();
    }
  }

  // ─── Reports ──────────────────────────────────────────────────
  Future<double> getRevenueForDateRange(DateTime start, DateTime end) async {
    final snapshot = await _db
        .collection('orders')
        .where('status', isEqualTo: 'completed')
        .get();
    double total = 0;
    for (var doc in snapshot.docs) {
      final createdAt = DateTime.tryParse(doc.data()['createdAt'] as String? ?? '');
      if (createdAt != null && !createdAt.isBefore(start) && createdAt.isBefore(end)) {
        total += (doc.data()['totalAmount'] as num).toDouble();
      }
    }
    return total;
  }

  Future<int> getOrderCountForDateRange(DateTime start, DateTime end) async {
    final snapshot = await _db
        .collection('orders')
        .where('status', isEqualTo: 'completed')
        .get();
    int count = 0;
    for (var doc in snapshot.docs) {
      final createdAt = DateTime.tryParse(doc.data()['createdAt'] as String? ?? '');
      if (createdAt != null && !createdAt.isBefore(start) && createdAt.isBefore(end)) {
        count++;
      }
    }
    return count;
  }

  Future<List<Map<String, dynamic>>> getTopSellingItems({int limit = 5}) async {
    final snapshot = await _db.collection('orders').where('status', isEqualTo: 'completed').get();
    final Map<String, Map<String, dynamic>> itemStats = {};
    for (var doc in snapshot.docs) {
      final itemsList = doc.data()['items'] as List<dynamic>? ?? [];
      for (var map in itemsList) {
        final itemMap = map as Map<String, dynamic>;
        final name = itemMap['name'] as String;
        final qty = (itemMap['quantity'] as num).toInt();
        final unitPrice = (itemMap['unitPrice'] as num).toDouble();
        if (!itemStats.containsKey(name)) {
          itemStats[name] = {'name': name, 'totalQty': 0, 'totalRevenue': 0.0};
        }
        itemStats[name]!['totalQty'] += qty;
        itemStats[name]!['totalRevenue'] += (qty * unitPrice);
      }
    }
    final sortedStats = itemStats.values.toList()
      ..sort((a, b) => (b['totalQty'] as int).compareTo(a['totalQty'] as int));
    return sortedStats.take(limit).toList();
  }

  Future<List<Map<String, dynamic>>> getDailyRevenue(int days) async {
    final start = DateTime.now().subtract(Duration(days: days));
    final snapshot = await _db.collection('orders').where('status', isEqualTo: 'completed').get();
    final Map<String, Map<String, dynamic>> dailyStats = {};
    for (var doc in snapshot.docs) {
      final dateStr = doc.data()['createdAt'] as String;
      final date = DateTime.tryParse(dateStr);
      if (date == null || date.isBefore(start)) continue;
      final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      if (!dailyStats.containsKey(dayKey)) {
        dailyStats[dayKey] = {'day': dayKey, 'revenue': 0.0, 'orderCount': 0};
      }
      dailyStats[dayKey]!['revenue'] += (doc.data()['totalAmount'] as num).toDouble();
      dailyStats[dayKey]!['orderCount'] += 1;
    }
    final sortedDays = dailyStats.values.toList()
      ..sort((a, b) => (a['day'] as String).compareTo(b['day'] as String));
    return sortedDays;
  }

  Future<List<Map<String, dynamic>>> getCategoryBreakdown() async {
    final ordersSnapshot = await _db.collection('orders').where('status', isEqualTo: 'completed').get();
    final menuItemsSnapshot = await _db.collection('menu_items').get();
    final Map<String, String> itemToCategory = {};
    for (var doc in menuItemsSnapshot.docs) {
      itemToCategory[doc.id] = doc.data()['category'] as String;
    }
    final Map<String, Map<String, dynamic>> catStats = {};
    for (var doc in ordersSnapshot.docs) {
      final itemsList = doc.data()['items'] as List<dynamic>? ?? [];
      for (var map in itemsList) {
        final itemMap = map as Map<String, dynamic>;
        final menuItemId = itemMap['menuItemId'] as String;
        final qty = (itemMap['quantity'] as num).toInt();
        final unitPrice = (itemMap['unitPrice'] as num).toDouble();
        final category = itemToCategory[menuItemId] ?? 'Unknown';
        if (!catStats.containsKey(category)) {
          catStats[category] = {'category': category, 'totalQty': 0, 'totalRevenue': 0.0};
        }
        catStats[category]!['totalQty'] += qty;
        catStats[category]!['totalRevenue'] += (qty * unitPrice);
      }
    }
    final sortedCats = catStats.values.toList()
      ..sort((a, b) => (b['totalRevenue'] as double).compareTo(a['totalRevenue'] as double));
    return sortedCats;
  }

  /// Groups last 30 days of completed orders by hour of day.
  /// Intended to be called inside compute() by the ReportProvider.
  Future<List<Map<String, dynamic>>> getPeakHourData() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final snapshot = await _db.collection('orders').where('status', isEqualTo: 'completed').get();

    final Map<int, int> hourCounts = {};
    for (var doc in snapshot.docs) {
      final dateStr = doc.data()['createdAt'] as String?;
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null || date.isBefore(cutoff)) continue;
      hourCounts[date.hour] = (hourCounts[date.hour] ?? 0) + 1;
    }

    final result = List.generate(24, (h) => {'hour': h, 'count': hourCounts[h] ?? 0});
    return result;
  }
}
