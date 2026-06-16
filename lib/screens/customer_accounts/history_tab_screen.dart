import 'package:flutter/material.dart';

import '../../services/api_services.dart';
import '../../services/auth_service.dart';
import '../../utils/format_api_label.dart';

class HistoryTabScreen extends StatefulWidget {
  const HistoryTabScreen({super.key});

  @override
  State<HistoryTabScreen> createState() => _HistoryTabScreenState();
}

class _HistoryTabScreenState extends State<HistoryTabScreen> {
  static const _brand = Color(0xFF014F5B);

  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = await AuthService.getToken();
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Not signed in';
      });
      return;
    }

    final result = await ApiService.getCustomerAccountHistory(token);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _history = (result['history'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        _error = result['message'] as String? ?? 'Could not load history';
      }
    });
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $h:$min $ampm';
    } catch (_) {
      return raw;
    }
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'delivery':
        return Icons.local_shipping_outlined;
      case 'cylinder_return':
        return Icons.keyboard_return_rounded;
      case 'payment':
        return Icons.payments_outlined;
      case 'support_message':
        return Icons.mail_outline_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: _brand,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadHistory,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _brand));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadHistory, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history_rounded,
                  size: 56,
                  color: _brand,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No history yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _brand,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your deliveries, payments, returns, and messages will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.45),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _brand,
      onRefresh: _loadHistory,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = _history[index];
          final title = item['title']?.toString() ?? 'Activity';
          final subtitle = item['subtitle']?.toString() ?? '';
          final status = formatApiLabelForUi(item['status']?.toString());
          final amount = item['amount'];
          final type = item['type']?.toString();
          final date = _formatDate(item['occurred_at']?.toString());

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: _brand.withValues(alpha: 0.1),
                child: Icon(_iconForType(type), color: _brand, size: 22),
              ),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle),
                  ],
                  if (status.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: amount != null
                  ? Text(
                      'KES $amount',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _brand,
                      ),
                    )
                  : null,
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
