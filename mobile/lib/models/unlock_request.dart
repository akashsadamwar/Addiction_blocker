import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a keyholder unlock request.
enum UnlockRequestStatus {
  pending,
  codeGenerated,
  used,
  expired,
}

extension UnlockRequestStatusX on UnlockRequestStatus {
  String get value {
    switch (this) {
      case UnlockRequestStatus.pending:
        return 'pending';
      case UnlockRequestStatus.codeGenerated:
        return 'code_generated';
      case UnlockRequestStatus.used:
        return 'used';
      case UnlockRequestStatus.expired:
        return 'expired';
    }
  }

  static UnlockRequestStatus fromString(String? v) {
    switch (v) {
      case 'pending':
        return UnlockRequestStatus.pending;
      case 'code_generated':
        return UnlockRequestStatus.codeGenerated;
      case 'used':
        return UnlockRequestStatus.used;
      case 'expired':
        return UnlockRequestStatus.expired;
      default:
        return UnlockRequestStatus.pending;
    }
  }
}

/// Request for an emergency unlock when Keyholder mode is on.
/// Partner generates a one-time code; user enters it to unlock.
class UnlockRequest {
  final String? id;
  final String requestedByUid;
  final String partnerUid;
  final String? code;
  final DateTime? expiresAt;
  final UnlockRequestStatus status;
  final DateTime? createdAt;

  const UnlockRequest({
    this.id,
    required this.requestedByUid,
    required this.partnerUid,
    this.code,
    this.expiresAt,
    this.status = UnlockRequestStatus.pending,
    this.createdAt,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isUsable =>
      status == UnlockRequestStatus.codeGenerated &&
      code != null &&
      !isExpired;

  Map<String, dynamic> toMap() {
    return {
      'requestedByUid': requestedByUid,
      'partnerUid': partnerUid,
      'code': code,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
      'status': status.value,
      'createdAt': createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  static DateTime? _dateFromMap(dynamic v) {
    if (v == null) return null;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is Timestamp) return v.toDate();
    return null;
  }

  factory UnlockRequest.fromMap(String? id, Map<String, dynamic> map) {
    return UnlockRequest(
      id: id,
      requestedByUid: map['requestedByUid'] as String? ?? '',
      partnerUid: map['partnerUid'] as String? ?? '',
      code: map['code'] as String?,
      expiresAt: _dateFromMap(map['expiresAt']),
      status: UnlockRequestStatusX.fromString(map['status'] as String?),
      createdAt: _dateFromMap(map['createdAt']),
    );
  }

  UnlockRequest copyWith({
    String? code,
    DateTime? expiresAt,
    UnlockRequestStatus? status,
  }) {
    return UnlockRequest(
      id: id,
      requestedByUid: requestedByUid,
      partnerUid: partnerUid,
      code: code ?? this.code,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
