import 'dart:async';

class Debouncer {
  Debouncer({
    this.delay = const Duration(milliseconds: 300),
  });

  final Duration delay;
  Timer? _timer;

  void run(void Function() action) {
    cancel();

    _timer = Timer(delay, () {
      _timer = null;
      action();
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}