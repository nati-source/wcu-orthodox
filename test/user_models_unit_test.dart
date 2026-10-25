import 'package:flutter_test/flutter_test.dart';
import 'package:wcu_orthodox/models/user_models.dart';

void main() {
  group('UserRole Extension Unit Tests', () {
    test('displayName returns appropriate human-readable names for all roles', () {
      expect(UserRole.student.displayName, 'Student / Fellow');
      expect(UserRole.admin.displayName, 'Admin');
      expect(UserRole.spiritualParent.displayName, 'Spiritual Parent');
      expect(UserRole.volunteerCoordinator.displayName, 'Volunteer Coordinator');
    });

    test('badgeColor returns unique contrasting colors for each role', () {
      final studentColor = UserRole.student.badgeColor;
      final adminColor = UserRole.admin.badgeColor;
      final parentColor = UserRole.spiritualParent.badgeColor;
      final coordinatorColor = UserRole.volunteerCoordinator.badgeColor;

      expect(studentColor, isNotNull);
      expect(adminColor, isNotNull);
      expect(parentColor, isNotNull);
      expect(coordinatorColor, isNotNull);
      expect(studentColor != adminColor, isTrue);
      expect(adminColor != parentColor, isTrue);
    });
  });

  group('FellowshipDepartmentConstants Unit Tests', () {
    test('normalize correctly converts aliases and legacy uppercase keys to standard IDs', () {
      expect(
        FellowshipDepartmentConstants.normalize('DEPT_EDUCATION'),
        FellowshipDepartmentConstants.deptEducation,
      );
      expect(
        FellowshipDepartmentConstants.normalize('DEPT_MEMBER_CARE'),
        FellowshipDepartmentConstants.deptMemberCare,
      );
      expect(
        FellowshipDepartmentConstants.normalize('DEPT_CHOIR_ARTS'),
        FellowshipDepartmentConstants.deptChoirArts,
      );
      expect(
        FellowshipDepartmentConstants.normalize('DEPT_DEVELOPMENT'),
        FellowshipDepartmentConstants.deptDevelopment,
      );
      expect(
        FellowshipDepartmentConstants.normalize('DEPT_FINANCE_PROPERTY'),
        FellowshipDepartmentConstants.deptFinanceProperty,
      );
      expect(
        FellowshipDepartmentConstants.normalize('DEPT_BATCH_PROGRAMS'),
        FellowshipDepartmentConstants.deptBatchPrograms,
      );
      expect(
        FellowshipDepartmentConstants.normalize('DEPT_CHARITY'),
        FellowshipDepartmentConstants.deptCharity,
      );
      expect(
        FellowshipDepartmentConstants.normalize('DEPT_SPECIAL_NEEDS'),
        FellowshipDepartmentConstants.deptSpecialNeeds,
      );
      expect(
        FellowshipDepartmentConstants.normalize('DEPT_PLANNING'),
        FellowshipDepartmentConstants.deptPlanning,
      );
      expect(
        FellowshipDepartmentConstants.normalize('DEPT_AUDIT'),
        FellowshipDepartmentConstants.deptAudit,
      );
    });

    test('all 11 departments have both English and Amharic titles defined', () {
      expect(FellowshipDepartmentConstants.allDepartmentIds.length, 11);
      for (final id in FellowshipDepartmentConstants.allDepartmentIds) {
        expect(FellowshipDepartmentConstants.amharicNames[id], isNotNull);
        expect(FellowshipDepartmentConstants.amharicNames[id]!.isNotEmpty, isTrue);
        expect(FellowshipDepartmentConstants.englishNames[id], isNotNull);
        expect(FellowshipDepartmentConstants.englishNames[id]!.isNotEmpty, isTrue);
      }
    });

    test('separate Mezmur and Sacred Arts department constants and helpers', () {
      expect(FellowshipDepartmentConstants.deptChoir, 'dept-mezmur');
      expect(FellowshipDepartmentConstants.deptSacredArts, 'dept-arts');
      expect(FellowshipDepartmentConstants.deptChoirArts, 'dept-music');

      expect(FellowshipDepartmentConstants.isLegacyCombinedMusicScope('dept-music'), isTrue);
      expect(FellowshipDepartmentConstants.isLegacyCombinedMusicScope('dept-mezmur'), isFalse);
      expect(FellowshipDepartmentConstants.isLegacyCombinedMusicScope('dept-arts'), isFalse);

      expect(FellowshipDepartmentConstants.isAuditScope('dept-audit'), isTrue);
      expect(FellowshipDepartmentConstants.isAuditScope('dept-mezmur'), isFalse);

      expect(
        FellowshipDepartmentConstants.formatCoordinatorScope('dept-mezmur'),
        contains('Mezmur / Choir'),
      );
      expect(
        FellowshipDepartmentConstants.formatCoordinatorScope('dept-arts'),
        contains('Sacred Arts'),
      );
    });
  });

  group('UserModel Gender Inference Unit Tests', () {
    test('inferGender detects female from English names', () {
      expect(UserModel.inferGender('Martha Yohannes', 'Wolete Selassie'), 'female');
      expect(UserModel.inferGender('Selamawit Bekele', ''), 'female');
      expect(UserModel.inferGender('Sara Abraham', ''), 'female');
      expect(UserModel.inferGender('Bethlehem Tadesse', ''), 'female');
      expect(UserModel.inferGender('Eden Hailu', ''), 'female');
    });

    test('inferGender detects female from Ge\'ez/Amharic names and baptismal names', () {
      expect(UserModel.inferGender('ማርታ ተስፋዬ', ''), 'female');
      expect(UserModel.inferGender('Student', 'ወለተ ማርያም'), 'female');
      expect(UserModel.inferGender('Unknown', 'ወለተ ጊዮርጊስ'), 'female');
      expect(UserModel.inferGender('Unknown', 'እኅተ ማርያም'), 'female');
      expect(UserModel.inferGender('Unknown', 'አመተ ማርያም'), 'female');
      expect(UserModel.inferGender('Unknown', 'ኪዳነ ወለተ'), 'female');
    });

    test('inferGender detects male from male baptismal prefixes and names', () {
      expect(UserModel.inferGender('Abebe Bikila', 'Gebre Maryam'), 'male');
      expect(UserModel.inferGender('Unknown', 'ኃይለ ሚካኤል'), 'male');
      expect(UserModel.inferGender('Unknown', 'ተክለ ሃይማኖት'), 'male');
      expect(UserModel.inferGender('Unknown', 'ወልደ ገብርኤል'), 'male');
      expect(UserModel.inferGender('Unknown', 'ኪዳነ ማርያም'), 'male');
    });

    test('inferGender defaults to male when name is unrecognized or generic', () {
      expect(UserModel.inferGender('Anonymous Fellow', 'Unknown'), 'male');
    });
  });

  group('UserModel Serialization & Server-Managed Role Unit Tests', () {
    test('UserModel.fromMap strictly respects server-managed roles without client-side email escalation', () {
      final map = {
        'email': 'natnaeltedla25@gmail.com',
        'name': 'Natnael',
        'role': 'student', // server role in DB
        'isApproved': false,
      };

      final user = UserModel.fromMap(map, 'user-01');
      expect(user.role, UserRole.student);
      expect(user.isApproved, false);
      expect(user.fullName, 'Natnael');
    });

    test('UserModel.fromMap respects non-admin student properties', () {
      final map = {
        'email': 'student@wcu.edu.et',
        'fullName': 'Yared Shiferaw',
        'baptismalName': 'Gebre Medhin',
        'role': 'student',
        'isApproved': true,
        'department': 'Software Engineering',
        'academicYear': 3,
        'batchYear': '2023',
      };

      final user = UserModel.fromMap(map, 'stud-001');
      expect(user.id, 'stud-001');
      expect(user.role, UserRole.student);
      expect(user.isApproved, true);
      expect(user.department, 'Software Engineering');
      expect(user.academicYear, 3);
      expect(user.gender, 'male');
    });

    test('UserModel copyWith accurately alters specified attributes', () {
      final user = UserModel(
        id: 'u-1',
        fullName: 'Initial Name',
        baptismalName: 'Initial Bap',
        phoneNumber: '0911000000',
        batchYear: '2024',
        department: 'CS',
        academicYear: 2,
        role: UserRole.student,
        isApproved: false,
      );

      final updated = user.copyWith(
        fullName: 'Updated Name',
        isApproved: true,
        academicYear: 3,
      );

      expect(updated.id, 'u-1');
      expect(updated.fullName, 'Updated Name');
      expect(updated.isApproved, true);
      expect(updated.academicYear, 3);
      expect(user.fullName, 'Initial Name'); // original immutable
      expect(user.isApproved, false);
    });

    test('UserModel.fromMap flexibly handles bool, string and int for isApproved', () {
      final userBool = UserModel.fromMap({'fullName': 'Student A', 'isApproved': true}, 'id-1');
      expect(userBool.isApproved, true);

      final userString = UserModel.fromMap({'fullName': 'Student B', 'isApproved': 'true'}, 'id-2');
      expect(userString.isApproved, true);

      final userStringCaps = UserModel.fromMap({'fullName': 'Student C', 'isApproved': 'True'}, 'id-3');
      expect(userStringCaps.isApproved, true);

      final userInt = UserModel.fromMap({'fullName': 'Student D', 'isApproved': 1}, 'id-4');
      expect(userInt.isApproved, true);

      final userFalse = UserModel.fromMap({'fullName': 'Student E', 'isApproved': false}, 'id-5');
      expect(userFalse.isApproved, false);

      final userFalseStr = UserModel.fromMap({'fullName': 'Student F', 'isApproved': 'false'}, 'id-6');
      expect(userFalseStr.isApproved, false);

      final userNull = UserModel.fromMap({'fullName': 'Student G'}, 'id-7');
      expect(userNull.isApproved, false);
    });
  });
}
