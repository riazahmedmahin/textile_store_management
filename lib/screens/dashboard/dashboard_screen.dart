import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isDataLoading = false;
  bool _showAllLowStock = false;
  final ScrollController _sectionScrollController = ScrollController();
  late AnimationController _entranceController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData(forceSpinner: false);
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _sectionScrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshData({bool forceSpinner = false}) async {
    if (!mounted) return;
    final stockProvider = context.read<StockProvider>();
    final sectionProvider = context.read<SectionProvider>();
    final productProvider = context.read<ProductProvider>();

    if (stockProvider.dashboardStats.isEmpty || forceSpinner) {
      setState(() => _isDataLoading = true);
    }

    _entranceController.reset();

    await Future.wait([
      stockProvider.loadDashboardStats(forceLoading: forceSpinner),
      sectionProvider.loadSections(),
      productProvider.loadAllProducts(),
    ]);

    if (mounted) {
      setState(() => _isDataLoading = false);
      _entranceController.forward();
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
        // stock > 0 && stock < 5 → Low Stock (db_helper এর সাথে মিল রাখা)
        // stock <= 0 → Out of Stock (আলাদা category)
        if (stock > 0 && stock < 5) {
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
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Loading Dashboard Data...',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: SingleChildScrollView(
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
                                  Expanded(
                                      flex: 3, child: _buildStockFlowChart()),
                                  const SizedBox(width: 20),
                                  Expanded(
                                      flex: 2, child: _buildSectionPieChart()),
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
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final isMobile = MediaQuery.of(context).size.width < 800;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24, vertical: isMobile ? 12 : 16),
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt_rounded,
                              size: 12, color: AppTheme.primary),
                          SizedBox(width: 3),
                          Text(
                            'Live',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat(isMobile ? 'dd MMM yyyy' : 'EEEE, dd MMMM yyyy')
                      .format(DateTime.now()),
                  style:
                      const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _AnimatedRefreshButton(
            onPressed: () => _refreshData(forceSpinner: true),
            isMobile: isMobile,
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
        double childAspectRatio = 1.55;
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
              accentGradient: const LinearGradient(
                colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
              ),
            ),
            _StatCard(
              label: 'Total In',
              value: totalIn.toStringAsFixed(0),
              icon: Icons.arrow_downward_rounded,
              iconColor: AppTheme.success,
              bgColor: const Color(0xFFECFDF5),
              accentGradient: const LinearGradient(
                colors: [Color(0xFF34D399), Color(0xFF10B981)],
              ),
            ),
            _StatCard(
              label: 'Total Out',
              value: totalOut.toStringAsFixed(0),
              icon: Icons.arrow_upward_rounded,
              iconColor: AppTheme.danger,
              bgColor: const Color(0xFFFFF1F2),
              accentGradient: const LinearGradient(
                colors: [Color(0xFFF87171), Color(0xFFEF4444)],
              ),
            ),
            _StatCard(
              label: 'Low Stock Items',
              value: '$lowStockCount',
              icon: Icons.warning_amber_rounded,
              iconColor: AppTheme.warning,
              bgColor: const Color(0xFFFFF7ED),
              accentGradient: const LinearGradient(
                colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
              ),
            ),
            _StatCard(
              label: 'Out of Stock Items',
              value: '$outOfStockCount',
              icon: Icons.error_outline_rounded,
              iconColor: AppTheme.danger,
              bgColor: const Color(0xFFFEF2F2),
              accentGradient: const LinearGradient(
                colors: [Color(0xFFFB7185), Color(0xFFE11D48)],
              ),
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
            // শুধু low stock দেখাবো: stock > 0 এবং stock < 5
            // Out of Stock (stock <= 0) এগুলো এখানে আসবে না
            if (stock > 0 && stock < 5) {
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
        final displayItems =
            _showAllLowStock ? lowStockItems : lowStockItems.take(8).toList();

        return _CardContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _PulsingWarningIcon(),
                  const SizedBox(width: 10),
                  const Text(
                    'Low Stock Alerts',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.danger,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${lowStockItems.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.danger,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                child: Column(
                  children: [
                    ...displayItems.map((item) {
                      final product = item['product'] as Product;
                      final section = item['section'] as AppSection;
                      final stock = item['stock'] as double;
                      return _AnimatedAlertRow(
                        product: product,
                        section: section,
                        stock: stock,
                      );
                    }).toList(),
                    if (hasMore) ...[
                      const SizedBox(height: 6),
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
                            border: Border.all(
                                color: AppTheme.danger.withAlpha(50)),
                            borderRadius: BorderRadius.circular(8),
                            color: AppTheme.danger.withAlpha(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _showAllLowStock
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
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
                      color: AppTheme.primary.withAlpha(20),
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
                        fontWeight: FontWeight.w700,
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
                height: isMobile ? 140 : 215,
                child: totalIn == 0 && totalOut == 0
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bar_chart_rounded,
                                color: AppTheme.textMuted.withAlpha(90),
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
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                final label =
                                    rodIndex == 0 ? 'Stock In' : 'Stock Out';
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
                              color: AppTheme.border.withAlpha(120),
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
                                    color: AppTheme.success.withAlpha(12),
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
                                    color: AppTheme.danger.withAlpha(12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        swapAnimationDuration:
                            const Duration(milliseconds: 600),
                        swapAnimationCurve: Curves.easeOutCubic,
                      ),
              ),
              const SizedBox(height: 12),
              // Legend
              Wrap(
                spacing: isMobile ? 12 : 20,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _LegendDot(
                      color: AppTheme.success,
                      label: 'Stock In',
                      isCompact: isMobile),
                  _LegendDot(
                      color: AppTheme.danger,
                      label: 'Stock Out',
                      isCompact: isMobile),
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
                        color: AppTheme.accent.withAlpha(20),
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
                          fontWeight: FontWeight.w700,
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
                          color: AppTheme.textMuted.withAlpha(90), size: 40),
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

        final List<Color> chartPalette = [
          const Color(0xFF10B981),
          const Color(0xFFEF4444),
          const Color(0xFF3B82F6),
          const Color(0xFF8B5CF6),
          const Color(0xFFF59E0B),
          const Color(0xFF06B6D4),
          const Color(0xFFEC4899),
          const Color(0xFF6366F1),
          const Color(0xFF14B8A6),
          const Color(0xFFF97316),
        ];

        final List<_PieData> pieData = [];
        int colorIdx = 0;
        for (final sec in sections) {
          final stats = sectionStats[sec.id] ?? {};
          final totalStock = (stats['total_stock'] as double?) ?? 0.0;
          if (totalStock > 0) {
            final distinctColor = chartPalette[colorIdx % chartPalette.length];
            colorIdx++;
            pieData.add(_PieData(
              name: sec.name,
              value: totalStock,
              color: distinctColor,
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
                      color: AppTheme.accent.withAlpha(20),
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
                        fontWeight: FontWeight.w700,
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
                                color: AppTheme.textMuted.withAlpha(90),
                                size: 40),
                            const SizedBox(height: 8),
                            const Text('No stock data',
                                style: TextStyle(
                                    color: AppTheme.textMuted, fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  : _InteractiveSectionPieChart(
                      pieData: pieData,
                      grandTotal: grandTotal,
                      isMobile: isMobile,
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
                      color: AppTheme.warning.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: AppTheme.warning, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Recent Transactions History',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                      color: AppTheme.secondary.withAlpha(20),
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
                      fontWeight: FontWeight.w700,
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
                            final double screenWidth =
                                MediaQuery.of(context).size.width;
                            final bool isMobile = screenWidth < 800;

                            final int visibleCardsCount = 3;
                            final double spacing = 12.0;
                            final int totalSections =
                                secProvider.sections.length;

                            final double cardWidth = isMobile
                                ? double.infinity
                                : (totalSections < visibleCardsCount
                                    ? (constraints.maxWidth -
                                            (spacing * (totalSections - 1))) /
                                        totalSections
                                    : (constraints.maxWidth -
                                            (spacing *
                                                (visibleCardsCount - 1))) /
                                        visibleCardsCount);

                            final List<Widget> widgets =
                                secProvider.sections.map((section) {
                              final stats = sectionStats[section.id] ?? {};
                              final productCount =
                                  (stats['product_count'] as int?) ?? 0;
                              final totalStock =
                                  (stats['total_stock'] as double?) ?? 0.0;
                              final isLowStock =
                                  totalStock < 10 && productCount > 0;
                              final products = prodProvider
                                  .getProductsForSection(section.id!);

                              return _AnimatedSectionCard(
                                section: section,
                                productCount: productCount,
                                totalStock: totalStock,
                                isLowStock: isLowStock,
                                products: products,
                                stockProvider: stockProvider,
                                isMobile: isMobile,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          SectionDetailScreen(section: section),
                                    ),
                                  ).then((_) => _refreshData());
                                },
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

                            return ScrollConfiguration(
                              behavior: _AllDeviceScrollBehavior(),
                              child: SingleChildScrollView(
                                controller: _sectionScrollController,
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: cardWidgets,
                                ),
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
            Icon(icon, color: AppTheme.textMuted.withAlpha(90), size: 36),
            const SizedBox(height: 8),
            Text(text,
                style:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─── Interactive Animated Section Pie Chart ──────────────────────────────────
class _InteractiveSectionPieChart extends StatefulWidget {
  final List<_PieData> pieData;
  final double grandTotal;
  final bool isMobile;

  const _InteractiveSectionPieChart({
    required this.pieData,
    required this.grandTotal,
    required this.isMobile,
  });

  @override
  State<_InteractiveSectionPieChart> createState() =>
      _InteractiveSectionPieChartState();
}

class _InteractiveSectionPieChartState
    extends State<_InteractiveSectionPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final hasTouch =
        _touchedIndex >= 0 && _touchedIndex < widget.pieData.length;
    final activeData = hasTouch ? widget.pieData[_touchedIndex] : null;

    // Precompute center values to avoid layout shifts from AnimatedSwitcher
    final centerValue = hasTouch
        ? activeData!.value.toStringAsFixed(0)
        : widget.grandTotal.toStringAsFixed(0);
    final centerLabel = hasTouch ? activeData!.name : 'Total Stock';
    final centerColor = hasTouch ? activeData!.color : AppTheme.textPrimary;
    final centerLabelColor = hasTouch ? activeData!.color : AppTheme.textMuted;

    // Fixed chart height - pie slice expansion doesn't shift the donut center
    final chartHeight = widget.isMobile ? 200.0 : 240.0;
    // centerSpaceRadius stays fixed - only slice radius changes
    final centerSpaceRadius = widget.isMobile ? 48.0 : 60.0;

    return Column(
      children: [
        SizedBox(
          height: chartHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sectionsSpace: 3,
                  centerSpaceRadius: centerSpaceRadius,
                  sections: widget.pieData.asMap().entries.map((entry) {
                    final i = entry.key;
                    final d = entry.value;
                    final isTouched = i == _touchedIndex;
                    final pct = widget.grandTotal > 0
                        ? (d.value / widget.grandTotal * 100)
                        : 0.0;
                    final showTitle = pct >= 5;

                    return PieChartSectionData(
                      value: d.value,
                      color: d.color,
                      // Small pop-out, no layout jitter
                      radius: isTouched
                          ? (widget.isMobile ? 38.0 : 50.0)
                          : (widget.isMobile ? 30.0 : 40.0),
                      title: showTitle ? '${pct.toStringAsFixed(0)}%' : '',
                      titleStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: widget.isMobile ? 10 : 12,
                        shadows: const [
                          Shadow(blurRadius: 4, color: Colors.black38)
                        ],
                      ),
                    );
                  }).toList(),
                ),
                swapAnimationDuration: const Duration(milliseconds: 350),
                swapAnimationCurve: Curves.easeOutCubic,
              ),
              // Fixed-size center donut display - never shifts layout
              IgnorePointer(
                child: SizedBox(
                  width: centerSpaceRadius * 1.5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        style: TextStyle(
                          fontSize: widget.isMobile ? 18 : 22,
                          fontWeight: FontWeight.w800,
                          color: centerColor,
                          height: 1.1,
                        ),
                        child: Text(
                          centerValue,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        style: TextStyle(
                          fontSize: widget.isMobile ? 9 : 11,
                          fontWeight: FontWeight.w500,
                          color: centerLabelColor,
                        ),
                        child: Text(
                          centerLabel,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: widget.isMobile ? 10 : 14),
        // Legend rows - only color/opacity animates, no size changes
        LayoutBuilder(
          builder: (context, constraints) {
            final halfWidth = (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.pieData.asMap().entries.map((entry) {
                final idx = entry.key;
                final d = entry.value;
                final isSelected = idx == _touchedIndex;
                final pct = widget.grandTotal > 0
                    ? (d.value / widget.grandTotal * 100)
                    : 0.0;

                return SizedBox(
                  width: widget.isMobile ? constraints.maxWidth : halfWidth,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _touchedIndex = idx),
                    onExit: (_) => setState(() => _touchedIndex = -1),
                    cursor: SystemMouseCursors.click,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      // Fixed padding - no layout shift
                      padding: EdgeInsets.symmetric(
                          horizontal: widget.isMobile ? 8 : 10,
                          vertical: widget.isMobile ? 6 : 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? d.color.withAlpha(18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        // Fixed border width - no layout shift
                        border: Border.all(
                          color: isSelected
                              ? d.color.withAlpha(100)
                              : AppTheme.border.withAlpha(100),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Fixed-size dot with color change only
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: d.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              d.name,
                              style: TextStyle(
                                fontSize: widget.isMobile ? 10 : 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: d.color.withAlpha(isSelected ? 40 : 20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: widget.isMobile ? 9 : 10,
                                fontWeight: FontWeight.w700,
                                color: d.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.isMobile
                                ? '${d.value.toStringAsFixed(0)}u'
                                : '${d.value.toStringAsFixed(0)} units',
                            style: TextStyle(
                              fontSize: widget.isMobile ? 10 : 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ─── Pulsing Warning Icon Animation ──────────────────────────────────────────
class _PulsingWarningIcon extends StatefulWidget {
  const _PulsingWarningIcon();

  @override
  State<_PulsingWarningIcon> createState() => _PulsingWarningIconState();
}

class _PulsingWarningIconState extends State<_PulsingWarningIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.12);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.danger.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.danger
                      .withAlpha((_pulseController.value * 100).toInt()),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppTheme.danger, size: 18),
          ),
        );
      },
    );
  }
}

// ─── Animated Refresh Button ──────────────────────────────────────────────────
class _AnimatedRefreshButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isMobile;

  const _AnimatedRefreshButton({
    required this.onPressed,
    required this.isMobile,
  });

  @override
  State<_AnimatedRefreshButton> createState() => _AnimatedRefreshButtonState();
}

class _AnimatedRefreshButtonState extends State<_AnimatedRefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _triggerRefresh() {
    _rotationController.forward(from: 0.0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isMobile
        ? IconButton(
            onPressed: _triggerRefresh,
            icon: RotationTransition(
              turns: Tween(begin: 0.0, end: 1.0).animate(_rotationController),
              child: const Icon(Icons.refresh_rounded,
                  color: AppTheme.primary, size: 20),
            ),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primary.withAlpha(20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(8),
            ),
          )
        : OutlinedButton.icon(
            onPressed: _triggerRefresh,
            icon: RotationTransition(
              turns: Tween(begin: 0.0, end: 1.0).animate(_rotationController),
              child: const Icon(Icons.refresh_rounded, size: 16),
            ),
            label: const Text('Refresh'),
          );
  }
}

// ─── Animated Section Card ────────────────────────────────────────────────────
class _AnimatedSectionCard extends StatefulWidget {
  final AppSection section;
  final int productCount;
  final double totalStock;
  final bool isLowStock;
  final List<Product> products;
  final StockProvider stockProvider;
  final bool isMobile;
  final VoidCallback onTap;

  const _AnimatedSectionCard({
    required this.section,
    required this.productCount,
    required this.totalStock,
    required this.isLowStock,
    required this.products,
    required this.stockProvider,
    required this.isMobile,
    required this.onTap,
  });

  @override
  State<_AnimatedSectionCard> createState() => _AnimatedSectionCardState();
}

class _AnimatedSectionCardState extends State<_AnimatedSectionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: widget.isMobile
              ? const EdgeInsets.only(bottom: 12)
              : EdgeInsets.zero,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hovered ? widget.section.color.withAlpha(8) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.section.color.withAlpha(_hovered ? 120 : 40),
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.section.color.withAlpha(_hovered ? 25 : 6),
                blurRadius: _hovered ? 10 : 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: widget.section.color.withAlpha(40),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      _iconFromString(widget.section.icon),
                      color: widget.section.color,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.section.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${widget.productCount} ${widget.productCount == 1 ? 'product' : 'products'}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${widget.totalStock.toStringAsFixed(widget.totalStock % 1 == 0 ? 0 : 1)}',
                        style: TextStyle(
                          color: widget.isLowStock
                              ? AppTheme.danger
                              : AppTheme.success,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'units',
                        style: TextStyle(
                          fontSize: 9,
                          color: widget.isLowStock
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
                    color: widget.section.color.withAlpha(140),
                  ),
                ],
              ),
              if (widget.products.isNotEmpty) ...[
                const SizedBox(height: 8),
                Divider(height: 1, color: widget.section.color.withAlpha(30)),
                const SizedBox(height: 6),
                ...widget.products.take(3).map((product) {
                  final stock =
                      widget.stockProvider.getCurrentStock(product.id!);
                  final isLow = stock < 10;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isLow
                                ? AppTheme.danger
                                : widget.section.color.withAlpha(150),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${stock.toStringAsFixed(stock % 1 == 0 ? 0 : 1)} ${product.unit}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color:
                                isLow ? AppTheme.danger : AppTheme.textPrimary,
                          ),
                        ),
                        if (isLow) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withAlpha(20),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Text(
                              'LOW',
                              style: TextStyle(
                                color: AppTheme.danger,
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                if (widget.products.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+ ${widget.products.length - 3} more',
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.section.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ],
          ),
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

// ─── Animated Alert Row ───────────────────────────────────────────────────────
class _AnimatedAlertRow extends StatefulWidget {
  final Product product;
  final AppSection section;
  final double stock;

  const _AnimatedAlertRow({
    required this.product,
    required this.section,
    required this.stock,
  });

  @override
  State<_AnimatedAlertRow> createState() => _AnimatedAlertRowState();
}

class _AnimatedAlertRowState extends State<_AnimatedAlertRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.danger.withAlpha(_hovered ? 15 : 6),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: AppTheme.danger.withAlpha(_hovered ? 60 : 20)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.section.name,
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
                color: AppTheme.danger.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${widget.stock.toStringAsFixed(widget.stock % 1 == 0 ? 0 : 1)} ${widget.product.unit}',
                style: const TextStyle(
                  color: AppTheme.danger,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Animated Stat Card ──────────────────────────────────────────────────────
class _StatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Gradient accentGradient;
  final String? subtitle;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.accentGradient,
    this.subtitle,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              _hovered ? const Color(0xFFF8FAFC) : const Color(0xFFEFF6FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered
                ? widget.iconColor.withAlpha(90)
                : const Color(0xFFDBEAFE),
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.iconColor.withAlpha(_hovered ? 30 : 12),
              blurRadius: _hovered ? 10 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.bgColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _hovered
                    ? [
                        BoxShadow(
                          color: widget.iconColor.withAlpha(50),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: _hovered ? 25 : 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      height: 1,
                    ),
                    child: Text(widget.value),
                  ),
                  const SizedBox(height: 3),
                  Text(widget.label,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted)),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle!,
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
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
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
              fontWeight: FontWeight.w700,
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
class _ActivityRow extends StatefulWidget {
  final StockEntry entry;
  const _ActivityRow({required this.entry});

  @override
  State<_ActivityRow> createState() => _ActivityRowState();
}

class _ActivityRowState extends State<_ActivityRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isIn = widget.entry.type == 'in';
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isIn
              ? AppTheme.success.withAlpha(_hovered ? 25 : 10)
              : AppTheme.danger.withAlpha(_hovered ? 25 : 10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isIn
                ? AppTheme.success.withAlpha(_hovered ? 60 : 30)
                : AppTheme.danger.withAlpha(_hovered ? 60 : 30),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color:
                    (isIn ? AppTheme.success : AppTheme.danger).withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isIn
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
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
                    widget.entry.productName ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '${widget.entry.sectionName ?? ''} · Bill: ${widget.entry.billNo}',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIn ? '+' : '-'}${widget.entry.quantity.toStringAsFixed(0)} ${widget.entry.productUnit ?? ''}',
                  style: TextStyle(
                    color: isIn ? AppTheme.success : AppTheme.danger,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  DateFormat('dd/MM').format(widget.entry.date),
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom ScrollBehavior that allows mouse, stylus, and touch to drag-scroll.
class _AllDeviceScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}
