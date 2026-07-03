import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/section.dart';
import '../../models/product.dart';
import '../../models/stock_entry.dart';

/// Cloud-compatible storage using Supabase database.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  final _supabase = Supabase.instance.client;

  // ─── SECTIONS ────────────────────────────────────────────────────────────────

  Future<List<AppSection>> getSections() async {
    try {
      final response = await _supabase
          .from('sections')
          .select()
          .order('created_at', ascending: true);
      return response.map((m) => AppSection.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> insertSection(AppSection section) async {
    final data = section.toMap();
    // Remove ID if null to let database auto-generate it
    if (section.id == null) {
      data.remove('id');
    }
    final response = await _supabase
        .from('sections')
        .insert(data)
        .select('id')
        .single();
    return response['id'] as int;
  }

  Future<void> updateSection(AppSection section) async {
    await _supabase
        .from('sections')
        .update(section.toMap())
        .eq('id', section.id!);
  }

  Future<void> deleteSection(int id) async {
    // Note: Database cascade delete will automatically handle products and stock entries
    await _supabase
        .from('sections')
        .delete()
        .eq('id', id);
  }

  // ─── PRODUCTS ────────────────────────────────────────────────────────────────

  Future<List<Product>> getAllProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select();
      return response.map((m) => Product.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Product>> getProductsBySection(int sectionId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('section_id', sectionId)
          .order('name', ascending: true);
      return response.map((m) => Product.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<int> insertProduct(Product product) async {
    final data = product.toMap();
    if (product.id == null) {
      data.remove('id');
    }
    final response = await _supabase
        .from('products')
        .insert(data)
        .select('id')
        .single();
    return response['id'] as int;
  }

  Future<void> updateProduct(Product product) async {
    await _supabase
        .from('products')
        .update(product.toMap())
        .eq('id', product.id!);
  }

  Future<void> deleteProduct(int id) async {
    // Note: Database cascade delete will handle stock entries
    await _supabase
        .from('products')
        .delete()
        .eq('id', id);
  }

  // ─── STOCK ENTRIES ───────────────────────────────────────────────────────────

  Future<List<StockEntry>> getStockEntriesByProduct(int productId) async {
    try {
      final response = await _supabase
          .from('stock_entries')
          .select('*, products(*, sections(*))')
          .eq('product_id', productId)
          .order('date', ascending: false)
          .order('created_at', ascending: false);

      return response.map((m) {
        final prodMap = m['products'] as Map<String, dynamic>?;
        final secMap = prodMap != null ? prodMap['sections'] as Map<String, dynamic>? : null;
        return StockEntry.fromMap({
          ...m,
          'product_name': prodMap?['name'],
          'product_unit': prodMap?['unit'],
          'section_name': secMap?['name'],
          'section_id': secMap?['id'],
        });
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<StockEntry>> getAllStockEntries({
    int? sectionId,
    int? productId,
    String? billNo,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final response = await _supabase
          .from('stock_entries')
          .select('*, products(*, sections(*))');

      final list = response.map((m) {
        final prodMap = m['products'] as Map<String, dynamic>?;
        final secMap = prodMap != null ? prodMap['sections'] as Map<String, dynamic>? : null;
        return StockEntry.fromMap({
          ...m,
          'product_name': prodMap?['name'],
          'product_unit': prodMap?['unit'],
          'section_name': secMap?['name'],
          'section_id': secMap?['id'],
        });
      }).toList();

      return list.where((e) {
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
    } catch (e) {
      return [];
    }
  }

  Future<int> insertStockEntry(StockEntry entry) async {
    final data = entry.toMap();
    if (entry.id == null) {
      data.remove('id');
    }
    final response = await _supabase
        .from('stock_entries')
        .insert(data)
        .select('id')
        .single();
    return response['id'] as int;
  }

  Future<void> deleteStockEntry(int id) async {
    await _supabase
        .from('stock_entries')
        .delete()
        .eq('id', id);
  }

  Future<void> updateStockEntry(StockEntry entry) async {
    await _supabase
        .from('stock_entries')
        .update(entry.toMap())
        .eq('id', entry.id!);
  }

  // ─── STOCK CALCULATION ───────────────────────────────────────────────────────

  Future<double> getCurrentStock(int productId, double initialStock) async {
    try {
      final response = await _supabase
          .from('stock_entries')
          .select('type, quantity')
          .eq('product_id', productId);

      final totalIn = response
          .where((e) => e['type'] == 'in')
          .fold(0.0, (s, e) => s + (e['quantity'] as num).toDouble());
      final totalOut = response
          .where((e) => e['type'] == 'out')
          .fold(0.0, (s, e) => s + (e['quantity'] as num).toDouble());
      return initialStock + totalIn - totalOut;
    } catch (e) {
      return initialStock;
    }
  }

  // ─── SECTION STATS ───────────────────────────────────────────────────────────

  Future<Map<int, Map<String, dynamic>>> getSectionStats() async {
    try {
      final products = await getAllProducts();
      final entriesResponse = await _supabase
          .from('stock_entries')
          .select('product_id, type, quantity');

      // Group products by section
      final Map<int, List<Product>> bySection = {};
      for (final p in products) {
        bySection.putIfAbsent(p.sectionId, () => []).add(p);
      }

      // Compute current stock for each product
      final Map<int, double> productStock = {};
      for (final p in products) {
        final productEntries = entriesResponse.where((e) => e['product_id'] == p.id!);
        final totalIn = productEntries
            .where((e) => e['type'] == 'in')
            .fold(0.0, (s, e) => s + (e['quantity'] as num).toDouble());
        final totalOut = productEntries
            .where((e) => e['type'] == 'out')
            .fold(0.0, (s, e) => s + (e['quantity'] as num).toDouble());
        productStock[p.id!] = p.initialStock + totalIn - totalOut;
      }

      final Map<int, Map<String, dynamic>> result = {};
      for (final entry in bySection.entries) {
        final sectionId = entry.key;
        final prods = entry.value;
        final totalStock = prods.fold(0.0, (s, p) => s + (productStock[p.id!] ?? 0.0));
        result[sectionId] = {
          'product_count': prods.length,
          'total_stock': totalStock,
        };
      }
      return result;
    } catch (e) {
      return {};
    }
  }

  // ─── DASHBOARD STATS ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final sections = await getSections();
      final products = await getAllProducts();
      final entriesResponse = await _supabase
          .from('stock_entries')
          .select('*, products(*, sections(*))');

      final entries = entriesResponse.map((m) {
        final prodMap = m['products'] as Map<String, dynamic>?;
        final secMap = prodMap != null ? prodMap['sections'] as Map<String, dynamic>? : null;
        return StockEntry.fromMap({
          ...m,
          'product_name': prodMap?['name'],
          'product_unit': prodMap?['unit'],
          'section_name': secMap?['name'],
          'section_id': secMap?['id'],
        });
      }).toList();

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

      final recent = List<StockEntry>.from(entries)
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
    } catch (e) {
      return {
        'section_count': 0,
        'product_count': 0,
        'total_in': 0.0,
        'total_out': 0.0,
        'today_in': 0.0,
        'today_out': 0.0,
        'low_stock_count': 0,
        'out_of_stock_count': 0,
        'recent_entries': <StockEntry>[],
      };
    }
  }
}
