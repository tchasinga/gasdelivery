import 'package:flutter/material.dart';

/// Full-screen brand gradient, header, and asymmetric white sheet.
class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    super.key,
    required this.sheetChild,
    this.leading,
  });

  final Widget sheetChild;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final sheetH = (h * 0.62).clamp(400.0, h * 0.72);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF014F5B),
                    Color(0xFF02788D),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) leading!,
                  Expanded(child: _BrandHeader()),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              // borderRadius: const BorderRadius.only(
              //   topLeft: Radius.circular(28),
              //   topRight: Radius.circular(88),
              // ),
              child: Material(
                color: Colors.white,
                child: SizedBox(
                  width: double.infinity,
                  height: sheetH,
                  child: SafeArea(
                    top: false,
                    child: sheetChild,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gas express',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Fast delivery, right to your door',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.78),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthFormStyles {
  static TextStyle sheetTitleStyle() => const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: Colors.black,
        height: 1.15,
      );

  static TextStyle labelStyle() => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Color(0xFF8E8E8E),
        height: 1.2,
      );

  static TextStyle footerGreyStyle() => const TextStyle(
        fontSize: 14,
        color: Color(0xFF8E8E8E),
      );

  static TextStyle linkStyle() => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2F6FED),
      );

  static InputDecoration outlineDecoration({String? hint}) {
    const borderColor = Color(0xFFE6E6E6);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: borderColor, width: 1),
    );
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 15,
        color: Color(0xFFC4C4C4),
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1A1A1A), width: 1.4),
      ),
      errorBorder: border,
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE53935)),
      ),
    );
  }
}

class AuthLabeledField extends StatelessWidget {
  const AuthLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.paddingBottom = 18,
  });

  final String label;
  final Widget child;
  final double paddingBottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: paddingBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AuthFormStyles.labelStyle()),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0D0D0D),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          disabledBackgroundColor: const Color(0xFF0D0D0D).withValues(alpha: 0.45),
          shape: const StadiumBorder(),
          elevation: 0,
          splashFactory: InkRipple.splashFactory,
        ),
        child:
            loading
                ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }
}
