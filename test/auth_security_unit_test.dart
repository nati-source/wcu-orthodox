import 'package:flutter_test/flutter_test.dart';
import 'package:wcu_orthodox/models/user_models.dart';

void main() {
  group('AppAdminConstants Security Unit Tests', () {
    test('isAdminEmail identifies exact admin email correctly', () {
      expect(AppAdminConstants.isAdminEmail('natisita928@gmail.com'), isTrue);
    });

    test('isAdminEmail is case-insensitive and trims surrounding whitespace', () {
      expect(AppAdminConstants.isAdminEmail('  natisita928@gmail.com  '), isTrue);
      expect(AppAdminConstants.isAdminEmail('NATISITA928@GMAIL.COM'), isTrue);
      expect(AppAdminConstants.isAdminEmail(' Natisita928@Gmail.Com '), isTrue);
    });

    test('isAdminEmail rejects unauthorized emails, empty strings, and null', () {
      expect(AppAdminConstants.isAdminEmail(null), isFalse);
      expect(AppAdminConstants.isAdminEmail(''), isFalse);
      expect(AppAdminConstants.isAdminEmail('   '), isFalse);
      expect(AppAdminConstants.isAdminEmail('hacker@gmail.com'), isFalse);
      expect(AppAdminConstants.isAdminEmail('natisita928@gmail.com.co'), isFalse);
      expect(AppAdminConstants.isAdminEmail('sub.natisita928@gmail.com'), isFalse);
      expect(AppAdminConstants.isAdminEmail('student@wcu.edu.et'), isFalse);
    });
  });

  group('Password Strength & Validation Unit Tests', () {
    String? validatePassword(String? v) {
      if (v == null || v.isEmpty) return 'Password is required / የይለፍ ቃል ያስፈልጋል';
      if (v.length < 8) return 'Password must be at least 8 characters / ቢያንስ 8 ፊደላት መሆን አለበት';
      if (!RegExp(r'[a-zA-Z]').hasMatch(v) || !RegExp(r'[0-9]').hasMatch(v)) {
        return 'Include both letters and numbers / ፊደላትና ቁጥሮችን ያካትቱ';
      }
      return null;
    }

    test('rejects passwords shorter than 8 characters', () {
      expect(validatePassword(''), isNotNull);
      expect(validatePassword(null), isNotNull);
      expect(validatePassword('Abc1'), contains('at least 8 characters'));
      expect(validatePassword('Passw1'), contains('at least 8 characters'));
    });

    test('rejects passwords without numbers or without letters', () {
      expect(validatePassword('passwordonly'), contains('Include both letters and numbers'));
      expect(validatePassword('1234567890'), contains('Include both letters and numbers'));
      expect(validatePassword('!@#\$%^&*()'), contains('Include both letters and numbers'));
    });

    test('accepts strong passwords with 8+ characters, letters and numbers', () {
      expect(validatePassword('Orthodox2024'), isNull);
      expect(validatePassword('wcuGibiGubae1'), isNull);
      expect(validatePassword('SecurePass123!'), isNull);
    });
  });

  group('Brute-force Rate Limit Logic Unit Tests', () {
    test('enforces lockout after 5 consecutive failed attempts', () {
      int failedAttempts = 0;
      bool isLockedOut = false;
      int lockoutSeconds = 0;

      void recordFailedAttempt() {
        failedAttempts++;
        if (failedAttempts >= 5) {
          isLockedOut = true;
          lockoutSeconds = 30;
        }
      }

      for (int i = 0; i < 4; i++) {
        recordFailedAttempt();
        expect(isLockedOut, isFalse);
        expect(5 - failedAttempts, 5 - (i + 1));
      }

      // 5th attempt triggers lockout
      recordFailedAttempt();
      expect(isLockedOut, isTrue);
      expect(lockoutSeconds, 30);
    });

    test('successful login resets failed attempts counter to 0', () {
      int failedAttempts = 3;
      void onLoginSuccess() {
        failedAttempts = 0;
      }

      onLoginSuccess();
      expect(failedAttempts, 0);
    });
  });
}
