import 'package:flutter/material.dart';

/// Tappable wrapper that participates in focus traversal and paints a
/// visible ring when focused, so controller users can see where they are.
/// Use it for custom controller-focusable actions.
class FocusableTap extends StatefulWidget {
  const FocusableTap({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius,
    this.autofocus = false,
  });

  final VoidCallback? onTap;
  final Widget child;
  final BorderRadius? borderRadius;
  final bool autofocus;

  @override
  State<FocusableTap> createState() => _FocusableTapState();
}

class _FocusableTapState extends State<FocusableTap> {
  static const _ink = Color(0xFF1C1C1E);

  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(20);
    return InkWell(
      onTap: widget.onTap,
      autofocus: widget.autofocus,
      borderRadius: radius,
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: _focused
              ? Border.all(color: _ink, width: 3.5)
              : Border.all(color: Colors.transparent, width: 3.5),
        ),
        child: widget.child,
      ),
    );
  }
}
