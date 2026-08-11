import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../utils/auth_gatekeeper.dart';
import '../../utils/repeat_order_helper.dart';
import 'help_tab_screen.dart';
import 'history_tab_screen.dart';
import 'map_tab_screen.dart';
import 'my_cart_screen.dart';
import 'my_orders_screen.dart';
import 'order_screen.dart';
import 'profile_tab_screen.dart';
import 'return_tab_screen.dart';
import 'widgets/app_bottom_nav_bar.dart';
import 'widgets/cart_icon_button.dart';
import 'widgets/home_image_carousel.dart';

/// Bottom tabs: Home, Help, History, Profile. [Map] and [Return] are hidden by default.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- Tab visibility: flip to `true` to restore hidden tabs ---
  static const bool _kShowMapTab = false;
  static const bool _kShowReturnTab = false;

  int _currentIndex = 0;
  late final PageController _pageController;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _pages = [
      HomeTabScreen(
        onPlaceNewOrder: _openOrderProducts,
        onFollowOngoingOrder: () => _followOngoingOrder(),
      ),
      const HelpTabScreen(),
      const HistoryTabScreen(),
      if (_kShowMapTab) const MapTabScreen(),
      if (_kShowReturnTab) const ReturnTabScreen(),
      const ProfileTabScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<AppBottomNavItem> get _navItems => [
    const AppBottomNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    const AppBottomNavItem(
      icon: Icons.help_outline_rounded,
      activeIcon: Icons.help_rounded,
      label: 'Help',
    ),
    const AppBottomNavItem(
      icon: Icons.history_rounded,
      activeIcon: Icons.history,
      label: 'History',
    ),
    if (_kShowMapTab)
      const AppBottomNavItem(
        icon: Icons.map_outlined,
        activeIcon: Icons.map_rounded,
        label: 'Map',
      ),
    if (_kShowReturnTab)
      const AppBottomNavItem(
        icon: Icons.keyboard_return_outlined,
        activeIcon: Icons.keyboard_return_rounded,
        label: 'Return',
      ),
    const AppBottomNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  void _goToTab(int index) {
    if (index < 0 || index >= _navItems.length) return;
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  void _openOrderProducts() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const OrderScreen()));
  }

  Future<void> _followOngoingOrder() async {
    if (!await AuthGatekeeper.requireAuth(context) || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MyOrdersScreen(initialTab: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: _pages,
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 76,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF014F5B), Color(0xFF02788D)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF014F5B).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const CartIconButton(iconColor: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _goToTab,
        items: _navItems,
      ),
    );
  }
}

class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({
    super.key,
    required this.onPlaceNewOrder,
    required this.onFollowOngoingOrder,
  });

  final VoidCallback onPlaceNewOrder;
  final VoidCallback onFollowOngoingOrder;

  static const Color _brand = Color(0xFF014F5B);

  Future<void> _repeatPreviousOrder(BuildContext context) async {
    if (!await AuthGatekeeper.requireAuth(context) || !context.mounted) return;

    final cart = context.read<CartProvider>();
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Loading your last order…'),
        duration: Duration(seconds: 2),
      ),
    );

    final result = await RepeatOrderHelper.loadMostRecentCompletedOrder(cart);
    if (!context.mounted) return;

    if (!result.success) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? 'Could not repeat order.')),
      );
      return;
    }

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MyCartScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final customerData = authProvider.customerData;
    final displayName = customerData?['account_customer_name']
        ?.toString()
        .trim();
    final isGuest = !authProvider.isAuthenticated;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Home'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          const HomeImageCarousel(),
          const SizedBox(height: 28),
          Text(
            displayName != null && displayName.isNotEmpty
                ? 'Hello $displayName,'
                : 'Hello,',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: _brand,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isGuest
                ? 'Browse products and add to cart — sign in when you\'re ready to order.'
                : 'Thanks for visiting TaifaGas',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
              height: 1.35,
            ),
          ),
          if (!isGuest) ...[
            const SizedBox(height: 6),
            Text(
              'Would like to place an order?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 28),
          _HomeActionCard(
            icon: Icons.add_shopping_cart_rounded,
            iconColor: _brand,
            title: 'Place new order',
            subtitle: 'Few clicks away',
            onTap: onPlaceNewOrder,
          ),
          const SizedBox(height: 12),
          _HomeActionCard(
            icon: Icons.replay_rounded,
            iconColor: const Color(0xFF02788D),
            title: 'Repeat my Previous Orders',
            subtitle: 'Reorder your last delivery',
            onTap: () => _repeatPreviousOrder(context),
          ),
          const SizedBox(height: 12),
          _HomeActionCard(
            icon: Icons.local_shipping_outlined,
            iconColor: Colors.orange.shade800,
            title: 'Follow my Ongoing order',
            subtitle: 'Track active deliveries',
            onTap: onFollowOngoingOrder,
          ),
        ],
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  static const _brand = Color(0xFF014F5B);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: _brand.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _brand,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
