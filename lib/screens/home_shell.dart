import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'budget_screen.dart';
import 'catering_calculator_screen.dart';
import 'checklist_screen.dart';
import 'dashboard_screen.dart';
import 'report_screen.dart';
import 'savings_screen.dart';
import 'seserahan_screen.dart';
import 'settings_screen.dart';
import 'vendors_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<Widget> _pages = [
    DashboardScreen(),
    SavingsScreen(),
    BudgetScreen(),
    VendorsScreen(),
    ChecklistScreen(),
    CateringCalculatorScreen(),
    SeserahanScreen(),
    ReportScreen(),
    SettingsScreen(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(
      label: 'Beranda',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _NavItem(
      label: 'Tabungan',
      icon: Icons.savings_outlined,
      selectedIcon: Icons.savings,
    ),
    _NavItem(
      label: 'Anggaran',
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
    ),
    _NavItem(
      label: 'Vendor',
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront,
    ),
    _NavItem(
      label: 'Checklist',
      icon: Icons.fact_check_outlined,
      selectedIcon: Icons.fact_check,
    ),
    _NavItem(
      label: 'Kalkulator Katering',
      icon: Icons.restaurant_menu_outlined,
      selectedIcon: Icons.restaurant_menu,
    ),
    _NavItem(
      label: 'Seserahan & Mahar',
      icon: Icons.card_giftcard_outlined,
      selectedIcon: Icons.card_giftcard,
    ),
    _NavItem(
      label: 'Laporan & Grafik',
      icon: Icons.pie_chart_outline,
      selectedIcon: Icons.pie_chart,
    ),
    _NavItem(
      label: 'Pengaturan & Backup',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().requestNotificationPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 760;

    if (!isDesktop) {
      final mobileIndex = _index > 4 ? 0 : _index;
      return Scaffold(
        body: IndexedStack(
          index: mobileIndex,
          children: _pages.sublist(0, 5),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: mobileIndex,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            for (var i = 0; i < 5; i++)
              NavigationDestination(
                icon: Icon(_navItems[i].icon),
                selectedIcon: Icon(_navItems[i].selectedIcon),
                label: _navItems[i].label,
              ),
          ],
        ),
      );
    }

    final s = context.watch<AppState>();
    final days = s.daysToWedding;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Row(
        children: [
          Container(
            width: 272,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: heroGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22B5677A),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('💍',
                                  style: TextStyle(fontSize: 18)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Dana Nikah',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    s.profile.coupleName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: s.savingProgress,
                            minHeight: 6,
                            color: Colors.white,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(s.savingProgress * 100).round()}% terkumpul',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (days != null)
                              Text(
                                days > 0
                                    ? 'H-$days hari'
                                    : (days == 0 ? 'Hari H!' : 'Selesai'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(12, 4, 12, 6),
                          child: Text(
                            'MENU UTAMA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        for (var i = 0; i < 5; i++)
                          _SidebarTile(
                            item: _navItems[i],
                            selected: _index == i,
                            onTap: () => setState(() => _index = i),
                          ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(12, 16, 12, 6),
                          child: Text(
                            'PERENCANAAN & LAPORAN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        for (var i = 5; i < _navItems.length; i++)
                          _SidebarTile(
                            item: _navItems[i],
                            selected: _index == i,
                            onTap: () => setState(() => _index = i),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.border, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const IconBox(Icons.account_balance_wallet, size: 34),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sisa Saldo Kas',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.muted),
                              ),
                              Text(
                                rupiah(s.balance),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: s.balance < 0
                                      ? AppColors.danger
                                      : AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: IndexedStack(index: _index, children: _pages),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? AppColors.roseSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 21,
                  color: selected ? AppColors.roseDark : AppColors.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.roseDark : AppColors.ink,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.rose,
                      shape: BoxShape.circle,
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
