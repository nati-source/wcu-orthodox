import 'package:flutter_test/flutter_test.dart';
import 'package:wcu_orthodox/models/family_models.dart';

void main() {
  group('SpiritualParentModel Unit Tests', () {
    test('isFather and isMother correctly classify based on roleTitle and gender', () {
      final father = SpiritualParentModel(
        id: 'sp-1',
        fullName: 'Yared Teshome',
        baptismalName: 'Gebre Mikael',
        department: 'Theology',
        faculty: 'Theology',
        phoneNumber: '0911000001',
        roleTitle: 'Spiritual Father',
      );

      final mother = SpiritualParentModel(
        id: 'sp-2',
        fullName: 'Hanna Daniel',
        baptismalName: 'Wolete Selassie',
        department: 'Health Sciences',
        faculty: 'Medicine',
        phoneNumber: '0911000002',
        roleTitle: 'Spiritual Mother',
      );

      expect(father.isFather, isTrue);
      expect(father.isMother, isFalse);
      expect(father.gender, 'male');

      expect(mother.isMother, isTrue);
      expect(mother.isFather, isFalse);
      expect(mother.gender, 'female');
    });

    test('SpiritualParentModel serialization round trip', () {
      final parent = SpiritualParentModel(
        id: 'sp-3',
        fullName: 'Martha Bekele',
        baptismalName: 'Wolete Petros',
        department: 'Computer Science',
        faculty: 'Informatics',
        phoneNumber: '0912345678',
        roleTitle: 'Spiritual Mother (የመንፈስ እናት)',
      );

      final map = parent.toMap();
      expect(map['fullName'], 'Martha Bekele');
      expect(map['gender'], 'female');

      final reconstructed = SpiritualParentModel.fromMap(map, 'sp-3');
      expect(reconstructed.id, 'sp-3');
      expect(reconstructed.fullName, 'Martha Bekele');
      expect(reconstructed.isMother, isTrue);
    });
  });

  group('FamilyModel Unit Tests', () {
    test('FamilyModel memberCount accurately calculates list length', () {
      final father = SpiritualParentModel(
        id: 'f1',
        fullName: 'Father 1',
        baptismalName: 'Bap 1',
        department: 'Dept',
        faculty: 'Fac',
        phoneNumber: '0911',
        roleTitle: 'Spiritual Father',
      );
      final mother = SpiritualParentModel(
        id: 'm1',
        fullName: 'Mother 1',
        baptismalName: 'Bap 2',
        department: 'Dept',
        faculty: 'Fac',
        phoneNumber: '0922',
        roleTitle: 'Spiritual Mother',
      );

      final family = FamilyModel(
        id: 'fam-01',
        name: 'Family of St. Teklehaimanot',
        formedDate: '2025 E.C.',
        spiritualFather: father,
        spiritualMother: mother,
        maxCapacity: 12,
        telegramGroupUrl: 'https://t.me/st_tekle',
        whatsappGroupUrl: '',
        memberIds: ['m-01', 'm-02', 'm-03', 'm-04'],
      );

      expect(family.memberCount, 4);
      expect(family.maxCapacity, 12);
      expect(family.name, 'Family of St. Teklehaimanot');

      final updated = family.copyWith(
        memberIds: [...family.memberIds, 'm-05'],
      );
      expect(updated.memberCount, 5);
      expect(family.memberCount, 4); // original untouched
    });

    test('FamilyModel.fromMap handles string fallback parent names gracefully', () {
      final map = {
        'name': 'Family of Abba Samuel',
        'spiritualFatherName': 'Abba Samuel',
        'spiritualMotherName': 'Emebet Maryam',
        'memberIds': ['stud-1', 'stud-2'],
      };

      final family = FamilyModel.fromMap(map, 'fam-samuel');
      expect(family.id, 'fam-samuel');
      expect(family.name, 'Family of Abba Samuel');
      expect(family.spiritualFather.fullName, 'Abba Samuel');
      expect(family.spiritualMother.fullName, 'Emebet Maryam');
      expect(family.memberCount, 2);
    });
  });
}
