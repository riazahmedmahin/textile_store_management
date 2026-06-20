import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/stock_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../models/stock_entry.dart';

class StockHistoryScreen extends StatefulWidget {
  final Product product;
  const StockHistoryScreen({super.key, required this.product});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<StockProvider>()
          .loadEntriesForProduct(widget.product.id!, widget.product.initialStock);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: Column(
        children: [
          // Top Bar
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.history_rounded, color: AppTheme.primary, size: 22),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.product.name} — History',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Text(
                      'Complete stock movement log',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Consumer<StockProvider>(
              builder: (context, sp, _) {
                final entries = sp.getEntriesForProduct(widget.product.id!);
                final currentStock = sp.getCurrentStock(widget.product.id!);

                return Column(
                  children: [
                    // Summary Bar
                    _buildSummaryBar(entries, currentStock),
                    // List
                    Expanded(
                      child: sp.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : entries.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 68,
                                        height: 68,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: const Icon(Icons.history_rounded,
                                            color: AppTheme.primary, size: 30),
                                      ),
                                      const SizedBox(height: 14),
                                      const Text('No stock entries yet',
                                          style: TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(24),
                                  itemCount: entries.length,
                                  itemBuilder: (ctx, i) => _EntryRow(
                                      entry: entries[i],
                                      product: widget.product),
                                ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSummaryBar(List<StockEntry> entries, double currentStock) {
    final totalIn =
        entries.where((e) => e.type == 'in').fold(0.0, (s, e) => s + e.quantity);
    final totalOut =
        entries.where((e) => e.type == 'out').fold(0.0, (s, e) => s + e.quantity);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.bgSurface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            _SummaryChip(
              label: 'Opening',
              value: widget.product.initialStock,
              unit: widget.product.unit,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            const Icon(Icons.add, size: 14, color: AppTheme.textMuted),
            const SizedBox(width: 6),
            _SummaryChip(
              label: 'Total In',
              value: totalIn,
              unit: widget.product.unit,
              color: AppTheme.success,
            ),
            const SizedBox(width: 6),
            const Icon(Icons.remove, size: 14, color: AppTheme.textMuted),
            const SizedBox(width: 6),
            _SummaryChip(
              label: 'Total Out',
              value: totalOut,
              unit: widget.product.unit,
              color: AppTheme.danger,
            ),
            const SizedBox(width: 6),
            const Icon(Icons.drag_handle, size: 14, color: AppTheme.textMuted),
            const SizedBox(width: 6),
            _SummaryChip(
              label: 'Current',
              value: currentStock,
              unit: widget.product.unit,
              color: AppTheme.primary,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;
  final bool bold;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ─── Entry Row ────────────────────────────────────────────────────────────────
class _EntryRow extends StatelessWidget {
  final StockEntry entry;
  final Product product;
  const _EntryRow({required this.entry, required this.product});

  @override
  Widget build(BuildContext context) {
    final isIn = entry.type == 'in';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isIn ? AppTheme.success : AppTheme.danger).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isIn ? AppTheme.success : AppTheme.danger).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (isIn ? AppTheme.success : AppTheme.danger).withOpacity(0.2),
              ),
            ),
            child: Icon(
              isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isIn ? AppTheme.success : AppTheme.danger,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isIn ? AppTheme.success : AppTheme.danger)
                            .withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isIn ? 'STOCK IN' : 'STOCK OUT',
                        style: TextStyle(
                          color: isIn ? AppTheme.success : AppTheme.danger,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(Icons.receipt_outlined,
                            size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 3),
                        Text(
                          'Bill: ${entry.billNo}',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.note!,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIn ? '+' : '-'}${entry.quantity.toStringAsFixed(1)} ${product.unit}',
                style: TextStyle(
                  color: isIn ? AppTheme.success : AppTheme.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy').format(entry.date),
                style:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppTheme.textMuted, size: 17),
            tooltip: 'Delete Entry',
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.bgSurface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.all(6),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text(
          'Delete this stock entry? Stock will be recalculated.',
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
              context.read<StockProvider>().deleteEntry(
                    entry.id!,
                    product.id!,
                    product.initialStock,
                  );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
