import 'package:flutter/material.dart';

import 'select_return_rider_screen.dart';

/// Return tab: start customer → rider cylinder return flow.
class ReturnTabScreen extends StatelessWidget {
  const ReturnTabScreen({super.key});

  static const Color _brand = Color(0xFF014F5B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: _brand,
        elevation: 0,
        title: const Text(
          'Return',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Return a cylinder',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _brand,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hand your empty cylinder to a rider. You will confirm the transfer with an OTP sent to the rider.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                          height: 1.45,
                        ),
                  ),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4F6),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _brand.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.keyboard_return_rounded,
                      size: 56,
                      color: _brand,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Ready to return?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _brand,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Choose a rider, select the cylinder to return, then verify with OTP.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade700,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SelectReturnRiderScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_search_rounded),
                    label: const Text('Select a Rider'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _brand,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
