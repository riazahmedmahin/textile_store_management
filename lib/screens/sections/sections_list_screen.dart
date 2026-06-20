import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/section_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/section.dart';
import 'section_detail_screen.dart';
import '../widgets/section_form_dialog.dart';

class SectionsListScreen extends StatelessWidget {
  const SectionsListScreen({super.key});

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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sections',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Manage your store sections',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddSection(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Section'),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Consumer<SectionProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                if (provider.sections.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.category_outlined,
                              color: AppTheme.primary, size: 36),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No sections yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Create your first section to get started',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => _showAddSection(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add First Section'),
                        ),
                      ],
                    ),
                  );
                }
                return _buildSectionsGrid(context, provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsGrid(BuildContext context, SectionProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 340,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
        ),
        itemCount: provider.sections.length,
        itemBuilder: (context, i) {
          return _SectionCard(section: provider.sections[i]);
        },
      ),
    );
  }

  void _showAddSection(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const SectionFormDialog(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final AppSection section;
  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SectionDetailScreen(section: section),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [section.color, section.color.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _iconFromString(section.icon),
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded,
                          color: AppTheme.textMuted, size: 18),
                      onSelected: (value) {
                        if (value == 'edit') {
                          showDialog(
                            context: context,
                            builder: (_) => SectionFormDialog(section: section),
                          );
                        } else if (value == 'delete') {
                          _confirmDelete(context);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_outlined, color: AppTheme.primary, size: 16),
                            SizedBox(width: 8),
                            Text('Edit', style: TextStyle(fontSize: 14)),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline, color: AppTheme.danger, size: 16),
                            SizedBox(width: 8),
                            Text('Delete',
                                style: TextStyle(color: AppTheme.danger, fontSize: 14)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  section.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: section.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 12,
                        color: section.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 12, color: AppTheme.textMuted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Section'),
        content: Text(
          'Delete "${section.name}"? All products and stock entries will also be deleted.',
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
              context.read<SectionProvider>().deleteSection(section.id!);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
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
