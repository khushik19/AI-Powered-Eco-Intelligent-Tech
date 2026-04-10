import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phone,
    required String city,
    required String state,
    required String country,
    String? institution,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;
    final isOrg = role == 'college_org';

    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'state': state,
      'country': country,
      'institution': institution ?? '',
      'role': role,
      'stardust': 0,
      'weeklyStreak': 0,
      'totalActions': 0,
      'lastActionDate': null,
      'createdAt': DateTime.now().toIso8601String(),
    });

    if (isOrg) {
      await _db.collection('colleges').doc(uid).set({
        'name': name,
        'email': email,
        'city': city,
        'state': state,
        'country': country,
        'totalStardust': 0,
        'memberCount': 0,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
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