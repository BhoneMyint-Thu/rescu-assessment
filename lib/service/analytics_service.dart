import 'dart:async';

import 'package:get/get.dart';

import '../util/log_service.dart';
import 'fake_api_service.dart';

class AnalyticsEvent {
  final String name;
  final Map<String, dynamic> properties;
  final DateTime at;

  AnalyticsEvent(this.name, this.properties) : at = DateTime.now();

  Map<String, dynamic> toJson() => {
        'name': name,
        'properties': properties,
        'at': at.toIso8601String(),
      };
}

/// Session analytics history, with deduplicated, batched deal impressions.
class AnalyticsService extends GetxService {
  final FakeApiService api;

  AnalyticsService({required this.api});

  final events = <AnalyticsEvent>[].obs;
  final Set<int> _impressedDealIds = <int>{};
  final _pending = <AnalyticsEvent>[];
  Timer? _flushTimer;
  bool _isSending = false;

  bool hasImpression(int dealId) => _impressedDealIds.contains(dealId);

  AnalyticsEvent logEvent(String name,
      [Map<String, dynamic> properties = const {}]) {
    final event = AnalyticsEvent(name, properties);
    events.add(event);
    LogService.log('analytics: $name $properties');
    return event;
  }

  void recordImpression({
    required int dealId,
    required String source,
    required int position,
  }) {
    if (isClosed || !_impressedDealIds.add(dealId)) return;

    _pending.add(logEvent('deal_impression', {
      'deal_id': dealId,
      'source': source,
      'position': position,
    }));
    _scheduleFlush();
    if (_pending.length >= 10) unawaited(_flush());
  }

  void _scheduleFlush() {
    // Later events do not postpone the first waiting event's deadline.
    _flushTimer ??= Timer(const Duration(seconds: 15), () {
      _flushTimer = null;
      unawaited(_flush());
    });
  }

  Future<void> _flush() async {
    if (isClosed || _isSending || _pending.isEmpty) return;
    _isSending = true;
    _flushTimer?.cancel();
    _flushTimer = null;

    final batch = _pending.toList();
    try {
      await api
          .sendAnalyticsBatch(batch.map((event) => event.toJson()).toList());
    } catch (error) {
      LogService.error(
          'analytics batch failed; keeping events for retry', error);
      if (!isClosed) _scheduleFlush();
      return;
    } finally {
      _isSending = false;
    }

    if (isClosed) return;
    // New arrivals stay queued; only remove the snapshot that was sent.
    _pending.removeRange(0, batch.length);
    if (_pending.isNotEmpty && (_pending.length >= 10 || _flushTimer == null)) {
      // A waiting batch may already be full or its timer may have elapsed.
      unawaited(_flush());
    }
  }

  @override
  void onClose() {
    _flushTimer?.cancel();
    super.onClose();
  }
}
