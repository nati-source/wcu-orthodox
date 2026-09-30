import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';

class FirestoreService {
  final FirebaseFirestore? _customFirestore;

  FirestoreService({FirebaseFirestore? firestore}) : _customFirestore = firestore;

  FirebaseFirestore? get _firestoreInstance {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore get _firestore {
    final inst = _firestoreInstance;
    if (inst == null) {
      throw StateError('FirebaseFirestore is not initialized');
    }
    return inst;
  }

  FirebaseFirestore get firestore => _firestore;

  // ===========================================================================
  // 1. PILGRIMAGE TRIPS & REGISTRATIONS
  // ===========================================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamPilgrimageTrips() {
    return _firestore.collection('pilgrimage_trips').snapshots();
  }

  Future<void> upsertPilgrimageTrip(PilgrimageTripModel trip) async {
    try {
      await _firestore.collection('pilgrimage_trips').doc(trip.id).set(
        trip.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore upsert pilgrimage trip error: $e');
      rethrow;
    }
  }

  Future<void> deletePilgrimageTrip(String tripId) async {
    final inst = _firestoreInstance;
    if (inst == null) return;
    try {
      await inst.collection('pilgrimage_trips').doc(tripId).delete();
      // Clean up orphaned registrations for this trip
      final regsSnap = await inst.collection('trip_registrations').where('tripId', isEqualTo: tripId).get();
      final batch = inst.batch();
      for (final doc in regsSnap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore delete pilgrimage trip error: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamTripRegistrations() {
    final inst = _firestoreInstance;
    if (inst == null) return const Stream.empty();
    return inst.collection('trip_registrations').snapshots();
  }

  Future<void> registerPilgrim(TripRegistrationModel reg, String tripId) async {
    final inst = _firestoreInstance;
    if (inst == null) return;
    try {
      // Write registration record
      await inst.collection('trip_registrations').doc(reg.id).set(
        reg.toMap(),
        SetOptions(merge: true),
      );

      // Increment booked seats on the trip doc safely using merge
      await inst.collection('pilgrimage_trips').doc(tripId).set({
        'bookedSeats': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore register pilgrim error: $e');
    }
  }

  Future<void> updateTripRegistration(TripRegistrationModel reg) async {
    final inst = _firestoreInstance;
    if (inst == null) return;
    try {
      await inst.collection('trip_registrations').doc(reg.id).set(
        reg.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore update trip registration error: $e');
    }
  }

  Future<void> upsertTripRegistration(TripRegistrationModel reg) => updateTripRegistration(reg);

  Future<void> deleteTripRegistration(String regId, {String? tripId}) async {
    final inst = _firestoreInstance;
    if (inst == null) return;
    try {
      await inst.collection('trip_registrations').doc(regId).delete();
      if (tripId != null) {
        await inst.collection('pilgrimage_trips').doc(tripId).set({
          'bookedSeats': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore delete trip registration error: $e');
    }
  }

  // ===========================================================================
  // 2. FAMILIES & SMART MATCHING ROSTER
  // ===========================================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamFamilies() {
    return _firestore.collection('families').snapshots();
  }

  Future<void> upsertFamily(FamilyModel family) async {
    final inst = _firestoreInstance;
    if (inst == null) return;
    try {
      await inst.collection('families').doc(family.id).set(
        family.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore upsert family error: $e');
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamFamilyConfig() {
    return _firestore.collection('app_config').doc('family_roster').snapshots();
  }

  Future<void> publishFamiliesRoster(bool isPublished) async {
    try {
      await _firestore.collection('app_config').doc('family_roster').set({
        'isFamilyPublished': isPublished,
        'publishedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also update all family documents
      final snap = await _firestore.collection('families').get();
      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.set(doc.reference, {'isPublished': isPublished}, SetOptions(merge: true));
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore publish families roster error: $e');
    }
  }

  // ===========================================================================
  // 3. USERS & STUDENT PROFILES
  // ===========================================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamUsers() {
    return _firestore.collection('users').snapshots();
  }

  Future<void> upsertUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(
        user.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore upsert user error: $e');
      rethrow;
    }
  }

  Future<void> updateUserFamilyAssignment(String userId, String familyId) async {
    final inst = _firestoreInstance;
    if (inst == null) return;
    try {
      await inst.collection('users').doc(userId).set({
        'assignedFamilyId': familyId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore update user family assignment error: $e');
    }
  }

  // ===========================================================================
  // 4. LIVE ATTENDANCE & QR SESSIONS
  // ===========================================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamActiveAttendanceSessions() {
    return _firestore
        .collection('attendance_sessions')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  Future<void> upsertAttendanceSession(AttendanceSessionModel session) async {
    try {
      await _firestore.collection('attendance_sessions').doc(session.sessionId).set(
        {
          'sessionId': session.sessionId,
          'courseName': session.courseName,
          'courseCode': session.courseCode,
          'faculty': session.faculty,
          'code': session.code,
          'rollingPin': session.rollingPin,
          'generatedAt': session.generatedAt.toIso8601String(),
          'refreshIntervalSeconds': session.refreshIntervalSeconds,
          'totalEnrolled': session.totalEnrolled,
          'isActive': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore upsert attendance session error: $e');
    }
  }

  /// Marks an attendance session as closed so it no longer appears in the active stream.
  Future<void> closeAttendanceSession(String sessionId) async {
    try {
      await _firestore.collection('attendance_sessions').doc(sessionId).set({
        'isActive': false,
        'closedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore close attendance session error: $e');
    }
  }

  Future<void> recordAttendanceCheckIn({
    required String sessionId,
    required AttendanceRecordModel scan,
  }) async {
    try {
      await _firestore
          .collection('attendance_sessions')
          .doc(sessionId)
          .collection('scans')
          .doc(scan.studentId)
          .set({
            'studentId': scan.studentId,
            'studentName': scan.studentName,
            'timestamp': scan.timestamp.toIso8601String(),
            'status': scan.status.name,
          }, SetOptions(merge: true));

      await _firestore.collection('attendance_sessions').doc(sessionId).set({
        'lastScanAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore record attendance checkin error: $e');
    }
  }

  // ===========================================================================
  // 5. ACADEMIC MENTORSHIP & MATCHES
  // ===========================================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAcademicMentors() {
    return _firestore.collection('academic_mentors').snapshots();
  }

  Future<void> upsertAcademicMentor(AcademicMentorModel mentor) async {
    try {
      await _firestore.collection('academic_mentors').doc(mentor.id).set(
        mentor.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore upsert academic mentor error: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMentorshipRequests() {
    return _firestore.collection('mentorship_requests').snapshots();
  }

  Future<void> submitMentorshipRequest(MentorshipRequestModel req) async {
    try {
      await _firestore.collection('mentorship_requests').doc(req.id).set(
        req.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore submit mentorship request error: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // 6. CONFESSOR FATHERS, APPOINTMENTS & SPIRITUAL QUESTIONS
  // ===========================================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamConfessors() {
    return _firestore.collection('confessors').snapshots();
  }

  Future<void> upsertConfessor(ConfessorFatherModel confessor) async {
    try {
      await _firestore.collection('confessors').doc(confessor.id).set(
        confessor.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore upsert confessor error: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamConfessionAppointments() {
    return _firestore.collection('confession_appointments').snapshots();
  }

  Future<void> upsertConfessionAppointment(ConfessionAppointmentModel appt) async {
    try {
      await _firestore.collection('confession_appointments').doc(appt.id).set(
        appt.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore upsert confession appointment error: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamSpiritualQuestions() {
    return _firestore.collection('spiritual_questions').snapshots();
  }

  Future<void> submitSpiritualQuestion(AnonymousSpiritualQuestionModel question) async {
    try {
      await _firestore.collection('spiritual_questions').doc(question.id).set(
        question.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore submit spiritual question error: $e');
    }
  }

  // ===========================================================================
  // 7. CHARITY, EMERGENCY AID & FINANCIAL DUES
  // ===========================================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCharityCampaigns() {
    final inst = _firestoreInstance;
    if (inst == null) return const Stream.empty();
    return inst.collection('charity_campaigns').snapshots();
  }

  Future<void> upsertCharityCampaign(CharityCampaignModel campaign) async {
    final inst = _firestoreInstance;
    if (inst == null) return;
    try {
      await inst.collection('charity_campaigns').doc(campaign.id).set(
        campaign.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore upsert charity campaign error: $e');
    }
  }

  Future<void> deleteCharityCampaign(String campaignId) async {
    final inst = _firestoreInstance;
    if (inst == null) return;
    try {
      await inst.collection('charity_campaigns').doc(campaignId).delete();
    } catch (e) {
      debugPrint('Firestore delete charity campaign error: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAidRequests() {
    final inst = _firestoreInstance;
    if (inst == null) return const Stream.empty();
    return inst.collection('emergency_aid_requests').snapshots();
  }

  Future<void> submitAidRequest(EmergencyAidRequestModel req) async {
    final inst = _firestoreInstance;
    if (inst == null) return;
    try {
      await inst.collection('emergency_aid_requests').doc(req.id).set(
        req.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore submit aid request error: $e');
    }
  }

  Future<void> updateAidRequestStatus(String reqId, String status, {String? adminNote}) async {
    final inst = _firestoreInstance;
    if (inst == null) return;
    try {
      await inst.collection('emergency_aid_requests').doc(reqId).set({
        'status': status,
        if (adminNote != null) 'adminNote': adminNote,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore update aid request status error: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamFinancialDues() {
    final inst = _firestoreInstance;
    if (inst == null) return const Stream.empty();
    return inst.collection('financial_dues').snapshots();
  }

  Future<void> recordDuesPayment(DuesPaymentModel due) async {
    final inst = _firestoreInstance;
    if (inst == null) return;
    try {
      await inst.collection('financial_dues').doc(due.id).set(
        due.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore record dues payment error: $e');
    }
  }

  Future<void> deleteDuesPayment(String paymentId) async {
    final inst = _firestoreInstance;
    if (inst == null) return;
    try {
      await inst.collection('financial_dues').doc(paymentId).delete();
    } catch (e) {
      debugPrint('Firestore delete dues payment error: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamCharityDisbursements() {
    final inst = _firestoreInstance;
    if (inst == null) return const Stream.empty();
    return inst.collection('charity_disbursements').snapshots();
  }

  Future<void> recordCharityDisbursement(CharityDisbursementModel disbursement) async {
    final inst = _firestoreInstance;
    if (inst == null) return;
    try {
      await inst.collection('charity_disbursements').doc(disbursement.id).set(
        disbursement.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore record charity disbursement error: $e');
    }
  }

  Future<void> deleteCharityDisbursement(String disbursementId) async {
    final inst = _firestoreInstance;
    if (inst == null) return;
    try {
      await inst.collection('charity_disbursements').doc(disbursementId).delete();
    } catch (e) {
      debugPrint('Firestore delete charity disbursement error: $e');
    }
  }

  // ===========================================================================
  // 8. CHURCH PROGRAMS & DIGITAL LIBRARY
  // ===========================================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamChurchPrograms() {
    return _firestore.collection('church_programs').snapshots();
  }

  Future<void> upsertChurchProgram(ChurchProgramModel program) async {
    try {
      await _firestore.collection('church_programs').doc(program.id).set(
        program.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore upsert church program error: $e');
    }
  }

  Future<void> deleteChurchProgram(String programId) async {
    try {
      await _firestore.collection('church_programs').doc(programId).delete();
    } catch (e) {
      debugPrint('Firestore delete church program error: $e');
    }
  }

  // ===========================================================================
  // 8.1 THEOLOGICAL TRIVIA QUIZZES (FAITH CHALLENGES)
  // ===========================================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamTriviaQuizzes() {
    return _firestore.collection('trivia_quizzes').snapshots();
  }

  Future<void> upsertTriviaQuiz(TriviaQuizModel quiz) async {
    try {
      await _firestore.collection('trivia_quizzes').doc(quiz.id).set(
        quiz.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore upsert trivia quiz error: $e');
    }
  }

  Future<void> deleteTriviaQuiz(String quizId) async {
    try {
      await _firestore.collection('trivia_quizzes').doc(quizId).delete();
    } catch (e) {
      debugPrint('Firestore delete trivia quiz error: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamLibraryItems() {
    return _firestore.collection('library_items').snapshots();
  }

  Future<void> upsertLibraryItem(LibraryItemModel item) async {
    try {
      await _firestore.collection('library_items').doc(item.id).set(
        item.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore upsert library item error: $e');
    }
  }

  Future<void> deleteLibraryItem(String itemId) async {
    try {
      await _firestore.collection('library_items').doc(itemId).delete();
    } catch (e) {
      debugPrint('Firestore delete library item error: $e');
    }
  }

  // ===========================================================================
  // 9. ANNOUNCEMENTS, BROADCASTS & VOLUNTEER APPLICATIONS
  // ===========================================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAnnouncements() {
    return _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> createAnnouncement({
    required String title,
    required String content,
    required String authorName,
    required String category,
    String? imageUrl,
    bool isUrgent = false,
  }) async {
    try {
      await _firestore.collection('announcements').add({
        'title': title,
        'content': content,
        'authorName': authorName,
        'category': category,
        'imageUrl': imageUrl,
        'isUrgent': isUrgent,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore create announcement error: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamDepartmentBroadcasts() {
    return _firestore.collection('department_broadcasts').snapshots();
  }

  Future<void> upsertDepartmentBroadcast(DepartmentBroadcastMessageModel broadcast) async {
    try {
      await _firestore.collection('department_broadcasts').doc(broadcast.id).set(
        broadcast.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore upsert department broadcast error: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamDepartmentApplications() {
    return _firestore.collection('department_applications').snapshots();
  }

  Future<void> submitDepartmentApplication(VolunteerApplicationModel app) async {
    try {
      await _firestore.collection('department_applications').doc(app.id).set(
        app.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore submit department application error: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamDepartmentMembers() {
    return _firestore.collection('department_members').snapshots();
  }

  Future<void> upsertDepartmentMember(DepartmentMemberModel member) async {
    try {
      await _firestore.collection('department_members').doc(member.id).set(
        member.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore upsert department member error: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamFundraisingProposals() {
    return _firestore.collection('fundraising_proposals').snapshots();
  }

  Future<void> upsertFundraisingProposal(FundraisingProposalModel proposal) async {
    try {
      await _firestore.collection('fundraising_proposals').doc(proposal.id).set(
        proposal.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore upsert fundraising proposal error: $e');
    }
  }

  // ===========================================================================
  // 10. TRIVIA & QUIZ ATTEMPTS
  // ===========================================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> streamTriviaLeaderboard() {
    return _firestore
        .collection('trivia_scores')
        .orderBy('totalScore', descending: true)
        .limit(50)
        .snapshots();
  }

  Future<void> submitQuizScore({
    required String studentUid,
    required String studentName,
    required String quizId,
    required int score,
    required int maxScore,
  }) async {
    try {
      final scoreDoc = _firestore.collection('trivia_scores').doc(studentUid);
      final doc = await scoreDoc.get();

      if (doc.exists) {
        await scoreDoc.update({
          'studentName': studentName,
          'totalScore': FieldValue.increment(score),
          'quizzesCompleted': FieldValue.increment(1),
          'lastActive': FieldValue.serverTimestamp(),
        });
      } else {
        await scoreDoc.set({
          'studentUid': studentUid,
          'studentName': studentName,
          'totalScore': score,
          'quizzesCompleted': 1,
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Firestore submit quiz score error: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamQuizAttempts() {
    return _firestore.collection('quiz_attempts').snapshots();
  }

  Future<void> recordQuizAttempt(QuizAttemptModel attempt) async {
    try {
      await _firestore.collection('quiz_attempts').doc(attempt.id).set(
        attempt.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore record quiz attempt error: $e');
    }
  }

  // ===========================================================================
  // 11. BULK DATABASE SEEDER (ALL 20+ COLLECTIONS)
  // ===========================================================================

  Future<int> seedCompleteDatabase({
    required List<UserModel> students,
    required List<UserModel> pendingApprovals,
    required List<FamilyModel> families,
    required List<PilgrimageTripModel> pilgrimageTrips,
    required List<TripRegistrationModel> tripRegistrations,
    required List<LibraryItemModel> libraryItems,
    required List<ChurchProgramModel> programs,
    required List<DepartmentBroadcastMessageModel> broadcasts,
    required List<FundraisingProposalModel> proposals,
    required List<VolunteerApplicationModel> applications,
    required List<DepartmentMemberModel> members,
    required List<ConfessorFatherModel> confessors,
    required List<ConfessionAppointmentModel> appointments,
    required List<AnonymousSpiritualQuestionModel> questions,
    required List<CharityCampaignModel> campaigns,
    required List<DuesPaymentModel> dues,
    required List<CharityDisbursementModel> disbursements,
    required List<EmergencyAidRequestModel> aidRequests,
    required List<AcademicMentorModel> mentors,
    required List<MentorshipRequestModel> mentorshipRequests,
    required List<QuizAttemptModel> quizAttempts,
    List<TriviaQuizModel> triviaQuizzes = const [],
    required AttendanceSessionModel activeSession,
  }) async {
    int totalDocs = 0;
    try {
      // 1. Users
      for (final u in students) {
        await _firestore.collection('users').doc(u.id).set(u.toMap(), SetOptions(merge: true));
        totalDocs++;
      }
      for (final u in pendingApprovals) {
        await _firestore.collection('users').doc(u.id).set(u.toMap(), SetOptions(merge: true));
        totalDocs++;
      }

      // 2. Families
      for (final f in families) {
        await _firestore.collection('families').doc(f.id).set(f.toMap(), SetOptions(merge: true));
        totalDocs++;
      }
      await _firestore.collection('app_config').doc('family_roster').set({
        'isFamilyPublished': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Pilgrimage Trips
      for (final t in pilgrimageTrips) {
        await _firestore.collection('pilgrimage_trips').doc(t.id).set(t.toMap(), SetOptions(merge: true));
        totalDocs++;
      }

      // 4. Trip Registrations
      for (final r in tripRegistrations) {
        await _firestore.collection('trip_registrations').doc(r.id).set(r.toMap(), SetOptions(merge: true));
        totalDocs++;
      }

      // 5. Library Items
      for (final l in libraryItems) {
        await _firestore.collection('library_items').doc(l.id).set(l.toMap(), SetOptions(merge: true));
        totalDocs++;
      }

      // 6. Church Programs
      for (final p in programs) {
        await _firestore.collection('church_programs').doc(p.id).set(p.toMap(), SetOptions(merge: true));
        totalDocs++;
      }

      // 7. Department Broadcasts
      for (final b in broadcasts) {
        await _firestore.collection('department_broadcasts').doc(b.id).set(b.toMap(), SetOptions(merge: true));
        totalDocs++;
      }

      // 8. Fundraising Proposals
      for (final fp in proposals) {
        await _firestore.collection('fundraising_proposals').doc(fp.id).set(fp.toMap(), SetOptions(merge: true));
        totalDocs++;
      }

      // 9. Department Applications
      for (final app in applications) {
        await _firestore.collection('department_applications').doc(app.id).set(app.toMap(), SetOptions(merge: true));
        totalDocs++;
      }

      // 10. Department Members
      for (final m in members) {
        await _firestore.collection('department_members').doc(m.id).set(m.toMap(), SetOptions(merge: true));
        totalDocs++;
      }

      // 11. Confessors
      for (final cf in confessors) {
        await _firestore.collection('confessors').doc(cf.id).set(cf.toMap(), SetOptions(merge: true));
        totalDocs++;
      }

      // 12. Appointments
      for (final ca in appointments) {
        await _firestore.collection('confession_appointments').doc(ca.id).set(ca.toMap(), SetOptions(merge: true));
        totalDocs++;
      }

      // 13. Questions
      for (final sq in questions) {
        await _firestore.collection('spiritual_questions').doc(sq.id).set(sq.toMap(), SetOptions(merge: true));
        totalDocs++;
      }

      // 14. Campaigns
      for (final cc in campaigns) {
        await _firestore.collection('charity_campaigns').doc(cc.id).set(cc.toMap(), SetOptions(merge: true));
        totalDocs++;
      }

      // 15. Financial Dues
      for (final d in dues) {
        await _firestore.collection('financial_dues').doc(d.id).set(d.toMap(), SetOptions(merge: true));
        totalDocs++;
      }

      // 16. Disbursements
      for (final cd in disbursements) {
        await _firestore.collection('charity_disbursements').doc(cd.id).set(cd.toMap(), SetOptions(merge: true));
        totalDocs++;
      }

      // 17. Aid Requests
      for (final ear in aidRequests) {
        await _firestore.collection('emergency_aid_requests').doc(ear.id).set(ear.toMap(), SetOptions(merge: true));
        totalDocs++;
      }

      // 18. Mentors
      for (final am in mentors) {
        await _firestore.collection('academic_mentors').doc(am.id).set(am.toMap(), SetOptions(merge: true));
        totalDocs++;
      }

      // 19. Mentorship Requests
      for (final mr in mentorshipRequests) {
        await _firestore.collection('mentorship_requests').doc(mr.id).set(mr.toMap(), SetOptions(merge: true));
        totalDocs++;
      }

      // 20. Quiz Attempts
      for (final qa in quizAttempts) {
        await _firestore.collection('quiz_attempts').doc(qa.id).set(qa.toMap(), SetOptions(merge: true));
        totalDocs++;
      }

      // 20.1 Trivia Quizzes (Weekly Faith Challenges)
      for (final tq in triviaQuizzes) {
        await _firestore.collection('trivia_quizzes').doc(tq.id).set(tq.toMap(), SetOptions(merge: true));
        totalDocs++;
      }

      // 21. Active Attendance Session
      await _firestore.collection('attendance_sessions').doc(activeSession.sessionId).set(
        {
          'sessionId': activeSession.sessionId,
          'courseName': activeSession.courseName,
          'courseCode': activeSession.courseCode,
          'faculty': activeSession.faculty,
          'code': activeSession.code,
          'rollingPin': activeSession.rollingPin,
          'generatedAt': activeSession.generatedAt.toIso8601String(),
          'refreshIntervalSeconds': activeSession.refreshIntervalSeconds,
          'totalEnrolled': activeSession.totalEnrolled,
          'scans': activeSession.scans.map((s) => {
            'studentId': s.studentId,
            'studentName': s.studentName,
            'timestamp': s.timestamp.toIso8601String(),
            'status': s.status.name,
          }).toList(),
        },
        SetOptions(merge: true),
      );
      totalDocs++;

      debugPrint('Firestore bulk seeding complete! Total docs pushed: $totalDocs');
    } catch (e) {
      debugPrint('Firestore seedCompleteDatabase notice: $e');
    }
    return totalDocs;
  }
}
