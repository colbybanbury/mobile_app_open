String formatDuration(double seconds) {
  var intSeconds = seconds.ceil();
  var minutes = intSeconds ~/ Duration.secondsPerMinute;
  intSeconds -= minutes * Duration.secondsPerMinute;
  final hours = minutes ~/ Duration.minutesPerHour;
  minutes -= hours * Duration.minutesPerHour;

  final tokens = <String>[];
  if (hours != 0) {
    tokens.add(hours.toString().padLeft(2, '0'));
  }
  tokens.add(minutes.toString().padLeft(2, '0'));
  tokens.add(intSeconds.toString().padLeft(2, '0'));

  return tokens.join(':');
}
