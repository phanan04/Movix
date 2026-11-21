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

  const TVFocusable({
    super.key,
    required this.child,
    this.onPressed,
    this.borderRadius,
    this.scale = 1.06,
    this.duration = const Duration(milliseconds: 150),
    this.autoFocus = false,
  });

  @override
  State<TVFocusable> createState() => _TVFocusableState();
}

class _TVFocusableState extends State<TVFocusable> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);

    return FocusableActionDetector(
      autofocus: widget.autoFocus,
      onFocusChange: (focused) {
        if (mounted) {
          setState(() {
            _isFocused = focused;
          });
        }
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
        child: AnimatedScale(
          scale: _isFocused ? widget.scale : 1.0,
          duration: widget.duration,
          curve: Curves.easeInOut,
          child: AnimatedContainer(
            duration: widget.duration,
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: _isFocused
                  ? Border.all(color: Colors.white, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
              boxShadow: _isFocused
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
