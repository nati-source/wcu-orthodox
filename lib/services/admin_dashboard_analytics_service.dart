import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance_models.dart';
import '../models/user_models.dart';

class AdminDashboardAttendanceSession {
  final AttendanceSessionModel session;
  final List<AttendanceEnrollmentSnapshot> enrolledStudents;
  final List<AttendanceRecordModel> scans;

  const AdminDashboardAttendanceSession({
    required this.session,
    required this.enrolledStudents,
    required this.scans,
  });
}

class AdminDashboardAnalyticsSnapshot {
  final List<UserModel> students;
  final List<UserModel> pendingStudents;
  final List<AdminDashboardAttendanceSession> sessions;

  const AdminDashboardAnalyticsSnapshot({
    required this.students,
    required this.pendingStudents,
    required this.sessions,
  });
}

/// Reads the records used by the admin dashboard from Firestore and leaves
/// aggregation to the dashboard so department filters use the same source data.
class AdminDashboardAnalyticsService {
  final FirebaseFirestore? _firestore;

  AdminDashboardAnalyticsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? _resolveFirestore();

  static FirebaseFirestore? _resolveFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<AdminDashboardAnalyticsSnapshot> load() async {
    final firestore = _firestore;
    if (firestore == null) {
      return const AdminDashboardAnalyticsSnapshot(
        students: [],
        pendingStudents: [],
        sessions: [],
      );
    }
    final userSnapshot = await firestore
        .collection('users')
        .get()
        .timeout(const Duration(seconds: 5));
    final students = <UserModel>[];
    final pendingStudents = <UserModel>[];

    for (final doc in userSnapshot.docs) {
      final user = UserModel.fromMap(doc.data(), doc.id);
      // Exclude the admin/system accounts from member counts — they are
      // operators, not fellowship registrants. Include all other roles
      // (student, spiritualParent, volunteerCoordinator) in the lists.
      if (user.role == UserRole.admin) continue;
      if (user.isApproved) {
        students.add(user);
      } else {
        pendingStudents.add(user);
      }
    }

    QuerySnapshot<Map<String, dynamic>> sessionSnapshot;
    try {
      sessionSnapshot = await firestore
          .collection('attendance_sessions')
          .orderBy('generatedAt', descending: true)
          .limit(20)
          .get()
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      sessionSnapshot = await firestore
          .collection('attendance_sessions')
          .limit(20)
          .get()
          .timeout(const Duration(seconds: 4));
    }
    final sessionDocs = sessionSnapshot.docs;
    final sessions = <AdminDashboardAttendanceSession>[];

    // Keep concurrent reads bounded while loading each session's real check-ins.
    for (var offset = 0; offset < sessionDocs.length; offset += 10) {
      final batch = sessionDocs.skip(offset).take(10);
      final batchResults = await Future.wait(
        batch.map((doc) async {
          final data = Map<String, dynamic>.from(doc.data());
          final session = AttendanceSessionModel.fromMap(data, doc.id);
          List<AttendanceRecordModel> scans = const [];
          try {
            final scansSnapshot = await doc.reference
                .collection('scans')
                .limit(100)
                .get()
                .timeout(const Duration(seconds: 3));
            scans = scansSnapshot.docs
                .where((scan) {
                  final status = scan.data()['status']?.toString();
                  return status == AttendanceStatus.present.name ||
                      status == AttendanceStatus.late.name ||
                      status == AttendanceStatus.absent.name;
                })
                .map(
                  (scan) => AttendanceRecordModel.fromMap(scan.data(), scan.id),
                )
                .toList();
          } catch (_) {}
          return AdminDashboardAttendanceSession(
            session: session.copyWith(scans: scans),
            enrolledStudents: session.enrollmentSnapshot,
            scans: scans,
          );
        }),
      );
      sessions.addAll(batchResults);
    }

    return AdminDashboardAnalyticsSnapshot(
      students: students,
      pendingStudents: pendingStudents,
      sessions: sessions,
    );
  }
}
