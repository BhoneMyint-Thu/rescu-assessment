import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../service/clock_service.dart';
import '../../../util/format_countdown.dart';

/// Only this label rebuilds on each clock tick.
class ReservationCountdown extends StatelessWidget {
  final DateTime expiresAt;

  const ReservationCountdown({super.key, required this.expiresAt});

  @override
  Widget build(BuildContext context) {
    final clock = Get.find<ClockService>();
    return Obx(() {
      final remaining = expiresAt.difference(clock.time.value);
      return Text(
        remaining <= Duration.zero
            ? 'Reservation expired'
            : 'Reserved for ${formatCountdown(remaining)}',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      );
    });
  }
}
