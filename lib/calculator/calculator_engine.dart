import 'package:math_expressions/math_expressions.dart';

class CalculatorEngine {
  static String evaluate(String expression, {bool isDegree = false}) {
    if (expression.isEmpty || expression == '0') return '0';
    try {
      String cleanExp = expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', 'pi')
          .replaceAll(',', ''); 

      // Basic percentage handling: replace "num%" with "(num/100)"
      final percentRegex = RegExp(r'(\d+\.?\d*)%');
      cleanExp = cleanExp.replaceAllMapped(percentRegex, (m) {
        final val = double.parse(m.group(1)!);
        return '(${val / 100})';
      });

      // Special handling for factorial ! (math_expressions doesn't support it natively in some versions)
      // For simplicity, we'll keep it but it might error if not implemented in the parser version.

      // If in degree mode, convert trig inputs
      if (isDegree) {
        final trigRegex = RegExp(r'(sin|cos|tan)\(([^)]+)\)');
        cleanExp = cleanExp.replaceAllMapped(trigRegex, (m) {
          final func = m.group(1);
          final val = m.group(2);
          return '$func(($val)*pi/180)';
        });
      }

      Parser p = Parser();
      Expression exp = p.parse(cleanExp);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      
      if (eval.isInfinite || eval.isNaN) return 'Error';
      
      // Round to 10 decimal places to avoid floating point noise
      String res = eval.toStringAsFixed(10);
      if (res.contains('.')) {
        res = res.replaceAll(RegExp(r'0*$'), ''); // Remove trailing zeros
        res = res.replaceAll(RegExp(r'\.$'), ''); // Remove trailing dot
      }
      
      return res;
    } catch (_) {
      return 'Error';
    }
  }
}
