import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';

class AuthService {
  FirebaseAuth? get _authInstance {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _firestoreInstance {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth get _auth {
    final inst = _authInstance;
    if (inst == null) throw StateError('Firebase Auth is not initialized');
    return inst;
  }

  FirebaseFirestore get _firestore {
    final inst = _firestoreInstance;
    if (inst == null) throw StateError('Firestore is not initialized');
    return inst;
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges {
    final inst = _authInstance;
    if (inst == null) return const Stream.empty();
    return inst.authStateChanges();
  }

  // Current logged in Firebase user
  User? get currentUser => _authInstance?.currentUser;

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

      final bool isAdminEmail = AppAdminConstants.isAdminEmail(email);
      final effectiveRole = isAdminEmail ? UserRole.admin : initialRole;
      final effectiveApproved = isAdminEmail ? true : false;

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
        'role': effectiveRole.name,
        'isApproved': effectiveApproved,  // Admin is approved immediately; students require approval
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
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (AppAdminConstants.isAdminEmail(email)) {
        final uid = credential.user?.uid;
        if (uid != null) {
          try {
            await _firestore.collection('users').doc(uid).set({
              'id': uid,
              'email': email.trim().toLowerCase(),
              'role': 'admin',
              'isApproved': true,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          } catch (_) {}
        }
      }
      return credential;
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

  /// Change/Update Password for currently logged in user
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null || user.email!.trim().isEmpty) {
      throw Exception('No active authenticated email user session found.');
    }
    // Re-authenticate user to confirm their identity before password change
    final cred = EmailAuthProvider.credential(
      email: user.email!.trim(),
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
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
