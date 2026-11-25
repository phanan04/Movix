import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget hỗ trợ Focus rõ ràng cho điều khiển Remote D-pad trên Android TV và bàn phím
/// Khi có Focus (hasFocus == true):
/// - Phóng to nhẹ AnimatedScale (scale: 1.06, thời gian 150ms)
/// - Viền sáng màu trắng 2px (#FFFFFF)
/// - Đổ bóng nhẹ để dễ nhận biết vị trí con trỏ trên TV
class TVFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final BorderRadius? borderRadius;
  final double scale;
  final Duration duration;
  final bool autoFocus;
  final ValueChanged<bool>? onFocusChange;
  final bool showBorder;

  const TVFocusable({
    super.key,
    required this.child,
    this.onPressed,
    this.borderRadius,
    this.scale = 1.06,
    this.duration = const Duration(milliseconds: 150),
    this.autoFocus = false,
    this.onFocusChange,
    this.showBorder = true,
  });

  @override
  State<TVFocusable> createState() => _TVFocusableState();
}

class _TVFocusableState extends State<TVFocusable> {
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);
    final double targetScale = _isPressed
        ? 0.96
        : (_isFocused ? widget.scale : 1.0);

    return FocusableActionDetector(
      autofocus: widget.autoFocus,
      onFocusChange: (focused) {
        if (mounted) {
          setState(() {
            _isFocused = focused;
          });
        }
        widget.onFocusChange?.call(focused);
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (intent) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: widget.onPressed != null
            ? (_) {
                if (mounted) setState(() => _isPressed = true);
              }
            : null,
        onTapUp: widget.onPressed != null
            ? (_) {
                if (mounted) setState(() => _isPressed = false);
              }
            : null,
        onTapCancel: widget.onPressed != null
            ? () {
                if (mounted) setState(() => _isPressed = false);
              }
            : null,
        child: AnimatedScale(
          scale: targetScale,
          duration: _isPressed ? const Duration(milliseconds: 100) : widget.duration,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: widget.duration,
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: (_isFocused && widget.showBorder)
                  ? Border.all(color: Colors.white, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
              boxShadow: (_isFocused && widget.showBorder)
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Hiệu ứng nhấn nhẹ (scale 0.96 khi giữ, trả về 1.0 khi thả) cho các thẻ không dùng TVFocusable
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) {
        if (mounted) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (mounted) setState(() => _isPressed = false);
      },
      onTapCancel: () {
        if (mounted) setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Hiệu ứng chuyển icon kèm pop scale nhẹ (0.75 -> 1.2 -> 1.0) cho nút Lưu / Yêu thích
class PopIconSwitch extends StatelessWidget {
  final Widget child;

  const PopIconSwitch({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) {
        final popScale = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.75, end: 1.2), weight: 55),
          TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 45),
        ]).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut));
        return ScaleTransition(
          scale: popScale,
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      child: child,
    );
  }
}
