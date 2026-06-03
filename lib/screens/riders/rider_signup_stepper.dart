import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/auth_screen_shell.dart';

/// Multi-step rider registration aligned with Laravel `POST /api/auth/register-rider`.
class RiderSignupStepper extends StatefulWidget {
  const RiderSignupStepper({super.key, required this.onRegistered});

  final VoidCallback onRegistered;

  @override
  State<RiderSignupStepper> createState() => _RiderSignupStepperState();
}

class _RiderSignupStepperState extends State<RiderSignupStepper> {
  int _step = 0;
  bool _loading = false;
  bool _agreed = false;

  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  DateTime? _dateOfBirth;
  String _gender = 'male';
  final _nationalId = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  final _licenseNo = TextEditingController();
  DateTime? _licenseExpiryDate;
  String _vehicleType = 'motorcycle';
  final _vehicleModel = TextEditingController();
  final _plate = TextEditingController();

  XFile? _nationalIdPhoto;
  XFile? _selfiePhoto;

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _email.dispose();
    _nationalId.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    _licenseNo.dispose();
    _vehicleModel.dispose();
    _plate.dispose();
    super.dispose();
  }

  static String _formatYmd(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final last = DateTime(now.year - 16, now.month, now.day);
    final first = DateTime(1940);
    final initial = _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first)
          ? first
          : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
      helpText: 'Date of birth',
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _pickLicenseExpiry() async {
    final today = DateTime.now();
    final first = DateTime(today.year, today.month, today.day);
    final last = DateTime(today.year + 20, today.month, today.day);
    final initial = _licenseExpiryDate ?? DateTime(today.year + 1, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
      helpText: 'Licence expiry',
    );
    if (picked != null) setState(() => _licenseExpiryDate = picked);
  }

  Future<void> _pickImage({required bool nationalId}) async {
    if (!mounted) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
    if (source == null || !mounted) return;

    // Let the bottom sheet route finish closing before touching the platform
    // channel; calling pickImage immediately often triggers ImagePickerApi channel-error.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    try {
      // Fresh picker avoids stale Android plugin bindings after hot reload / sheet pop.
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
        requestFullMetadata: false,
      );
      if (file != null) {
        setState(() {
          if (nationalId) {
            _nationalIdPhoto = file;
          } else {
            _selfiePhoto = file;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  bool _validateStep0() {
    if (_fullName.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _dateOfBirth == null ||
        _nationalId.text.trim().isEmpty ||
        _password.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required personal fields (password min 8).'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    if (_password.text != _passwordConfirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.'), backgroundColor: Colors.red),
      );
      return false;
    }
    return true;
  }

  bool _validateStep1() {
    if (_licenseNo.text.trim().isEmpty ||
        _licenseExpiryDate == null ||
        _vehicleModel.text.trim().isEmpty ||
        _plate.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete license and vehicle fields.'), backgroundColor: Colors.red),
      );
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_nationalIdPhoto == null || _selfiePhoto == null) {
      final missing = <String>[];
      if (_nationalIdPhoto == null) missing.add('National ID photo');
      if (_selfiePhoto == null) missing.add('Selfie verification photo');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload required photo(s): ${missing.join(', ')}.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validateStep2()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms and Conditions'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final result = await auth.registerRider(
      fullName: _fullName.text.trim(),
      phoneNumber: _phone.text.trim(),
      emailAddress: _email.text.trim(),
      dateOfBirth: _formatYmd(_dateOfBirth!),
      gender: _gender,
      nationalId: _nationalId.text.trim(),
      password: _password.text,
      passwordConfirmation: _passwordConfirm.text,
      drivingLicenseNumber: _licenseNo.text.trim(),
      licenseExpiryDate: _formatYmd(_licenseExpiryDate!),
      vehicleType: _vehicleType,
      vehicleModel: _vehicleModel.text.trim(),
      vehiclePlateNumber: _plate.text.trim(),
      nationalIdPhotoFile: _nationalIdPhoto,
      selfiePhotoFile: _selfiePhoto,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Registered. Await approval.'),
          backgroundColor: const Color(0xFF014F5B),
        ),
      );
      widget.onRegistered();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Signup failed'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _dateTile({
    required String label,
    required String hint,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final text = value == null ? hint : _formatYmd(value);
    final style = TextStyle(
      fontSize: 15,
      color: value == null ? const Color(0xFF8E8E8E) : const Color(0xFF1A1A1A),
    );
    return AuthLabeledField(
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: AuthFormStyles.outlineDecoration(hint: hint).copyWith(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: Row(
              children: [
                Expanded(child: Text(text, style: style)),
                const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF014F5B)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoSection({
    required String title,
    required String subtitle,
    required XFile? file,
    required VoidCallback onPick,
    required VoidCallback onClear,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            if (required) ...[
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E8E))),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 16 / 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: file == null
                ? Material(
                    color: const Color(0xFFF0F0F0),
                    child: InkWell(
                      onTap: onPick,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_photo_alternate_outlined, size: 40, color: Color(0xFF8E8E8E)),
                            const SizedBox(height: 8),
                            Text(
                              required ? 'Tap to add (required)' : 'Tap to add',
                              style: const TextStyle(color: Color(0xFF8E8E8E)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      FutureBuilder<Uint8List>(
                        future: file.readAsBytes(),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                          }
                          return Image.memory(snap.data!, fit: BoxFit.cover);
                        },
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          children: [
                            Material(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                              child: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                                onPressed: onPick,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Material(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                onPressed: onClear,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenShell(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      sheetChild: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
            child: Text('Rider sign up', style: AuthFormStyles.sheetTitleStyle()),
          ),
          Expanded(
            child: Stepper(
              currentStep: _step,
              onStepContinue: () {
                if (_step == 0) {
                  if (!_validateStep0()) return;
                  setState(() => _step = 1);
                } else if (_step == 1) {
                  if (!_validateStep1()) return;
                  setState(() => _step = 2);
                } else {
                  if (!_validateStep2()) return;
                  _submit();
                }
              },
              onStepCancel: () {
                if (_step > 0) {
                  setState(() => _step -= 1);
                } else {
                  Navigator.of(context).maybePop();
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(onPressed: details.onStepCancel, child: Text(_step == 0 ? 'Back' : 'Previous')),
                      ),
                      const SizedBox(height: 8),
                      AuthPrimaryButton(
                        label: _step < 2 ? 'Continue' : 'Submit application',
                        loading: _loading,
                        onPressed: details.onStepContinue,
                      ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Personal'),
                  isActive: _step >= 0,
                  state: _step > 0 ? StepState.complete : StepState.indexed,
                  content: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        AuthLabeledField(
                          label: 'Full name',
                          child: TextField(controller: _fullName, decoration: AuthFormStyles.outlineDecoration(hint: 'Jane Doe')),
                        ),
                        AuthLabeledField(
                          label: 'Phone',
                          child: TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: AuthFormStyles.outlineDecoration(hint: '+2547…'),
                          ),
                        ),
                        AuthLabeledField(
                          label: 'Email',
                          child: TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: AuthFormStyles.outlineDecoration(hint: 'you@example.com'),
                          ),
                        ),
                        _dateTile(
                          label: 'Date of birth',
                          hint: 'Tap to choose date',
                          value: _dateOfBirth,
                          onTap: _pickDateOfBirth,
                        ),
                        AuthLabeledField(
                          label: 'Gender',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                ['male', 'female', 'other'].map((g) {
                                  final label = g[0].toUpperCase() + g.substring(1);
                                  return ChoiceChip(
                                    label: Text(label),
                                    selected: _gender == g,
                                    onSelected: (_) => setState(() => _gender = g),
                                  );
                                }).toList(),
                          ),
                        ),
                        AuthLabeledField(
                          label: 'National ID',
                          child: TextField(controller: _nationalId, decoration: AuthFormStyles.outlineDecoration(hint: 'ID number')),
                        ),
                        AuthLabeledField(
                          label: 'Password',
                          child: TextField(
                            controller: _password,
                            obscureText: true,
                            decoration: AuthFormStyles.outlineDecoration(hint: 'Min 8 characters'),
                          ),
                        ),
                        AuthLabeledField(
                          label: 'Confirm password',
                          child: TextField(
                            controller: _passwordConfirm,
                            obscureText: true,
                            decoration: AuthFormStyles.outlineDecoration(hint: 'Repeat password'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Step(
                  title: const Text('License & vehicle'),
                  isActive: _step >= 1,
                  state: _step > 1 ? StepState.complete : StepState.indexed,
                  content: Column(
                    children: [
                      AuthLabeledField(
                        label: 'Driving license number',
                        child: TextField(controller: _licenseNo, decoration: AuthFormStyles.outlineDecoration(hint: 'License #')),
                      ),
                      _dateTile(
                        label: 'License expiry',
                        hint: 'Tap to choose date',
                        value: _licenseExpiryDate,
                        onTap: _pickLicenseExpiry,
                      ),
                      AuthLabeledField(
                        label: 'Vehicle type',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              [
                                ('bike', 'Bike'),
                                ('motorcycle', 'Motorcycle'),
                                ('car', 'Car'),
                                ('van', 'Van'),
                              ].map((e) {
                                return ChoiceChip(
                                  label: Text(e.$2),
                                  selected: _vehicleType == e.$1,
                                  onSelected: (_) => setState(() => _vehicleType = e.$1),
                                );
                              }).toList(),
                        ),
                      ),
                      AuthLabeledField(
                        label: 'Vehicle model',
                        child: TextField(controller: _vehicleModel, decoration: AuthFormStyles.outlineDecoration(hint: 'e.g. Honda CB')),
                      ),
                      AuthLabeledField(
                        label: 'Plate number',
                        child: TextField(
                          controller: _plate,
                          textCapitalization: TextCapitalization.characters,
                          decoration: AuthFormStyles.outlineDecoration(hint: 'KAA 123A'),
                        ),
                      ),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Photos'),
                  isActive: _step >= 2,
                  state: StepState.indexed,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload a clear photo of your national ID and a selfie for verification. Both photos are required. Images are sent securely with your application.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF8E8E8E)),
                      ),
                      const SizedBox(height: 20),
                      _photoSection(
                        title: 'National ID photo',
                        subtitle: 'Legible document photo (gallery or camera).',
                        file: _nationalIdPhoto,
                        onPick: () => _pickImage(nationalId: true),
                        onClear: () => setState(() => _nationalIdPhoto = null),
                        required: true,
                      ),
                      const SizedBox(height: 24),
                      _photoSection(
                        title: 'Selfie verification',
                        subtitle: 'Your face clearly visible (gallery or camera).',
                        file: _selfiePhoto,
                        onPick: () => _pickImage(nationalId: false),
                        onClear: () => setState(() => _selfiePhoto = null),
                        required: true,
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('I agree to the Terms and Conditions', style: TextStyle(fontSize: 13)),
                        value: _agreed,
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
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
