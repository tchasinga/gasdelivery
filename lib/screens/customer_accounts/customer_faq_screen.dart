import 'package:flutter/material.dart';

class CustomerFaqScreen extends StatelessWidget {
  const CustomerFaqScreen({super.key});

  static const Color _brand = Color(0xFF014F5B);

  static const _faqs = [
    (
      'How do I place a gas order?',
      'From the Home tab, tap Place new order, choose your cylinder size, add to cart, and complete checkout with your delivery address.',
    ),
    (
      'How do I track my delivery?',
      'Open Home → Follow my Ongoing order, or check the History tab for past and current activity.',
    ),
    (
      'What payment methods are accepted?',
      'We support M-Pesa STK push. The rider or shop attendant will prompt you to pay when your order is ready for delivery.',
    ),
    (
      'How do I return an empty cylinder?',
      'Contact customer care or use the Return flow when it is enabled in your app version.',
    ),
    (
      'Who can I contact for help?',
      'Call customer care Monday to Friday, 9 AM – 5 PM, or send us a message from the Help tab.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        title: const Text('FAQ'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final faq = _faqs[index];
          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                iconColor: _brand,
                collapsedIconColor: _brand,
                title: Text(
                  faq.$1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _brand,
                    fontSize: 15,
                  ),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      faq.$2,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
