import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../widgets/address_picker_dialog.dart';
import '../widgets/auth_screen_shell.dart';
import 'login_screen.dart';
import 'riders/rider_signup_stepper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  bool _agreedToTerms = false;

  String? _portal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickPortal());
  }

  Future<void> _pickPortal() async {
    if (!mounted || _portal != null) return;
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Sign up as'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Customer'),
                subtitle: const Text('Phone delivery account'),
                onTap: () => Navigator.pop(ctx, AppAuthRole.customerAccounts),
              ),
              ListTile(
                leading: const Icon(Icons.two_wheeler),
                title: const Text('Rider'),
                subtitle: const Text('Multi-step rider application'),
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickAddress() async {
    final address = await showDialog<String>(
      context: context,
      builder:
          (context) =>
              AddressPickerDialog(initialAddress: _addressController.text),
    );

    if (address != null && address.isNotEmpty && mounted) {
      setState(() {
        _addressController.text = address;
      });
    }
  }

  Future<void> _signup() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final address = _addressController.text.trim();
    final result = await authProvider.signup(
      accountCustomerName: _nameController.text.trim(),
      accountCustomerPhoneNumber: _phoneController.text.trim(),
      accountCustomerAddress: address.isNotEmpty ? address : null,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Please login.'),
          backgroundColor: Color(0xFF014F5B),
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
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

  @override
  Widget build(BuildContext context) {
    if (_portal == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF014F5B))),
      );
    }

    if (_portal == AppAuthRole.riders) {
      return RiderSignupStepper(
        onRegistered: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
      );
    }

    final checkboxTheme = CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      side: const BorderSide(color: Color(0xFFC9C9C9), width: 1.2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );

    return AuthScreenShell(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
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
                  onPressed: () {
                    setState(() => _portal = null);
                    WidgetsBinding.instance.addPostFrameCallback((_) => _pickPortal());
                  },
                  child: const Text('Change account type'),
                ),
              ),
              Text('Welcome.', style: AuthFormStyles.sheetTitleStyle()),
              const SizedBox(height: 28),
              AuthLabeledField(
                label: 'Name',
                child: TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 15),
                  decoration: AuthFormStyles.outlineDecoration(
                    hint: 'Your full name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
              ),
              AuthLabeledField(
                label: 'Phone',
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
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
              AuthLabeledField(
                label: 'Delivery address',
                child: TextFormField(
                  controller: _addressController,
                  minLines: 1,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 15),
                  decoration: AuthFormStyles.outlineDecoration(
                    hint: 'Street, city, area',
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.place_outlined, color: Color(0xFF8E8E8E)),
                      onPressed: _pickAddress,
                      tooltip: 'Search address',
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your delivery address';
                    }
                    return null;
                  },
                ),
              ),
              Theme(
                data: Theme.of(context).copyWith(checkboxTheme: checkboxTheme),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: Checkbox(
                          value: _agreedToTerms,
                          onChanged: (v) {
                            setState(() {
                              _agreedToTerms = v ?? false;
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
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _agreedToTerms = !_agreedToTerms;
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'I agree to the Terms and Conditions',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8E8E8E),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AuthPrimaryButton(
                label: 'Sign up',
                loading: _isLoading,
                onPressed: _signup,
              ),
              const SizedBox(height: 28),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Already a member? ',
                      style: AuthFormStyles.footerGreyStyle(),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Sign in',
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
