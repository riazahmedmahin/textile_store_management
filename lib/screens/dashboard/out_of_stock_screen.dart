import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/section_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../models/section.dart';

class OutOfStockScreen extends StatefulWidget {
  const OutOfStockScreen({super.key});

  @override
  State<OutOfStockScreen> createState() => _OutOfStockScreenState();
}

class _OutOfStockScreenState extends State<OutOfStockScreen> {
  String _searchQuery = '';
  String? _selectedSectionId;

  @override
  Widget build(BuildContext context) {
    return Consumer3<SectionProvider, ProductProvider, StockProvider>(
      builder: (context, secProvider, prodProvider, stockProvider, _) {
        // Collect all out-of-stock items
        final List<Map<String, dynamic>> outOfStockItems = [];

        for (final section in secProvider.sections) {
          if (section.id == null) continue;
          final products = prodProvider.getProductsForSection(section.id!);
          for (final product in products) {
            if (product.id == null) continue;
            final stock = stockProvider.getCurrentStock(product.id!);
            if (stock <= 0) {
              outOfStockItems.add({
                'product': product,
                'section': section,
                'stock': stock,
              });
            }
          }
        }

        // Build section filter list
        final sectionIds = outOfStockItems
            .map((e) => (e['section'] as AppSection).id.toString())
            .toSet()
            .toList();

        // Apply filters
        final filtered = outOfStockItems.where((item) {
          final product = item['product'] as Product;
          final section = item['section'] as AppSection;

          final matchSearch = _searchQuery.isEmpty ||
              product.name
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              section.name
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase());

          final matchSection = _selectedSectionId == null ||
              section.id.toString() == _selectedSectionId;

          return matchSearch && matchSection;
        }).toList();

        // Section name map
        final sectionMap = {
          for (final s in secProvider.sections)
            if (s.id != null) s.id.toString(): s.name
        };

        return Scaffold(
          backgroundColor: AppTheme.bgPage,
          body: Column(
            children: [
              // ── Top Bar ──────────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: AppTheme.bgCard,
                  border:
                      Border(bottom: BorderSide(color: AppTheme.border)),
                ),
                child: Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.danger.withAlpha(40)),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: AppTheme.danger, size: 20),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Icon + Title
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.error_outline_rounded,
                          color: AppTheme.danger, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Out of Stock Items',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            '${outOfStockItems.length} items with no stock',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withAlpha(15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.danger.withAlpha(50)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              color: AppTheme.danger, size: 14),
                          const SizedBox(width: 5),
                          Text(
                            '${filtered.length}/${outOfStockItems.length}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Search + Filter Bar ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                color: AppTheme.bgCard,
                child: Row(
                  children: [
                    // Search field
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.bgPage,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: TextField(
                          onChanged: (v) =>
                              setState(() => _searchQuery = v),
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary),
                          decoration: const InputDecoration(
                           hintText: 'Search by product or section...',
                            hintStyle: TextStyle(
                                fontSize: 13, color: AppTheme.textMuted),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: AppTheme.textMuted, size: 18),
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Section filter dropdown
                    if (sectionIds.length > 1)
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.bgPage,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedSectionId,
                            hint: const Text('All Sections',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted)),
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textPrimary),
                            icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: AppTheme.textMuted),
                            onChanged: (v) =>
                                setState(() => _selectedSectionId = v),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('All Sections'),
                              ),
                              ...sectionIds.map((id) => DropdownMenuItem(
                                    value: id,
                                    child: Text(
                                        sectionMap[id] ?? id,
                                        style: const TextStyle(
                                            fontSize: 12)),
                                  )),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── List ─────────────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty ||
                                      _selectedSectionId != null
                                  ? Icons.search_off_rounded
                                  : Icons.check_circle_outline_rounded,
                              color: AppTheme.textMuted.withAlpha(100),
                              size: 56,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty ||
                                      _selectedSectionId != null
                                  ? 'No results found'
                                  : 'All items are in stock! 🎉',
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final product = item['product'] as Product;
                          final section = item['section'] as AppSection;

                          return _OutOfStockTile(
                            index: index + 1,
                            product: product,
                            section: section,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Single Row Tile ────────────────────────────────────────────────────────────
class _OutOfStockTile extends StatefulWidget {
  final int index;
  final Product product;
  final AppSection section;

  const _OutOfStockTile({
    required this.index,
    required this.product,
    required this.section,
  });

  @override
  State<_OutOfStockTile> createState() => _OutOfStockTileState();
}

class _OutOfStockTileState extends State<_OutOfStockTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _hovered
              ? AppTheme.danger.withAlpha(8)
              : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                _hovered ? AppTheme.danger.withAlpha(80) : AppTheme.border,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.danger.withAlpha(_hovered ? 20 : 8),
              blurRadius: _hovered ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Index number
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.danger.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.index}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.danger,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.folder_outlined,
                          size: 11, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        widget.section.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Out of stock badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.danger.withAlpha(15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.danger.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.remove_circle_outline_rounded,
                      size: 12, color: AppTheme.danger),
                  const SizedBox(width: 4),
                  Text(
                    '0 ${widget.product.unit}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.danger,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
