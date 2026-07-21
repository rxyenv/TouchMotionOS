import 'dart:io';

import 'package:flutter/material.dart';

/// In-memory state for the current sign-in session.
///
/// Set by the organisation login screen once the OTP is accepted; read by
/// later screens (e.g. the patient profile greeting). Resets on app restart.
class Session {
  static String? patientName;

  /// Current UI locale. The language screen writes it; [MaterialApp]
  /// listens and rebuilds, so the whole app switches language live.
  static final locale = ValueNotifier<Locale>(const Locale('en'));

  /// Whether the clock displays in 24-hour format. Persisted to disk.
  static final use24h = ValueNotifier<bool>(false);

  /// IANA timezone name currently set on the system, e.g. "Asia/Kolkata".
  static final timeZone = ValueNotifier<String>('');

  static final _formatFile = File(
    '${Platform.environment['HOME'] ?? '/root'}/.config/tomoro/clock-format',
  );

  /// Load persisted clock format and current system timezone. Call once at
  /// app startup or when the settings screen opens.
  static Future<void> loadTimeSettings() async {
    try {
      final raw = await _formatFile.readAsString();
      use24h.value = raw.trim() == '24';
    } on Exception {
      // file absent → default 12h
    }
    try {
      final result = await Process.run(
        'timedatectl',
        ['show', '--property=Timezone', '--value'],
      );
      final tz = (result.stdout as String).trim();
      if (tz.isNotEmpty) timeZone.value = tz;
    } on Exception {
      timeZone.value = DateTime.now().timeZoneName;
    }
  }

  /// Persist the clock format choice and update [use24h].
  static Future<void> setUse24h(bool value) async {
    use24h.value = value;
    try {
      await _formatFile.parent.create(recursive: true);
      await _formatFile.writeAsString(value ? '24' : '12');
    } on Exception {
      // non-fatal
    }
  }

  /// Set system timezone via timedatectl and update [timeZone].
  static Future<bool> setTimeZone(String tz) async {
    try {
      final result = await Process.run('timedatectl', ['set-timezone', tz]);
      if (result.exitCode == 0) {
        timeZone.value = tz;
        return true;
      }
    } on Exception {
      // fall through
    }
    return false;
  }

  /// First word of the patient's name, for casual greetings.
  static String get firstName {
    final name = patientName;
    if (name == null || name.isEmpty) return 'there';
    return name.split(' ').first;
  }
}
