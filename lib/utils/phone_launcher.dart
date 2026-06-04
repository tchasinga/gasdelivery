import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the device dialer for [phone]. Returns false if launch failed.
Future<bool> launchPhoneCall(String phone, {BuildContext? context}) async {
  final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.isEmpty) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return false;
  }

  final uri = Uri(scheme: 'tel', path: digits);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open phone dialer'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return launched;
  } catch (_) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open phone dialer'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return false;
  }
}
