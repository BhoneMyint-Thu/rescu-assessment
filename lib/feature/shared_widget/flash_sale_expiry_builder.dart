import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../service/clock_service.dart';

/// Rebuilds its content only when expiry changes, not on every clock tick.
class FlashSaleExpiryBuilder extends StatefulWidget {
  final DateTime? endsAt;
  final Widget Function(BuildContext context, bool expired) builder;

  const FlashSaleExpiryBuilder({
    super.key,
    required this.endsAt,
    required this.builder,
  });

  @override
  State<FlashSaleExpiryBuilder> createState() => _FlashSaleExpiryBuilderState();
}

class _FlashSaleExpiryBuilderState extends State<FlashSaleExpiryBuilder> {
  late bool _expired;
  Worker? _worker;

  bool _isExpired(DateTime now) =>
      widget.endsAt != null && !now.isBefore(widget.endsAt!);

  @override
  void initState() {
    super.initState();
    _watchExpiry();
  }

  void _watchExpiry() {
    _worker?.dispose();
    _worker = null;
    final clock = Get.find<ClockService>();
    _expired = _isExpired(clock.now);
    if (widget.endsAt == null) return;

    _worker = ever(clock.time, (now) {
      final expired = _isExpired(now);
      if (expired != _expired) setState(() => _expired = expired);
    });
  }

  @override
  void didUpdateWidget(covariant FlashSaleExpiryBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endsAt != widget.endsAt) _watchExpiry();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _expired);

  @override
  void dispose() {
    _worker?.dispose();
    super.dispose();
  }
}
