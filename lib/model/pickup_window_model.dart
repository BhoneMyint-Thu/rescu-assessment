import 'package:intl/intl.dart';

/// A store's pickup window. The API sends instants as ISO-8601 UTC strings.
class PickupWindowModel {
  final DateTime start;
  final DateTime end;

  const PickupWindowModel({required this.start, required this.end});

  factory PickupWindowModel.fromJson(Map<String, dynamic> json) {
    return PickupWindowModel(
      start: DateTime.parse(json['start'] as String? ?? ''),
      end: DateTime.parse(json['end'] as String? ?? ''),
    );
  }

  // Bangkok uses UTC+7. Shift calendar fields only for display/date checks;
  // keep the original instants for countdowns and availability comparisons.
  DateTime _bangkokWallClock(DateTime instant) =>
      instant.toUtc().add(const Duration(hours: 7));

  /// Human readable pickup times in Bangkok, e.g. "17:30 – 21:00".
  String get label {
    final format = DateFormat('HH:mm');
    return '${format.format(_bangkokWallClock(start))} – '
        '${format.format(_bangkokWallClock(end))}';
  }

  /// Whether pickup starts today in Bangkok.
  bool get isToday => isTodayAt(DateTime.now());

  /// Whether pickup starts on the Bangkok calendar date containing [now].
  bool isTodayAt(DateTime now) {
    final pickupDate = _bangkokWallClock(start);
    final today = _bangkokWallClock(now);
    return pickupDate.year == today.year &&
        pickupDate.month == today.month &&
        pickupDate.day == today.day;
  }

  /// Whether the store is currently accepting pickups.
  bool get isOpenNow {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  Duration get untilStart => start.difference(DateTime.now());
}
