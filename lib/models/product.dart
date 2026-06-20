class Product {
  final int? id;
  final int sectionId;
  final String name;
  final String unit; // pcs, meter, kg, roll, etc.
  final double initialStock;
  final DateTime createdAt;

  Product({
    this.id,
    required this.sectionId,
    required this.name,
    required this.unit,
    this.initialStock = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Product copyWith({
    int? id,
    int? sectionId,
    String? name,
    String? unit,
    double? initialStock,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      initialStock: initialStock ?? this.initialStock,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'section_id': sectionId,
      'name': name,
      'unit': unit,
      'initial_stock': initialStock,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      sectionId: map['section_id'] as int,
      name: map['name'] as String,
      unit: map['unit'] as String,
      initialStock: (map['initial_stock'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
