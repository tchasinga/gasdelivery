import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../widgets/auth_screen_shell.dart';
import 'customer_accounts/home_screen.dart';
import 'riders/rider_home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _riderFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _riderEmailController = TextEditingController();
  final _riderPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _rememberMe = false;

  /// `null` until the user picks a portal from the dialog.
  String? _portal;

  static const _keyRemember = 'auth_remember_me';
  static const _keySavedPhone = 'auth_saved_phone';

  @override
  void initState() {
    super.initState();
    _loadRememberedPhone();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickPortal());
  }

  Future<void> _pickPortal() async {
    if (!mounted || _portal != null) return;
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Sign in as'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Customer'),
                subtitle: const Text('Phone number and OTP'),
                onTap: () => Navigator.pop(ctx, AppAuthRole.customerAccounts),
              ),
              ListTile(
                leading: const Icon(Icons.two_wheeler),
                title: const Text('Rider'),
                subtitle: const Text('Email and password'),
                onTap: () => Navigator.pop(ctx, AppAuthRole.riders),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted) return;
    setState(() {
      _portal = choice ?? AppAuthRole.customerAccounts;
    });
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
    _riderEmailController.dispose();
    _riderPasswordController.dispose();
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

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.login(
        accountCustomerPhoneNumber: _phoneController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        await _persistRememberPreference();
        setState(() {
          _otpSent = true;
          _otpController.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP code has been sent to your phone number'),
              backgroundColor: Color(0xFF014F5B),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Failed to send OTP. Please try again.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
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

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.verifyOtp(
        accountCustomerPhoneNumber: _phoneController.text.trim(),
        accountOptCode: _otpController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        await _persistRememberPreference();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ??
                    'Invalid OTP code. Please check and try again.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          _otpController.clear();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      _otpController.clear();
    }
  }

  Future<void> _riderSignIn() async {
    final email = _riderEmailController.text.trim();
    final password = _riderPasswordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter email and password'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final result = await auth.loginRider(email: email, password: password);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const RiderHomeScreen()),
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']?.toString() ?? 'Login failed'),
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

  Future<void> _switchPortal() async {
    setState(() {
      _portal = null;
      _otpSent = false;
      _otpController.clear();
    });
    await _pickPortal();
  }

  @override
  Widget build(BuildContext context) {
    if (_portal == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF014F5B))),
      );
    }

    if (_portal == AppAuthRole.riders) {
      return AuthScreenShell(
        sheetChild: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Form(
            key: _riderFormKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _switchPortal,
                      child: const Text('Change account type'),
                    ),
                  ),
                  Text('Rider sign in', style: AuthFormStyles.sheetTitleStyle()),
                  const SizedBox(height: 28),
                  AuthLabeledField(
                    label: 'Email',
                    child: TextFormField(
                      controller: _riderEmailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 15),
                      decoration: AuthFormStyles.outlineDecoration(hint: 'you@example.com'),
                    ),
                  ),
                  AuthLabeledField(
                    label: 'Password',
                    child: TextFormField(
                      controller: _riderPasswordController,
                      obscureText: true,
                      style: const TextStyle(fontSize: 15),
                      decoration: AuthFormStyles.outlineDecoration(hint: 'Password'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AuthPrimaryButton(
                    label: 'Sign in',
                    loading: _isLoading,
                    onPressed: _riderSignIn,
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text("Don't have an account? ", style: AuthFormStyles.footerGreyStyle()),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const SignupScreen()),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('Sign up', style: AuthFormStyles.linkStyle()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final checkboxTheme = CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      side: const BorderSide(color: Color(0xFFC9C9C9), width: 1.2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );

    return AuthScreenShell(
      sheetChild: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _switchPortal,
                  child: const Text('Change account type'),
                ),
              ),
              Text('Welcome back.', style: AuthFormStyles.sheetTitleStyle()),
              const SizedBox(height: 28),
              AuthLabeledField(
                label: 'Phone',
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !_otpSent,
                  style: const TextStyle(fontSize: 15),
                  decoration: AuthFormStyles.outlineDecoration(
                    hint: '+2547XXXXXXXX',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
              ),
              if (_otpSent) ...[
                AuthLabeledField(
                  label: 'Verification code',
                  paddingBottom: 12,
                  child: TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 6,
                    ),
                    decoration: AuthFormStyles.outlineDecoration(
                      hint: '000000',
                    ).copyWith(counterText: ''),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                setState(() {
                                  _otpSent = false;
                                  _otpController.clear();
                                });
                                _sendOtp();
                              },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: const Color(0xFF2F6FED),
                      ),
                      child: const Text(
                        'Resend code',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              Theme(
                data: Theme.of(context).copyWith(checkboxTheme: checkboxTheme),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) {
                          setState(() {
                            _rememberMe = v ?? false;
                          });
                        },
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Color(0xFF0D0D0D);
                          }
                          return Colors.transparent;
                        }),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _rememberMe = !_rememberMe;
                          });
                        },
                        child: const Text(
                          'Remember me',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8E8E8E),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AuthPrimaryButton(
                label: _otpSent ? 'Sign in' : 'Continue',
                loading: _isLoading,
                onPressed: _otpSent ? _verifyOtp : _sendOtp,
              ),
              const SizedBox(height: 28),
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
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Sign up',
                        style: AuthFormStyles.linkStyle(),
                      ),
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
