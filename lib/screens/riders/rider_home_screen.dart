import 'package:flutter/material.dart';

import 'tabs/rider_tab_delivery.dart';
import 'tabs/rider_tab_history.dart';
import 'tabs/rider_tab_home.dart';
import 'tabs/rider_tab_map.dart';
import 'tabs/rider_tab_profile.dart';

/// Rider shell: bottom [NavigationBar] only. Each tab body lives in its own file under `tabs/`.
class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  int _currentIndex = 0;

  static const List<String> _titles = [
    'Dashboard',
    'Delivery',
    'Map view',
    'History',
    'Profile',
  ];

  bool get _isMapTab => _currentIndex == 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: _isMapTab,
      appBar: _isMapTab
          ? null
          : AppBar(
              title: Text(_titles[_currentIndex]),
              backgroundColor: const Color(0xFF014F5B),
              foregroundColor: Colors.white,
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const RiderTabHome(),
          const RiderTabDelivery(),
          RiderTabMap(isActive: _currentIndex == 2),
          const RiderTabHistory(),
          const RiderTabProfile(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() => _currentIndex = index);
        },
        indicatorColor: const Color(0xFF014F5B).withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Delivery',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map view',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
