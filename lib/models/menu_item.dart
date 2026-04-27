class MenuItem {
  final String? id;
  final String name;
  final String category;
  final double price;
  final String iconName;
  final bool isAvailable;

  MenuItem({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    this.iconName = 'coffee',
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'iconName': iconName,
      'isAvailable': isAvailable,
    };
  }

  factory MenuItem.fromMap(Map<String, dynamic> map) {
    final avail = map['isAvailable'];
    final isAvailable = avail is bool ? avail : (avail as int?) == 1;
    return MenuItem(
      id: map['id'] as String?,
      name: map['name'] as String,
      category: map['category'] as String,
      price: (map['price'] as num).toDouble(),
      iconName: map['iconName'] as String? ?? 'coffee',
      isAvailable: isAvailable,
    );
  }

  MenuItem copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? iconName,
    bool? isAvailable,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      iconName: iconName ?? this.iconName,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
