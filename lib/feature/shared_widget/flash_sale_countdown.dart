import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../service/clock_service.dart';
import '../../util/format_countdown.dart';

class FlashSaleCountdown extends StatelessWidget {
  final DateTime endsAt;
  final TextStyle? style;

  const FlashSaleCountdown({super.key, required this.endsAt, this.style});

  @override
  Widget build(BuildContext context) {
    final clock = Get.find<ClockService>();
    return Obx(() => Text(
          formatCountdown(endsAt.difference(clock.time.value)),
          style: style,
        ));
  }
}
