import 'package:flutter/material.dart';

class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Floating dock-style bottom navigation with a sliding selection pill.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppBottomNavItem> items;

  static const Color brand = Color(0xFF014F5B);
  static const Color brandLight = Color(0xFF02788D);
  static const Color muted = Color(0xFF7A8B90);

  static const Duration _slideDuration = Duration(milliseconds: 320);
  static const Curve _slideCurve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        child: Container(
          height: 68,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: brand.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: brand.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final count = items.length;
              final slotWidth = constraints.maxWidth / count;
              final pillLeft = slotWidth * currentIndex;

              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: _slideDuration,
                    curve: _slideCurve,
                    left: pillLeft,
                    width: slotWidth,
                    top: 0,
                    bottom: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [brand, brandLight],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: brand.withValues(alpha: 0.28),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(count, (index) {
                      final selected = index == currentIndex;
                      final item = items[index];
                      return Expanded(
                        child: Semantics(
                          button: true,
                          selected: selected,
                          label: item.label,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onTap(index),
                              borderRadius: BorderRadius.circular(18),
                              splashColor: brand.withValues(alpha: 0.08),
                              highlightColor: brand.withValues(alpha: 0.04),
                              child: SizedBox(
                                height: double.infinity,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      child: Icon(
                                        selected ? item.activeIcon : item.icon,
                                        key: ValueKey('${item.label}_$selected'),
                                        size: 22,
                                        color: selected ? Colors.white : muted,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 220),
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: selected
                                            ? Colors.white
                                            : muted,
                                        height: 1.1,
                                      ),
                                      child: Text(
                                        item.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
