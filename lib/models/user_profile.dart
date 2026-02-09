import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile stored in Firestore (display name, FCM token, partner link).
class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? fcmToken;
  final String? partnerId; // linked accountability partner uid
  final int streakDays;
  final DateTime? lastTriggerAt;
  final DateTime? createdAt;

  const UserProfile({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.fcmToken,
    this.partnerId,
    this.streakDays = 0,
    this.lastTriggerAt,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'fcmToken': fcmToken,
      'partnerId': partnerId,
      'streakDays': streakDays,
      'lastTriggerAt': lastTriggerAt?.millisecondsSinceEpoch,
      'createdAt': createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  static DateTime? _dateFromMap(dynamic v) {
    if (v == null) return null;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is Timestamp) return v.toDate();
    return null;
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      fcmToken: map['fcmToken'] as String?,
      partnerId: map['partnerId'] as String?,
      streakDays: (map['streakDays'] as num?)?.toInt() ?? 0,
      lastTriggerAt: _dateFromMap(map['lastTriggerAt']),
      createdAt: _dateFromMap(map['createdAt']),
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? fcmToken,
    String? partnerId,
    int? streakDays,
    DateTime? lastTriggerAt,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      fcmToken: fcmToken ?? this.fcmToken,
      partnerId: partnerId ?? this.partnerId,
      streakDays: streakDays ?? this.streakDays,
      lastTriggerAt: lastTriggerAt ?? this.lastTriggerAt,
      createdAt: createdAt,
    );
  }
}
