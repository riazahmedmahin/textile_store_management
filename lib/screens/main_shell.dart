import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/section_provider.dart';
import '../providers/stock_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'sections/sections_list_screen.dart';
import 'transactions/transactions_screen.dart';
import 'store/store_view_screen.dart';

enum AppView { admin, store }

class MainShell extends StatefulWidget {
  final String? initialRoute;
  const MainShell({super.key, this.initialRoute});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  AppView _currentView = AppView.admin;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<_NavItem> _adminNavItems = const [
    _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Dashboard',
        color: Color(0xFF6366F1)),
    _NavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: 'Transactions',
        color: Color(0xFF10B981)),
  ];

  final List<_NavItem> _storeNavItems = const [
    _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Dashboard',
        color: Color(0xFF6366F1)),
    _NavItem(
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2_rounded,
        label: 'Stock Entry',
        color: Color(0xFF8B5CF6)),
    _NavItem(
        icon: Icons.category_outlined,
        activeIcon: Icons.category_rounded,
        label: 'Sections',
        color: Color(0xFFF59E0B)),
    _NavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: 'Transactions',
        color: Color(0xFF10B981)),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();

    final auth = context.read<AuthProvider>();
    _currentView = auth.role == 'store' ? AppView.store : AppView.admin;

    // Parse initial route if provided (e.g., deep link)
    if (widget.initialRoute != null) {
      _parseRoute(widget.initialRoute!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SectionProvider>().loadSections();
      context.read<StockProvider>().loadDashboardStats();
      _updateBrowserUrl();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<_NavItem> get _navItems =>
      _currentView == AppView.admin ? _adminNavItems : _storeNavItems;

  String get _currentTitle {
    if (_currentView == AppView.admin) {
      return _currentIndex == 1 ? 'Transactions' : 'Dashboard';
    }
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Stock Entry';
      case 2:
        return 'Sections';
      case 3:
        return 'Transactions';
      default:
        return 'Store';
    }
  }

  // Admin screens — kept alive in memory via IndexedStack
  final List<Widget> _adminScreens = const [
    DashboardScreen(),
    TransactionsScreen(),
  ];

  // Store screens — kept alive in memory via IndexedStack
  final List<Widget> _storeScreens = const [
    DashboardScreen(),
    StoreViewScreen(),
    SectionsListScreen(),
    TransactionsScreen(),
  ];

  Widget _buildIndexedStack() {
    final screens =
        _currentView == AppView.admin ? _adminScreens : _storeScreens;
    final index = _currentIndex.clamp(0, screens.length - 1);
    return IndexedStack(
      index: index,
      children: screens,
    );
  }

  void _changeIndex(int i) {
    _animController.reset();
    setState(() => _currentIndex = i);
    _animController.forward();
    _updateBrowserUrl();
  }

  void _changeView(AppView v) {
    _animController.reset();
    setState(() {
      _currentView = v;
      _currentIndex = 0;
    });
    _animController.forward();
    _updateBrowserUrl();
  }

  void _parseRoute(String route) {
    final auth = context.read<AuthProvider>();
    if (route == '/stock-entry') {
      _currentView = AppView.store;
      _currentIndex = 1;
    } else if (route == '/sections') {
      _currentView = AppView.store;
      _currentIndex = 2;
    } else if (route == '/transactions') {
      if (auth.role == 'store') {
        _currentView = AppView.store;
        _currentIndex = 3;
      } else {
        _currentView = AppView.admin;
        _currentIndex = 1;
      }
    } else {
      // /dashboard or unknown → default home
      if (auth.role == 'store') {
        _currentView = AppView.store;
        _currentIndex = 0;
      } else {
        _currentView = AppView.admin;
        _currentIndex = 0;
      }
    }
  }

  void _updateBrowserUrl() {
    String route = '/dashboard';
    if (_currentView == AppView.store) {
      switch (_currentIndex) {
        case 0:
          route = '/dashboard';
          break;
        case 1:
          route = '/stock-entry';
          break;
        case 2:
          route = '/sections';
          break;
        case 3:
          route = '/transactions';
          break;
      }
    } else {
      switch (_currentIndex) {
        case 0:
          route = '/dashboard';
          break;
        case 1:
          route = '/transactions';
          break;
      }
    }
    SystemNavigator.routeInformationUpdated(uri: Uri.parse(route));
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final auth = context.watch<AuthProvider>();
    final showViewSwitcher = auth.role == 'admin';

    final sidebarWidget = _Sidebar(
      currentIndex: _currentIndex,
      currentView: _currentView,
      navItems: _navItems,
      showViewSwitcher: showViewSwitcher,
      onIndexChanged: _changeIndex,
      onViewChanged: _changeView,
    );

    if (isMobile) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.black12,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 0,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withAlpha(80),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: Colors.white, size: 17),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'KTL',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    _currentTitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
            ],
          ),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A)),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: const Color(0xFFE2E8F0)),
          ),
        ),
        drawer: Drawer(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: sidebarWidget,
        ),
        body: _buildIndexedStack(),
        bottomNavigationBar: _navItems.length > 1
            ? Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: _changeIndex,
                  selectedItemColor: const Color(0xFF4F46E5),
                  unselectedItemColor: const Color(0xFF94A3B8),
                  showUnselectedLabels: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  selectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 11),
                  unselectedLabelStyle: const TextStyle(fontSize: 11),
                  items: _navItems
                      .map((item) => BottomNavigationBarItem(
                            icon: Icon(item.icon, size: 22),
                            activeIcon: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withAlpha(20),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(item.activeIcon,
                                  size: 22, color: const Color(0xFF4F46E5)),
                            ),
                            label: item.label,
                          ))
                      .toList(),
                ),
              )
            : null,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          sidebarWidget,
          Expanded(
            child: _buildIndexedStack(),
          ),
        ],
      ),
    );
  }
}

