import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/section_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/stock_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/stock_entry.dart';
import '../../models/product.dart';
import '../../models/section.dart';
import '../sections/section_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isDataLoading = false;
  bool _showAllLowStock = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isDataLoading = true);
    final stockProvider = context.read<StockProvider>();
    final sectionProvider = context.read<SectionProvider>();
    final productProvider = context.read<ProductProvider>();

    await stockProvider.loadDashboardStats();
    await sectionProvider.loadSections();

    // Load products and stock entries for each section
    for (final section in sectionProvider.sections) {
      if (section.id != null) {
        await productProvider.loadProductsForSection(section.id!);
        final products = productProvider.getProductsForSection(section.id!);
        for (final product in products) {
          if (product.id != null) {
            await stockProvider.loadEntriesForProduct(product.id!, product.initialStock);
          }
        }
      }
    }
    if (mounted) {
      setState(() => _isDataLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    final secProvider = context.watch<SectionProvider>();
    final prodProvider = context.watch<ProductProvider>();
    final stockProvider = context.watch<StockProvider>();

    bool hasLowStock = false;
    for (final section in secProvider.sections) {
      if (section.id == null) continue;
      final products = prodProvider.getProductsForSection(section.id!);
      for (final product in products) {
        if (product.id == null) continue;
        final stock = stockProvider.getCurrentStock(product.id!);
        if (stock < 10) {
          hasLowStock = true;
          break;
        }
      }
      if (hasLowStock) break;
    }

    return Scaffold(
      backgroundColor: AppTheme.bgPage,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _isDataLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsRow(),
                        const SizedBox(height: 24),
                        // Charts row
                        if (isMobile) ...[
                          _buildStockFlowChart(),
                          const SizedBox(height: 16),
                          _buildSectionPieChart(),
                          const SizedBox(height: 20),
                          _buildSectionSummary(),
                          if (hasLowStock) ...[
                            const SizedBox(height: 20),
                            _buildLowStockAlert(),
                          ],
                          const SizedBox(height: 20),
                          _buildRecentActivity(),
                        ] else ...[
                          // Row 1: Stock Flow + Stock by Section
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: _buildStockFlowChart()),
                              const SizedBox(width: 20),
                              Expanded(flex: 2, child: _buildSectionPieChart()),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Row 2: Store Stock - Section Wise (Full Width)
                          _buildSectionSummary(),
                          const SizedBox(height: 24),
                          // Row 3: Recent Activity (Stock History) + Low Stock Alert
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: hasLowStock ? 3 : 1,
                                child: _buildRecentActivity(),
                              ),
                              if (hasLowStock) ...[
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 2,
                                  child: _buildLowStockAlert(),
                                ),
                              ],
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
            onPressed: _refreshData,
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
        final totalIn = (stats['total_in'] as num?)?.toDouble() ?? 0;
        final totalOut = (stats['total_out'] as num?)?.toDouble() ?? 0;
        final lowStockCount = stats['low_stock_count'] ?? 0;
        final outOfStockCount = stats['out_of_stock_count'] ?? 0;

        final double width = MediaQuery.of(context).size.width;
        int crossAxisCount = 5;
        double childAspectRatio = 1.6;
        if (width < 600) {
          crossAxisCount = 2;
          childAspectRatio = 1.35;
        } else if (width < 900) {
          crossAxisCount = 3;
          childAspectRatio = 1.4;
        } else if (width < 1200) {
          crossAxisCount = 4;
          childAspectRatio = 1.5;
        }

        final netStock = totalIn - totalOut;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            _StatCard(
              label: 'Current Stock',
              value: netStock.toStringAsFixed(0),
              icon: Icons.inventory_2_outlined,
              iconColor: AppTheme.primary,
              bgColor: const Color(0xFFEEF2FF),
            ),
            _StatCard(
              label: 'Total In',
              value: totalIn.toStringAsFixed(0),
              icon: Icons.arrow_downward_rounded,
              iconColor: AppTheme.success,
              bgColor: const Color(0xFFECFDF5),
            ),
            _StatCard(
              label: 'Total Out',
              value: totalOut.toStringAsFixed(0),
              icon: Icons.arrow_upward_rounded,
              iconColor: AppTheme.danger,
              bgColor: const Color(0xFFFFF1F2),
            ),
            _StatCard(
              label: 'Low Stock Items',
              value: '$lowStockCount',
              icon: Icons.warning_amber_rounded,
              iconColor: AppTheme.warning,
              bgColor: const Color(0xFFFFF7ED),
            ),
            _StatCard(
              label: 'Out of Stock Items',
              value: '$outOfStockCount',
              icon: Icons.error_outline_rounded,
              iconColor: AppTheme.danger,
              bgColor: const Color(0xFFFEF2F2),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLowStockAlert() {
    return Consumer3<SectionProvider, ProductProvider, StockProvider>(
      builder: (context, secProvider, prodProvider, stockProvider, _) {
        final List<Map<String, dynamic>> lowStockItems = [];
        
        for (final section in secProvider.sections) {
          if (section.id == null) continue;
          final products = prodProvider.getProductsForSection(section.id!);
          for (final product in products) {
            if (product.id == null) continue;
            final stock = stockProvider.getCurrentStock(product.id!);
            if (stock < 10) {
              lowStockItems.add({
                'product': product,
                'section': section,
                'stock': stock,
              });
            }
          }
        }

        if (lowStockItems.isEmpty) return const SizedBox.shrink();

        final hasMore = lowStockItems.length > 8;
        final displayItems = _showAllLowStock 
            ? lowStockItems 
            : lowStockItems.take(8).toList();

        return _CardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Low Stock Alerts',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.danger,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${lowStockItems.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.danger,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Column(
                    children: [
                      ...displayItems.map((item) {
                        final product = item['product'] as Product;
                        final section = item['section'] as AppSection;
                        final stock = item['stock'] as double;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.danger.withOpacity(0.08)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      section.name,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.danger.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${stock.toStringAsFixed(stock % 1 == 0 ? 0 : 1)} ${product.unit}',
                                  style: const TextStyle(
                                    color: AppTheme.danger,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      if (hasMore) ...[
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showAllLowStock = !_showAllLowStock;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
                              borderRadius: BorderRadius.circular(8),
                              color: AppTheme.danger.withOpacity(0.02),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _showAllLowStock ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                  color: AppTheme.danger,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _showAllLowStock
                                      ? 'Show Less'
                                      : 'View ${lowStockItems.length - 8} More Items',
                                  style: const TextStyle(
                                    color: AppTheme.danger,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

  // ─── Stock In vs Out Bar Chart ─────────────────────────────────────────────
  Widget _buildStockFlowChart() {
    return Consumer<StockProvider>(
      builder: (context, stockProvider, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 800;

        final stats = stockProvider.dashboardStats;
        final totalIn = (stats['total_in'] as num?)?.toDouble() ?? 0;
        final totalOut = (stats['total_out'] as num?)?.toDouble() ?? 0;
        final netStock = totalIn - totalOut;

        // Build per-section in/out data
        final recentEntries =
            (stats['recent_entries'] as List<StockEntry>?) ?? [];

        // Group recent entries by section
        final Map<String, double> sectionIn = {};
        final Map<String, double> sectionOut = {};
        for (final entry in recentEntries) {
          final secName = entry.sectionName ?? 'Other';
          if (entry.type == 'in') {
            sectionIn[secName] = (sectionIn[secName] ?? 0) + entry.quantity;
          } else {
            sectionOut[secName] = (sectionOut[secName] ?? 0) + entry.quantity;
          }
        }

        return _CardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bar_chart_rounded,
                        color: AppTheme.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Stock Flow Overview',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Summary chips
              Wrap(
                spacing: isMobile ? 6 : 10,
                runSpacing: isMobile ? 6 : 10,
                children: [
                  _ChipBadge(
                    label: 'In',
                    value: totalIn.toStringAsFixed(0),
                    color: AppTheme.success,
                    icon: Icons.arrow_downward_rounded,
                    isCompact: isMobile,
                  ),
                  _ChipBadge(
                    label: 'Out',
                    value: totalOut.toStringAsFixed(0),
                    color: AppTheme.danger,
                    icon: Icons.arrow_upward_rounded,
                    isCompact: isMobile,
                  ),
                  _ChipBadge(
                    label: 'Net',
                    value: netStock.toStringAsFixed(0),
                    color: netStock >= 0 ? AppTheme.primary : AppTheme.warning,
                    icon: Icons.trending_up_rounded,
                    isCompact: isMobile,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Bar chart
              SizedBox(
                height: isMobile ? 130 : 200,
                child: totalIn == 0 && totalOut == 0
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bar_chart_rounded,
                                color: AppTheme.textMuted.withOpacity(0.4),
                                size: 40),
                            const SizedBox(height: 8),
                            const Text('No stock data yet',
                                style: TextStyle(
                                    color: AppTheme.textMuted, fontSize: 13)),
                          ],
                        ),
                      )
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (totalIn > totalOut ? totalIn : totalOut) * 1.3,
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final label = rodIndex == 0 ? 'Stock In' : 'Stock Out';
                                return BarTooltipItem(
                                  '$label\n${rod.toY.toStringAsFixed(0)}',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  switch (value.toInt()) {
                                    case 0:
                                      return Text('Overall',
                                          style: TextStyle(
                                              fontSize: isMobile ? 9 : 11,
                                              color: AppTheme.textMuted));
                                    default:
                                      return const SizedBox.shrink();
                                  }
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: isMobile ? 24 : 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                        fontSize: isMobile ? 8 : 10,
                                        color: AppTheme.textMuted),
                                  );
                                },
                              ),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval:
                                ((totalIn > totalOut ? totalIn : totalOut) / 4)
                                    .clamp(1, double.infinity),
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: AppTheme.border.withOpacity(0.5),
                              strokeWidth: 1,
                              dashArray: [4, 4],
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                  toY: totalIn,
                                  color: AppTheme.success,
                                  width: isMobile ? 16 : 28,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6)),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: (totalIn > totalOut
                                            ? totalIn
                                            : totalOut) *
                                        1.3,
                                    color: AppTheme.success.withOpacity(0.05),
                                  ),
                                ),
                                BarChartRodData(
                                  toY: totalOut,
                                  color: AppTheme.danger,
                                  width: isMobile ? 16 : 28,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6)),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: (totalIn > totalOut
                                            ? totalIn
                                            : totalOut) *
                                        1.3,
                                    color: AppTheme.danger.withOpacity(0.05),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              // Legend
              Wrap(
                spacing: isMobile ? 12 : 20,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _LegendDot(color: AppTheme.success, label: 'Stock In', isCompact: isMobile),
                  _LegendDot(color: AppTheme.danger, label: 'Stock Out', isCompact: isMobile),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Section-wise Pie Chart ─────────────────────────────────────────────────
  Widget _buildSectionPieChart() {
    return Consumer2<SectionProvider, StockProvider>(
      builder: (context, secProvider, stockProvider, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 800;

        final sectionStats = stockProvider.sectionStats;
        final sections = secProvider.sections;

        if (sections.isEmpty) {
          return _CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.pie_chart_rounded,
                          color: AppTheme.accent, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Stock by Section',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.pie_chart_outline_rounded,
                          color: AppTheme.textMuted.withOpacity(0.4), size: 40),
                      const SizedBox(height: 8),
                      const Text('No sections yet',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        }

        // Build pie data
        final List<_PieData> pieData = [];
        for (final sec in sections) {
          final stats = sectionStats[sec.id] ?? {};
          final totalStock = (stats['total_stock'] as double?) ?? 0.0;
          if (totalStock > 0) {
            pieData.add(_PieData(
              name: sec.name,
              value: totalStock,
              color: sec.color,
            ));
          }
        }

        final grandTotal = pieData.fold(0.0, (s, d) => s + d.value);

        return _CardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.pie_chart_rounded,
                        color: AppTheme.accent, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Stock by Section',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              pieData.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.pie_chart_outline_rounded,
                                color: AppTheme.textMuted.withOpacity(0.4),
                                size: 40),
                            const SizedBox(height: 8),
                            const Text('No stock data',
                                style: TextStyle(
                                    color: AppTheme.textMuted, fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        SizedBox(
                          height: isMobile ? 130 : 180,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: isMobile ? 25 : 40,
                              sections: pieData.map((d) {
                                final pct = grandTotal > 0
                                    ? (d.value / grandTotal * 100)
                                    : 0.0;
                                return PieChartSectionData(
                                  value: d.value,
                                  color: d.color,
                                  radius: isMobile ? 25 : 40,
                                  title: '${pct.toStringAsFixed(0)}%',
                                  titleStyle: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: isMobile ? 9 : 11,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 10 : 16),
                        // Legend
                        ...pieData.map((d) => Padding(
                              padding: EdgeInsets.only(bottom: isMobile ? 4 : 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: isMobile ? 8 : 10,
                                    height: isMobile ? 8 : 10,
                                    decoration: BoxDecoration(
                                      color: d.color,
                                      borderRadius: BorderRadius.circular(isMobile ? 2 : 3),
                                    ),
                                  ),
                                  SizedBox(width: isMobile ? 6 : 8),
                                  Expanded(
                                    child: Text(
                                      d.name,
                                      style: TextStyle(
                                          fontSize: isMobile ? 10 : 12,
                                          color: AppTheme.textSecondary,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ),
                                  Text(
                                    isMobile ? '${d.value.toStringAsFixed(0)} u' : '${d.value.toStringAsFixed(0)} units',
                                    style: TextStyle(
                                      fontSize: isMobile ? 10 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    return Consumer<StockProvider>(
      builder: (context, provider, _) {
        final recent =
            (provider.dashboardStats['recent_entries'] as List<StockEntry>?) ??
                [];

        return _CardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: AppTheme.warning, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              recent.isEmpty
                  ? _emptyState(
                      'No transactions yet', Icons.receipt_long_outlined)
                  : Column(
                      children: recent
                          .map((entry) => _ActivityRow(entry: entry))
                          .toList(),
                    ),
            ],
          ),
        );
      },
    );
  }

  // ─── Section Summary with clickable navigation ────────────────────────────
  Widget _buildSectionSummary() {
    return Consumer3<SectionProvider, ProductProvider, StockProvider>(
      builder: (context, secProvider, prodProvider, stockProvider, _) {
        final sectionStats = stockProvider.sectionStats;

        return _CardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.category_rounded,
                        color: AppTheme.secondary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Store Stock — Section Wise',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              secProvider.isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : secProvider.sections.isEmpty
                      ? _emptyState('No sections', Icons.category_outlined)
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final double screenWidth = MediaQuery.of(context).size.width;
                            final bool isMobile = screenWidth < 800;

                            final int visibleCardsCount = 3;
                            final double spacing = 12.0;
                            final int totalSections = secProvider.sections.length;

                            final double cardWidth = isMobile 
                                ? double.infinity 
                                : (totalSections < visibleCardsCount 
                                    ? (constraints.maxWidth - (spacing * (totalSections - 1))) / totalSections
                                    : (constraints.maxWidth - (spacing * (visibleCardsCount - 1))) / visibleCardsCount);

                            final List<Widget> widgets = secProvider.sections.map((section) {
                              final stats = sectionStats[section.id] ?? {};
                              final productCount =
                                  (stats['product_count'] as int?) ?? 0;
                              final totalStock =
                                  (stats['total_stock'] as double?) ?? 0.0;
                              final isLowStock =
                                  totalStock < 10 && productCount > 0;
                              final products =
                                  prodProvider.getProductsForSection(section.id!);

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SectionDetailScreen(
                                          section: section),
                                    ),
                                  ).then((_) => _refreshData());
                                },
                                child: Container(
                                  margin: isMobile 
                                      ? const EdgeInsets.only(bottom: 12) 
                                      : EdgeInsets.zero,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: section.color.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color:
                                            section.color.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header
                                      Row(
                                        children: [
                                          Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              color: section.color
                                                  .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                            ),
                                            child: Icon(
                                              _iconFromString(section.icon),
                                              color: section.color,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  section.name,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        AppTheme.textPrimary,
                                                  ),
                                                ),
                                                Text(
                                                  '$productCount ${productCount == 1 ? 'product' : 'products'}',
                                                  style: const TextStyle(
                                                    color: AppTheme.textMuted,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '${totalStock.toStringAsFixed(totalStock % 1 == 0 ? 0 : 1)}',
                                                style: TextStyle(
                                                  color: isLowStock
                                                      ? AppTheme.danger
                                                      : AppTheme.success,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                'units',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  color: isLowStock
                                                      ? AppTheme.danger
                                                      : AppTheme.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            size: 18,
                                            color: section.color
                                                .withOpacity(0.5),
                                          ),
                                        ],
                                      ),
                                      // Product list preview (max 3)
                                      if (products.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Divider(
                                            height: 1,
                                            color: section.color
                                                .withOpacity(0.12)),
                                        const SizedBox(height: 6),
                                        ...products
                                            .take(3)
                                            .map((product) {
                                          final stock = stockProvider
                                              .getCurrentStock(
                                                  product.id!);
                                          final isLow = stock < 10;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 3),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 5,
                                                  height: 5,
                                                  decoration: BoxDecoration(
                                                    color: isLow
                                                        ? AppTheme.danger
                                                        : section.color
                                                            .withOpacity(
                                                                0.6),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    product.name,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppTheme
                                                          .textSecondary,
                                                    ),
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  '${stock.toStringAsFixed(stock % 1 == 0 ? 0 : 1)} ${product.unit}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: isLow
                                                        ? AppTheme.danger
                                                        : AppTheme
                                                            .textPrimary,
                                                  ),
                                                ),
                                                if (isLow) ...[
                                                  const SizedBox(width: 4),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 4,
                                                            vertical: 1),
                                                    decoration:
                                                        BoxDecoration(
                                                      color: AppTheme.danger
                                                          .withOpacity(
                                                              0.08),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(3),
                                                    ),
                                                    child: const Text(
                                                      'LOW',
                                                      style: TextStyle(
                                                        color: AppTheme
                                                            .danger,
                                                        fontSize: 7,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          );
                                        }),
                                        if (products.length > 3)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                              '+ ${products.length - 3} more',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: section.color,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList();

                            if (isMobile) {
                              return Column(children: widgets);
                            }

                            final List<Widget> cardWidgets = [];
                            for (int i = 0; i < widgets.length; i++) {
                              cardWidgets.add(
                                SizedBox(
                                  width: cardWidth,
                                  child: widgets[i],
                                ),
                              );
                              if (i < widgets.length - 1) {
                                cardWidgets.add(SizedBox(width: spacing));
                              }
                            }

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: cardWidgets,
                              ),
                            );
                          },
                        ),
            ],
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
            Icon(icon, color: AppTheme.textMuted.withOpacity(0.4), size: 36),
            const SizedBox(height: 8),
            Text(text,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
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
class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
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
  final String? subtitle;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFEFF6FF), // Soft light blue tint
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDBEAFE)), // Soft blue border
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
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
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(label,
                    style:
                        const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chip Badge ───────────────────────────────────────────────────────────────
class _ChipBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isCompact;

  const _ChipBadge({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 10,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 11 : 13, color: color),
          SizedBox(width: isCompact ? 3 : 5),
          Text(
            isCompact ? '$label:$value' : '$label: $value',
            style: TextStyle(
              color: color,
              fontSize: isCompact ? 10 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Legend Dot ────────────────────────────────────────────────────────────────
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool isCompact;

  const _LegendDot({
    required this.color,
    required this.label,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isCompact ? 8 : 10,
          height: isCompact ? 8 : 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(isCompact ? 2 : 3),
          ),
        ),
        SizedBox(width: isCompact ? 4 : 6),
        Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 10 : 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─── Pie Data Helper ──────────────────────────────────────────────────────────
class _PieData {
  final String name;
  final double value;
  final Color color;
  _PieData({required this.name, required this.value, required this.color});
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
          color: isIn
              ? AppTheme.success.withOpacity(0.15)
              : AppTheme.danger.withOpacity(0.15),
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
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.textMuted),
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
                style:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
