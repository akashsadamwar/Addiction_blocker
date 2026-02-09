/// One-time pairing code stored in Firestore (creator uid, expiry).
class PairingCode {
  final String code;       // 6-digit string
  final String creatorUid; // user who generated the code
  final DateTime expiresAt;

  const PairingCode({
    required this.code,
    required this.creatorUid,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'creatorUid': creatorUid,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
    };
  }

  factory PairingCode.fromMap(Map<String, dynamic> map) {
    return PairingCode(
      code: map['code'] as String? ?? '',
      creatorUid: map['creatorUid'] as String? ?? '',
      expiresAt: map['expiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int)
          : DateTime.now(),
    );
  }
}
