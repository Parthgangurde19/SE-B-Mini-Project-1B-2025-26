class InventoryItem {
  final String? id;
  final String name;
  final String unit; // kg, L, pcs
  final double currentStock;
  final double minStock;
  final DateTime? lastRestocked;

  bool get isLowStock => currentStock <= minStock;

  InventoryItem({
    this.id,
    required this.name,
    required this.unit,
    required this.currentStock,
    required this.minStock,
    this.lastRestocked,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'currentStock': currentStock,
      'minStock': minStock,
      'lastRestocked': lastRestocked?.toIso8601String(),
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as String?,
      name: map['name'] as String,
      unit: map['unit'] as String,
      currentStock: (map['currentStock'] as num?)?.toDouble() ?? 0.0,
      minStock: ((map['minStock'] ?? map['minimumStock']) as num?)?.toDouble() ?? 0.0,
      lastRestocked: map['lastRestocked'] != null
          ? DateTime.parse(map['lastRestocked'] as String)
          : null,
    );
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? unit,
    double? currentStock,
    double? minStock,
    DateTime? lastRestocked,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      lastRestocked: lastRestocked ?? this.lastRestocked,
    );
  }
}
