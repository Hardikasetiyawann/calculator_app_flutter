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
  String _tempResult = '';
  String _currentOperand = ''; // Track the current number being entered

  bool _isScientific = false;
  bool _isDegree = true;

  void _onTap(String value) {
    setState(() {
      if (value == 'AC') {
        _expression = '';
        _display = '0';
        _tempResult = '';
        _currentOperand = '';
      } else if (value == 'Deg') {
        _isDegree = !_isDegree;
      } else if (value == '=') {
        if (_expression.isEmpty) return;
        
        final result = CalculatorEngine.evaluate(_expression, isDegree: _isDegree);
        _display = _formatNumber(result);
        _expression = result; 
        _currentOperand = result;
        _tempResult = ''; // Clear temporary result on equals
      } else if (value == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
          _display = _expression.isEmpty ? '0' : _expression;
        }
      } else if (['sin', 'cos', 'tan', 'log', 'ln', 'sqrt'].contains(value)) {
        _expression += '$value(';
      } else if (value == 'π') {
        _expression += 'pi';
      } else if (value == 'e') {
        _expression += 'e';
      } else if (['+', '-', '×', '÷', '%', '^', '(', ')', '!'].contains(value)) {
        _expression += value;
      } else {
        _expression += value;
      }
      
      // Update display and calculate temporary result
      if (value != '=') {
        _display = _expression.isEmpty ? '0' : _expression;
        
        // Calculate temporary result if expression is not just a single number or empty
        if (_expression.isNotEmpty && 
            _expression != 'Error' && 
            RegExp(r'[+\-×÷%^^!()]').hasMatch(_expression)) {
          final temp = CalculatorEngine.evaluate(_expression, isDegree: _isDegree);
          if (temp != 'Error') {
            _tempResult = _formatNumber(temp);
          } else {
             _tempResult = '';
          }
        } else {
          _tempResult = '';
        }
      }
    });
  }

  String _formatNumber(String s) {
    if (s.isEmpty) return '0';
    if (s == 'Error') return s;
    
    try {
      final double val = double.parse(s.replaceAll(',', ''));
      // Formatter for large numbers
      final pattern = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      
      String intPart = val.toInt().toString();
      String formatted = intPart.replaceAllMapped(pattern, (m) => '${m[1]},');
      
      if (s.contains('.')) {
        String decPart = s.split('.')[1];
        return '$formatted.$decPart';
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return OrientationBuilder(
              builder: (context, orientation) {
                final isLandscape = orientation == Orientation.landscape;
                
                if (isLandscape) {
                  return _buildLandscapeLayout(theme, constraints);
                } else {
                  return _buildPortraitLayout(theme, constraints);
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(ThemeData theme, BoxConstraints constraints) {
    return Column(
      children: [
        // Expression and Result Display
        Expanded(
          flex: 3,
          child: _buildDisplayArea(theme),
        ),

        // Scientific Toggle Row
        _buildControlsRow(theme),

        // Keypad area
        Expanded(
          flex: 7,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                if (_isScientific) ...[
                  Expanded(child: _buildScientificRows()),
                  const SizedBox(height: 8),
                ],
                Expanded(
                  flex: _isScientific ? 2 : 1,
                  child: _buildStandardRows(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(ThemeData theme, BoxConstraints constraints) {
    return Row(
      children: [
        // Left side: Display
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Expanded(child: _buildDisplayArea(theme)),
              _buildControlsRow(theme),
            ],
          ),
        ),
        // Vertical Divider
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: theme.dividerColor.withOpacity(0.1),
        ),
        // Right side: Keypad
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_isScientific) ...[
                  Expanded(child: _buildScientificRows()),
                  const SizedBox(height: 8),
                ],
                Expanded(
                  flex: _isScientific ? 2 : 1,
                  child: _buildStandardRows(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayArea(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 8, 16),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: _buildThemeToggle(),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(
                    _tempResult,
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontSize: 20,
                      color: theme.textTheme.displayMedium?.color?.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(
                    _display,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 48,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -1,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlsRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isScientific ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: theme.iconTheme.color?.withOpacity(0.4),
              size: 24,
            ),
            onPressed: () => setState(() => _isScientific = !_isScientific),
          ),
          const Spacer(),
          // Theme toggle moved to display area
        ],
      ),
    );
  }

  Widget _buildScientificRows() {
    return Column(
      children: [
        Expanded(
          child: _buildRow([
            _buildBtn('sqrt', isOperator: true),
            _buildBtn('π', isOperator: true),
            _buildBtn('^', isOperator: true),
            _buildBtn('!', isOperator: true),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildRow([
            _buildBtn(_isDegree ? 'Deg' : 'Rad', isOperator: true),
            _buildBtn('sin', isOperator: true),
            _buildBtn('cos', isOperator: true),
            _buildBtn('tan', isOperator: true),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildRow([
            _buildBtn('Inv', isOperator: true),
            _buildBtn('e', isOperator: true),
            _buildBtn('ln', isOperator: true),
            _buildBtn('log', isOperator: true),
          ]),
        ),
      ],
    );
  }

  Widget _buildStandardRows() {
    return Column(
      children: [
        Expanded(
          child: _buildRow([
            _buildBtn('AC', isAction: true),
            _buildBtn('(', isOperator: true),
            _buildBtn(')', isOperator: true),
            _buildBtn('÷', isOperator: true),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildRow([
            _buildBtn('7'),
            _buildBtn('8'),
            _buildBtn('9'),
            _buildBtn('×', isOperator: true),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildRow([
            _buildBtn('4'),
            _buildBtn('5'),
            _buildBtn('6'),
            _buildBtn('-', isOperator: true),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildRow([
            _buildBtn('1'),
            _buildBtn('2'),
            _buildBtn('3'),
            _buildBtn('+', isOperator: true),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildRow([
            _buildBtn('0'),
            _buildBtn('.'),
            _buildBtn('%', isOperator: true),
            _buildBtn('⌫', isAction: true), // Backspace integrated here
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildRow([
             _buildBtn('=',
                isAccent: true,
                onLongPress: _onEqualLongPress,
                onLongPressEnd: _onEqualLongPressEnd),
          ]),
        ),
      ],
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Row(
      children: children
          .expand((w) => [
                w is Spacer 
                  ? w 
                  : Expanded(
                      child: w,
                    ),
                const SizedBox(width: 8)
              ])
          .toList()
        ..removeLast(),
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

    return IconButton(
      onPressed: _toggleTheme,
      icon: Icon(
        isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
        color: theme.iconTheme.color?.withOpacity(0.4),
      ),
    );
  }
}
