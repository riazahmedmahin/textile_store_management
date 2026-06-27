import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/section_provider.dart';
import '../../providers/stock_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/stock_entry.dart';
import '../../models/section.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int? _selectedSectionId;
  String _billNoQuery = '';
  DateTime? _fromDate;
  DateTime? _toDate;
  String _typeFilter = 'all'; // 'all', 'in', 'out'
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEntries());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadEntries() {
    context.read<StockProvider>().loadAllEntries(
          sectionId: _selectedSectionId,
          billNo: _billNoQuery.isEmpty ? null : _billNoQuery,
          fromDate: _fromDate,
          toDate: _toDate,
        );
  }

  bool get _hasFilters =>
      _selectedSectionId != null ||
      _billNoQuery.isNotEmpty ||
      _fromDate != null ||
      _toDate != null;

  Widget _buildTopBar(bool isMobile) {
    if (isMobile) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: const BoxDecoration(
          color: AppTheme.bgCard,
          border: Border(bottom: BorderSide(color: AppTheme.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const Text(
              'All stock movements',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search bill...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 16, color: AppTheme.textMuted),
                      suffixIcon: _billNoQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _billNoQuery = '');
                                _loadEntries();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      setState(() => _billNoQuery = v);
                      _loadEntries();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _showFilterDialog,
                  icon: Stack(
                    children: [
                      const Icon(Icons.tune_rounded,
                          size: 20, color: AppTheme.primary),
                      if (_hasFilters)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primary.withOpacity(0.08),
                    padding: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (_hasFilters) ...[
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear',
                        style: TextStyle(color: AppTheme.danger, fontSize: 13)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            // Type filter tabs
            Row(
              children: [
                _TypeTab(
                    label: 'All',
                    value: 'all',
                    current: _typeFilter,
                    onTap: (v) => setState(() => _typeFilter = v)),
                const SizedBox(width: 8),
                _TypeTab(
                    label: 'Stock In',
                    value: 'in',
                    current: _typeFilter,
                    color: AppTheme.success,
                    onTap: (v) => setState(() => _typeFilter = v)),
                const SizedBox(width: 8),
                _TypeTab(
                    label: 'Stock Out',
                    value: 'out',
                    current: _typeFilter,
                    color: AppTheme.danger,
                    onTap: (v) => setState(() => _typeFilter = v)),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transactions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'All stock movements across sections',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const Spacer(),
              // Search
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search bill no...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 16, color: AppTheme.textMuted),
                    suffixIcon: _billNoQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _billNoQuery = '');
                              _loadEntries();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  onChanged: (v) {
                    setState(() => _billNoQuery = v);
                    _loadEntries();
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Filter
              OutlinedButton.icon(
                onPressed: _showFilterDialog,
                icon: Stack(
                  children: [
                    const Icon(Icons.tune_rounded, size: 16),
                    if (_hasFilters)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                label: const Text('Filters'),
              ),
              if (_hasFilters) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear All',
                      style: TextStyle(color: AppTheme.danger)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Type filter tabs
          Row(
            children: [
              _TypeTab(
                  label: 'All',
                  value: 'all',
                  current: _typeFilter,
                  onTap: (v) => setState(() => _typeFilter = v)),
              const SizedBox(width: 8),
              _TypeTab(
                  label: 'Stock In',
                  value: 'in',
                  current: _typeFilter,
                  color: AppTheme.success,
                  onTap: (v) => setState(() => _typeFilter = v)),
              const SizedBox(width: 8),
              _TypeTab(
                  label: 'Stock Out',
                  value: 'out',
                  current: _typeFilter,
                  color: AppTheme.danger,
                  onTap: (v) => setState(() => _typeFilter = v)),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }


  Widget _buildMobileList(List<StockEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (ctx, i) {
        final entry = entries[i];
        final isIn = entry.type == 'in';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (isIn ? AppTheme.success : AppTheme.danger)
                      .withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isIn
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: isIn ? AppTheme.success : AppTheme.danger,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.productName ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.sectionName ?? ""} · Bill: ${entry.billNo}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      DateFormat('dd MMM yyyy').format(entry.date),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${isIn ? '+' : '-'}${entry.quantity.toStringAsFixed(1)} ${entry.productUnit ?? ""}',
                    style: TextStyle(
                      color: isIn ? AppTheme.success : AppTheme.danger,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: Column(
        children: [
          _buildTopBar(isMobile),

          // Active filters row
          if (_hasFilters) _activeFiltersRow(),

          // Content
          Expanded(
            child: Consumer<StockProvider>(
              builder: (context, sp, _) {
                if (sp.isLoading) {
                  return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2));
                }

                var entries = sp.allEntries;
                if (_typeFilter != 'all') {
                  entries =
                      entries.where((e) => e.type == _typeFilter).toList();
                }

                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.receipt_long_outlined,
                              color: AppTheme.primary, size: 32),
                        ),
                        const SizedBox(height: 16),
                        const Text('No transactions found',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 6),
                        const Text('Try adjusting your filters',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return isMobile
                    ? _buildMobileList(entries)
                    : _buildTable(entries);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<StockEntry> entries) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 36),
                  SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Text('Product / Section',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Bill No',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted)),
                  ),
                  Expanded(
                    child: Text('Date',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted)),
                  ),
                  Expanded(
                    child: Text('Qty',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted)),
                  ),
                ],
              ),
            ),
            // Table Rows
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: entries.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
                itemBuilder: (ctx, i) => _TableRow(entry: entries[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeFiltersRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: AppTheme.primary.withOpacity(0.04),
      child: Row(
        children: [
          const Icon(Icons.filter_list_rounded,
              size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          const Text('Filters: ',
              style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600)),
          if (_selectedSectionId != null)
            Consumer<SectionProvider>(builder: (_, p, __) {
              final sec = p.sections
                  .where((s) => s.id == _selectedSectionId)
                  .firstOrNull;
              return _FilterChip(
                label: sec?.name ?? 'Section',
                onRemove: () {
                  setState(() => _selectedSectionId = null);
                  _loadEntries();
                },
              );
            }),
          if (_fromDate != null || _toDate != null)
            _FilterChip(
              label:
                  '${_fromDate != null ? DateFormat('dd/MM').format(_fromDate!) : '...'} → ${_toDate != null ? DateFormat('dd/MM').format(_toDate!) : '...'}',
              onRemove: () {
                setState(() {
                  _fromDate = null;
                  _toDate = null;
                });
                _loadEntries();
              },
            ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedSectionId = null;
      _billNoQuery = '';
      _fromDate = null;
      _toDate = null;
      _typeFilter = 'all';
      _searchController.clear();
    });
    _loadEntries();
  }

  void _showFilterDialog() {
    final sections = context.read<SectionProvider>().sections;
    showDialog(
      context: context,
      builder: (ctx) => _FilterDialog(
        sections: sections,
        selectedSectionId: _selectedSectionId,
        fromDate: _fromDate,
        toDate: _toDate,
        onApply: (sectionId, from, to) {
          setState(() {
            _selectedSectionId = sectionId;
            _fromDate = from;
            _toDate = to;
          });
          _loadEntries();
        },
      ),
    );
  }
}

// ─── Table Row ────────────────────────────────────────────────────────────────
class _TableRow extends StatelessWidget {
  final StockEntry entry;
  const _TableRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isIn = entry.type == 'in';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  (isIn ? AppTheme.success : AppTheme.danger).withOpacity(0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isIn ? AppTheme.success : AppTheme.danger,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.productName ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (entry.sectionName != null)
                  Text(
                    entry.sectionName!,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMuted),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.billNo,
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              DateFormat('dd MMM yy').format(entry.date),
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              '${isIn ? '+' : '-'}${entry.quantity.toStringAsFixed(1)} ${entry.productUnit ?? ''}',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isIn ? AppTheme.success : AppTheme.danger,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Type Tab ─────────────────────────────────────────────────────────────────
class _TypeTab extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final Color? color;
  final ValueChanged<String> onTap;

  const _TypeTab({
    required this.label,
    required this.value,
    required this.current,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current == value;
    final activeColor = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : AppTheme.textMuted,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 13, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}

// ─── Filter Dialog ────────────────────────────────────────────────────────────
class _FilterDialog extends StatefulWidget {
  final List<AppSection> sections;
  final int? selectedSectionId;
  final DateTime? fromDate;
  final DateTime? toDate;
  final Function(int?, DateTime?, DateTime?) onApply;

  const _FilterDialog({
    required this.sections,
    required this.selectedSectionId,
    required this.fromDate,
    required this.toDate,
    required this.onApply,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  int? _sectionId;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _sectionId = widget.selectedSectionId;
    _from = widget.fromDate;
    _to = widget.toDate;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter Transactions',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const SizedBox(height: 20),
              const Text('Section',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int?>(
                value: _sectionId,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined,
                      color: AppTheme.textMuted, size: 18),
                ),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('All Sections')),
                  ...widget.sections.map((s) =>
                      DropdownMenuItem(value: s.id, child: Text(s.name))),
                ],
                onChanged: (v) => setState(() => _sectionId = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('From Date',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        _dateTile(_from, (d) => setState(() => _from = d)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('To Date',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        _dateTile(_to, (d) => setState(() => _to = d)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(_sectionId, _from, _to);
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateTile(DateTime? date, ValueChanged<DateTime> onPicked) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 14, color: AppTheme.textMuted),
            const SizedBox(width: 6),
            Text(
              date != null ? DateFormat('dd/MM/yy').format(date) : 'Select',
              style: TextStyle(
                color: date != null ? AppTheme.textPrimary : AppTheme.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
