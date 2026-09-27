import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../service/analytics_service.dart';

/// Reports a card only after it stays at least half visible for one second.
class DealImpressionTracker extends StatefulWidget {
  final int dealId;
  final String source;
  final int position;
  final Widget child;

  const DealImpressionTracker({
    super.key,
    required this.dealId,
    required this.source,
    required this.position,
    required this.child,
  });

  @override
  State<DealImpressionTracker> createState() => _DealImpressionTrackerState();
}

class _DealImpressionTrackerState extends State<DealImpressionTracker>
    with WidgetsBindingObserver {
  late final AnalyticsService _analytics;
  // Unique per card instance: the same deal can appear in several lists.
  Key _visibilityKey = UniqueKey();
  ModalRoute<dynamic>? _route;
  Timer? _timer;
  bool _halfVisible = false;
  bool _active = true;

  bool get _canTrack =>
      mounted &&
      _active &&
      (_route?.isCurrent ?? true) &&
      _halfVisible &&
      !_analytics.hasImpression(widget.dealId);

  @override
  void initState() {
    super.initState();
    _analytics = Get.find<AnalyticsService>();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _active = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ModalRoute notifies dependents when another route covers this page.
    _route = ModalRoute.of(context);
    _updateTimer();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;
    _halfVisible = info.visibleFraction >= 0.5;
    _updateTimer();
  }

  void _updateTimer() {
    if (!_canTrack) {
      _cancelTimer();
      return;
    }
    // Changes that remain above 50% keep the original timer running.
    _timer ??= Timer(const Duration(seconds: 1), () {
      _timer = null;
      if (!_canTrack) return;
      _analytics.recordImpression(
        dealId: widget.dealId,
        source: widget.source,
        position: widget.position,
      );
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _updateTimer();
  }

  @override
  void didUpdateWidget(covariant DealImpressionTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dealId != widget.dealId ||
        oldWidget.source != widget.source) {
      _cancelTimer();
      _halfVisible = false;
      VisibilityDetectorController.instance.forget(_visibilityKey);
      _visibilityKey = UniqueKey();
    }
  }

  @override
  Widget build(BuildContext context) => VisibilityDetector(
        key: _visibilityKey,
        onVisibilityChanged: _onVisibilityChanged,
        child: widget.child,
      );

  @override
  void dispose() {
    _cancelTimer();
    WidgetsBinding.instance.removeObserver(this);
    VisibilityDetectorController.instance.forget(_visibilityKey);
    super.dispose();
  }
}
