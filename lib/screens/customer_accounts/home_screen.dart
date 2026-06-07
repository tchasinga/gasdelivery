import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_services.dart';
import '../../services/auth_service.dart';
import 'return_tab_screen.dart';
import 'map_tab_screen.dart';
import 'order_screen.dart';
import 'profile_tab_screen.dart';
import 'widgets/cart_icon_button.dart';

/// Bottom tabs: Home, Map, Orders, Return, Profile.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _tabs = [
    const HomeTabScreen(),
    const MapTabScreen(),
    const OrderScreen(),
    const ReturnTabScreen(),
    const ProfileTabScreen(),
  ];

  void _goToTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      floatingActionButton: _currentIndex == 2
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: const CartIconButton(),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _goToTab,
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8F4F6),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black26,
        elevation: 8,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart_rounded),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.keyboard_return_outlined),
            selectedIcon: Icon(Icons.keyboard_return_rounded),
            label: 'Return',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  static const Color _brand = Color(0xFF014F5B);

  int _cylinderCount = 0;
  List<Map<String, dynamic>> _cylinders = [];
  bool _loadingCylinders = true;
  String? _cylinderError;

  @override
  void initState() {
    super.initState();
    _loadCylinders();
  }

  Future<void> _refreshPage() async {
    final authProvider = context.read<AuthProvider>();
    await Future.wait([
      _loadCylinders(),
      authProvider.checkAuthStatus(),
    ]);
  }

  Future<void> _loadCylinders() async {
    setState(() {
      _loadingCylinders = true;
      _cylinderError = null;
    });

    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loadingCylinders = false;
        _cylinderError = 'Not signed in';
      });
      return;
    }

    final result = await ApiService.getCustomerCylinderCount(token);
    if (!mounted) return;

    setState(() {
      _loadingCylinders = false;
      if (result['success'] == true) {
        final list = result['cylinders'];
        _cylinders = list is List<Map<String, dynamic>>
            ? list
            : (list is List
                ? list
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList()
                : []);
        _cylinderCount = result['cylinder_count'] as int? ?? _cylinders.length;
      } else {
        _cylinderError = result['message'] as String? ?? 'Could not load cylinders';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final customerData = authProvider.customerData;
    final displayName = customerData?['account_customer_name'] ?? 'Customer';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        color: _brand,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: _brand,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshPage,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 20,
                  bottom: 16,
                  end: 20,
                ),
                background: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF014F5B),
                        Color(0xFF02788D),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Welcome back',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Order gas in a few taps — anywhere, anytime.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Your cylinders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _brand,
                          ),
                        ),
                      ),
                      if (!_loadingCylinders && _cylinderError == null)
                        Text(
                          '$_cylinderCount',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _brand,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _MyCylindersSection(
                    loading: _loadingCylinders,
                    cylinders: _cylinders,
                    error: _cylinderError,
                    onRetry: _loadCylinders,
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'How it works',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _brand,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _StepCard(
                    step: '1',
                    title: 'Choose quantity',
                    body: 'Pick cylinder size and delivery window.',
                  ),
                  const SizedBox(height: 10),
                  const _StepCard(
                    step: '2',
                    title: 'Confirm address',
                    body: 'We use your saved location for faster checkout.',
                  ),
                  const SizedBox(height: 10),
                  const _StepCard(
                    step: '3',
                    title: 'Pay on delivery',
                    body: 'Pay for your gas on delivery.',
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyCylindersSection extends StatelessWidget {
  const _MyCylindersSection({
    required this.loading,
    required this.cylinders,
    required this.error,
    required this.onRetry,
  });

  final bool loading;
  final List<Map<String, dynamic>> cylinders;
  final String? error;
  final VoidCallback onRetry;

  static const Color _brand = Color(0xFF014F5B);

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Material(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(18)),
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2, color: _brand),
            ),
          ),
        ),
      );
    }

    if (error != null) {
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(error!, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (cylinders.isEmpty) {
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.propane_tank_outlined, size: 28, color: _brand),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'No cylinders with you yet. Place an order to receive gas.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < cylinders.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _CylinderDetailCard(cylinder: cylinders[i]),
        ],
      ],
    );
  }
}

class _CylinderDetailCard extends StatelessWidget {
  const _CylinderDetailCard({required this.cylinder});

  final Map<String, dynamic> cylinder;

  static const Color _brand = Color(0xFF014F5B);

  String _formatDeliveredAt(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $h:$min $ampm';
    } catch (_) {
      return iso;
    }
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final serial = cylinder['serial_number']?.toString() ?? '—';
    final size = cylinder['size']?.toString() ?? 'Unknown';
    final capacity = cylinder['capacity_kg'];
    final capacityLabel = capacity != null ? ' · ${capacity}kg' : '';
    final condition = _titleCase(cylinder['condition']?.toString() ?? '—');
    final isEmpty = cylinder['is_empty'] == true;
    final fillLabel = isEmpty ? 'Empty' : 'Filled';
    final fillColor = isEmpty ? Colors.orange.shade800 : Colors.green.shade700;
    final fillBg = isEmpty ? Colors.orange.shade50 : Colors.green.shade50;
    final deliveredAt = _formatDeliveredAt(cylinder['delivered_at']?.toString());

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.propane_tank, size: 26, color: _brand),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serial,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _brand,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$size$capacityLabel',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: fillBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    fillLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fillColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _DetailRow(label: 'Condition', value: condition),
            const SizedBox(height: 8),
            _DetailRow(
              label: 'Delivered',
              value: deliveredAt,
              icon: Icons.local_shipping_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
        ],
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.title,
    required this.body,
  });

  final String step;
  final String title;
  final String body;

  static const Color _brand = Color(0xFF014F5B);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE8F4F6),
              child: Text(
                step,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _brand,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: _brand,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