// ─── Premium Sidebar ──────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final int currentIndex;
  final AppView currentView;
  final List<_NavItem> navItems;
  final bool showViewSwitcher;
  final ValueChanged<int> onIndexChanged;
  final ValueChanged<AppView> onViewChanged;

  const _Sidebar({
    required this.currentIndex,
    required this.currentView,
    required this.navItems,
    required this.showViewSwitcher,
    required this.onIndexChanged,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1744), Color(0xFF1E1B4B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo Header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withAlpha(120),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lucky Group',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [Color(0xFF818CF8), Color(0xFF6EE7B7)],
                          ).createShader(b),
                          child: const Text(
                            'Kattali Textile Limited',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Thin accent divider
                Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4F46E5), Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── View Switcher ────────────────────────────────────────────
          if (showViewSwitcher)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0E30),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF312E81), width: 1),
                ),
                padding: const EdgeInsets.all(5),
                child: Row(
                  children: [
                    _ViewTab(
                      label: 'Admin',
                      icon: Icons.shield_outlined,
                      isSelected: currentView == AppView.admin,
                      onTap: () {
                        onViewChanged(AppView.admin);
                        if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    _ViewTab(
                      label: 'Store',
                      icon: Icons.storefront_outlined,
                      isSelected: currentView == AppView.store,
                      onTap: () {
                        onViewChanged(AppView.store);
                        if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 8),

          // ── Section Label ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6366F1),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  currentView == AppView.admin ? 'ADMIN PANEL' : 'STORE PANEL',
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // ── Nav Items ────────────────────────────────────────────────
          ...navItems.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isActive = currentIndex == idx;
            return _NavTile(
              item: item,
              isActive: isActive,
              onTap: () {
                onIndexChanged(idx);
                if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                  Navigator.pop(context);
                }
              },
            );
          }),

          const Spacer(),

          // ── User Info Card ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0E30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF312E81), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: auth.role == 'admin'
                            ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                            : [
                                const Color(0xFF10B981),
                                const Color(0xFF059669)
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          auth.role == 'admin' ? 'Admin User' : 'Store User',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          auth.email ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Color(0xFF818CF8), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                        Navigator.pop(context);
                      }
                      auth.logout();
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: Color(0xFFEF4444), size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Developed by Footer ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.code_rounded,
                      color: Colors.white, size: 10),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Developed by ',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFF818CF8), Color(0xFF6EE7B7)],
                  ).createShader(b),
                  child: const Text(
                    'Riaz Ahmed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
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

// ─── View Tab ─────────────────────────────────────────────────────────────────

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
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withAlpha(100),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: isSelected ? Colors.white : const Color(0xFF6366F1)),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF818CF8),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nav Tile ─────────────────────────────────────────────────────────────────

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTile(
      {required this.item, required this.isActive, required this.onTap});

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? widget.item.color.withAlpha(40)
                  : _hovered
                      ? const Color(0xFF312E81).withAlpha(80)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: widget.isActive
                  ? Border.all(color: widget.item.color.withAlpha(80), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                // Color dot indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: widget.isActive ? 3 : 0,
                  height: 20,
                  decoration: BoxDecoration(
                    color: widget.item.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                if (widget.isActive) const SizedBox(width: 10),
                // Icon with colored bg when active
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? widget.item.color.withAlpha(50)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    widget.isActive ? widget.item.activeIcon : widget.item.icon,
                    size: 18,
                    color: widget.isActive
                        ? widget.item.color
                        : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: TextStyle(
                      color: widget.isActive
                          ? Colors.white
                          : const Color(0xFF9CA3AF),
                      fontSize: 14,
                      fontWeight:
                          widget.isActive ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
                if (widget.isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: widget.item.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.item.color.withAlpha(150),
                          blurRadius: 6,
                        )
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Nav Item Model ───────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}
