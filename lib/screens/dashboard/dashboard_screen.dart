import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/section_provider.dart';
import '../../providers/stock_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/stock_entry.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().loadDashboardStats();
      context.read<SectionProvider>().loadSections();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  if (isMobile) ...[
                    _buildRecentActivity(),
                    const SizedBox(height: 20),
                    _buildSectionSummary(),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _buildRecentActivity()),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: _buildSectionSummary()),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {
              context.read<StockProvider>().loadDashboardStats();
              context.read<SectionProvider>().loadSections();
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Consumer2<SectionProvider, StockProvider>(
      builder: (context, secProvider, stockProvider, _) {
        final stats = stockProvider.dashboardStats;
        final sectionCount = stats['section_count'] ?? 0;
        final productCount = stats['product_count'] ?? 0;
        final totalIn = (stats['total_in'] as num?)?.toDouble() ?? 0;
        final totalOut = (stats['total_out'] as num?)?.toDouble() ?? 0;

        final double width = MediaQuery.of(context).size.width;
        int crossAxisCount = 4;
        double childAspectRatio = 1.8;
        if (width < 600) {
          crossAxisCount = 1;
          childAspectRatio = 3.2;
        } else if (width < 950) {
          crossAxisCount = 2;
          childAspectRatio = 2.0;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _StatCard(
              label: 'Total Sections',
              value: '$sectionCount',
              icon: Icons.category_rounded,
              iconColor: AppTheme.primary,
              bgColor: const Color(0xFFEEF2FF),
              trend: 'Active sections',
            ),
            _StatCard(
              label: 'Total Products',
              value: '$productCount',
              icon: Icons.inventory_2_rounded,
              iconColor: AppTheme.secondary,
              bgColor: const Color(0xFFECFDF5),
              trend: 'Tracked products',
            ),
            _StatCard(
              label: 'Total Stock In',
              value: totalIn.toStringAsFixed(0),
              icon: Icons.arrow_downward_rounded,
              iconColor: AppTheme.success,
              bgColor: const Color(0xFFF0FDF4),
              trend: 'Units received',
            ),
            _StatCard(
              label: 'Total Stock Out',
              value: totalOut.toStringAsFixed(0),
              icon: Icons.arrow_upward_rounded,
              iconColor: AppTheme.danger,
              bgColor: const Color(0xFFFFF1F2),
              trend: 'Units dispatched',
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    return Consumer<StockProvider>(
      builder: (context, provider, _) {
        final recent = (provider.dashboardStats['recent_entries'] as List<StockEntry>?) ?? [];

        return _SectionCard(
          title: 'Recent Transactions',
          action: const Text('', style: TextStyle(fontSize: 12)),
          child: recent.isEmpty
              ? _emptyState('No transactions yet', Icons.receipt_long_outlined)
              : Column(
                  children: recent.map((entry) => _ActivityRow(entry: entry)).toList(),
                ),
        );
      },
    );
  }

  // ─── Enhanced Sections Overview ───────────────────────────────────────────────
  Widget _buildSectionSummary() {
    return Consumer2<SectionProvider, StockProvider>(
      builder: (context, secProvider, stockProvider, _) {
        final sectionStats = stockProvider.sectionStats;

        return _SectionCard(
          title: 'Sections — Stock Overview',
          action: const SizedBox.shrink(),
          child: secProvider.isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : secProvider.sections.isEmpty
                  ? _emptyState('No sections', Icons.category_outlined)
                  : Column(
                      children: secProvider.sections.map((section) {
                        final stats = sectionStats[section.id] ?? {};
                        final productCount = (stats['product_count'] as int?) ?? 0;
                        final totalStock = (stats['total_stock'] as double?) ?? 0.0;
                        final isLowStock = totalStock < 10 && productCount > 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: section.color.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: section.color.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: icon + name + product count badge
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: section.color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Icon(
                                      _iconFromString(section.icon),
                                      color: section.color,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      section.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  // Product count pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: section.color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$productCount ${productCount == 1 ? 'product' : 'products'}',
                                      style: TextStyle(
                                        color: section.color,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              if (productCount > 0) ...[
                                const SizedBox(height: 10),
                                // Divider line
                                Divider(
                                  height: 1,
                                  color: section.color.withOpacity(0.15),
                                ),
                                const SizedBox(height: 8),
                                // Stock bar row
                                Row(
                                  children: [
                                    Icon(
                                      isLowStock
                                          ? Icons.warning_amber_rounded
                                          : Icons.inventory_2_outlined,
                                      size: 13,
                                      color: isLowStock
                                          ? AppTheme.danger
                                          : AppTheme.textMuted,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Total Stock:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      totalStock.toStringAsFixed(
                                          totalStock % 1 == 0 ? 0 : 1),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isLowStock
                                            ? AppTheme.danger
                                            : AppTheme.success,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'units',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isLowStock
                                            ? AppTheme.danger
                                            : AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isLowStock) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '⚠ Low stock — reorder soon',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.danger,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ] else ...[
                                const SizedBox(height: 6),
                                Text(
                                  'No products added yet',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
        );
      },
    );
  }

  Widget _emptyState(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: AppTheme.textMuted, size: 36),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ],
        ),
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

// ─── Shared Card Container ────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget action;
  final Widget child;

  const _SectionCard({required this.title, required this.action, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                action,
              ],
            ),
          ),
          const Divider(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String trend;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Activity Row ─────────────────────────────────────────────────────────────
class _ActivityRow extends StatelessWidget {
  final StockEntry entry;
  const _ActivityRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isIn = entry.type == 'in';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isIn
            ? AppTheme.success.withOpacity(0.04)
            : AppTheme.danger.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isIn ? AppTheme.success.withOpacity(0.15) : AppTheme.danger.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: (isIn ? AppTheme.success : AppTheme.danger).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isIn ? AppTheme.success : AppTheme.danger,
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.productName ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${entry.sectionName ?? ''} · Bill: ${entry.billNo}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIn ? '+' : '-'}${entry.quantity.toStringAsFixed(0)} ${entry.productUnit ?? ''}',
                style: TextStyle(
                  color: isIn ? AppTheme.success : AppTheme.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                DateFormat('dd/MM').format(entry.date),
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
