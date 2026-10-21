import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import 'notification_service.dart';

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
    UserCredential? credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      await credential.user!.updateDisplayName(fullName);

      // All client signups are initialized with student role and pending approval.
      // Elevated roles (admin, coordinator) must be provisioned via Firebase Console / server-managed roles.
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
        'role': UserRole.student.name,
        'isApproved': false,
        'gender': gender.toLowerCase(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return credential;
    } catch (e) {
      if (credential?.user != null) {
        try {
          await credential!.user!.delete();
        } catch (_) {}
      }
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
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final profile = await _firestore.collection('users').doc(user.uid).get();
        final data = profile.data() ?? const <String, dynamic>{};
        final coordinatorProfile = data['coordinatorProfile'];
        final departmentId = coordinatorProfile is Map
            ? coordinatorProfile['departmentId']?.toString()
            : null;
        await NotificationService.instance.clearUserSubscriptions(
          role: data['role']?.toString() ?? '',
          assignedFamilyId: data['assignedFamilyId']?.toString(),
          departmentId: departmentId,
        );
      } catch (e) {
        debugPrint('Unable to clear notification subscriptions before sign out: $e');
      }
    }
    await _auth.signOut();
  }

  /// Fetch User Profile data from Firestore with resilient timeout & offline cache fallback
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      // 1. Try server fetch with a fast 4-second timeout
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 4));
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
    } catch (_) {
      // 2. If network is slow or offline, immediately attempt local cache
      try {
        final cacheDoc = await _firestore
            .collection('users')
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
        if (cacheDoc.exists && cacheDoc.data() != null) {
          return cacheDoc.data();
        }
      } catch (_) {}
    }
    return null;
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
