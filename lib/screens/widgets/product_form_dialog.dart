import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';

class ProductFormDialog extends StatefulWidget {
  final int sectionId;
  final Product? product;
  const ProductFormDialog({super.key, required this.sectionId, this.product});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _initialStockController;
  String _selectedUnit = 'pcs';

  final List<String> _units = [
    'pcs',
    'meter',
    'kg',
    'roll',
    'box',
    'liter',
    'set',
    'pair',
    'gram',
    'yard',
  ];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.product?.name ?? '');
    _initialStockController = TextEditingController(
        text: widget.product?.initialStock.toStringAsFixed(0) ?? '0');
    _selectedUnit = widget.product?.unit ?? 'pcs';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Dialog(
      child: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.inventory_2_outlined,
                          color: AppTheme.secondary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEdit ? 'Edit Product' : 'Add New Product',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.bgSurface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Product Name
                const Text('Product Name *',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Cotton Fabric, Machine Belt...',
                    prefixIcon: Icon(Icons.inventory_2_outlined,
                        color: AppTheme.textMuted, size: 18),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                // Unit
                const Text('Unit of Measurement *',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                // Unit chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _units.map((u) {
                    final isSelected = _selectedUnit == u;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedUnit = u),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primary.withOpacity(0.08)
                              : AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : AppTheme.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          u,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Opening Stock
                const Text('Opening Stock',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                const Text(
                  'Stock already in store before tracking starts',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _initialStockController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '0',
                    prefixIcon: const Icon(Icons.numbers_outlined,
                        color: AppTheme.textMuted, size: 18),
                    suffixText: _selectedUnit,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Buttons
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
                        onPressed: _submit,
                        child: Text(isEdit ? 'Update Product' : 'Add Product'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ProductProvider>();
    final initialStock =
        double.tryParse(_initialStockController.text) ?? 0;

    if (widget.product == null) {
      provider.addProduct(Product(
        sectionId: widget.sectionId,
        name: _nameController.text.trim(),
        unit: _selectedUnit,
        initialStock: initialStock,
      ));
    } else {
      provider.updateProduct(widget.product!.copyWith(
        name: _nameController.text.trim(),
        unit: _selectedUnit,
        initialStock: initialStock,
      ));
    }
    Navigator.pop(context);
  }
}
