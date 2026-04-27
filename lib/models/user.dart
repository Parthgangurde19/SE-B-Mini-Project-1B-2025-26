class User {
  final String? id;
  final String name;
  final String email;
  final String password;
  final String role;
  final int loyaltyPoints;
  final bool freeItemReady;
  // { 'menuItemId': { 'count': 15, 'lastOrderedAt': '2025-01-01T00:00:00.000' } }
  final Map<String, Map<String, dynamic>> orderFrequency;

  bool get isAdmin =>
      role == 'admin' || email.toLowerCase() == 'admin@coffee.com';

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.role = 'customer',
    this.loyaltyPoints = 0,
    this.freeItemReady = false,
    this.orderFrequency = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'loyaltyPoints': loyaltyPoints,
      'freeItemReady': freeItemReady,
      'orderFrequency': orderFrequency,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    // Parse orderFrequency — Firestore returns Map<String, dynamic> nested
    final rawFreq = map['orderFrequency'];
    final Map<String, Map<String, dynamic>> freq = {};
    if (rawFreq is Map) {
      rawFreq.forEach((key, value) {
        if (value is Map) {
          freq[key.toString()] = Map<String, dynamic>.from(value);
        }
      });
    }

    return User(
      id: map['id'] as String?,
      name: map['name'] as String? ?? 'Unknown',
      email: map['email'] as String? ?? '',
      password: map['password'] as String? ?? '',
      role: map['role'] as String? ?? 'customer',
      loyaltyPoints: (map['loyaltyPoints'] as num?)?.toInt() ?? 0,
      freeItemReady: map['freeItemReady'] as bool? ?? false,
      orderFrequency: freq,
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? role,
    int? loyaltyPoints,
    bool? freeItemReady,
    Map<String, Map<String, dynamic>>? orderFrequency,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      freeItemReady: freeItemReady ?? this.freeItemReady,
      orderFrequency: orderFrequency ?? this.orderFrequency,
    );
  }
}
