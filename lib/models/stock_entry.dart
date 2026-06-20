class StockEntry {
  final int? id;
  final int productId;
  final String type; // 'in' or 'out'
  final double quantity;
  final DateTime date;
  final String billNo;
  final String? note;
  final DateTime createdAt;

  // Optional join fields
  final String? productName;
  final String? productUnit;
  final String? sectionName;
  final int? sectionId;

  StockEntry({
    this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    required this.date,
    required this.billNo,
    this.note,
    DateTime? createdAt,
    this.productName,
    this.productUnit,
    this.sectionName,
    this.sectionId,
  }) : createdAt = createdAt ?? DateTime.now();

  StockEntry copyWith({
    int? id,
    int? productId,
    String? type,
    double? quantity,
    DateTime? date,
    String? billNo,
    String? note,
    DateTime? createdAt,
  }) {
    return StockEntry(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      date: date ?? this.date,
      billNo: billNo ?? this.billNo,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'type': type,
      'quantity': quantity,
      'date': date.toIso8601String(),
      'bill_no': billNo,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StockEntry.fromMap(Map<String, dynamic> map) {
    return StockEntry(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      type: map['type'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      billNo: map['bill_no'] as String,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      productName: map['product_name'] as String?,
      productUnit: map['product_unit'] as String?,
      sectionName: map['section_name'] as String?,
      sectionId: map['section_id'] as int?,
    );
  }
}
