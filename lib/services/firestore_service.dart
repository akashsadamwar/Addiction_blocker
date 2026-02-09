import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gj4_accountability/models/limit_rule.dart';
import 'package:gj4_accountability/models/pairing_code.dart';
import 'package:gj4_accountability/models/usage_state.dart';
import 'package:gj4_accountability/models/unlock_request.dart';
import 'package:gj4_accountability/models/user_profile.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _users = 'users';
  static const _pairingCodes = 'pairingCodes';
  static const _limitRules = 'limitRules';
  static const _unlockRequests = 'unlockRequests';
  static const _blockerConfig = 'blockerConfig';
  static const _usageState = 'usageState';

  // ---------- User profile ----------
  Future<void> setUserProfile(
    String uid, {
    required String email,
    String displayName = '',
  }) async {
    await _firestore.collection(_users).doc(uid).set({
      'email': email,
      'displayName': displayName.isEmpty ? email.split('@').first : displayName,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection(_users).doc(uid).get();
    if (doc.data() == null) return null;
    return UserProfile.fromMap(uid, doc.data()!);
  }

  Future<void> updateUserFcmToken(String uid, String? token) async {
    await _firestore.collection(_users).doc(uid).update({
      'fcmToken': token,
    });
  }

  Future<void> linkPartners(String uid1, String uid2) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection(_users).doc(uid1), {'partnerId': uid2});
    batch.update(_firestore.collection(_users).doc(uid2), {'partnerId': uid1});
    await batch.commit();
  }

  // ---------- Pairing codes ----------
  Future<PairingCode> createPairingCode(String creatorUid) async {
    const length = 6;
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = List.generate(length, (i) => ((random + i * 997) % 10).abs().toString()).join();
    final expiresAt = DateTime.now().add(const Duration(minutes: 10));
    final pairing = PairingCode(code: code, creatorUid: creatorUid, expiresAt: expiresAt);
    await _firestore.collection(_pairingCodes).doc(code).set(pairing.toMap());
    return pairing;
  }

  Future<PairingCode?> consumePairingCode(String code) async {
    final doc = await _firestore.collection(_pairingCodes).doc(code).get();
    if (doc.data() == null) return null;
    final pairing = PairingCode.fromMap(doc.data()!);
    if (pairing.isExpired) return null;
    await _firestore.collection(_pairingCodes).doc(code).delete();
    return pairing;
  }

  // ---------- Limit rules ----------
  Future<void> setLimitRule(String uid, LimitRule rule) async {
    final col = _firestore.collection(_users).doc(uid).collection(_limitRules);
    if (rule.id != null) {
      await col.doc(rule.id).set(rule.toMap());
    } else {
      await col.add(rule.toMap());
    }
  }

  Future<List<LimitRule>> getLimitRules(String uid) async {
    final snap = await _firestore
        .collection(_users)
        .doc(uid)
        .collection(_limitRules)
        .get();
    return snap.docs
        .map((d) => LimitRule.fromMap(d.id, d.data()))
        .where((r) => r.active)
        .toList();
  }

  Stream<List<LimitRule>> streamLimitRules(String uid) {
    return _firestore
        .collection(_users)
        .doc(uid)
        .collection(_limitRules)
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => LimitRule.fromMap(d.id, d.data())).toList());
  }

  // ---------- Unlock requests (Keyholder) ----------
  Future<UnlockRequest> createUnlockRequest(String requestedByUid, String partnerUid) async {
    final expiresAt = DateTime.now().add(const Duration(minutes: 15));
    final request = UnlockRequest(
      requestedByUid: requestedByUid,
      partnerUid: partnerUid,
      expiresAt: expiresAt,
      status: UnlockRequestStatus.pending,
      createdAt: DateTime.now(),
    );
    final ref = await _firestore.collection(_unlockRequests).add(request.toMap());
    final doc = await ref.get();
    return UnlockRequest.fromMap(ref.id, doc.data()!);
  }

  Future<UnlockRequest?> getUnlockRequest(String requestId) async {
    final doc = await _firestore.collection(_unlockRequests).doc(requestId).get();
    if (doc.data() == null) return null;
    return UnlockRequest.fromMap(doc.id, doc.data()!);
  }

  /// Pending requests for this partner (so they can generate a code).
  Future<List<UnlockRequest>> getPendingUnlockRequestsForPartner(String partnerUid) async {
    final snap = await _firestore
        .collection(_unlockRequests)
        .where('partnerUid', isEqualTo: partnerUid)
        .where('status', isEqualTo: UnlockRequestStatus.pending.value)
        .get();
    return snap.docs
        .map((d) => UnlockRequest.fromMap(d.id, d.data()))
        .where((r) => !r.isExpired)
        .toList();
  }

  /// Latest pending request by the blocked user (to show "waiting for partner" or enter code).
  Future<UnlockRequest?> getLatestPendingRequestByUser(String requestedByUid) async {
    final snap = await _firestore
        .collection(_unlockRequests)
        .where('requestedByUid', isEqualTo: requestedByUid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return UnlockRequest.fromMap(doc.id, doc.data());
  }

  Future<void> setUnlockCode(String requestId, String code) async {
    final expiresAt = DateTime.now().add(const Duration(minutes: 5));
    await _firestore.collection(_unlockRequests).doc(requestId).update({
      'code': code,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'status': UnlockRequestStatus.codeGenerated.value,
    });
  }

  Future<bool> consumeUnlockCode(String requestId, String code) async {
    final doc = await _firestore.collection(_unlockRequests).doc(requestId).get();
    if (doc.data() == null) return false;
    final request = UnlockRequest.fromMap(doc.id, doc.data()!);
    if (!request.isUsable || request.code != code) return false;
    await _firestore.collection(_unlockRequests).doc(requestId).update({
      'status': UnlockRequestStatus.used.value,
    });
    return true;
  }

  // ---------- Blocker config & usage state (for native Android/iOS) ----------
  /// Write config the native blocker reads: restricted apps + limit. Call after limit rules change.
  Future<void> setBlockerConfig(String uid, BlockerConfig config) async {
    await _firestore
        .collection(_users)
        .doc(uid)
        .collection(_blockerConfig)
        .doc('current')
        .set(config.toMap());
  }

  Future<BlockerConfig?> getBlockerConfig(String uid) async {
    final doc = await _firestore
        .collection(_users)
        .doc(uid)
        .collection(_blockerConfig)
        .doc('current')
        .get();
    if (doc.data() == null) return null;
    return BlockerConfig.fromMap(uid, doc.data()!);
  }

  /// Build and save blocker config from current limit rules. Call when user saves limits.
  Future<void> syncBlockerConfigFromRules(String uid, String displayName) async {
    final rules = await getLimitRules(uid);
    final restrictedApps = rules
        .map((r) => r.appPackageOrCategory)
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList();
    final minutesAllowed = rules.isEmpty ? 30 : rules.map((r) => r.minutesAllowed).reduce((a, b) => a < b ? a : b);
    final windowMinutes = rules.isEmpty ? 180 : rules.map((r) => r.windowMinutes).reduce((a, b) => a < b ? a : b);
    await setBlockerConfig(
      uid,
      BlockerConfig(
        userId: uid,
        restrictedApps: restrictedApps,
        minutesAllowed: minutesAllowed,
        windowMinutes: windowMinutes,
        displayName: displayName,
      ),
    );
  }

  Future<UsageState?> getUsageState(String uid) async {
    final doc = await _firestore
        .collection(_users)
        .doc(uid)
        .collection(_usageState)
        .doc('current')
        .get();
    if (doc.data() == null) return null;
    return UsageState.fromMap(uid, doc.data()!);
  }

  Future<void> setUsageState(String uid, UsageState state) async {
    await _firestore
        .collection(_users)
        .doc(uid)
        .collection(_usageState)
        .doc('current')
        .set(state.toMap());
  }

  /// List of restricted package names for this user (from limit rules). For native blocker.
  Future<List<String>> getRestrictedAppPackages(String uid) async {
    final rules = await getLimitRules(uid);
    return rules
        .map((r) => r.appPackageOrCategory)
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList();
  }
}
