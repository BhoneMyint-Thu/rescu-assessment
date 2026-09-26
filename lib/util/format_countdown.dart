String formatCountdown(Duration remaining) {
  if (remaining <= Duration.zero) return 'Expired';

  // Show 00:01 while less than one second remains; show Expired at zero.
  final rounded = Duration(
    seconds: (remaining.inMicroseconds / Duration.microsecondsPerSecond).ceil(),
  );
  final hours = rounded.inHours;
  final minutes = rounded.inMinutes % 60;
  final seconds = rounded.inSeconds % 60;
  final parts = [
    if (hours > 0) hours,
    minutes,
    seconds,
  ];
  return parts.map((part) => part.toString().padLeft(2, '0')).join(':');
}
