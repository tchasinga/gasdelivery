import 'package:flutter/material.dart';

/// In-app Terms and Conditions for Gas express customers.
class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  static const _brand = Color(0xFF014F5B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: _brand,
        elevation: 0,
        title: const Text(
          'Terms and Conditions',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Text(
            'Gas express — Terms and Conditions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _brand,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Last updated: August 11, 2026',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          const _Section(
            title: '1. About these Terms',
            body:
                'These Terms and Conditions (“Terms”) govern your use of the Gas express mobile application and related services operated by Jocsoft Solutions Ltd (“we”, “us”, or “our”).\n\n'
                'By creating an account, signing in, or placing an order, you confirm that you have read, understood, and agree to be bound by these Terms. If you do not agree, please do not use the app.',
          ),
          const _Section(
            title: '2. Who may use Gas express',
            body:
                'You must be at least 18 years old and able to enter into a binding agreement under the laws of Kenya (or your country of residence).\n\n'
                'You agree to provide accurate information when registering (including your name and phone number) and to keep your account details up to date.',
          ),
          const _Section(
            title: '3. Our service',
            body:
                'Gas express allows customers to browse LPG cylinders and related accessories, place delivery orders from participating mini warehouses/shops, manage delivery addresses, track orders, and request returns where available.\n\n'
                'Availability of products, shops, riders, and delivery coverage may vary by location and time. We do not guarantee that any particular product or delivery slot will always be available.',
          ),
          const _Section(
            title: '4. Orders, pricing, and payment',
            body:
                'When you place an order, you offer to purchase the selected items at the prices shown in the app at that time. Prices may change without notice before you confirm an order.\n\n'
                'Order confirmation, acceptance, and fulfilment are subject to stock, rider availability, and our operational checks. We may cancel or refuse an order if there is an error, safety concern, suspected fraud, or inability to deliver.\n\n'
                'You are responsible for providing a correct delivery address and being available to receive the order. Failed deliveries caused by incorrect address details or customer unavailability may result in extra charges or cancellation as communicated in the app.',
          ),
          const _Section(
            title: '5. Delivery and LPG safety',
            body:
                'LPG cylinders are hazardous goods. You agree to:\n'
                '• Receive deliveries only at a safe, accessible location;\n'
                '• Ensure a responsible adult is present to accept the cylinder;\n'
                '• Follow safe storage and handling guidance for LPG;\n'
                '• Not ask riders to leave cylinders in unsafe or unsupervised places.\n\n'
                'We and our partners may refuse delivery if conditions appear unsafe. You are responsible for the safe use of cylinders after delivery.',
          ),
          const _Section(
            title: '6. Returns and exchanges',
            body:
                'Empty cylinder returns and related processes (including OTP verification where applicable) must follow the steps shown in the app. Eligibility, timing, and conditions for returns may depend on the order type, shop policy, and applicable regulations.\n\n'
                'Damaged, tampered, or non-compliant cylinders may be rejected on inspection.',
          ),
          const _Section(
            title: '7. Accounts and OTP login',
            body:
                'Access to your account may use phone-number verification (OTP). You must keep your phone secure and not share OTPs with anyone.\n\n'
                'You are responsible for activity under your account. Notify us promptly if you suspect unauthorized access.',
          ),
          const _Section(
            title: '8. Acceptable use',
            body:
                'You agree not to:\n'
                '• Misuse the app, disrupt services, or attempt unauthorized access;\n'
                '• Place fraudulent or abusive orders;\n'
                '• Harass riders, shop staff, or support agents;\n'
                '• Use the service for unlawful purposes.\n\n'
                'We may suspend or terminate accounts that violate these Terms.',
          ),
          const _Section(
            title: '9. Privacy',
            body:
                'We collect and process personal data (such as your name, phone number, addresses, and order history) to operate the service, deliver orders, and improve the app.\n\n'
                'By using Gas express, you consent to this processing as reasonably necessary to provide the service. We take appropriate measures to protect your information, but no system is completely secure.',
          ),
          const _Section(
            title: '10. Third parties',
            body:
                'Orders may involve independent shops, warehouses, and delivery riders. While we work to provide a reliable experience, those parties remain responsible for their own conduct and services to the extent permitted by law.',
          ),
          const _Section(
            title: '11. Limitation of liability',
            body:
                'To the maximum extent permitted by applicable law, Gas express and Jocsoft Solutions Ltd are not liable for indirect, incidental, or consequential losses arising from use of the app or delivery services.\n\n'
                'Nothing in these Terms excludes liability that cannot be excluded by law, including liability for death or personal injury caused by negligence where such exclusion is prohibited.',
          ),
          const _Section(
            title: '12. Changes to the service or Terms',
            body:
                'We may update the app, features, prices, and these Terms from time to time. Continued use after changes take effect means you accept the updated Terms. Material changes may be communicated in the app or by other reasonable means.',
          ),
          const _Section(
            title: '13. Contact',
            body:
                'For questions about these Terms or the Gas express service, contact customer care through the Help section in the app, or reach Jocsoft Solutions Ltd using the support channels listed on the Google Play store listing for Gas express.',
          ),
          const _Section(
            title: '14. Governing law',
            body:
                'These Terms are governed by the laws of Kenya, without regard to conflict-of-law principles. Disputes shall be subject to the competent courts of Kenya, unless mandatory consumer protections in your jurisdiction require otherwise.',
          ),
          const SizedBox(height: 12),
          Text(
            'By checking “I agree to the Terms and Conditions” during signup, you acknowledge that you have read and accepted these Terms.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF014F5B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }
}
