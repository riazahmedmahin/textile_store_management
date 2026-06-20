import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/section_provider.dart';
import '../providers/stock_provider.dart';
import '../core/theme/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'sections/sections_list_screen.dart';
import 'transactions/transactions_screen.dart';
import 'store/store_view_screen.dart';

enum AppView { admin, store }

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  AppView _currentView = AppView.admin;

  final List<_NavItem> _adminNavItems = const [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(icon: Icons.category_outlined, activeIcon: Icons.category, label: 'Sections'),
    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Transactions'),
  ];

  final List<_NavItem> _storeNavItems = const [
    _NavItem(icon: Icons.store_outlined, activeIcon: Icons.store, label: 'Stock Entry'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SectionProvider>().loadSections();
      context.read<StockProvider>().loadDashboardStats();
    });
  }

  List<_NavItem> get _navItems =>
      _currentView == AppView.admin ? _adminNavItems : _storeNavItems;

  Widget _currentScreen() {
    if (_currentView == AppView.store) {
      return const StoreViewScreen();
    }
    switch (_currentIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const SectionsListScreen();
      case 2:
        return const TransactionsScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────────
          _Sidebar(
            currentIndex: _currentIndex,
            currentView: _currentView,
            navItems: _navItems,
            onIndexChanged: (i) => setState(() => _currentIndex = i),
            onViewChanged: (v) => setState(() {
              _currentView = v;
              _currentIndex = 0;
            }),
          ),
          // ── Main Content ─────────────────────────────────────────────────
          Expanded(
            child: _currentScreen(),
          ),
        ],
      ),
    );
  }
}

// ─── Sidebar Widget ───────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final int currentIndex;
  final AppView currentView;
  final List<_NavItem> navItems;
  final ValueChanged<int> onIndexChanged;
  final ValueChanged<AppView> onViewChanged;

  const _Sidebar({
    required this.currentIndex,
    required this.currentView,
    required this.navItems,
    required this.onIndexChanged,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppTheme.bgSidebar,
        boxShadow: [
          BoxShadow(
            color: Color(0x20000000),
            blurRadius: 20,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF312E81), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'StitchOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Textile Manager',
                      style: TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // View Switcher
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF312E81),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _ViewTab(
                    label: 'Admin',
                    icon: Icons.admin_panel_settings_outlined,
                    isSelected: currentView == AppView.admin,
                    onTap: () => onViewChanged(AppView.admin),
                  ),
                  _ViewTab(
                    label: 'Store',
                    icon: Icons.store_outlined,
                    isSelected: currentView == AppView.store,
                    onTap: () => onViewChanged(AppView.store),
                  ),
                ],
              ),
            ),
          ),

          // Nav Section Label
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
            child: Text(
              currentView == AppView.admin ? 'ADMIN PANEL' : 'STORE PANEL',
              style: const TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // Nav Items
          ...navItems.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isActive = currentIndex == idx;
            return _NavTile(
              item: item,
              isActive: isActive,
              onTap: () => onIndexChanged(idx),
            );
          }),

          const Spacer(),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF312E81), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF312E81),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_outline_rounded, color: Color(0xFF818CF8), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentView == AppView.admin ? 'Admin User' : 'Store User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        currentView == AppView.admin ? 'Full Access' : 'Entry Only',
                        style: const TextStyle(color: Color(0xFF6366F1), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: isSelected ? Colors.white : const Color(0xFF818CF8)),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF818CF8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile({required this.item, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF4F46E5) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: 18,
                  color: isActive ? Colors.white : const Color(0xFF818CF8),
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFFB0B7D3),
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
