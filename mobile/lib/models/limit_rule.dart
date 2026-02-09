/// Rule for app usage limit (e.g. 30 minutes in 3 hours).
class LimitRule {
  final String? id;
  final String appPackageOrCategory; // e.g. com.instagram.android or "Social"
  final String appDisplayName;       // e.g. "Instagram"
  final int minutesAllowed;          // e.g. 30
  final int windowMinutes;           // e.g. 180 (3 hours)
  final String shameMessage;         // custom message sent to partner
  final bool keyholderRequired;      // if true, partner must send code to unlock
  final bool active;

  const LimitRule({
    this.id,
    required this.appPackageOrCategory,
    required this.appDisplayName,
    this.minutesAllowed = 30,
    this.windowMinutes = 180,
    this.shameMessage = 'has exceeded their time limit.',
    this.keyholderRequired = false,
    this.active = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'appPackageOrCategory': appPackageOrCategory,
      'appDisplayName': appDisplayName,
      'minutesAllowed': minutesAllowed,
      'windowMinutes': windowMinutes,
      'shameMessage': shameMessage,
      'keyholderRequired': keyholderRequired,
      'active': active,
    };
  }

  factory LimitRule.fromMap(String? id, Map<String, dynamic> map) {
    return LimitRule(
      id: id,
      appPackageOrCategory: map['appPackageOrCategory'] as String? ?? '',
      appDisplayName: map['appDisplayName'] as String? ?? '',
      minutesAllowed: (map['minutesAllowed'] as num?)?.toInt() ?? 30,
      windowMinutes: (map['windowMinutes'] as num?)?.toInt() ?? 180,
      shameMessage: map['shameMessage'] as String? ?? 'has exceeded their time limit.',
      keyholderRequired: map['keyholderRequired'] as bool? ?? false,
      active: map['active'] as bool? ?? true,
    );
  }

  LimitRule copyWith({
    String? appPackageOrCategory,
    String? appDisplayName,
    int? minutesAllowed,
    int? windowMinutes,
    String? shameMessage,
    bool? keyholderRequired,
    bool? active,
  }) {
    return LimitRule(
      id: id,
      appPackageOrCategory: appPackageOrCategory ?? this.appPackageOrCategory,
      appDisplayName: appDisplayName ?? this.appDisplayName,
      minutesAllowed: minutesAllowed ?? this.minutesAllowed,
      windowMinutes: windowMinutes ?? this.windowMinutes,
      shameMessage: shameMessage ?? this.shameMessage,
      keyholderRequired: keyholderRequired ?? this.keyholderRequired,
      active: active ?? this.active,
    );
  }
}
