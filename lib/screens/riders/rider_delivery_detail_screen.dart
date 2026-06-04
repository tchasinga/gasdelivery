import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_services.dart';
import '../../services/auth_service.dart';
import '../../utils/format_api_label.dart';
import '../../utils/phone_launcher.dart';
import 'rider_deliver_payment_phone_sheet.dart';

class RiderDeliveryDetailScreen extends StatefulWidget {
  final int orderId;
  const RiderDeliveryDetailScreen({super.key, required this.orderId});

  @override
  State<RiderDeliveryDetailScreen> createState() =>
      _RiderDeliveryDetailScreenState();
}

class _RiderDeliveryDetailScreenState extends State<RiderDeliveryDetailScreen> {
  static const _brand = Color(0xFF014F5B);
  static const _brandLight = Color(0xFFE8F4F6);
  static const _surface = Color(0xFFF5F7F8);
  static const _cardRadius = 16.0;

  Map<String, dynamic>? _order;
  bool _loading = true;
  bool _busy = false;
  final _otpController = TextEditingController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 4), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final token = await AuthService.getToken();
    if (token == null) return;
    final res = await ApiService.getRiderDeliveryOrder(token, widget.orderId);
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _order = Map<String, dynamic>.from(res['order']);
        _loading = false;
      });
    } else if (!silent) {
      setState(() => _loading = false);
    }
  }

  Future<void> _deliverNow() async {
    final o = _order ?? {};
    final customer = o['customer'] as Map<String, dynamic>?;
    final defaultPhone = (customer?['phone']?.toString() ?? '').trim();
    final orderNumber = o['order_number']?.toString() ?? 'this order';

    final choice = await RiderDeliverPaymentPhoneSheet.show(
      context,
      defaultPhone: defaultPhone,
      orderNumber: orderNumber,
    );
    if (choice == null || !mounted) return;

    setState(() => _busy = true);
    final token = await AuthService.getToken();
    final res = await ApiService.riderDeliverNow(
      token!,
      widget.orderId,
      customerNumberAlternative:
          choice.useDefault ? null : choice.alternativePhone,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message']?.toString() ?? ''),
        backgroundColor: res['success'] == true ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    _load();
  }

  Future<void> _verifyOtp() async {
    setState(() => _busy = true);
    final token = await AuthService.getToken();
    final res = await ApiService.riderVerifyDeliveryOtp(
      token: token!,
      orderId: widget.orderId,
      otp: _otpController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message']?.toString() ?? ''),
        backgroundColor: res['success'] == true ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    if (res['success'] == true) Navigator.pop(context, true);
  }

  _StatusStyle _statusStyle(String? status) {
    switch (status) {
      case 'assigned_to_rider':
        return const _StatusStyle(
          color: Color(0xFF0369A1),
          bg: Color(0xFFE0F2FE),
          icon: Icons.assignment_ind_outlined,
        );
      case 'in_transit':
        return const _StatusStyle(
          color: Color(0xFF0D9488),
          bg: Color(0xFFCCFBF1),
          icon: Icons.local_shipping_outlined,
        );
      case 'awaiting_payment':
        return const _StatusStyle(
          color: Color(0xFFD97706),
          bg: Color(0xFFFFEDD5),
          icon: Icons.payments_outlined,
        );
      case 'awaiting_delivery_otp':
        return const _StatusStyle(
          color: Color(0xFF7C3AED),
          bg: Color(0xFFEDE9FE),
          icon: Icons.pin_outlined,
        );
      case 'completed':
        return const _StatusStyle(
          color: Color(0xFF15803D),
          bg: Color(0xFFDCFCE7),
          icon: Icons.check_circle_outline,
        );
      case 'cancelled':
        return _StatusStyle(
          color: Colors.grey.shade700,
          bg: Colors.grey.shade200,
          icon: Icons.cancel_outlined,
        );
      default:
        return const _StatusStyle(
          color: _brand,
          bg: _brandLight,
          icon: Icons.info_outline,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _order == null) {
      return Scaffold(
        backgroundColor: _surface,
        appBar: AppBar(
          title: const Text('Delivery'),
          backgroundColor: _brand,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: _brand),
        ),
      );
    }

    final o = _order ?? {};
    final customer = o['customer'] as Map<String, dynamic>?;
    final status = o['status']?.toString();
    final statusUi = formatApiLabelForUi(status);
    final statusStyle = _statusStyle(status);
    final customerPhone = (customer?['phone']?.toString() ?? '').trim();
    final customerName = (customer?['name']?.toString() ?? 'Customer').trim();
    final orderNumber = o['order_number']?.toString() ?? 'Delivery';
    final qty = o['quantity_fulfilled'] ?? o['quantity_requested'];
    final amount = o['total_amount'];
    final deliveryAddress = o['delivery_address']?.toString() ?? '—';
    final customerAddress = customer?['address']?.toString() ?? '';
    final altPayPhone =
        (o['customer_number_alternative']?.toString() ?? '').trim();
    final initial =
        customerName.isNotEmpty ? customerName[0].toUpperCase() : '?';

    final canDeliver =
        status == 'assigned_to_rider' || status == 'in_transit';
    final awaitingPayment = status == 'awaiting_payment';
    final awaitingOtp = status == 'awaiting_delivery_otp';

    return Scaffold(
      backgroundColor: _surface,
      body: RefreshIndicator(
        color: _brand,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: _brand,
              foregroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 14, right: 48),
                title: Text(
                  orderNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF014F5B), Color(0xFF027A8A)],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 48, right: 12),
                      child: Icon(
                        Icons.two_wheeler,
                        size: 64,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                if (customerPhone.isNotEmpty)
                  IconButton(
                    onPressed: () => launchPhoneCall(
                      customerPhone,
                      context: context,
                    ),
                    icon: const Icon(Icons.phone_in_talk_outlined),
                    tooltip: 'Call $customerName',
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StatusBanner(
                        label: statusUi,
                        style: statusStyle,
                      ),
                      const SizedBox(height: 16),
                      if (amount != null) ...[
                        _AmountHighlight(amount: amount.toString()),
                        const SizedBox(height: 16),
                      ],
                      _SectionCard(
                        title: 'Customer',
                        icon: Icons.person_outline,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: _brandLight,
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      color: _brand,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customerName,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      if (customerPhone.isNotEmpty)
                                        Text(
                                          customerPhone,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (customerPhone.isNotEmpty)
                                  Material(
                                    color: _brandLight,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: () => launchPhoneCall(
                                        customerPhone,
                                        context: context,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      child: const Padding(
                                        padding: EdgeInsets.all(10),
                                        child: Icon(
                                          Icons.phone,
                                          color: _brand,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (customerAddress.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              _InfoRow(
                                icon: Icons.home_outlined,
                                label: 'Address',
                                value: customerAddress,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Delivery details',
                        icon: Icons.inventory_2_outlined,
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.tag_outlined,
                              label: 'Status',
                              value: statusUi,
                            ),
                            _InfoRow(
                              icon: Icons.propane_tank_outlined,
                              label: 'Quantity',
                              value: '$qty cylinder${qty == 1 ? '' : 's'}',
                            ),
                            _InfoRow(
                              icon: Icons.location_on_outlined,
                              label: 'Drop-off',
                              value: deliveryAddress,
                              multiline: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (canDeliver) _DeliverNowPanel(busy: _busy, onTap: _deliverNow),
                      if (awaitingPayment)
                        _AwaitingPaymentPanel(alternativePhone: altPayPhone),
                      if (awaitingOtp)
                        _OtpPanel(
                          controller: _otpController,
                          busy: _busy,
                          onConfirm: _verifyOtp,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.color,
    required this.bg,
    required this.icon,
  });

  final Color color;
  final Color bg;
  final IconData icon;
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.label, required this.style});

  final String label;
  final _StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(_RiderDeliveryDetailScreenState._cardRadius),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: style.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(style.icon, color: style.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current status',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: style.color,
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

class _AmountHighlight extends StatelessWidget {
  const _AmountHighlight({required this.amount});

  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF014F5B), Color(0xFF026B7A)],
        ),
        borderRadius: BorderRadius.circular(
          _RiderDeliveryDetailScreenState._cardRadius,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF014F5B).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.payments, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount to collect',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'KES $amount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(_RiderDeliveryDetailScreenState._cardRadius),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: _RiderDeliveryDetailScreenState._brand,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliverNowPanel extends StatelessWidget {
  const _DeliverNowPanel({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF014F5B).withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey.shade700, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Start delivery to send an M-Pesa prompt to the customer.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: busy ? null : onTap,
          icon: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.play_circle_outline),
          label: Text(busy ? 'Processing…' : 'Deliver now'),
          style: FilledButton.styleFrom(
            backgroundColor: _RiderDeliveryDetailScreenState._brand,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

class _AwaitingPaymentPanel extends StatelessWidget {
  const _AwaitingPaymentPanel({required this.alternativePhone});

  final String alternativePhone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(
          _RiderDeliveryDetailScreenState._cardRadius,
        ),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Waiting for M-Pesa payment',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ask the customer to enter their PIN on the STK prompt.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
          if (alternativePhone.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone_android, size: 18, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Text(
                    'STK sent to $alternativePhone',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF78350F),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OtpPanel extends StatelessWidget {
  const _OtpPanel({
    required this.controller,
    required this.busy,
    required this.onConfirm,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(_RiderDeliveryDetailScreenState._cardRadius),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE9FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    color: Color(0xFF7C3AED),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm delivery',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Enter the 6-digit OTP from the customer',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 12,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: '••••••',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: _RiderDeliveryDetailScreenState._brand,
                    width: 2,
                  ),
                ),
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy ? null : onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: _RiderDeliveryDetailScreenState._brand,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Confirm delivery',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
