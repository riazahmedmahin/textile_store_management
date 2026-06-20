import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/section_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/section.dart';

class SectionFormDialog extends StatefulWidget {
  final AppSection? section;
  const SectionFormDialog({super.key, this.section});

  @override
  State<SectionFormDialog> createState() => _SectionFormDialogState();
}

class _SectionFormDialogState extends State<SectionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  int _selectedColorValue = AppTheme.sectionColors[0].value;
  String _selectedIcon = 'category';

  final List<Map<String, dynamic>> _iconOptions = [
    {'key': 'category', 'icon': Icons.category_rounded, 'label': 'General'},
    {'key': 'electric_bolt', 'icon': Icons.electric_bolt_rounded, 'label': 'Electric'},
    {'key': 'precision_manufacturing', 'icon': Icons.precision_manufacturing_rounded, 'label': 'Machine'},
    {'key': 'texture', 'icon': Icons.texture_rounded, 'label': 'Fabric'},
    {'key': 'build', 'icon': Icons.build_rounded, 'label': 'Tools'},
    {'key': 'local_shipping', 'icon': Icons.local_shipping_rounded, 'label': 'Shipping'},
    {'key': 'inventory', 'icon': Icons.inventory_2_rounded, 'label': 'Inventory'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.section?.name ?? '');
    if (widget.section != null) {
      _selectedColorValue = widget.section!.colorValue;
      _selectedIcon = widget.section!.icon;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.section != null;
    return Dialog(
      child: SizedBox(
        width: 440,
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
                        color: AppTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.category_outlined,
                          color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEdit ? 'Edit Section' : 'Add New Section',
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

                // Section Name
                const Text('Section Name *',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Machine Section, Fabric Store...',
                    prefixIcon: Icon(Icons.label_outline,
                        color: AppTheme.textMuted, size: 18),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 22),

                // Icon
                const Text('Icon',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _iconOptions.map((opt) {
                    final isSelected = _selectedIcon == opt['key'];
                    final color = Color(_selectedColorValue);
                    return Tooltip(
                      message: opt['label'] as String,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedIcon = opt['key'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.12)
                                : AppTheme.bgSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? color : AppTheme.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            opt['icon'] as IconData,
                            color: isSelected ? color : AppTheme.textMuted,
                            size: 22,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),

                // Color
                const Text('Color',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: AppTheme.sectionColors.map((color) {
                    final isSelected = _selectedColorValue == color.value;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedColorValue = color.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ]
                              : [],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }).toList(),
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
                        child: Text(isEdit ? 'Update Section' : 'Add Section'),
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
    final provider = context.read<SectionProvider>();
    if (widget.section == null) {
      provider.addSection(AppSection(
        name: _nameController.text.trim(),
        colorValue: _selectedColorValue,
        icon: _selectedIcon,
      ));
    } else {
      provider.updateSection(widget.section!.copyWith(
        name: _nameController.text.trim(),
        colorValue: _selectedColorValue,
        icon: _selectedIcon,
      ));
    }
    Navigator.pop(context);
  }
}
