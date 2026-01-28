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
      bgColor = isDark ? const Color(0xFF2D2D33) : const Color(0xFFEDEEF0);
      textColor = isDark ? Colors.white : Colors.black;
    } else if (isAction) {
      bgColor = isDark ? const Color(0xFF2D2D33) : const Color(0xFFEDEEF0);
      textColor = const Color(0xFFFF4B4B); // Red for AC
    } else {
      bgColor = isDark ? const Color(0xFF25252B) : const Color(0xFFFAFAFA);
      textColor = isDark ? Colors.white : Colors.black;
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      onLongPressEnd: (_) => onLongPressEnd?.call(),
      child: Container(
        // height removed to allow flexibility within Expanded
        decoration: BoxDecoration(
          color: bgColor,
          gradient: isAccent
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.accentGradientStart, AppTheme.accentGradientEnd],
                )
              : null,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            if (isAccent)
              BoxShadow(
                color: AppTheme.accentGradientStart.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            if (!isAccent && !isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Center(
          child: icon ?? Text(
            text,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
