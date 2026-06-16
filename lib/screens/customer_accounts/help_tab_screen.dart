import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/phone_launcher.dart';
import 'customer_faq_screen.dart';
import 'customer_message_form_screen.dart';

class HelpTabScreen extends StatelessWidget {
  const HelpTabScreen({super.key});

  static const Color _brand = Color(0xFF014F5B);
  static const String _customerCarePhone = '+254700751245';

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<AuthProvider>().customerData;
    final name = customer?['account_customer_name']?.toString().trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        title: const Text('Help'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Text(
            name != null && name.isNotEmpty ? 'Hello $name,' : 'Hello,',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: _brand,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'How can we help you?',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 24),
          _HelpCard(
            icon: Icons.help_outline_rounded,
            title: 'Help',
            subtitle: 'Have a question, visit our FAQ section',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomerFaqScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _HelpCard(
            icon: Icons.mail_outline_rounded,
            title: 'Write us a message',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CustomerMessageFormScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _HelpCard(
            icon: Icons.phone_in_talk_outlined,
            title: 'Contact customer care',
            subtitle:
                'Call our customer care Monday to Friday 9 AM - 5 PM',
            onTap: () => launchPhoneCall(_customerCarePhone, context: context),
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  static const Color _brand = Color(0xFF014F5B);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _brand, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: _brand,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
