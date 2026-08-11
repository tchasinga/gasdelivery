import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_screen_shell.dart';
import 'customer_accounts/home_screen.dart';
import 'login_screen.dart';
import 'terms_and_conditions_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _otpSent = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _openTerms() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TermsAndConditionsScreen(),
      ),
    );
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Conditions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.signup(
      accountCustomerName: _firstNameController.text.trim(),
      accountCustomerSurname: _surnameController.text.trim(),
      accountCustomerPhoneNumber: _phoneController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      setState(() {
        _otpSent = true;
        _otpController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created. Enter the OTP sent to your phone.'),
          backgroundColor: AuthColors.brand,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Signup failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.login(
      accountCustomerPhoneNumber: _phoneController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['success'] == true
              ? 'OTP code has been resent to your phone number'
              : (result['message'] ?? 'Failed to resend OTP'),
        ),
        backgroundColor:
            result['success'] == true ? AuthColors.brand : Colors.red,
      ),
    );
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the OTP code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP code must be 6 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.verifyOtp(
      accountCustomerPhoneNumber: _phoneController.text.trim(),
      accountOptCode: otp,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
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
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenShell(
      tagline: _otpSent
          ? 'Verify your phone to finish signup'
          : 'Create your account in under a minute',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () {
          if (_otpSent) {
            // Account already exists — send them to sign-in instead of recreating.
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          } else {
            Navigator.of(context).maybePop();
          }
        },
      ),
      sheetChild: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _otpSent ? 'Verify your account' : 'Create account',
                style: AuthFormStyles.sheetTitleStyle(),
              ),
              const SizedBox(height: 8),
              Text(
                _otpSent
                    ? 'We sent a 6-digit code to ${_phoneController.text.trim()}.'
                    : 'Join Gas express to order cylinders and track delivery live.',
                style: AuthFormStyles.subtitleStyle(),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  AuthStepChip(label: '1 · Details', active: !_otpSent),
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
                            TextButton(
                              onPressed: _isLoading ? null : _resendOtp,
                              child: const Text('Resend code'),
                            ),
                          ],
                        ),
                      )
                    : KeyedSubtree(
                        key: const ValueKey('details'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AuthLabeledField(
                              label: 'First name',
                              child: TextFormField(
                                controller: _firstNameController,
                                keyboardType: TextInputType.name,
                                textCapitalization: TextCapitalization.words,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AuthColors.ink,
                                ),
                                decoration: AuthFormStyles.outlineDecoration(
                                  hint: 'First name',
                                  prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
                                    color: AuthColors.brand,
                                  ),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Please enter your first name'
                                    : null,
                              ),
                            ),
                            AuthLabeledField(
                              label: 'Surname',
                              child: TextFormField(
                                controller: _surnameController,
                                keyboardType: TextInputType.name,
                                textCapitalization: TextCapitalization.words,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AuthColors.ink,
                                ),
                                decoration: AuthFormStyles.outlineDecoration(
                                  hint: 'Surname',
                                  prefixIcon: const Icon(
                                    Icons.badge_outlined,
                                    color: AuthColors.brand,
                                  ),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Please enter your surname'
                                    : null,
                              ),
                            ),
                            AuthLabeledField(
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
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Please enter your phone number'
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => setState(
                                () => _agreedToTerms = !_agreedToTerms,
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _agreedToTerms,
                                        activeColor: AuthColors.brand,
                                        side: const BorderSide(
                                          color: AuthColors.line,
                                          width: 1.4,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        onChanged: (v) => setState(
                                          () => _agreedToTerms = v ?? false,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            const Text(
                                              'I agree to the ',
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                color: AuthColors.muted,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: _openTerms,
                                              child: Text(
                                                'Terms and Conditions',
                                                style: AuthFormStyles
                                                    .linkStyle()
                                                    .copyWith(
                                                      fontSize: 13.5,
                                                      decoration: TextDecoration
                                                          .underline,
                                                      decorationColor:
                                                          AuthColors.brand,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 18),
              AuthPrimaryButton(
                label: _otpSent ? 'Verify & continue' : 'Create account',
                loading: _isLoading,
                onPressed: _otpSent ? _verifyOtp : _signup,
              ),
              if (!_otpSent) ...[
                const SizedBox(height: 24),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AuthFormStyles.footerGreyStyle(),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child:
                            Text('Sign in', style: AuthFormStyles.linkStyle()),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
