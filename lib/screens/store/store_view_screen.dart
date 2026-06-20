import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/section_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/section.dart';
import '../../models/product.dart';
import '../../models/stock_entry.dart';

/// Simplified Store View — only for stock entry (in/out), no management.
class StoreViewScreen extends StatefulWidget {
  const StoreViewScreen({super.key});

  @override
  State<StoreViewScreen> createState() => _StoreViewScreenState();
}

class _StoreViewScreenState extends State<StoreViewScreen> {
  AppSection? _selectedSection;
  Product? _selectedProduct;

  // Form state
  final _formKey = GlobalKey<FormState>();
  final _billController = TextEditingController();
  final _qtyController = TextEditingController();
  final _noteController = TextEditingController();
  String _type = 'in';
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SectionProvider>().loadSections();
    });
  }

  @override
  void dispose() {
    _billController.dispose();
    _qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Widget _buildTopBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.store_rounded,
                    color: AppTheme.secondary, size: 16),
                const SizedBox(width: 5),
                Text(
                  'STORE MODE',
                  style: TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quick Stock Entry',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (!isMobile)
                  const Text(
                    'Record stock in or out quickly',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerList() {
    return Consumer<SectionProvider>(
      builder: (context, secProvider, _) {
        if (secProvider.isLoading) {
          return const Center(
              child: CircularProgressIndicator(strokeWidth: 2));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: secProvider.sections.length,
          itemBuilder: (ctx, i) {
            final sec = secProvider.sections[i];
            return _SectionExpansion(
              section: sec,
              selectedProduct: _selectedProduct,
              onProductSelected: (p) {
                setState(() {
                  _selectedSection = sec;
                  _selectedProduct = p;
                });
                context
                    .read<StockProvider>()
                    .loadEntriesForProduct(p.id!, p.initialStock);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDesktopPicker() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'Select Section & Product',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _buildPickerList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(
            'Select Section & Product to continue',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _buildPickerList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.touch_app_outlined,
                color: AppTheme.primary, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select a product',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose a section and product from the left panel',
            style: TextStyle(
                color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
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

          // Body
          Expanded(
            child: isMobile
                ? (_selectedProduct == null
                    ? _buildMobilePicker()
                    : _buildEntryForm(true))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDesktopPicker(),
                      Expanded(
                        child: _selectedProduct == null
                            ? _buildEmptyState()
                            : _buildEntryForm(false),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryForm(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isMobile) ...[
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedProduct = null),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Back to Product List'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                // Product Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (_selectedSection?.color ?? AppTheme.primary).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_selectedSection?.color ?? AppTheme.primary).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (_selectedSection?.color ?? AppTheme.primary).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: _selectedSection?.color ?? AppTheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedProduct!.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '${_selectedSection?.name ?? ''} · Unit: ${_selectedProduct!.unit}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Consumer<StockProvider>(
                        builder: (_, sp, __) {
                          final stock = sp.getCurrentStock(_selectedProduct!.id!);
                          final isLow = stock < 5;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Current',
                                  style: TextStyle(
                                      fontSize: 10, color: AppTheme.textMuted)),
                              Text(
                                '${stock.toStringAsFixed(1)} ${_selectedProduct!.unit}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isLow ? AppTheme.danger : AppTheme.success,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Type Selector
                const Text('Transaction Type',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _TypeButton(
                        label: 'Stock IN',
                        icon: Icons.arrow_downward_rounded,
                        color: AppTheme.success,
                        isSelected: _type == 'in',
                        onTap: () => setState(() => _type = 'in'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TypeButton(
                        label: 'Stock OUT',
                        icon: Icons.arrow_upward_rounded,
                        color: AppTheme.danger,
                        isSelected: _type == 'out',
                        onTap: () => setState(() => _type = 'out'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Date
                const Text('Date',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setState(() => _date = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 16, color: AppTheme.textMuted),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMMM yyyy').format(_date),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down_rounded,
                            color: AppTheme.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bill No
                const Text('Bill / Challan No *',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _billController,
                  decoration: const InputDecoration(
                    hintText: 'Enter bill number',
                    prefixIcon: Icon(Icons.receipt_outlined,
                        color: AppTheme.textMuted, size: 18),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Quantity
                Text('Quantity (${_selectedProduct!.unit}) *',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Enter quantity',
                    prefixIcon: Icon(
                      _type == 'in'
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: _type == 'in' ? AppTheme.success : AppTheme.danger,
                      size: 18,
                    ),
                    suffixText: _selectedProduct!.unit,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final qty = double.tryParse(v);
                    if (qty == null || qty <= 0) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Note
                const Text('Note (optional)',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Add remarks...',
                    prefixIcon: Icon(Icons.notes_outlined,
                        color: AppTheme.textMuted, size: 18),
                  ),
                ),
                const SizedBox(height: 28),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _type == 'in' ? AppTheme.success : AppTheme.danger,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            _type == 'in' ? '✓  Save Stock In' : '✓  Save Stock Out',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final entry = StockEntry(
      productId: _selectedProduct!.id!,
      type: _type,
      quantity: double.parse(_qtyController.text),
      date: _date,
      billNo: _billController.text.trim(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    await context
        .read<StockProvider>()
        .addEntry(entry, _selectedProduct!.initialStock);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _billController.clear();
        _qtyController.clear();
        _noteController.clear();
        _type = 'in';
        _date = DateTime.now();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _type == 'in' ? AppTheme.success : AppTheme.danger,
          content: const Text('Entry saved successfully!',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }
  }
}

// ─── Section Expansion Tile ───────────────────────────────────────────────────
class _SectionExpansion extends StatefulWidget {
  final AppSection section;
  final Product? selectedProduct;
  final ValueChanged<Product> onProductSelected;

  const _SectionExpansion({
    required this.section,
    required this.selectedProduct,
    required this.onProductSelected,
  });

  @override
  State<_SectionExpansion> createState() => _SectionExpansionState();
}

class _SectionExpansionState extends State<_SectionExpansion> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProductsForSection(widget.section.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final iconMap = {
      'precision_manufacturing': Icons.precision_manufacturing_rounded,
      'electric_bolt': Icons.electric_bolt_rounded,
      'texture': Icons.texture_rounded,
      'build': Icons.build_rounded,
      'local_shipping': Icons.local_shipping_rounded,
      'inventory': Icons.inventory_2_rounded,
      'category': Icons.category_rounded,
    };
    final icon = iconMap[widget.section.icon] ?? Icons.category_rounded;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: widget.section.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: widget.section.color, size: 15),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.section.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          Consumer<ProductProvider>(
            builder: (ctx, provider, _) {
              final products =
                  provider.getProductsForSection(widget.section.id!);
              if (products.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(left: 46, bottom: 8),
                  child: Text(
                    'No products',
                    style: TextStyle(
                        color: AppTheme.textMuted.withOpacity(0.6), fontSize: 12),
                  ),
                );
              }
              return Column(
                children: products.map((p) {
                  final isSelected = widget.selectedProduct?.id == p.id;
                  return InkWell(
                    onTap: () => widget.onProductSelected(p),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(left: 16, right: 4, bottom: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withOpacity(0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primary.withOpacity(0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 14,
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            p.unit,
                            style: const TextStyle(
                                color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─── Type Button ──────────────────────────────────────────────────────────────
class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : AppTheme.textMuted, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
