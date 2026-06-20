import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/section.dart';
import '../../models/product.dart';
import '../widgets/product_form_dialog.dart';
import '../stock/stock_history_screen.dart';
import '../stock/stock_entry_screen.dart';

class SectionDetailScreen extends StatefulWidget {
  final AppSection section;
  const SectionDetailScreen({super.key, required this.section});

  @override
  State<SectionDetailScreen> createState() => _SectionDetailScreenState();
}

class _SectionDetailScreenState extends State<SectionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProductsForSection(widget.section.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: Column(
        children: [
          // Top bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: AppTheme.bgCard,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.bgSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.section.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _iconFromString(widget.section.icon),
                    color: widget.section.color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.section.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Text(
                      'Product Management',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddProduct(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Product'),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                final products = provider.getProductsForSection(widget.section.id!);
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: widget.section.color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(Icons.inventory_2_outlined,
                              color: widget.section.color, size: 32),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No products yet',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Add products to start tracking stock',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => _showAddProduct(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Product'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: products.length,
                  itemBuilder: (ctx, i) => _ProductRow(
                    product: products[i],
                    sectionColor: widget.section.color,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProduct(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ProductFormDialog(sectionId: widget.section.id!),
    );
  }

  IconData _iconFromString(String name) {
    const map = {
      'precision_manufacturing': Icons.precision_manufacturing_rounded,
      'electric_bolt': Icons.electric_bolt_rounded,
      'texture': Icons.texture_rounded,
      'build': Icons.build_rounded,
      'local_shipping': Icons.local_shipping_rounded,
      'inventory': Icons.inventory_2_rounded,
      'category': Icons.category_rounded,
    };
    return map[name] ?? Icons.category_rounded;
  }
}

// ─── Product Row ──────────────────────────────────────────────────────────────

class _ProductRow extends StatefulWidget {
  final Product product;
  final Color sectionColor;
  const _ProductRow({required this.product, required this.sectionColor});

  @override
  State<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<_ProductRow> {
  @override
  void initState() {
    super.initState();
    _loadStock();
  }

  Future<void> _loadStock() async {
    await context
        .read<StockProvider>()
        .loadEntriesForProduct(widget.product.id!, widget.product.initialStock);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: widget.sectionColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.inventory_2_outlined,
                      color: widget.sectionColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Unit: ${widget.product.unit}  ·  Opening: ${widget.product.initialStock.toStringAsFixed(0)} ${widget.product.unit}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Consumer<StockProvider>(
                  builder: (context, sp, _) {
                    final stock = sp.getCurrentStock(widget.product.id!);
                    final isLow = stock < 5;
                    return Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isLow
                            ? AppTheme.danger.withOpacity(0.08)
                            : AppTheme.success.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isLow
                              ? AppTheme.danger.withOpacity(0.3)
                              : AppTheme.success.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLow ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                            size: 14,
                            color: isLow ? AppTheme.danger : AppTheme.success,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${stock.toStringAsFixed(1)} ${widget.product.unit}',
                            style: TextStyle(
                              color: isLow ? AppTheme.danger : AppTheme.success,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppTheme.textMuted, size: 18),
                  onSelected: (v) {
                    if (v == 'edit') {
                      showDialog(
                        context: context,
                        builder: (_) => ProductFormDialog(
                          sectionId: widget.product.sectionId,
                          product: widget.product,
                        ),
                      );
                    } else if (v == 'delete') {
                      _confirmDelete(context);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 16, color: AppTheme.primary),
                        SizedBox(width: 8),
                        Text('Edit', style: TextStyle(fontSize: 14)),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline, size: 16, color: AppTheme.danger),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: AppTheme.danger, fontSize: 14)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Row(
            children: [
              _ActionBtn(
                icon: Icons.arrow_downward_rounded,
                label: 'Stock In',
                color: AppTheme.success,
                onTap: () => _openEntry(context, 'in'),
              ),
              Container(width: 1, height: 36, color: AppTheme.border),
              _ActionBtn(
                icon: Icons.arrow_upward_rounded,
                label: 'Stock Out',
                color: AppTheme.danger,
                onTap: () => _openEntry(context, 'out'),
              ),
              Container(width: 1, height: 36, color: AppTheme.border),
              _ActionBtn(
                icon: Icons.history_rounded,
                label: 'History',
                color: AppTheme.primary,
                onTap: () => _openHistory(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openEntry(BuildContext ctx, String type) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => StockEntryScreen(product: widget.product, type: type),
      ),
    ).then((_) => _loadStock());
  }

  void _openHistory(BuildContext ctx) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => StockHistoryScreen(product: widget.product),
      ),
    ).then((_) => _loadStock());
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Delete "${widget.product.name}"? All stock entries will also be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<ProductProvider>()
                  .deleteProduct(widget.product.id!, widget.product.sectionId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15, color: color),
        label: Text(label, style: TextStyle(color: color, fontSize: 13)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: const RoundedRectangleBorder(),
        ),
      ),
    );
  }
}
