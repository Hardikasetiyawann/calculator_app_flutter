import 'package:flutter/material.dart';
import '../main.dart'; // To access themeNotifier
import 'calculator_engine.dart';
import 'secret_trigger.dart';
import '../ui/calc_button.dart';
import '../vault/auth_guard.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _expression = '';
  String _display = '0';
  String _currentOperand = ''; // Track the current number being entered

  void _onTap(String value) {
    setState(() {
      if (value == 'AC') {
        _expression = '';
        _display = '0';
        _currentOperand = '';
      } else if (value == '=') {
        // Evaluate
        // Handle case where expression ends with operator
        if (_expression.isNotEmpty && ['+', '-', '×', '÷'].contains(_expression[_expression.length - 1])) {
           return; 
        }
        
        final result = CalculatorEngine.evaluate(_expression.replaceAll(',', ''));
        _display = _formatNumber(result);
        _expression = result; // Reset expression to result
        _currentOperand = result;
      } else if (['+', '-', '×', '÷', '%'].contains(value)) {
        // Operator
        if (_expression.isEmpty && _display != '0') {
           _expression = _display.replaceAll(',', '');
        }
        
        // Prevent double operators
        if (_expression.isNotEmpty && ['+', '-', '×', '÷', '%'].contains(_expression[_expression.length - 1])) {
           _expression = _expression.substring(0, _expression.length - 1) + value;
        } else {
           _expression += value;
        }
        
        _currentOperand = ''; // Reset current operand on operator
      } else {
        // Digit or Dot
        if (value == '.' && _currentOperand.contains('.')) return;
        
        if (_currentOperand == '0' && value != '.') {
           _currentOperand = value;
        } else {
           _currentOperand += value;
        }
        
        // Update display
         _display = _formatNumber(_currentOperand);
         
         // Update expression - this is tricky because we append. 
         // If we just append to expression, we need to sync it with current operand.
         // Simpler approach: Rebuild expression from history? 
         // Or: Just keep expression as the source of truth for the PREVIOUS parts, 
         // and append current operand to it for the view?
         // Actually, let's just append digits to expression.
         // If we just typed a digit, we might need to buffer it.
         
         // Fix: If _expression ends with a digit, we are appending to a number.
         // Ideally, we shouldn't maintain two states (_expression and _currentOperand) that conflict.
         // Let's treat _expression as the master "tape".
         
         // However, formatting requires us to know the "current block" of numbers.
         // So, keeping _currentOperand is useful for display formatting.
         
         // When user types '1', '0', '0', '0'
         // Tap '1': exp='1', cur='1', disp='1'
         // Tap '0': exp='10', cur='10', disp='10'
         // Tap '0': exp='100', cur='100', disp='100'
         // Tap '0': exp='1000', cur='1000', disp='1,000'
         
         // So yes, just append to expression.
         _expression += value;
      }
    });
  }

  String _formatNumber(String s) {
    if (s.isEmpty) return '0';
    if (s == 'Error') return s;
    
    try {
      final parts = s.split('.');
      String integerPart = parts[0].replaceAll(',', '');
      
      final pattern = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      String formatted = integerPart.replaceAllMapped(pattern, (m) => '${m[1]},');
      
      if (parts.length > 1) {
        return '$formatted.${parts[1]}';
      }
      return formatted;
    } catch (_) {
      return s;
    }
  }

  void _onEqualLongPress() {
    SecretTrigger.start(() async {
      final ok = await AuthGuard.verify(context);
      if (ok) {
        if (mounted) AuthGuard.openStorage(context);
      }
    });
  }

  void _onEqualLongPressEnd() {
    SecretTrigger.stop();
  }

  void _toggleTheme() {
    themeNotifier.value = themeNotifier.value == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Expression and Result Display
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _expression,
                      style: theme.textTheme.displayMedium,
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _display,
                      style: theme.textTheme.displayLarge,
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ),

            // Keypad area
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Grid (3 columns)
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildRow([
                            _buildThemeToggle(),
                            _buildBtn('%', isOperator: true),
                            _buildBtn('÷', isOperator: true),
                          ]),
                          const SizedBox(height: 16),
                          _buildRow([
                            _buildBtn('7'),
                            _buildBtn('8'),
                            _buildBtn('9'),
                          ]),
                          const SizedBox(height: 16),
                          _buildRow([
                            _buildBtn('4'),
                            _buildBtn('5'),
                            _buildBtn('6'),
                          ]),
                          const SizedBox(height: 16),
                          _buildRow([
                            _buildBtn('1'),
                            _buildBtn('2'),
                            _buildBtn('3'),
                          ]),
                          const SizedBox(height: 16),
                          _buildRow([
                            _buildBtn('AC', isAction: true),
                            _buildBtn('0'),
                            _buildBtn('.'),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Operator Column (1 column)
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildBtn('×', isOperator: true)),
                          const SizedBox(height: 16),
                          Expanded(child: _buildBtn('-', isOperator: true)),
                          const SizedBox(height: 16),
                          Expanded(child: _buildBtn('+', isOperator: true)),
                          const SizedBox(height: 16),
                          Expanded(
                            flex: 2,
                            child: _buildBtn('=',
                                isAccent: true,
                                isDoubleHeight: true,
                                onLongPress: _onEqualLongPress,
                                onLongPressEnd: _onEqualLongPressEnd),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children
            .expand((w) => [Expanded(child: w), const SizedBox(width: 16)])
            .toList()
          ..removeLast(),
      ),
    );
  }

  Widget _buildBtn(String text,
      {bool isAccent = false,
      bool isOperator = false,
      bool isAction = false,
      bool isDoubleHeight = false,
      VoidCallback? onLongPress,
      VoidCallback? onLongPressEnd}) {
    return CalcButton(
      text: text,
      onTap: () => _onTap(text),
      isAccent: isAccent,
      isOperator: isOperator,
      isAction: isAction,
      isDoubleHeight: isDoubleHeight,
      onLongPress: onLongPress,
      onLongPressEnd: onLongPressEnd,
    );
  }

  Widget _buildThemeToggle() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CalcButton(
      text: '',
      onTap: _toggleTheme,
      isOperator: true,
      icon: Icon(
        isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
        color: isDark ? Colors.white70 : Colors.black.withOpacity(0.8),
      ),
    );
  }
}
