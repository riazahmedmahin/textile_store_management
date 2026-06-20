import 'package:flutter/material.dart';
import '../core/database/db_helper.dart';
import '../models/stock_entry.dart';

class StockProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  final Map<int, List<StockEntry>> _entriesByProduct = {};
  final Map<int, double> _currentStock = {};
  List<StockEntry> _allEntries = [];
  Map<String, dynamic> _dashboardStats = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<StockEntry> get allEntries => _allEntries;
  Map<String, dynamic> get dashboardStats => _dashboardStats;

  List<StockEntry> getEntriesForProduct(int productId) =>
      _entriesByProduct[productId] ?? [];

  double getCurrentStock(int productId) => _currentStock[productId] ?? 0.0;

  Future<void> loadEntriesForProduct(int productId, double initialStock) async {
    _isLoading = true;
    notifyListeners();
    _entriesByProduct[productId] = await _db.getStockEntriesByProduct(productId);
    _currentStock[productId] = await _db.getCurrentStock(productId, initialStock);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEntry(StockEntry entry, double initialStock) async {
    final id = await _db.insertStockEntry(entry);
    final newEntry = entry.copyWith(id: id);
    _entriesByProduct[entry.productId] ??= [];
    _entriesByProduct[entry.productId]!.insert(0, newEntry);
    _currentStock[entry.productId] =
        await _db.getCurrentStock(entry.productId, initialStock);
    notifyListeners();
    await loadDashboardStats();
  }

  Future<void> deleteEntry(int entryId, int productId, double initialStock) async {
    await _db.deleteStockEntry(entryId);
    _entriesByProduct[productId]?.removeWhere((e) => e.id == entryId);
    _currentStock[productId] =
        await _db.getCurrentStock(productId, initialStock);
    notifyListeners();
    await loadDashboardStats();
  }

  Future<void> loadAllEntries({
    int? sectionId,
    int? productId,
    String? billNo,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    _isLoading = true;
    notifyListeners();
    _allEntries = await _db.getAllStockEntries(
      sectionId: sectionId,
      productId: productId,
      billNo: billNo,
      fromDate: fromDate,
      toDate: toDate,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDashboardStats() async {
    _dashboardStats = await _db.getDashboardStats();
    notifyListeners();
  }
}
