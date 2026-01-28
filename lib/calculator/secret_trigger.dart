import 'dart:async';

class SecretTrigger {
  static Timer? _timer;
  static bool _triggered = false;

  static void start(void Function() onTrigger) {
    _triggered = false;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 15), () {
      _triggered = true;
      onTrigger();
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static bool wasTriggered() {
    return _triggered;
  }
}
