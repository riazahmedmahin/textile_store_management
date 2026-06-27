import 'package:flutter/material.dart';
import '../core/database/db_helper.dart';
import '../models/product.dart';
import '../models/stock_entry.dart';

class ProductProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Map<int, List<Product>> _productsBySection = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<Product> getProductsForSection(int sectionId) =>
      _productsBySection[sectionId] ?? [];

  Future<void> loadProductsForSection(int sectionId) async {
    _isLoading = true;
    notifyListeners();
    _productsBySection[sectionId] = await _db.getProductsBySection(sectionId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    final openingQty = product.initialStock;
    // Save product with initialStock=0 so stock calculation won't double-count
    final productToSave = openingQty > 0
        ? product.copyWith(initialStock: 0)
        : product;
    final id = await _db.insertProduct(productToSave);
    final newProduct = productToSave.copyWith(id: id);
    _productsBySection[product.sectionId] ??= [];
    _productsBySection[product.sectionId]!.add(newProduct);
    // If there's an opening stock, create a Stock In entry for it
    if (openingQty > 0) {
      final openingEntry = StockEntry(
        productId: id,
        type: 'in',
        quantity: openingQty,
        date: product.createdAt,
        billNo: 'Opening Stock',
        note: 'Initial opening stock',
      );
      await _db.insertStockEntry(openingEntry);
    }
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    await _db.updateProduct(product);
    final list = _productsBySection[product.sectionId];
    if (list != null) {
      final idx = list.indexWhere((p) => p.id == product.id);
      if (idx != -1) {
        list[idx] = product;
        notifyListeners();
      }
    }
  }

  Future<void> deleteProduct(int productId, int sectionId) async {
    await _db.deleteProduct(productId);
    _productsBySection[sectionId]?.removeWhere((p) => p.id == productId);
    notifyListeners();
  }
}
