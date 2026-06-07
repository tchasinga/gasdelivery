import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/address_picker_dialog.dart';
import '../widgets/auth_screen_shell.dart';
import 'login_screen.dart';

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
      builder: (context) => const AddressPickerDialog(),
    );
    if (address != null && address.isNotEmpty) {
      setState(() => _addressController.text = address);
    }
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
      accountCustomerName: _nameController.text.trim(),
      accountCustomerPhoneNumber: _phoneController.text.trim(),
      accountCustomerAddress: _addressController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created. Please sign in.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
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
              Text('Welcome.', style: AuthFormStyles.sheetTitleStyle()),
              const SizedBox(height: 28),
              AuthLabeledField(
                label: 'Name',
                child: TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(fontSize: 15),
                  decoration:
                      AuthFormStyles.outlineDecoration(hint: 'Your full name'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Please enter your name' : null,
                ),
              ),
              AuthLabeledField(
                label: 'Phone',
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 15),
                  decoration:
                      AuthFormStyles.outlineDecoration(hint: '+2547XXXXXXXX'),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Please enter your phone number'
                      : null,
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
                      icon: const Icon(
                        Icons.place_outlined,
                        color: Color(0xFF8E8E8E),
                      ),
                      onPressed: _pickAddress,
                      tooltip: 'Search address',
                    ),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please enter your delivery address'
                      : null,
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
                          onChanged: (v) =>
                              setState(() => _agreedToTerms = v ?? false),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _agreedToTerms = !_agreedToTerms),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'I agree to the Terms and Conditions',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8E8E8E),
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
                  children: [
                    Text(
                      'Already a member? ',
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
                      child: Text('Sign in', style: AuthFormStyles.linkStyle()),
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
