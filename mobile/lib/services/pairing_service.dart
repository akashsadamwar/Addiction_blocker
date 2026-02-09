import 'package:gj4_accountability/models/user_profile.dart';
import 'package:gj4_accountability/services/firestore_service.dart';

class PairingService {
  final FirestoreService _firestore = FirestoreService();

  Future<String> generateCode(String creatorUid) async {
    final pairing = await _firestore.createPairingCode(creatorUid);
    return pairing.code;
  }

  Future<UserProfile?> enterCodeAsPartner(String code, String partnerUid) async {
    final pairing = await _firestore.consumePairingCode(code);
    if (pairing == null) return null;
    final creatorUid = pairing.creatorUid;
    if (creatorUid == partnerUid) return null;
    await _firestore.linkPartners(creatorUid, partnerUid);
    return _firestore.getUserProfile(creatorUid);
  }
}
