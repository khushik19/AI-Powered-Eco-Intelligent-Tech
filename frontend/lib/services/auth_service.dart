import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phone,
    required String city,
    required String state,
    required String country,
    String? institution,
    String? collegeId,
  }) async {
    String uid;

    final existingUser = _auth.currentUser;
    final isPhoneAuthed =
        existingUser != null && existingUser.phoneNumber != null;

    if (isPhoneAuthed) {
      // ── Phone OTP was verified — link email+password to the phone user ──
      // This means the user can sign in with EITHER phone OTP OR email+password.
      final emailCredential =
          EmailAuthProvider.credential(email: email, password: password);
      await existingUser.linkWithCredential(emailCredential);
      uid = existingUser.uid;
    } else {
      // If there is an existing user but they are not phone authenticated (e.g. Guest session),
      // sign out first to ensure a clean session for creating the new email/password account.
      if (existingUser != null) {
        await _auth.signOut();
      }
      // ── Fallback: create directly with email+password ───────────────────
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      uid = cred.user!.uid;
    }

    final isOrg = role == 'college_org';
    final userData = {
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'state': state,
      'country': country,
      'institution': institution ?? '',
      'collegeId': collegeId,
      'role': role,
      'stardust': 0,
      'weeklyStreak': 0,
      'totalActions': 0,
      'lastActionDate': null,
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      await _db.collection('users').doc(uid).set(userData);

      if (isOrg) {
        await _db.collection('colleges').doc(uid).set({
          'name': name,
          'email': email,
          'phone': phone,
          'city': city,
          'state': state,
          'country': country,
          'totalStardust': 0,
          'memberCount': 0,
          // Accreditation system fields — required for tier promotions
          'accreditationScore': 0,
          'accreditationTier': 'seedling',
          // Environmental impact aggregates
          'totalCo2Kg': 0.0,
          'totalEnergySavedKwh': 0.0,
          'totalWaterSavedL': 0.0,
          'totalEWasteKg': 0.0,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      final user = _auth.currentUser;
      if (user != null && !isPhoneAuthed) {
        try {
          await user.delete();
        } catch (_) {}
      }
      rethrow;
    }

    return {'uid': uid, ...userData};
  }

  static Future<Map<String, dynamic>?> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    final uid = cred.user!.uid;

    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      await _db.collection('users').doc(uid).set({
        'name': 'Guest Explorer',
        'email': 'guest@cleancosmos.app',
        'phone': '',
        'city': 'Cosmos',
        'state': 'Space',
        'country': 'Universe',
        'institution': '',
        'collegeId': null,
        'role': 'individual',
        'stardust': 0,
        'weeklyStreak': 0,
        'totalActions': 0,
        'lastActionDate': null,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    return getUserData(uid);
  }

  static Future<Map<String, dynamic>?> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return getUserData(cred.user!.uid);
  }

  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return {'uid': uid, ...doc.data()!};
  }

  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getUserData(user.uid);
  }

  static Future<void> signOut() => _auth.signOut();

  static User? get currentUser => _auth.currentUser;
}