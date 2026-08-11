import 'package:flutter/material.dart';

/// Brand colors shared by auth screens.
class AuthColors {
  static const brand = Color(0xFF014F5B);
  static const brandLight = Color(0xFF02788D);
  static const brandSoft = Color(0xFFE8F4F6);
  static const ink = Color(0xFF122126);
  static const muted = Color(0xFF6B7A80);
  static const line = Color(0xFFD9E4E7);
}

/// Full-screen brand gradient, header, and bottom form sheet.
class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    super.key,
    required this.sheetChild,
    this.leading,
    this.tagline = 'Fast delivery, right to your door',
  });

  final Widget sheetChild;
  final Widget? leading;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final sheetH = (size.height * 0.58).clamp(380.0, size.height * 0.68);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AuthColors.brand,
                  AuthColors.brandLight,
                  Color(0xFF0396AD),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -40,
            child: _GlowOrb(size: 220, opacity: 0.14),
          ),
          Positioned(
            top: size.height * 0.18,
            left: -70,
            child: _GlowOrb(size: 180, opacity: 0.10),
          ),
          Positioned(
            top: topInset + 8,
            left: 8,
            right: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null) leading!,
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: leading != null ? 4 : 16,
                      top: 8,
                    ),
                    child: _BrandHeader(tagline: tagline),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: topInset + (leading != null ? 88 : 96),
            child: const _HeroCue(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: sheetH,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33014F5B),
                    blurRadius: 28,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AuthColors.line,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Expanded(child: sheetChild),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.tagline});

  final String tagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gas express',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.8,
            height: 1.1,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tagline,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.86),
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class _HeroCue extends StatelessWidget {
  const _HeroCue();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: const Icon(
            Icons.local_shipping_outlined,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Order LPG cylinders and track delivery from your phone.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthFormStyles {
  static TextStyle sheetTitleStyle() => const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AuthColors.ink,
        height: 1.15,
        letterSpacing: -0.4,
      );

  static TextStyle subtitleStyle() => const TextStyle(
        fontSize: 14,
        color: AuthColors.muted,
        height: 1.4,
      );

  static TextStyle labelStyle() => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AuthColors.ink,
        height: 1.2,
      );

  static TextStyle footerGreyStyle() => const TextStyle(
        fontSize: 14,
        color: AuthColors.muted,
      );

  static TextStyle linkStyle() => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AuthColors.brand,
      );

  static InputDecoration outlineDecoration({
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AuthColors.line, width: 1),
    );
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 15,
        color: Color(0xFFA8B4B8),
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AuthColors.brandSoft.withValues(alpha: 0.35),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AuthColors.brand, width: 1.6),
      ),
      errorBorder: border,
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
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
    this.paddingBottom = 16,
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
          backgroundColor: AuthColors.brand,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          disabledBackgroundColor: AuthColors.brand.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: loading
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
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}

class AuthStepChip extends StatelessWidget {
  const AuthStepChip({
    super.key,
    required this.label,
    required this.active,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: active ? AuthColors.brandSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: active ? AuthColors.brand.withValues(alpha: 0.35) : AuthColors.line,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? AuthColors.brand : AuthColors.muted,
        ),
      ),
    );
  }
}
