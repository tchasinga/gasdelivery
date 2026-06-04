import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Result of the rider's M-Pesa payment phone choice before deliver-now.
class RiderDeliverPaymentPhoneChoice {
  const RiderDeliverPaymentPhoneChoice.defaultNumber()
      : useDefault = true,
        alternativePhone = null;

  const RiderDeliverPaymentPhoneChoice.alternative(this.alternativePhone)
      : useDefault = false;

  final bool useDefault;
  final String? alternativePhone;
}

/// Bottom sheet: default customer number vs alternative for STK push.
class RiderDeliverPaymentPhoneSheet extends StatefulWidget {
  const RiderDeliverPaymentPhoneSheet({
    super.key,
    required this.defaultPhone,
    required this.orderNumber,
  });

  final String defaultPhone;
  final String orderNumber;

  static Future<RiderDeliverPaymentPhoneChoice?> show(
    BuildContext context, {
    required String defaultPhone,
    required String orderNumber,
  }) {
    return showModalBottomSheet<RiderDeliverPaymentPhoneChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RiderDeliverPaymentPhoneSheet(
        defaultPhone: defaultPhone,
        orderNumber: orderNumber,
      ),
    );
  }

  @override
  State<RiderDeliverPaymentPhoneSheet> createState() =>
      _RiderDeliverPaymentPhoneSheetState();
}

class _RiderDeliverPaymentPhoneSheetState
    extends State<RiderDeliverPaymentPhoneSheet> {
  static const _brand = Color(0xFF014F5B);

  bool _useAlternative = false;
  final _altPhoneController = TextEditingController();

  @override
  void dispose() {
    _altPhoneController.dispose();
    super.dispose();
  }

  void _selectDefault() {
    setState(() => _useAlternative = false);
    Navigator.pop(
      context,
      const RiderDeliverPaymentPhoneChoice.defaultNumber(),
    );
  }

  void _continueWithAlternative() {
    final phone = _altPhoneController.text.trim();
    if (phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid phone number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      RiderDeliverPaymentPhoneChoice.alternative(phone),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final defaultDisplay = widget.defaultPhone.isNotEmpty
        ? widget.defaultPhone
        : 'Not on file';

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'M-Pesa payment number',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'An STK push will be sent for ${widget.orderNumber}. '
                  'Choose which number should receive the payment prompt.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                _OptionTile(
                  icon: Icons.phone_android,
                  title: 'Pay with default number',
                  subtitle: defaultDisplay,
                  selected: !_useAlternative,
                  onTap: widget.defaultPhone.isNotEmpty
                      ? _selectDefault
                      : null,
                  enabled: widget.defaultPhone.isNotEmpty,
                ),
                const SizedBox(height: 10),
                _OptionTile(
                  icon: Icons.phone_forwarded,
                  title: 'Pay with another number',
                  subtitle: 'Enter a different M-Pesa number',
                  selected: _useAlternative,
                  onTap: () => setState(() => _useAlternative = true),
                ),
                if (_useAlternative) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _altPhoneController,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Alternative phone number',
                      hintText: '07XX XXX XXX',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d+\s\-]')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _continueWithAlternative,
                    style: FilledButton.styleFrom(
                      backgroundColor: _brand,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF014F5B);

    return Material(
      color: selected ? brand.withValues(alpha: 0.08) : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? brand : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: enabled ? brand : Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? const Color(0xFF0F172A)
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              if (selected)
                const Icon(Icons.check_circle, color: brand, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
