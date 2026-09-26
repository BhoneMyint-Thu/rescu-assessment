import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// One clock for countdowns and bag expiry throughout the app.
class ClockService extends GetxService with WidgetsBindingObserver {
  ClockService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  DateTime get now => _now().toUtc();
  late final time = now.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  void _start() {
    time.value = now;
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      time.value = now;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _start();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
