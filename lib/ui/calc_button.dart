import 'package:flutter/material.dart';
import 'theme.dart';

class CalcButton extends StatelessWidget {
  final String text;
  final Widget? icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onLongPressEnd;
  final bool isAccent;
  final bool isOperator;
  final bool isAction;
  final bool isDoubleHeight;

  const CalcButton({
    super.key,
    required this.text,
    this.icon,
    required this.onTap,
    this.onLongPress,
    this.onLongPressEnd,
    this.isAccent = false,
    this.isOperator = false,
    this.isAction = false,
    this.isDoubleHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color? bgColor;
    Color? textColor;

    if (isAccent) {
      bgColor = null; // Will use gradient
      textColor = Colors.white;
    } else if (isOperator) {
      bgColor = isDark ? const Color(0xFF23232D) : const Color(0xFFE8E9F3);
      textColor = isDark ? Colors.white : Colors.black;
    } else if (isAction) {
      bgColor = isDark ? const Color(0xFF23232D) : const Color(0xFFFBEAEA);
      textColor = const Color(0xFFFF4B4B); // Red for AC
    } else {
      bgColor = isDark ? const Color(0xFF1C1C23) : Colors.white;
      textColor = isDark ? Colors.white : Colors.black;
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onLongPressEnd: (_) => onLongPressEnd?.call(),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          gradient: isAccent
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.accentGradientStart, AppTheme.accentGradientEnd],
                )
              : null,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            if (isAccent)
              BoxShadow(
                color: AppTheme.accentGradientStart.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            if (!isAccent)
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: icon ?? FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: text.length > 3 ? 18 : (text.length > 2 ? 22 : 28),
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
