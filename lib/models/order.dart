class OrderItem {
  final String? id;
  final String? orderId;
  final String menuItemId;
  final String name;
  final int quantity;
  final double unitPrice;

  double get subtotal => quantity * unitPrice;

  OrderItem({
    this.id,
    this.orderId,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'menuItemId': menuItemId,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as String?,
      orderId: map['orderId'] as String?,
      menuItemId: map['menuItemId'] as String,
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      unitPrice: (map['unitPrice'] as num).toDouble(),
    );
  }

  OrderItem copyWith({int? quantity}) {
    return OrderItem(
      id: id,
      orderId: orderId,
      menuItemId: menuItemId,
      name: name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice,
    );
  }
}

class Order {
  final String? id;
  final String? userId;
  final String orderNumber;
  final List<OrderItem> items;
  final double totalAmount;
  final double discountAmount;   // coupon / partial discount
  final String? couponCode;      // applied coupon code, null if none
  final String? paymentMethod;   // 'Cash', 'UPI', 'Card'
  final String status; // 'pending', 'completed', 'cancelled'
  final String brewStatus; // 'received', 'ready'
  final bool isFreeRedemption;
  final DateTime createdAt;

  Order({
    this.id,
    this.userId,
    required this.orderNumber,
    required this.items,
    required this.totalAmount,
    this.discountAmount = 0,
    this.couponCode,
    this.paymentMethod,
    this.status = 'pending',
    this.brewStatus = 'received',
    this.isFreeRedemption = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'orderNumber': orderNumber,
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      if (couponCode != null) 'couponCode': couponCode,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      'status': status,
      'brewStatus': brewStatus,
      'isFreeRedemption': isFreeRedemption,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map, List<OrderItem> items) {
    return Order(
      id: map['id'] as String?,
      userId: map['userId'] as String?,
      orderNumber: map['orderNumber'] as String,
      items: items,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0,
      couponCode: map['couponCode'] as String?,
      paymentMethod: map['paymentMethod'] as String?,
      status: map['status'] as String? ?? 'completed',
      brewStatus: map['brewStatus'] as String? ?? 'ready',
      isFreeRedemption: map['isFreeRedemption'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Order copyWith({String? status, String? brewStatus}) {
    return Order(
      id: id,
      userId: userId,
      orderNumber: orderNumber,
      items: items,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      couponCode: couponCode,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      brewStatus: brewStatus ?? this.brewStatus,
      isFreeRedemption: isFreeRedemption,
      createdAt: createdAt,
    );
  }
}
