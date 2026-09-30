import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current logged in Firebase user
  User? get currentUser => _auth.currentUser;

  /// Sign Up with Email and Password & initialize User Profile in Firestore
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? baptismalName,
    required String phoneNumber,
    required String studentId,
    required String department,
    required int academicYear,
    String batchYear = '2024',
    String campus = 'Main Campus (ዋናው ግቢ)',
    UserRole initialRole = UserRole.student,
    String gender = 'male',
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      await credential.user!.updateDisplayName(fullName);

      // Create user document in Firestore
      final userDoc = _firestore.collection('users').doc(uid);
      await userDoc.set({
        'id': uid,
        'fullName': fullName.trim(),
        'baptismalName': baptismalName?.trim() ?? '',
        'email': email.trim().toLowerCase(),
        'phoneNumber': phoneNumber.trim(),
        'studentId': studentId.trim(),
        'campus': campus.trim(),
        'department': department.trim(),
        'academicYear': academicYear,
        'batchYear': batchYear.trim(),
        'role': initialRole.name,
        'isApproved': true,
        'gender': gender.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign In with Email and Password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      rethrow;
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Fetch User Profile data from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update User Profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }
}
