import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../services/api_services.dart';
import '../../../services/auth_service.dart';
import '../../../utils/format_api_label.dart';
import '../../login_screen.dart';

/// Rider bottom tab: Profile — account details for the signed-in rider.
class RiderTabProfile extends StatefulWidget {
  const RiderTabProfile({super.key});

  @override
  State<RiderTabProfile> createState() => _RiderTabProfileState();
}

class _RiderTabProfileState extends State<RiderTabProfile> {
  Map<String, dynamic> _profile = {};
  bool _loading = true;
  String? _loadError;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    final cached = await AuthService.getCachedRiderProfile();
    final token = await AuthService.getToken();
    if (mounted) {
      setState(() {
        _profile = Map<String, dynamic>.from(cached);
        _authToken = token;
        _loading = false;
      });
    }

    final api = await AuthService.fetchAuthenticatedUser();
    if (!mounted) return;

    if (api['success'] == true && api['data'] is Map<String, dynamic>) {
      final fresh = Map<String, dynamic>.from(
        api['data'] as Map<String, dynamic>,
      );
      setState(() {
        _profile = _mergeRiderMaps(cached, fresh);
        _loadError = null;
      });
    } else {
      setState(() {
        if (_profile.isEmpty) {
          _loadError = api['message']?.toString() ?? 'Could not load profile';
        } else {
          _loadError = api['message']?.toString();
        }
      });
    }
  }

  /// Prefer live API fields; fall back to login cache for anything missing.
  static Map<String, dynamic> _mergeRiderMaps(
    Map<String, dynamic> cached,
    Map<String, dynamic> api,
  ) {
    final out = Map<String, dynamic>.from(api);
    for (final e in cached.entries) {
      out.putIfAbsent(e.key, () => e.value);
    }
    return out;
  }

  static String _str(dynamic v) {
    if (v == null) return '';
    final s = v.toString().trim();
    return s;
  }

  static String _displayDate(dynamic v) {
    final s = _str(v);
    if (s.isEmpty) return '—';
    final i = s.indexOf('T');
    if (i > 0) return s.substring(0, i);
    if (s.length >= 10 && s[4] == '-' && s[7] == '-') return s.substring(0, 10);
    return s;
  }

  static String _maskNationalId(dynamic v) {
    final raw = _str(v);
    if (raw.isEmpty) return '—';
    if (raw.length <= 4) return '••••';
    return '••••${raw.substring(raw.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final displayName =
        _str(_profile['full_name']).isNotEmpty
            ? _str(_profile['full_name'])
            : (_str(_profile['name']).isNotEmpty
                ? _str(_profile['name'])
                : (auth.riderDisplayName ?? 'Rider'));

    final rows = <({IconData icon, String label, String value})>[
      (
        icon: Icons.email_outlined,
        label: 'Email',
        value: _nonEmpty(_profile['email_address']),
      ),
      (
        icon: Icons.phone_outlined,
        label: 'Phone',
        value: _nonEmpty(_profile['phone_number']),
      ),
      (
        icon: Icons.cake_outlined,
        label: 'Date of birth',
        value: _displayDate(_profile['date_of_birth']),
      ),
      (
        icon: Icons.wc_outlined,
        label: 'Gender',
        value: _nonEmpty(formatApiLabelForUi(_str(_profile['gender']))),
      ),
      (
        icon: Icons.badge_outlined,
        label: 'National ID',
        value: _maskNationalId(_profile['national_id']),
      ),
      (
        icon: Icons.verified_user_outlined,
        label: 'Account status',
        value: _nonEmpty(formatApiLabelForUi(_str(_profile['riders_status']))),
      ),
      (
        icon: Icons.credit_card_outlined,
        label: 'Driving licence',
        value: _nonEmpty(_profile['driving_license_number']),
      ),
      (
        icon: Icons.event_outlined,
        label: 'Licence expires',
        value: _displayDate(_profile['license_expiry_date']),
      ),
      (
        icon: Icons.category_outlined,
        label: 'Vehicle type',
        value: _nonEmpty(formatApiLabelForUi(_str(_profile['vehicle_type']))),
      ),
      (
        icon: Icons.directions_car_outlined,
        label: 'Vehicle model',
        value: _nonEmpty(_profile['vehicle_model']),
      ),
      (
        icon: Icons.pin_outlined,
        label: 'Plate number',
        value: _nonEmpty(_profile['vehicle_plate_number']),
      ),
    ];

    return RefreshIndicator(
      color: const Color(0xFF014F5B),
      onRefresh: _loadProfile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Center(
            child: _RiderSelfieAvatar(
              selfiePath: _str(_profile['selfie_verification_photo']),
              authToken: _authToken,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Rider account',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF8E8E8E), fontSize: 14),
          ),
          if (_loadError != null && _profile.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
            ),
          ],
          if (_loadError != null && _profile.isEmpty && !_loading) ...[
            const SizedBox(height: 16),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8E8E8E)),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Your details',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: const Color(0xFFF7F7F7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, indent: 56, color: Colors.grey.shade300),
                  _RiderProfileInfoRow(
                    icon: rows[i].icon,
                    label: rows[i].label,
                    value: rows[i].value,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log out'),
            ),
          ),
        ],
      ),
    );
  }

  static String _nonEmpty(dynamic v) {
    final s = _str(v);
    return s.isEmpty ? '—' : s;
  }
}

/// Profile header: selfie from API when available, otherwise default avatar.
class _RiderSelfieAvatar extends StatefulWidget {
  const _RiderSelfieAvatar({
    required this.selfiePath,
    required this.authToken,
  });

  final String selfiePath;
  final String? authToken;

  @override
  State<_RiderSelfieAvatar> createState() => _RiderSelfieAvatarState();
}

class _RiderSelfieAvatarState extends State<_RiderSelfieAvatar> {
  bool _imageFailed = false;

  bool get _canLoadSelfie =>
      widget.selfiePath.isNotEmpty &&
      widget.authToken != null &&
      widget.authToken!.isNotEmpty &&
      !_imageFailed;

  @override
  void didUpdateWidget(covariant _RiderSelfieAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selfiePath != widget.selfiePath ||
        oldWidget.authToken != widget.authToken) {
      _imageFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canLoadSelfie) {
      return const CircleAvatar(
        radius: 40,
        backgroundColor: Color(0xFF014F5B),
        child: Icon(Icons.person, size: 44, color: Colors.white),
      );
    }

    final url = ApiService.riderVerificationPhotoUrl('selfie');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${widget.authToken}',
    };

    return CircleAvatar(
      radius: 40,
      backgroundColor: const Color(0xFF014F5B),
      backgroundImage: NetworkImage(url, headers: headers),
      onBackgroundImageError: (_, __) {
        if (mounted) setState(() => _imageFailed = true);
      },
    );
  }
}

class _RiderProfileInfoRow extends StatelessWidget {
  const _RiderProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: const Color(0xFF014F5B)),
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
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
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
