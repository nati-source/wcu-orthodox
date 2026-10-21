part of 'fellowship_state.dart';

class FamilyMatchingPreview {
  final List<FamilyModel> families;
  final Map<String, String> studentAssignments;
  final List<UserModel> unassignedStudents;
  final int eligibleStudentCount;
  final List<String> warnings;
  final String sourceSignature;

  FamilyMatchingPreview({
    required List<FamilyModel> families,
    required Map<String, String> studentAssignments,
    required List<UserModel> unassignedStudents,
    required this.eligibleStudentCount,
    required List<String> warnings,
    required this.sourceSignature,
  }) : families = List.unmodifiable(families),
       studentAssignments = Map.unmodifiable(studentAssignments),
       unassignedStudents = List.unmodifiable(unassignedStudents),
       warnings = List.unmodifiable(warnings);

  int get assignedStudentCount => studentAssignments.length;
  bool get canApply =>
      eligibleStudentCount > 0 &&
      unassignedStudents.isEmpty &&
      families.isNotEmpty &&
      warnings.every((warning) => !warning.startsWith('BLOCKER:'));
}

/// Feature slice managing Spiritual Families, Siblings, and Smart Cohort Matching.
class FamilyState extends ChangeNotifier {
  final FellowshipState root;
  FamilyState(this.root);
  void refresh() => notifyListeners();
}

