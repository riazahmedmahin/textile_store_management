import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/stock_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../../models/stock_entry.dart';

class StockEntryScreen extends StatefulWidget {
  final Product product;
  final String type;

  const StockEntryScreen(
      {super.key, required this.product, required this.type});

  @override
  State<StockEntryScreen> createState() => _StockEntryScreenState();
}

class _StockEntryScreenState extends State<StockEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _billNoController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  bool get isIn => widget.type == 'in';

  @override
  void dispose() {
    _quantityController.dispose();
    _billNoController.dispose();
    _noteController.dispose();
    super.dispose();
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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (isIn ? AppTheme.success : AppTheme.danger)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isIn
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: isIn ? AppTheme.success : AppTheme.danger,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isIn ? 'Stock In' : 'Stock Out',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Form
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 560),
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (isIn ? AppTheme.success : AppTheme.danger)
                                .withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (isIn ? AppTheme.success : AppTheme.danger)
                                  .withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isIn
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                color:
                                    isIn ? AppTheme.success : AppTheme.danger,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isIn ? 'STOCK IN' : 'STOCK ISSUE',
                                      style: TextStyle(
                                        color: isIn
                                            ? AppTheme.success
                                            : AppTheme.danger,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      widget.product.name,
                                      style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Consumer<StockProvider>(
                                builder: (_, sp, __) {
                                  final current =
                                      sp.getCurrentStock(widget.product.id!);
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Current Stock',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textMuted),
                                      ),
                                      Text(
                                        '${current.toStringAsFixed(1)} ${widget.product.unit}',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
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

                        // Date picker
                        const Text('Date',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        _DatePickerTile(
                          selectedDate: _selectedDate,
                          onChanged: (d) => setState(() => _selectedDate = d),
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
                          controller: _billNoController,
                          decoration: const InputDecoration(
                            hintText: 'Enter bill number',
                            prefixIcon: Icon(Icons.receipt_outlined,
                                color: AppTheme.textMuted, size: 18),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Bill No is required'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Quantity
                        Text('Quantity (${widget.product.unit}) *',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            hintText: 'Enter quantity',
                            prefixIcon: Icon(
                              isIn
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              color: isIn ? AppTheme.success : AppTheme.danger,
                              size: 18,
                            ),
                            suffixText: widget.product.unit,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Required';
                            final qty = double.tryParse(v);
                            if (qty == null || qty <= 0)
                              return 'Enter a valid quantity';
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
                            hintText: 'Add any remarks...',
                            prefixIcon: Icon(Icons.notes_outlined,
                                color: AppTheme.textMuted, size: 18),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isIn ? AppTheme.success : AppTheme.danger,
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
                                    isIn ? 'Save Stock In' : 'Save Stock Out',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final entry = StockEntry(
      productId: widget.product.id!,
      type: widget.type,
      quantity: double.parse(_quantityController.text),
      date: _selectedDate,
      billNo: _billNoController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    await context
        .read<StockProvider>()
        .addEntry(entry, widget.product.initialStock);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: isIn ? AppTheme.success : AppTheme.danger,
          content: Text(
            '${isIn ? 'Stock In' : 'Stock Out'} saved successfully!',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      Navigator.pop(context);
    }
  }
}

class _DatePickerTile extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  const _DatePickerTile({required this.selectedDate, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onChanged(picked);
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
                color: AppTheme.textMuted, size: 16),
            const SizedBox(width: 10),
            Text(
              DateFormat('dd MMMM yyyy').format(selectedDate),
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down_rounded,
                color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
