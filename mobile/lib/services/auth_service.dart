import 'package:firebase_auth/firebase_auth.dart';
import 'package:gj4_accountability/models/user_profile.dart';
import 'package:gj4_accountability/services/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestore = FirestoreService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return cred.user;
  }

  Future<User?> signUpWithEmail(String email, String password, String displayName) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user;
    if (user != null) {
      await _firestore.setUserProfile(
        user.uid,
        email: email.trim(),
        displayName: displayName.trim().isEmpty ? email.split('@').first : displayName.trim(),
      );
    }
    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserProfile?> getProfile(String uid) async {
    return _firestore.getUserProfile(uid);
  }

  Future<void> updateFcmToken(String uid, String? token) async {
    await _firestore.updateUserFcmToken(uid, token);
  }
}
