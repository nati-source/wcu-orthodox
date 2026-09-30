part of 'fellowship_state.dart';

/// Feature slice managing Spiritual Families, Siblings, and Smart Cohort Matching.
class FamilyState extends ChangeNotifier {
  final FellowshipState root; FamilyState(this.root);
  void refresh() => notifyListeners();
}

mixin FamilyStateMixin on ChangeNotifier {
  FirestoreService get _firestoreService;
  UserModel get _currentUser;
  set _currentUser(UserModel value);
  List<UserModel> get _allStudents;
  set _allStudents(List<UserModel> value);
  bool get canManageFamilies;
  void broadcastEmergency({required String title, required String description, String churchName, String category});

  // ----------------------------------------------------
  // DOMAIN 2: ORTHODOX FAMILY NETWORK
  // ----------------------------------------------------
  List<FamilyModel> _families = [];
  bool _isFamilyPublished = true; // Staged vs Published
  bool _isMatchingRunning = false;

  List<FamilyModel> get families => List.unmodifiable(_families);
  bool get isFamilyPublished => _isFamilyPublished;
  bool get isMatchingRunning => _isMatchingRunning;

  FamilyModel? get currentStudentFamily {
    final famId = _currentUser.assignedFamilyId;
    if (famId != null && famId.isNotEmpty) {
      try {
        return _families.firstWhere((f) => f.id == famId);
      } catch (_) {}
    }
    // Check if the current user ID is listed in any family's memberIds
    try {
      return _families.firstWhere((f) => f.memberIds.contains(_currentUser.id));
    } catch (_) {}

    // Check if current user is spiritual father or mother
    try {
      return _families.firstWhere((f) =>
          f.spiritualFather.id == _currentUser.id ||
          f.spiritualMother.id == _currentUser.id ||
          (f.spiritualFather.fullName.trim().isNotEmpty &&
              f.spiritualFather.fullName.trim().toLowerCase() == _currentUser.fullName.trim().toLowerCase()) ||
          (f.spiritualMother.fullName.trim().isNotEmpty &&
              f.spiritualMother.fullName.trim().toLowerCase() == _currentUser.fullName.trim().toLowerCase()));
    } catch (_) {}

    // Check if any student in allStudents with matching name or phone belongs to a family
    final matchedStudents = _allStudents.where((s) =>
        s.id == _currentUser.id ||
        (s.fullName.trim().isNotEmpty && s.fullName.trim().toLowerCase() == _currentUser.fullName.trim().toLowerCase()) ||
        (s.phoneNumber.isNotEmpty && s.phoneNumber == _currentUser.phoneNumber));
    for (final s in matchedStudents) {
      if (s.assignedFamilyId != null && s.assignedFamilyId!.isNotEmpty) {
        try {
          return _families.firstWhere((f) => f.id == s.assignedFamilyId);
        } catch (_) {}
      }
      try {
        return _families.firstWhere((f) => f.memberIds.contains(s.id));
      } catch (_) {}
    }

    // Do NOT default to _families.first! Unassigned students must show as unassigned
    return null;
  }

  List<UserModel> get currentFamilySiblings {
    final fam = currentStudentFamily;
    if (fam == null) return [];
    return _allStudents.where((s) {
      // Must be regular student, not coordinator/admin/spiritual parent
      if (s.role != UserRole.student) return false;
      // Do not include the current user
      if (s.id == _currentUser.id ||
          (s.fullName.trim().isNotEmpty &&
              s.fullName.trim().toLowerCase() == _currentUser.fullName.trim().toLowerCase())) {
        return false;
      }
      // Do not include spiritual parents
      if (s.id == fam.spiritualFather.id || s.id == fam.spiritualMother.id) {
        return false;
      }
      // Strict group boundary: If student has an assignedFamilyId, it MUST match this family!
      if (s.assignedFamilyId != null && s.assignedFamilyId!.isNotEmpty) {
        return s.assignedFamilyId == fam.id;
      }
      // Fallback only if no assignedFamilyId is set anywhere
      return fam.memberIds.contains(s.id);
    }).toList();
  }

  /// Returns the spiritual children assigned to this spiritual parent's family
  List<UserModel> get spiritualChildren {
    final fam = currentStudentFamily;
    if (fam == null) return [];
    return _allStudents.where((s) {
      if (s.role != UserRole.student) return false;
      if (s.id == _currentUser.id ||
          (s.fullName.trim().isNotEmpty &&
              s.fullName.trim().toLowerCase() == _currentUser.fullName.trim().toLowerCase())) {
        return false;
      }
      if (s.id == fam.spiritualFather.id || s.id == fam.spiritualMother.id) {
        return false;
      }
      if (s.assignedFamilyId != null && s.assignedFamilyId!.isNotEmpty) {
        return s.assignedFamilyId == fam.id;
      }
      return fam.memberIds.contains(s.id);
    }).toList();
  }

  void setFamilyPublished(bool published) {
    if (!canManageFamilies) return;
    _isFamilyPublished = published;
    _families = _families.map((f) => f.copyWith(isPublished: published)).toList();
    notifyListeners();
  }

  Future<void> runSmartMatching() async {
    if (!canManageFamilies) return;
    _isMatchingRunning = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1400));

    // 1. Identify all Spiritual Parents assigned in Role Assignments / Database
    final assignedParents = _allStudents.where((u) => u.role == UserRole.spiritualParent).toList();

    List<FamilyModel> activeFamilies = List<FamilyModel>.from(_families);

    final patronNames = [
      'Family of St. George (የቅዱስ ጊዮርጊስ ቤተሰብ)',
      'Family of St. Teklehaimanot (የአቡነ ተክለ ሃይማኖት ቤተሰብ)',
      'Family of St. Mary (የቅድስት ድንግል ማርያም ቤተሰብ)',
      'Family of St. Michael (የቅዱስ ሚካኤል ቤተሰብ)',
      'Family of St. Gabriel (የቅዱስ ገብርኤል ቤተሰብ)',
      'Family of St. Yared (የቅዱስ ያሬድ ቤተሰብ)',
    ];

    if (assignedParents.isNotEmpty) {
      // Partition strictly by gender so Father is ALWAYS Male and Mother is ALWAYS Female
      final List<UserModel> maleParents = assignedParents.where((u) => u.gender.toLowerCase() == 'male').toList();
      final List<UserModel> femaleParents = assignedParents.where((u) => u.gender.toLowerCase() == 'female').toList();

      int familyCount = maleParents.length > femaleParents.length ? maleParents.length : femaleParents.length;
      if (familyCount == 0) familyCount = (assignedParents.length / 2).ceil();
      if (familyCount < 1) familyCount = 1;

      final List<FamilyModel> dynamicFamilies = [];
      for (int i = 0; i < familyCount; i++) {
        final famId = 'fam-sp-${i + 1}';
        final famName = (i < patronNames.length) ? patronNames[i] : 'Orthodox Fellowship Family ${i + 1}';

        // Preserve existing Telegram invite URL if already customized
        String existingTelegram = 'https://t.me/WCU_Fellowship_Family';
        final oldFamIdx = _families.indexWhere((f) => f.id == famId || f.name == famName);
        if (oldFamIdx >= 0) {
          existingTelegram = _families[oldFamIdx].telegramGroupUrl;
        }

        // ♂ Spiritual Father (Always Male)
        final SpiritualParentModel fatherModel;
        if (i < maleParents.length) {
          final pMale = maleParents[i];
          fatherModel = SpiritualParentModel(
            id: pMale.id,
            fullName: pMale.fullName,
            baptismalName: pMale.baptismalName.isNotEmpty ? pMale.baptismalName : pMale.fullName,
            department: pMale.department,
            faculty: pMale.department,
            phoneNumber: pMale.phoneNumber,
            roleTitle: 'Spiritual Father (መንፈሳዊ አባት)',
            gender: 'male',
          );
          _updateStudentFamilyId(pMale.id, famId);
        } else {
          fatherModel = SpiritualParentModel(
            id: 'sp-father-mentor-${i + 1}',
            fullName: 'Senior Fellowship Father (አባት)',
            baptismalName: 'Gebre Kristos',
            department: 'Theology & Apostolic Ministry',
            faculty: 'Theology',
            phoneNumber: '+251911001122',
            roleTitle: 'Spiritual Father (መንፈሳዊ አባት)',
            gender: 'male',
          );
        }

        // ♀ Spiritual Mother (Always Female)
        final SpiritualParentModel motherModel;
        if (i < femaleParents.length) {
          final pFemale = femaleParents[i];
          motherModel = SpiritualParentModel(
            id: pFemale.id,
            fullName: pFemale.fullName,
            baptismalName: pFemale.baptismalName.isNotEmpty ? pFemale.baptismalName : pFemale.fullName,
            department: pFemale.department,
            faculty: pFemale.department,
            phoneNumber: pFemale.phoneNumber,
            roleTitle: 'Spiritual Mother (መንፈሳዊት እናት)',
            gender: 'female',
          );
          _updateStudentFamilyId(pFemale.id, famId);
        } else {
          motherModel = SpiritualParentModel(
            id: 'sp-mother-mentor-${i + 1}',
            fullName: 'Senior Fellowship Mother (እናት)',
            baptismalName: 'Walata Maryam',
            department: 'Member Care & Counseling',
            faculty: 'Counseling',
            phoneNumber: '+251922003344',
            roleTitle: 'Spiritual Mother (መንፈሳዊት እናት)',
            gender: 'female',
          );
        }

        dynamicFamilies.add(
          FamilyModel(
            id: famId,
            name: famName,
            formedDate: 'Active 2026',
            spiritualFather: fatherModel,
            spiritualMother: motherModel,
            maxCapacity: 12,
            telegramGroupUrl: existingTelegram,
            whatsappGroupUrl: '',
            isPublished: _isFamilyPublished,
            memberIds: [],
          ),
        );
      }
      activeFamilies = dynamicFamilies;
    } else {
      // Default: Reset member rosters on standard families
      activeFamilies = activeFamilies.map((f) => f.copyWith(memberIds: [])).toList();
    }

    // 2. Identify regular students (children) to be matched
    final childrenToMatch = _allStudents.where((u) => u.role == UserRole.student).toList();

    // 3. Department Cohort Grouping: Group children by department so peers stay together
    final Map<String, List<UserModel>> departmentBuckets = {};
    for (final child in childrenToMatch) {
      final deptKey = child.department.trim().isNotEmpty ? child.department.trim() : 'General';
      departmentBuckets.putIfAbsent(deptKey, () => []).add(child);
    }

    // Helper: Map department to broader faculty cluster
    String getFacultyCluster(String department) {
      final d = department.toLowerCase();
      if (d.contains('computer') || d.contains('information') || d.contains('software') || d.contains('tech')) {
        return 'Informatics';
      }
      if (d.contains('medicine') || d.contains('pharmacy') || d.contains('nursing') || d.contains('health') || d.contains('medical')) {
        return 'HealthSciences';
      }
      if (d.contains('engineer') || d.contains('civil') || d.contains('electrical') || d.contains('mechanical') || d.contains('architect')) {
        return 'Engineering';
      }
      if (d.contains('account') || d.contains('economic') || d.contains('business') || d.contains('management') || d.contains('finance')) {
        return 'Business';
      }
      if (d.contains('law') || d.contains('governance') || d.contains('social')) {
        return 'Law';
      }
      if (d.contains('agricult') || d.contains('horticult') || d.contains('plant') || d.contains('animal') || d.contains('forestry')) {
        return 'Agriculture';
      }
      return 'NaturalSciences';
    }

    // Helper: Calculate affinity between a family and a department
    int calculateAffinity(FamilyModel fam, String department) {
      final cluster = getFacultyCluster(department);
      final fatherCluster = getFacultyCluster(fam.spiritualFather.department);
      final motherCluster = getFacultyCluster(fam.spiritualMother.department);

      // Exact department match with Spiritual Father or Mother
      if (fam.spiritualFather.department.trim().toLowerCase() == department.toLowerCase() ||
          fam.spiritualMother.department.trim().toLowerCase() == department.toLowerCase()) {
        return 100;
      }
      // Faculty cluster match
      if (fatherCluster == cluster || motherCluster == cluster) {
        return 50;
      }
      return 0;
    }

    final Map<String, String> studentFamilyMap = {};

    // 4. Assign department cohorts together to the best matching family
    for (final entry in departmentBuckets.entries) {
      final deptName = entry.key;
      final deptStudents = entry.value;

      if (activeFamilies.isEmpty) break;

      // Sort families by affinity to this department first, then by least members
      activeFamilies.sort((a, b) {
        final affA = calculateAffinity(a, deptName);
        final affB = calculateAffinity(b, deptName);
        if (affA != affB) {
          return affB.compareTo(affA); // Higher affinity first
        }
        return a.memberIds.length.compareTo(b.memberIds.length); // Balance family sizes
      });

      // Target the top affinity family that has capacity
      FamilyModel targetFamily = activeFamilies.firstWhere(
        (f) => f.memberIds.length + deptStudents.length <= f.maxCapacity,
        orElse: () => activeFamilies.firstWhere(
          (f) => f.memberIds.length < f.maxCapacity,
          orElse: () => activeFamilies.first,
        ),
      );

      // Place ALL students of this department cohort TOGETHER into the target family
      for (final student in deptStudents) {
        if (targetFamily.memberIds.length >= targetFamily.maxCapacity && activeFamilies.length > 1) {
          // If family strictly overflows, pick next available family
          final nextFam = activeFamilies.firstWhere(
            (f) => f.id != targetFamily.id && f.memberIds.length < f.maxCapacity,
            orElse: () => targetFamily,
          );
          nextFam.memberIds.add(student.id);
          studentFamilyMap[student.id] = nextFam.id;
        } else {
          targetFamily.memberIds.add(student.id);
          studentFamilyMap[student.id] = targetFamily.id;
        }
      }
    }

    // 5. Synchronize assignedFamilyId on all students and currentUser
    _allStudents = _allStudents.map((s) {
      if (studentFamilyMap.containsKey(s.id)) {
        return s.copyWith(assignedFamilyId: studentFamilyMap[s.id]);
      }
      return s;
    }).toList();

    if (studentFamilyMap.containsKey(_currentUser.id)) {
      _currentUser = _currentUser.copyWith(assignedFamilyId: studentFamilyMap[_currentUser.id]);
    }

    _families = activeFamilies;
    _isMatchingRunning = false;
    notifyListeners();

    // 5. Asynchronously persist family matching assignments to Firestore
    try {
      for (final fam in _families) {
        _firestoreService.upsertFamily(fam).catchError((_) {});
      }
      for (final entry in studentFamilyMap.entries) {
        _firestoreService.updateUserFamilyAssignment(entry.key, entry.value).catchError((_) {});
      }
    } catch (_) {
      // Offline fallback
    }
  }

  void swapStudentsBetweenFamilies({
    required String studentAId,
    required String familyAId,
    required String studentBId,
    required String familyBId,
  }) {
    final famAIndex = _families.indexWhere((f) => f.id == familyAId);
    final famBIndex = _families.indexWhere((f) => f.id == familyBId);

    if (famAIndex != -1 && famBIndex != -1) {
      final famA = _families[famAIndex];
      final famB = _families[famBIndex];

      final membersA = List<String>.from(famA.memberIds);
      final membersB = List<String>.from(famB.memberIds);

      membersA.remove(studentAId);
      membersA.add(studentBId);

      membersB.remove(studentBId);
      membersB.add(studentAId);

      final updatedFamA = famA.copyWith(memberIds: membersA);
      final updatedFamB = famB.copyWith(memberIds: membersB);

      _families[famAIndex] = updatedFamA;
      _families[famBIndex] = updatedFamB;

      // Update student assigned family id
      _updateStudentFamilyId(studentAId, familyBId);
      _updateStudentFamilyId(studentBId, familyAId);

      notifyListeners();

      // Persist to Cloud Firestore with full family and student models
      try {
        _firestoreService.upsertFamily(updatedFamA).catchError((_) {});
        _firestoreService.upsertFamily(updatedFamB).catchError((_) {});
        _firestoreService.updateUserFamilyAssignment(studentAId, familyBId).catchError((_) {});
        _firestoreService.updateUserFamilyAssignment(studentBId, familyAId).catchError((_) {});
      } catch (e) {
        debugPrint('Firestore swap students notice: $e');
      }
    }
  }

  void assignStudentToFamily(String studentId, String targetFamilyId) {
    for (int i = 0; i < _families.length; i++) {
      if (_families[i].id == targetFamilyId) {
        if (!_families[i].memberIds.contains(studentId)) {
          final updated = List<String>.from(_families[i].memberIds)..add(studentId);
          _families[i] = _families[i].copyWith(memberIds: updated);
        }
      } else {
        if (_families[i].memberIds.contains(studentId)) {
          final updated = List<String>.from(_families[i].memberIds)..remove(studentId);
          _families[i] = _families[i].copyWith(memberIds: updated);
        }
      }
    }
    _updateStudentFamilyId(studentId, targetFamilyId);
    notifyListeners();

    try {
      _firestoreService.updateUserFamilyAssignment(studentId, targetFamilyId).catchError((_) {});
      for (final fam in _families) {
        _firestoreService.upsertFamily(fam).catchError((_) {});
      }
    } catch (e) {
      debugPrint('Firestore assignStudentToFamily notice: $e');
    }
  }

  void _updateStudentFamilyId(String studentId, String newFamilyId) {
    final index = _allStudents.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      _allStudents[index] = _allStudents[index].copyWith(assignedFamilyId: newFamilyId);
      if (_currentUser.id == studentId) {
        _currentUser = _currentUser.copyWith(assignedFamilyId: newFamilyId);
      }
    }
  }

  void publishAndBroadcastFamilies() {
    if (!canManageFamilies) return;
    _isFamilyPublished = true;
    _families = _families.map((f) => f.copyWith(isPublished: true)).toList();
    broadcastEmergency(
      title: 'Family Roster Released!',
      description: 'Your spiritual family assignment and Spiritual Parents contact cards are now live. Connect with your family group chat!',
      category: 'Fellowship Family',
    );
    notifyListeners();

    try {
      _firestoreService.publishFamiliesRoster(true);
    } catch (e) {
      debugPrint('Firestore publish families roster notice: $e');
    }
  }

}


