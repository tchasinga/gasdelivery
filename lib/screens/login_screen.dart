import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_screen_shell.dart';
import 'customer_accounts/home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.returnAfterLogin = false});

  /// When true, pops with `true` after OTP success so the caller can resume checkout.
  final bool returnAfterLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _rememberMe = false;

  static const _keyRemember = 'auth_remember_me';
  static const _keySavedPhone = 'auth_saved_phone';

  @override
  void initState() {
    super.initState();
    _loadRememberedPhone();
  }

  Future<void> _loadRememberedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (prefs.getBool(_keyRemember) ?? false) {
      final phone = prefs.getString(_keySavedPhone);
      setState(() {
        _rememberMe = true;
        if (phone != null && phone.isNotEmpty) {
          _phoneController.text = phone;
        }
      });
    }
  }

  Future<void> _persistRememberPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRemember, _rememberMe);
    if (_rememberMe) {
      await prefs.setString(_keySavedPhone, _phoneController.text.trim());
    } else {
      await prefs.remove(_keySavedPhone);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.login(
        accountCustomerPhoneNumber: _phoneController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        await _persistRememberPreference();
        setState(() {
          _otpSent = true;
          _otpController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP code has been sent to your phone number'),
            backgroundColor: AuthColors.brand,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Failed to send OTP. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the OTP code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP code must be 6 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.verifyOtp(
        accountCustomerPhoneNumber: _phoneController.text.trim(),
        accountOptCode: _otpController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        await _persistRememberPreference();
        if (!mounted) return;
        if (widget.returnAfterLogin) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (_) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ??
                  'Invalid OTP code. Please check and try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        _otpController.clear();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      _otpController.clear();
    }
  }

  void _editPhone() {
    setState(() {
      _otpSent = false;
      _otpController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenShell(
      leading: widget.returnAfterLogin
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(false),
            )
          : null,
      sheetChild: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _otpSent ? 'Enter verification code' : 'Welcome back',
                style: AuthFormStyles.sheetTitleStyle(),
              ),
              const SizedBox(height: 8),
              Text(
                _otpSent
                    ? 'We sent a 6-digit code to ${_phoneController.text.trim()}.'
                    : 'Sign in with your phone number to order gas delivery.',
                style: AuthFormStyles.subtitleStyle(),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  AuthStepChip(label: '1 · Phone', active: !_otpSent),
                  const SizedBox(width: 8),
                  AuthStepChip(label: '2 · OTP', active: _otpSent),
                ],
              ),
              const SizedBox(height: 22),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _otpSent
                    ? KeyedSubtree(
                        key: const ValueKey('otp'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AuthLabeledField(
                              label: 'Verification code',
                              paddingBottom: 8,
                              child: TextFormField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                autofocus: true,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 10,
                                  color: AuthColors.ink,
                                ),
                                decoration: AuthFormStyles.outlineDecoration(
                                  hint: '••••••',
                                ).copyWith(counterText: ''),
                              ),
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: _isLoading ? null : _editPhone,
                                  child: const Text('Change number'),
                                ),
                                TextButton(
                                  onPressed: _isLoading ? null : _sendOtp,
                                  child: const Text('Resend code'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : KeyedSubtree(
                        key: const ValueKey('phone'),
                        child: AuthLabeledField(
                          label: 'Phone number',
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AuthColors.ink,
                            ),
                            decoration: AuthFormStyles.outlineDecoration(
                              hint: '07XXXXXXXX',
                              prefixIcon: const Icon(
                                Icons.phone_iphone_rounded,
                                color: AuthColors.brand,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
              ),
              if (!_otpSent) ...[
                const SizedBox(height: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: AuthColors.brand,
                            side: const BorderSide(color: AuthColors.line, width: 1.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            onChanged: (v) =>
                                setState(() => _rememberMe = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Remember my phone number',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AuthColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              AuthPrimaryButton(
                label: _otpSent ? 'Verify & sign in' : 'Continue',
                loading: _isLoading,
                onPressed: _otpSent ? _verifyOtp : _sendOtp,
              ),
              const SizedBox(height: 24),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AuthFormStyles.footerGreyStyle(),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SignupScreen(),
                          ),
                        );
                      },
                      child: Text('Create account', style: AuthFormStyles.linkStyle()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
