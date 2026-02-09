import 'package:cloud_firestore/cloud_firestore.dart';

/// Runtime state for the blocker: current window and minutes used.
/// Stored at users/{uid}/usageState/current (or similar) for the native
/// AccessibilityService / DeviceActivity to read and update.
class UsageState {
  final String userId;
  final DateTime currentWindowStart;
  final int minutesUsedInWindow;

  const UsageState({
    required this.userId,
    required this.currentWindowStart,
    this.minutesUsedInWindow = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'currentWindowStart': currentWindowStart.millisecondsSinceEpoch,
      'minutesUsedInWindow': minutesUsedInWindow,
    };
  }

  static DateTime? _dateFromMap(dynamic v) {
    if (v == null) return null;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is Timestamp) return v.toDate();
    return null;
  }

  factory UsageState.fromMap(String userId, Map<String, dynamic> map) {
    return UsageState(
      userId: userId,
      currentWindowStart: _dateFromMap(map['currentWindowStart']) ?? DateTime.now(),
      minutesUsedInWindow: (map['minutesUsedInWindow'] as num?)?.toInt() ?? 0,
    );
  }

  UsageState copyWith({
    DateTime? currentWindowStart,
    int? minutesUsedInWindow,
  }) {
    return UsageState(
      userId: userId,
      currentWindowStart: currentWindowStart ?? this.currentWindowStart,
      minutesUsedInWindow: minutesUsedInWindow ?? this.minutesUsedInWindow,
    );
  }
}

/// Config the native blocker reads: restricted app packages and limit (e.g. 30 min in 3 hr).
/// Flutter app writes this from LimitRules so the Android/iOS service doesn't need to know rules.
class BlockerConfig {
  final String userId;
  final List<String> restrictedApps;
  final int minutesAllowed;
  final int windowMinutes;
  final String displayName; // for "Alex" in the snitch message

  const BlockerConfig({
    required this.userId,
    this.restrictedApps = const [],
    this.minutesAllowed = 30,
    this.windowMinutes = 180,
    this.displayName = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'restrictedApps': restrictedApps,
      'minutesAllowed': minutesAllowed,
      'windowMinutes': windowMinutes,
      'displayName': displayName,
    };
  }

  factory BlockerConfig.fromMap(String userId, Map<String, dynamic> map) {
    final list = map['restrictedApps'];
    return BlockerConfig(
      userId: userId,
      restrictedApps: list is List ? list.map((e) => e.toString()).toList() : [],
      minutesAllowed: (map['minutesAllowed'] as num?)?.toInt() ?? 30,
      windowMinutes: (map['windowMinutes'] as num?)?.toInt() ?? 180,
      displayName: map['displayName'] as String? ?? '',
    );
  }
}
