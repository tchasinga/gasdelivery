import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef ReturnOtpConfirmCallback = Future<Map<String, dynamic>> Function(
  String otp,
);

class CustomerReturnOtpSheet extends StatefulWidget {
  const CustomerReturnOtpSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onConfirm,
  });

  final String title;
  final String subtitle;
  final ReturnOtpConfirmCallback onConfirm;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required ReturnOtpConfirmCallback onConfirm,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => CustomerReturnOtpSheet(
        title: title,
        subtitle: subtitle,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<CustomerReturnOtpSheet> createState() => _CustomerReturnOtpSheetState();
}

class _CustomerReturnOtpSheetState extends State<CustomerReturnOtpSheet> {
  static const _brand = Color(0xFF014F5B);

  final _otpController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter the 6-digit OTP');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await widget.onConfirm(otp);
    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      _submitting = false;
      _error = result['message'] as String? ?? 'Invalid OTP';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '000000',
                    errorText: _error,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _brand,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Confirm return'),
                ),
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.pop(context, false),
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
