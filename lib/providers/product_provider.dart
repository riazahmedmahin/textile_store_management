import 'package:flutter/material.dart';
import '../core/database/db_helper.dart';
import '../models/product.dart';

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
    final id = await _db.insertProduct(product);
    final newProduct = product.copyWith(id: id);
    _productsBySection[product.sectionId] ??= [];
    _productsBySection[product.sectionId]!.add(newProduct);
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
