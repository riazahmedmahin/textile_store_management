import 'package:flutter/material.dart';
import '../core/database/db_helper.dart';
import '../models/section.dart';

class SectionProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<AppSection> _sections = [];
  bool _isLoading = false;

  List<AppSection> get sections => _sections;
  bool get isLoading => _isLoading;

  Future<void> loadSections() async {
    _isLoading = true;
    notifyListeners();
    _sections = await _db.getSections();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSection(AppSection section) async {
    final id = await _db.insertSection(section);
    _sections.add(section.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateSection(AppSection section) async {
    await _db.updateSection(section);
    final idx = _sections.indexWhere((s) => s.id == section.id);
    if (idx != -1) {
      _sections[idx] = section;
      notifyListeners();
    }
  }

  Future<void> deleteSection(int id) async {
    await _db.deleteSection(id);
    _sections.removeWhere((s) => s.id == id);
    notifyListeners();
  }
}