mixin FamilyStateMixin on ChangeNotifier {
  FirestoreService get _firestoreService;
  UserModel get _currentUser;
  set _currentUser(UserModel value);
  List<UserModel> get _allStudents;
  set _allStudents(List<UserModel> value);
  bool get canManageFamilyMatching;

  // ----------------------------------------------------
  // DOMAIN 2: ORTHODOX FAMILY NETWORK
  // ----------------------------------------------------
  List<FamilyModel> _families = [];
  bool _isFamilyPublished = false;
  bool _isMatchingRunning = false;

  List<FamilyModel> get families => List.unmodifiable(_families);
  bool get isFamilyPublished => _isFamilyPublished;
  bool get isMatchingRunning => _isMatchingRunning;

  List<UserModel> get eligibleFamilyStudents => List.unmodifiable(
    _allStudents.where(
      (student) => student.role == UserRole.student && student.isApproved,
    ),
  );

  int get assignedFamilyStudentCount {
    final familyIds = _families.map((family) => family.id).toSet();
    return eligibleFamilyStudents
        .where(
          (student) =>
              student.assignedFamilyId != null &&
              familyIds.contains(student.assignedFamilyId) &&
              _families.any(
                (family) =>
                    family.id == student.assignedFamilyId &&
                    family.memberIds.contains(student.id),
              ),
        )
        .length;
  }

  int get unassignedFamilyStudentCount =>
      eligibleFamilyStudents.length - assignedFamilyStudentCount;

  bool get canPublishFamilyRoster {
    final students = eligibleFamilyStudents;
    if (students.isEmpty || _families.isEmpty) return false;

    final familyIds = _families.map((family) => family.id).toSet();
    if (familyIds.length != _families.length) return false;
    if (_families.any(
      (family) =>
          family.id.trim().isEmpty ||
          !_hasValidParentPair(family) ||
          family.maxCapacity <= 0 ||
          family.memberIds.length > family.maxCapacity ||
          family.memberIds.toSet().length != family.memberIds.length,
    )) {
      return false;
    }

    final studentIds = students.map((student) => student.id).toSet();
    final rosterIds = <String>[];
    for (final family in _families) {
      rosterIds.addAll(family.memberIds);
    }
    if (rosterIds.toSet().length != rosterIds.length ||
        rosterIds.any((id) => !studentIds.contains(id))) {
      return false;
    }

    for (final student in students) {
      final familyId = student.assignedFamilyId;
      if (familyId == null ||
          !familyIds.contains(familyId) ||
          !_families.any(
            (family) =>
                family.id == familyId && family.memberIds.contains(student.id),
          )) {
        return false;
      }
    }
    return rosterIds.length == students.length;
  }

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
      return _families.firstWhere(
        (f) =>
            f.spiritualFather.id == _currentUser.id ||
            f.spiritualMother.id == _currentUser.id,
      );
    } catch (_) {}

    // Check if current user belongs to a family by UID
    final currentStudent = _allStudents.firstWhere(
      (s) => s.id == _currentUser.id,
      orElse: () => _currentUser,
    );
    if (currentStudent.assignedFamilyId != null &&
        currentStudent.assignedFamilyId!.isNotEmpty) {
      try {
        return _families.firstWhere(
          (f) => f.id == currentStudent.assignedFamilyId,
        );
      } catch (_) {}
    }
    try {
      return _families.firstWhere(
        (f) => f.memberIds.contains(currentStudent.id),
      );
    } catch (_) {}

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
      if (s.id == _currentUser.id) {
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
      if (s.id == _currentUser.id) {
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

  Future<void> setFamilyPublished(bool published) async {
    if (!canManageFamilyMatching)
      throw StateError(
        'Only Admin or Member Care can publish the family roster.',
      );
    if (published && !canPublishFamilyRoster) {
      throw StateError(
        'Resolve unassigned students, invalid parent records, or capacity issues before publishing.',
      );
    }
    await _firestoreService.publishFamiliesRoster(published);
    _isFamilyPublished = published;
    _families = _families
        .map((family) => family.copyWith(isPublished: published))
        .toList();
    notifyListeners();
  }

  Future<FamilyMatchingPreview?> previewSmartMatching() async {
    if (!canManageFamilyMatching) return null;
    _isMatchingRunning = true;
    notifyListeners();
    try {
      await Future<void>.delayed(Duration.zero);
      return _buildFamilyMatchingPreview();
    } finally {
      _isMatchingRunning = false;
      notifyListeners();
    }
  }

  /// Backward-compatible convenience method for callers that explicitly want
  /// to create a draft immediately. The admin UI uses preview + confirmation.
  Future<FamilyMatchingPreview?> runSmartMatching() async {
    final preview = await previewSmartMatching();
    if (preview == null || !preview.canApply) return preview;
    await applySmartMatchingPreview(preview);
    return preview;
  }

  Future<void> applySmartMatchingPreview(FamilyMatchingPreview preview) async {
    if (!canManageFamilyMatching)
      throw StateError('Only Admin or Member Care can apply family matching.');
    final currentPlan = _buildFamilyMatchingPreview();
    if (preview.sourceSignature != currentPlan.sourceSignature) {
      throw StateError(
        'The student or family data changed. Run matching again to review an up-to-date plan.',
      );
    }
    if (!currentPlan.canApply) {
      throw StateError(
        currentPlan.warnings.isEmpty
            ? 'This matching plan is incomplete and cannot be saved.'
            : currentPlan.warnings.join('\n'),
      );
    }

    await _firestoreService.saveFamilyRosterDraft(
      families: currentPlan.families,
      studentAssignments: currentPlan.studentAssignments,
    );
    _installLocalFamilyDraft(
      currentPlan.families,
      currentPlan.studentAssignments,
    );
  }

  FamilyMatchingPreview _buildFamilyMatchingPreview() {
    final warnings = <String>[];
    final studentsById = <String, UserModel>{};
    var duplicateStudentIds = false;
    for (final student in _allStudents.where(
      (user) => user.role == UserRole.student && user.isApproved,
    )) {
      if (studentsById.containsKey(student.id)) {
        duplicateStudentIds = true;
      } else {
        studentsById[student.id] = student;
      }
    }
    if (duplicateStudentIds) {
      warnings.add(
        'BLOCKER: Duplicate student IDs were found in the loaded roster. Refresh the user list before matching.',
      );
    }

    final students = studentsById.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (students.isEmpty)
      warnings.add(
        'BLOCKER: There are no approved student accounts to assign.',
      );

    final proposedFamilies = _families
        .map(
          (family) => family.copyWith(memberIds: const [], isPublished: false),
        )
        .toList();
    final familyIds = proposedFamilies.map((family) => family.id).toSet();
    if (familyIds.length != proposedFamilies.length ||
        familyIds.any((id) => id.trim().isEmpty)) {
      warnings.add(
        'BLOCKER: Family records have duplicate or empty IDs. Fix the family records before matching.',
      );
    }

    final usableFamilies = proposedFamilies
        .where(
          (family) => _hasValidParentPair(family) && family.maxCapacity > 0,
        )
        .toList();
    final invalidFamilies = proposedFamilies.length - usableFamilies.length;
    if (invalidFamilies > 0) {
      warnings.add(
        'BLOCKER: $invalidFamilies family record(s) have incomplete parent assignments or invalid capacity. Fix them before matching.',
      );
    }
    if (usableFamilies.isEmpty) {
      warnings.add(
        'BLOCKER: No configured family has a complete spiritual father and mother with positive capacity.',
      );
    }

    String normalized(String value) =>
        value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    int exactDepartmentAffinity(FamilyModel family, String department) {
      final key = normalized(department);
      if (key.isEmpty) return 0;
      return normalized(family.spiritualFather.department) == key ||
              normalized(family.spiritualMother.department) == key
          ? 1
          : 0;
    }

    final departmentGroups = <String, List<UserModel>>{};
    for (final student in students) {
      final departmentKey = normalized(student.department).isEmpty
          ? 'general'
          : normalized(student.department);
      departmentGroups.putIfAbsent(departmentKey, () => []).add(student);
    }
    for (final group in departmentGroups.values) {
      group.sort((a, b) => a.id.compareTo(b.id));
    }

    final familyMembers = <String, List<String>>{
      for (final family in usableFamilies) family.id: <String>[],
    };
    final assignments = <String, String>{};
    final unassigned = <UserModel>[];
    final sortedDepartments = departmentGroups.keys.toList()..sort();

    for (final department in sortedDepartments) {
      final remaining = List<UserModel>.from(departmentGroups[department]!);
      while (remaining.isNotEmpty) {
        final available = usableFamilies.where((family) {
          final used = familyMembers[family.id]!.length;
          return used < family.maxCapacity;
        }).toList();
        if (available.isEmpty) {
          unassigned.addAll(remaining);
          remaining.clear();
          continue;
        }

        available.sort((a, b) {
          final affinity = exactDepartmentAffinity(
            b,
            department,
          ).compareTo(exactDepartmentAffinity(a, department));
          if (affinity != 0) return affinity;
          final loadA = familyMembers[a.id]!.length / a.maxCapacity;
          final loadB = familyMembers[b.id]!.length / b.maxCapacity;
          final balance = loadA.compareTo(loadB);
          return balance != 0 ? balance : a.id.compareTo(b.id);
        });

        final wholeCohortFit = available
            .where(
              (family) =>
                  family.maxCapacity - familyMembers[family.id]!.length >=
                  remaining.length,
            )
            .toList();
        final target = wholeCohortFit.isNotEmpty
            ? wholeCohortFit.first
            : available.first;
        final freePlaces =
            target.maxCapacity - familyMembers[target.id]!.length;
        final assignedFromGroup = remaining.take(freePlaces).toList();
        for (final student in assignedFromGroup) {
          assignments[student.id] = target.id;
          familyMembers[target.id]!.add(student.id);
        }
        remaining.removeRange(0, assignedFromGroup.length);
      }
    }

    if (unassigned.isNotEmpty) {
      warnings.add(
        '${unassigned.length} student(s) remain unassigned because configured family capacity is insufficient.',
      );
    }
    if (usableFamilies.isEmpty && students.isNotEmpty && unassigned.isEmpty) {
      unassigned.addAll(students);
    }

    final proposedRoster = proposedFamilies
        .map(
          (family) => family.copyWith(
            memberIds: familyMembers[family.id] ?? const <String>[],
            isPublished: false,
          ),
        )
        .toList();
    final signatureStudents =
        _allStudents
            .map(
              (user) => [
                user.id,
                user.role.name,
                user.isApproved,
                user.fullName,
                user.baptismalName,
                user.department,
                user.gender,
              ],
            )
            .toList()
          ..sort((a, b) => a.first.toString().compareTo(b.first.toString()));
    final signatureFamilies = _families.map((family) => family.toMap()).toList()
      ..sort((a, b) => a['id'].toString().compareTo(b['id'].toString()));

    return FamilyMatchingPreview(
      families: proposedRoster,
      studentAssignments: assignments,
      unassignedStudents: unassigned,
      eligibleStudentCount: students.length,
      warnings: warnings,
      sourceSignature: jsonEncode({
        'students': signatureStudents,
        'families': signatureFamilies,
      }),
    );
  }

  bool _hasValidParentPair(FamilyModel family) =>
      family.spiritualFather.id.trim().isNotEmpty &&
      family.spiritualFather.fullName.trim().isNotEmpty &&
      family.spiritualFather.gender.toLowerCase() == 'male' &&
      family.spiritualMother.id.trim().isNotEmpty &&
      family.spiritualMother.fullName.trim().isNotEmpty &&
      family.spiritualMother.gender.toLowerCase() == 'female';

  void _installLocalFamilyDraft(
    List<FamilyModel> families,
    Map<String, String> assignments,
  ) {
    final byId = <String, String>{...assignments};
    _allStudents = _allStudents.map((student) {
      if (byId.containsKey(student.id)) {
        return student.copyWith(assignedFamilyId: byId[student.id]);
      }
      return student;
    }).toList();
    if (byId.containsKey(_currentUser.id)) {
      _currentUser = _currentUser.copyWith(
        assignedFamilyId: byId[_currentUser.id],
      );
    }
    _families = families
        .map((family) => family.copyWith(isPublished: false))
        .toList();
    _isFamilyPublished = false;
    notifyListeners();
  }

  Future<void> swapStudentsBetweenFamilies({
    required String studentAId,
    required String familyAId,
    required String studentBId,
    required String familyBId,
  }) async {
    if (!canManageFamilyMatching)
      throw StateError(
        'Only Admin or Member Care can edit family assignments.',
      );
    if (familyAId == familyBId)
      throw StateError('Choose students from two different families to swap.');
    final famAIndex = _families.indexWhere((f) => f.id == familyAId);
    final famBIndex = _families.indexWhere((f) => f.id == familyBId);
    if (famAIndex < 0 || famBIndex < 0)
      throw StateError('One of the selected families no longer exists.');
    final famA = _families[famAIndex];
    final famB = _families[famBIndex];
    final studentAIndex = _allStudents.indexWhere(
      (student) => student.id == studentAId,
    );
    final studentBIndex = _allStudents.indexWhere(
      (student) => student.id == studentBId,
    );
    if (studentAIndex < 0 ||
        studentBIndex < 0 ||
        _allStudents[studentAIndex].role != UserRole.student ||
        _allStudents[studentBIndex].role != UserRole.student ||
        !_allStudents[studentAIndex].isApproved ||
        !_allStudents[studentBIndex].isApproved) {
      throw StateError(
        'Only approved students can be swapped between families.',
      );
    }
    if (!famA.memberIds.contains(studentAId) ||
        !famB.memberIds.contains(studentBId)) {
      throw StateError(
        'The selected students are no longer in those families. Refresh and try again.',
      );
    }

    final draftFamilies = _families.map((family) {
      final members = List<String>.from(family.memberIds);
      if (family.id == familyAId) {
        members.remove(studentAId);
        members.add(studentBId);
      } else if (family.id == familyBId) {
        members.remove(studentBId);
        members.add(studentAId);
      }
      return family.copyWith(memberIds: members, isPublished: false);
    }).toList();
    final assignments = {studentAId: familyBId, studentBId: familyAId};
    await _firestoreService.saveFamilyRosterDraft(
      families: draftFamilies,
      studentAssignments: assignments,
    );
    _installLocalFamilyDraft(draftFamilies, assignments);
  }

  Future<void> assignStudentToFamily(
    String studentId,
    String targetFamilyId,
  ) async {
    if (!canManageFamilyMatching)
      throw StateError(
        'Only Admin or Member Care can edit family assignments.',
      );
    final studentIndex = _allStudents.indexWhere(
      (student) => student.id == studentId,
    );
    if (studentIndex < 0 ||
        _allStudents[studentIndex].role != UserRole.student ||
        !_allStudents[studentIndex].isApproved) {
      throw StateError('Only an approved student can be assigned to a family.');
    }
    final targetIndex = _families.indexWhere(
      (family) => family.id == targetFamilyId,
    );
    if (targetIndex < 0)
      throw StateError('The selected family no longer exists.');
    final currentFamily = _families[targetIndex];
    if (!currentFamily.memberIds.contains(studentId) &&
        currentFamily.memberIds.length >= currentFamily.maxCapacity) {
      throw StateError('${currentFamily.name} is at capacity.');
    }

    final draftFamilies = _families.map((family) {
      final members = List<String>.from(family.memberIds)..remove(studentId);
      if (family.id == targetFamilyId) members.add(studentId);
      return family.copyWith(memberIds: members, isPublished: false);
    }).toList();
    await _firestoreService.saveFamilyRosterDraft(
      families: draftFamilies,
      studentAssignments: {studentId: targetFamilyId},
    );
    _installLocalFamilyDraft(draftFamilies, {studentId: targetFamilyId});
  }

  Future<void> publishFamilyRoster() async {
    if (!canManageFamilyMatching)
      throw StateError(
        'Only Admin or Member Care can publish the family roster.',
      );
    if (!canPublishFamilyRoster) {
      throw StateError(
        'Resolve unassigned students, invalid parent records, or capacity issues before publishing.',
      );
    }
    await _firestoreService.publishFamiliesRoster(
      true,
      announcement: {
        'title': 'Family Roster Published',
        'content': 'The spiritual family roster is now available. Students can view their assigned family and parent contacts in the app.',
        'authorName': _currentUser.fullName,
        'category': 'Family Roster',
        'imageUrl': null,
        'isUrgent': false,
      },
    );
    _isFamilyPublished = true;
    _families = _families
        .map((family) => family.copyWith(isPublished: true))
        .toList();
    notifyListeners();
  }
}
