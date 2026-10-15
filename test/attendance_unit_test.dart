import 'package:flutter_test/flutter_test.dart';
import 'package:wcu_orthodox/models/attendance_models.dart';

void main() {
  group('AttendanceRecordModel Unit Tests', () {
    test('AttendanceRecordModel correctly initializes and serializes to map', () {
      final now = DateTime(2025, 10, 15, 8, 30, 0);
      final record = AttendanceRecordModel(
        id: 'rec-001',
        studentId: 'stud-101',
        studentName: 'Abebe Bikila',
        timestamp: now,
        status: AttendanceStatus.present,
        method: AttendanceCheckInMethod.qr,
        courseName: 'Patristics 101',
      );

      expect(record.id, 'rec-001');
      expect(record.studentId, 'stud-101');
      expect(record.status, AttendanceStatus.present);
      expect(record.method, AttendanceCheckInMethod.qr);

      final map = record.toMap();
      expect(map['id'], 'rec-001');
      expect(map['studentId'], 'stud-101');
      expect(map['status'], 'present');
      expect(map['method'], 'qr');
      expect(map['courseName'], 'Patristics 101');
    });

    test('AttendanceRecordModel.fromMap correctly parses statuses and methods', () {
      final mapLate = {
        'studentId': 'stud-102',
        'studentName': 'Sara Jenkins',
        'status': 'late',
        'method': 'pin',
        'courseName': 'Church History',
        'timestamp': '2025-10-15T09:00:00.000',
      };
      final parsedLate = AttendanceRecordModel.fromMap(mapLate, 'rec-002');
      expect(parsedLate.status, AttendanceStatus.late);
      expect(parsedLate.method, AttendanceCheckInMethod.pin);
      expect(parsedLate.studentName, 'Sara Jenkins');

      final mapAbsent = {
        'studentId': 'stud-103',
        'status': 'absent',
      };
      final parsedAbsent = AttendanceRecordModel.fromMap(mapAbsent, 'rec-003');
      expect(parsedAbsent.status, AttendanceStatus.absent);
      expect(parsedAbsent.method, AttendanceCheckInMethod.qr); // default fallback
      expect(parsedAbsent.studentName, 'Fellowship Student'); // default fallback
    });
  });

  group('AttendanceSessionModel Unit Tests', () {
    test('AttendanceSessionModel counts present, late, and absent accurately', () {
      final now = DateTime(2025, 10, 15, 10, 0, 0);
      final scans = [
        AttendanceRecordModel(
          id: 's1',
          studentId: 'st1',
          studentName: 'Dawit',
          timestamp: now,
          status: AttendanceStatus.present,
          method: AttendanceCheckInMethod.qr,
          courseName: 'Dogma',
        ),
        AttendanceRecordModel(
          id: 's2',
          studentId: 'st2',
          studentName: 'Marta',
          timestamp: now,
          status: AttendanceStatus.present,
          method: AttendanceCheckInMethod.pin,
          courseName: 'Dogma',
        ),
        AttendanceRecordModel(
          id: 's3',
          studentId: 'st3',
          studentName: 'Yohannes',
          timestamp: now,
          status: AttendanceStatus.late,
          method: AttendanceCheckInMethod.qr,
          courseName: 'Dogma',
        ),
      ];

      final session = AttendanceSessionModel(
        sessionId: 'session-2025-01',
        courseName: 'Dogma & Orthodox Worship',
        courseCode: 'ORTH-101',
        faculty: 'Theology',
        code: 'ORTH-101-LIVE',
        rollingPin: '8492',
        generatedAt: now,
        totalEnrolled: 10,
        scans: scans,
        isActive: true,
      );

      expect(session.presentCount, 2);
      expect(session.lateCount, 1);
      expect(session.scans.length, 3);
      // 10 enrolled - 3 scanned = 7 absent
      expect(session.absentCount, 7);
    });

    test('AttendanceSessionModel clamps absentCount to non-negative even if scans exceed totalEnrolled', () {
      final now = DateTime.now();
      final scans = List.generate(
        15,
        (i) => AttendanceRecordModel(
          id: 's$i',
          studentId: 'st$i',
          studentName: 'Student $i',
          timestamp: now,
          status: AttendanceStatus.present,
          method: AttendanceCheckInMethod.qr,
          courseName: 'Liturgy',
        ),
      );

      final session = AttendanceSessionModel(
        sessionId: 'session-clamped',
        courseName: 'Liturgy',
        courseCode: 'ORTH-201',
        faculty: 'Theology',
        code: 'TEST',
        rollingPin: '1234',
        generatedAt: now,
        totalEnrolled: 10,
        scans: scans,
        isActive: true,
      );

      expect(session.presentCount, 15);
      expect(session.absentCount, 0); // clamped to 0, never negative
    });

    test('AttendanceSessionModel copyWith updates fields without mutating original', () {
      final now = DateTime.now();
      final session = AttendanceSessionModel(
        sessionId: 'sess-original',
        courseName: 'Original Course',
        courseCode: 'ORIG-101',
        faculty: 'Faculty',
        code: 'CODE-STANDBY',
        rollingPin: '----',
        generatedAt: now,
        isActive: false,
        isExpired: false,
      );

      final liveSession = session.copyWith(
        isActive: true,
        rollingPin: '7391',
        code: 'CODE-LIVE',
        expiresAt: now.add(const Duration(seconds: 30)),
      );

      expect(session.isActive, false);
      expect(session.rollingPin, '----');
      expect(liveSession.isActive, true);
      expect(liveSession.rollingPin, '7391');
      expect(liveSession.code, 'CODE-LIVE');
      expect(liveSession.sessionId, 'sess-original');
    });

    test('AttendanceSessionModel toMap and fromMap round-trip fidelity', () {
      final genTime = DateTime(2025, 5, 20, 14, 0, 0);
      final expTime = DateTime(2025, 5, 20, 14, 0, 30);
      final session = AttendanceSessionModel(
        sessionId: 'round-trip-01',
        courseName: 'Church Administration',
        courseCode: 'ADM-401',
        faculty: 'Leadership',
        code: 'ADM-LIVE-55',
        rollingPin: '5521',
        generatedAt: genTime,
        expiresAt: expTime,
        refreshIntervalSeconds: 30,
        totalEnrolled: 60,
        isActive: true,
        isExpired: false,
      );

      final map = session.toMap();
      expect(map['sessionId'], 'round-trip-01');
      expect(map['rollingPin'], '5521');
      expect(map['refreshIntervalSeconds'], 30);
      expect(map['totalEnrolled'], 60);

      final restored = AttendanceSessionModel.fromMap(map, 'round-trip-01');
      expect(restored.sessionId, 'round-trip-01');
      expect(restored.courseName, 'Church Administration');
      expect(restored.rollingPin, '5521');
      expect(restored.refreshIntervalSeconds, 30);
      expect(restored.totalEnrolled, 60);
      expect(restored.isActive, true);
    });
  });
}
