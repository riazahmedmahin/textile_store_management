import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/section.dart';
import '../../models/product.dart';
import '../../models/stock_entry.dart';

/// Web-compatible storage using SharedPreferences + JSON.
/// Replaces sqflite which is not supported on Flutter Web.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static const _keySections = 'sections_v1';
  static const _keyProducts = 'products_v1';
  static const _keyStockEntries = 'stock_entries_v1';
  static const _keyNextId = 'next_id_v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ─── ID GENERATOR ────────────────────────────────────────────────────────────

  Future<int> _nextId() async {
    final p = await _p;
    final id = (p.getInt(_keyNextId) ?? 0) + 1;
    await p.setInt(_keyNextId, id);
    return id;
  }

  // ─── SECTIONS ────────────────────────────────────────────────────────────────

  Future<List<AppSection>> getSections() async {
    final p = await _p;
    var raw = p.getString(_keySections);
    if (raw == null) {
      await _insertDefaultSections();
      raw = p.getString(_keySections);
    }
    if (raw == null) return [];
    try {
      final List list = jsonDecode(raw) as List;
      return list
          .map((m) => AppSection.fromMap(Map<String, dynamic>.from(m)))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (e) {
      await p.remove(_keySections);
      await _insertDefaultSections();
      final freshRaw = p.getString(_keySections);
      if (freshRaw == null) return [];
      final List list = jsonDecode(freshRaw) as List;
      return list
          .map((m) => AppSection.fromMap(Map<String, dynamic>.from(m)))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
  }

  Future<void> _insertDefaultSections() async {
    final p = await _p;
    final defaults = [
      AppSection(
          id: 1,
          name: 'Machine Section',
          colorValue: 0xFF6C63FF,
          icon: 'precision_manufacturing'),
      AppSection(
          id: 2,
          name: 'Electric Section',
          colorValue: 0xFFFFC107,
          icon: 'electric_bolt'),
      AppSection(
          id: 3,
          name: 'Fabric Section', colorValue: 0xFF4CAF50, icon: 'texture'),
    ];
    await p.setString(
        _keySections, jsonEncode(defaults.map((s) => s.toMap()).toList()));
    await p.setInt(_keyNextId, 3);
  }

  Future<int> insertSection(AppSection section) async {
    final p = await _p;
    final sections = await getSections();
    final id = await _nextId();
    final withId = section.copyWith(id: id);
    sections.add(withId);
    await p.setString(
        _keySections, jsonEncode(sections.map((s) => s.toMap()).toList()));
    return id;
  }

  Future<void> updateSection(AppSection section) async {
    final p = await _p;
    final sections = await getSections();
    final idx = sections.indexWhere((s) => s.id == section.id);
    if (idx >= 0) sections[idx] = section;
    await p.setString(
        _keySections, jsonEncode(sections.map((s) => s.toMap()).toList()));
  }

  Future<void> deleteSection(int id) async {
    final p = await _p;
    var sections = await getSections();
    sections.removeWhere((s) => s.id == id);
    await p.setString(
        _keySections, jsonEncode(sections.map((s) => s.toMap()).toList()));
    // Cascade: delete products in this section
    var products = await getAllProducts();
    final deletedProductIds =
        products.where((pr) => pr.sectionId == id).map((pr) => pr.id!).toList();
    products.removeWhere((pr) => pr.sectionId == id);
    await p.setString(
        _keyProducts, jsonEncode(products.map((pr) => pr.toMap()).toList()));
    // Cascade: delete stock entries for those products
    var entries = await _getAllEntries();
    entries.removeWhere((e) => deletedProductIds.contains(e.productId));
    await p.setString(
        _keyStockEntries, jsonEncode(entries.map((e) => e.toMap()).toList()));
  }

  // ─── PRODUCTS ────────────────────────────────────────────────────────────────

  Future<List<Product>> getAllProducts() async {
    final p = await _p;
    final raw = p.getString(_keyProducts);
    if (raw == null) return [];
    try {
      final List list = jsonDecode(raw) as List;
      return list
          .map((m) => Product.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      await p.remove(_keyProducts);
      return [];
    }
  }

  Future<List<Product>> getProductsBySection(int sectionId) async {
    final all = await getAllProducts();
    return all.where((p) => p.sectionId == sectionId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<int> insertProduct(Product product) async {
    final p = await _p;
    final products = await getAllProducts();
    final id = await _nextId();
    final withId = product.copyWith(id: id);
    products.add(withId);
    await p.setString(
        _keyProducts, jsonEncode(products.map((pr) => pr.toMap()).toList()));
    return id;
  }

  Future<void> updateProduct(Product product) async {
    final p = await _p;
    final products = await getAllProducts();
    final idx = products.indexWhere((pr) => pr.id == product.id);
    if (idx >= 0) products[idx] = product;
    await p.setString(
        _keyProducts, jsonEncode(products.map((pr) => pr.toMap()).toList()));
  }

  Future<void> deleteProduct(int id) async {
    final p = await _p;
    var products = await getAllProducts();
    products.removeWhere((pr) => pr.id == id);
    await p.setString(
        _keyProducts, jsonEncode(products.map((pr) => pr.toMap()).toList()));
    // Cascade: delete stock entries for this product
    var entries = await _getAllEntries();
    entries.removeWhere((e) => e.productId == id);
    await p.setString(
        _keyStockEntries, jsonEncode(entries.map((e) => e.toMap()).toList()));
  }

  // ─── STOCK ENTRIES ───────────────────────────────────────────────────────────

  Future<List<StockEntry>> _getAllEntries() async {
    final p = await _p;
    final raw = p.getString(_keyStockEntries);
    if (raw == null) return [];
    try {
      final List list = jsonDecode(raw) as List;
      return list
          .map((m) => StockEntry.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      await p.remove(_keyStockEntries);
      return [];
    }
  }

  Future<List<StockEntry>> getStockEntriesByProduct(int productId) async {
    final entries = await _getAllEntries();
    final products = await getAllProducts();
    final sections = await getSections();
    final Map<int, Product> productMap = {for (var p in products) p.id!: p};
    final Map<int, AppSection> sectionMap = {for (var s in sections) s.id!: s};

    return entries.where((e) => e.productId == productId).map((e) {
      final prod = productMap[e.productId];
      final sec = prod != null ? sectionMap[prod.sectionId] : null;
      return StockEntry(
        id: e.id,
        productId: e.productId,
        type: e.type,
        quantity: e.quantity,
        date: e.date,
        billNo: e.billNo,
        note: e.note,
        createdAt: e.createdAt,
        productName: prod?.name,
        productUnit: prod?.unit,
        sectionName: sec?.name,
        sectionId: sec?.id,
      );
    }).toList()
      ..sort((a, b) {
        final dateComp = b.date.compareTo(a.date);
        return dateComp != 0 ? dateComp : b.createdAt.compareTo(a.createdAt);
      });
  }

  Future<List<StockEntry>> getAllStockEntries({
    int? sectionId,
    int? productId,
    String? billNo,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final entries = await _getAllEntries();
    final products = await getAllProducts();
    final sections = await getSections();
    final Map<int, Product> productMap = {for (var p in products) p.id!: p};
    final Map<int, AppSection> sectionMap = {for (var s in sections) s.id!: s};

    final enriched = entries.map((e) {
      final prod = productMap[e.productId];
      final sec = prod != null ? sectionMap[prod.sectionId] : null;
      return StockEntry(
        id: e.id,
        productId: e.productId,
        type: e.type,
        quantity: e.quantity,
        date: e.date,
        billNo: e.billNo,
        note: e.note,
        createdAt: e.createdAt,
        productName: prod?.name,
        productUnit: prod?.unit,
        sectionName: sec?.name,
        sectionId: sec?.id,
      );
    }).toList();

    return enriched.where((e) {
      if (productId != null && e.productId != productId) return false;
      if (sectionId != null && e.sectionId != sectionId) return false;
      if (billNo != null &&
          billNo.isNotEmpty &&
          !e.billNo.toLowerCase().contains(billNo.toLowerCase())) return false;
      if (fromDate != null && e.date.isBefore(fromDate)) return false;
      if (toDate != null && e.date.isAfter(toDate.add(const Duration(days: 1))))
        return false;
      return true;
    }).toList()
      ..sort((a, b) {
        final d = b.date.compareTo(a.date);
        return d != 0 ? d : b.createdAt.compareTo(a.createdAt);
      });
  }

  Future<int> insertStockEntry(StockEntry entry) async {
    final p = await _p;
    final entries = await _getAllEntries();
    final id = await _nextId();
    final withId = entry.copyWith(id: id);
    entries.add(withId);
    await p.setString(
        _keyStockEntries, jsonEncode(entries.map((e) => e.toMap()).toList()));
    return id;
  }

  Future<void> deleteStockEntry(int id) async {
    final p = await _p;
    var entries = await _getAllEntries();
    entries.removeWhere((e) => e.id == id);
    await p.setString(
        _keyStockEntries, jsonEncode(entries.map((e) => e.toMap()).toList()));
  }

  Future<void> updateStockEntry(StockEntry entry) async {
    final p = await _p;
    var entries = await _getAllEntries();
    final idx = entries.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) entries[idx] = entry;
    await p.setString(
        _keyStockEntries, jsonEncode(entries.map((e) => e.toMap()).toList()));
  }

  // ─── STOCK CALCULATION ───────────────────────────────────────────────────────

  Future<double> getCurrentStock(int productId, double initialStock) async {
    final entries = await _getAllEntries();
    final relevant = entries.where((e) => e.productId == productId);
    final totalIn = relevant
        .where((e) => e.type == 'in')
        .fold(0.0, (s, e) => s + e.quantity);
    final totalOut = relevant
        .where((e) => e.type == 'out')
        .fold(0.0, (s, e) => s + e.quantity);
    return initialStock + totalIn - totalOut;
  }

  // ─── SECTION STATS ───────────────────────────────────────────────────────────

  /// Returns a map of sectionId → { 'product_count': int, 'total_stock': double }
  Future<Map<int, Map<String, dynamic>>> getSectionStats() async {
    final products = await getAllProducts();
    final entries = await _getAllEntries();

    // Group products by section
    final Map<int, List<Product>> bySection = {};
    for (final p in products) {
      bySection.putIfAbsent(p.sectionId, () => []).add(p);
    }

    // Compute current stock for each product
    final Map<int, double> productStock = {};
    for (final p in products) {
      final productEntries = entries.where((e) => e.productId == p.id!);
      final totalIn = productEntries
          .where((e) => e.type == 'in')
          .fold(0.0, (s, e) => s + e.quantity);
      final totalOut = productEntries
          .where((e) => e.type == 'out')
          .fold(0.0, (s, e) => s + e.quantity);
      productStock[p.id!] = p.initialStock + totalIn - totalOut;
    }

    final Map<int, Map<String, dynamic>> result = {};
    for (final entry in bySection.entries) {
      final sectionId = entry.key;
      final prods = entry.value;
      final totalStock =
          prods.fold(0.0, (s, p) => s + (productStock[p.id!] ?? 0.0));
      result[sectionId] = {
        'product_count': prods.length,
        'total_stock': totalStock,
      };
    }
    return result;
  }

  // ─── DASHBOARD STATS ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardStats() async {
    final sections = await getSections();
    final products = await getAllProducts();
    final entries = await _getAllEntries();

    final initialStockSum = products.fold(0.0, (s, p) => s + p.initialStock);

    final totalIn = entries
        .where((e) => e.type == 'in')
        .fold(0.0, (s, e) => s + e.quantity) + initialStockSum;
    final totalOut = entries
        .where((e) => e.type == 'out')
        .fold(0.0, (s, e) => s + e.quantity);

    final now = DateTime.now();
    final todayEntries = entries.where((e) {
      return e.date.year == now.year &&
             e.date.month == now.month &&
             e.date.day == now.day;
    });

    final todayIn = todayEntries
        .where((e) => e.type == 'in')
        .fold(0.0, (s, e) => s + e.quantity);
    final todayOut = todayEntries
        .where((e) => e.type == 'out')
        .fold(0.0, (s, e) => s + e.quantity);

    int lowStockCount = 0;
    int outOfStockCount = 0;
    for (final p in products) {
      final productEntries = entries.where((e) => e.productId == p.id!);
      final prodIn = productEntries
          .where((e) => e.type == 'in')
          .fold(0.0, (s, e) => s + e.quantity);
      final prodOut = productEntries
          .where((e) => e.type == 'out')
          .fold(0.0, (s, e) => s + e.quantity);
      final currentStock = p.initialStock + prodIn - prodOut;
      if (currentStock <= 0) {
        outOfStockCount++;
      } else if (currentStock < 5) {
        lowStockCount++;
      }
    }

    final Map<int, Product> productMap = {for (var p in products) p.id!: p};
    final Map<int, AppSection> sectionMap = {for (var s in sections) s.id!: s};

    final recent = entries.map((e) {
      final prod = productMap[e.productId];
      final sec = prod != null ? sectionMap[prod.sectionId] : null;
      return StockEntry(
        id: e.id,
        productId: e.productId,
        type: e.type,
        quantity: e.quantity,
        date: e.date,
        billNo: e.billNo,
        note: e.note,
        createdAt: e.createdAt,
        productName: prod?.name,
        productUnit: prod?.unit,
        sectionName: sec?.name,
        sectionId: sec?.id,
      );
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return {
      'section_count': sections.length,
      'product_count': products.length,
      'total_in': totalIn,
      'total_out': totalOut,
      'today_in': todayIn,
      'today_out': todayOut,
      'low_stock_count': lowStockCount,
      'out_of_stock_count': outOfStockCount,
      'recent_entries': recent.take(10).toList(),
    };
  }
}
