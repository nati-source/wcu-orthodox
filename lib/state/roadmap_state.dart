part of 'fellowship_state.dart';

/// Feature slice managing Spiritual Curriculum Roadmaps & Weekly Lessons.
class RoadmapState extends ChangeNotifier {
  final FellowshipState root; RoadmapState(this.root);
  void refresh() => notifyListeners();
}

mixin RoadmapStateMixin on ChangeNotifier {
  bool canAccessStudentRoadmap(String targetStudentId);

  // ----------------------------------------------------
  // DOMAIN 4: COURSE ROADMAPS & PHASES
  // ----------------------------------------------------
  List<RoadmapPhaseModel> _roadmaps = [];
  List<RoadmapPhaseModel> get roadmaps => List.unmodifiable(_roadmaps);

  void toggleLessonDownload(String phaseId, String lessonId) {
    final pIndex = _roadmaps.indexWhere((p) => p.id == phaseId);
    if (pIndex != -1) {
      final phase = _roadmaps[pIndex];
      final lIndex = phase.weeklyLessons.indexWhere((l) => l.id == lessonId);
      if (lIndex != -1) {
        final lesson = phase.weeklyLessons[lIndex];
        final updatedLessons = List<LessonModel>.from(phase.weeklyLessons);
        updatedLessons[lIndex] = lesson.copyWith(isDownloaded: !lesson.isDownloaded);
        _roadmaps[pIndex] = phase.copyWith(weeklyLessons: updatedLessons);
        notifyListeners();
      }
    }
  }

  void addRoadmapPhase(RoadmapPhaseModel newPhase) {
    _roadmaps.add(newPhase);
    notifyListeners();
  }

  /// Scoped RBAC: Retrieves course roadmaps for a given student ID if authorized.
  List<RoadmapPhaseModel> getRoadmapsForStudent(String studentId) {
    if (!canAccessStudentRoadmap(studentId)) return [];
    return List.unmodifiable(_roadmaps);
  }

}

