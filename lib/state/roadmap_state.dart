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
  static List<RoadmapPhaseModel> get defaultRoadmapPhases => [
    RoadmapPhaseModel(
      id: 'phase-1',
      title: 'Foundations of Faith',
      description: 'An introduction to Orthodox theology, the Nicene Creed, and the structural beauty of the Divine Liturgy.',
      status: RoadmapStatus.completed,
      progress: 1.0,
      instructor: 'Dn. Ephrem Tadesse',
      batchYear: '2024',
      semester: 'Semester 1',
      weeklyLessons: [
        LessonModel(
          id: 'l1',
          title: 'Week 1: The Nicene-Constantinopolitan Creed',
          summary: 'Comprehensive line-by-line exposition of the 12 articles of Christian Orthodox belief.',
          readingList: [
            'Creed Commentary - St. Athanasius',
            'Faith of the 318 Fathers',
          ],
          isDownloaded: true,
        ),
        LessonModel(
          id: 'l2',
          title: 'Week 2: Order of the Divine Liturgy',
          summary: 'Understanding the Preparatory rites, Anaphora of the Apostles, and Eucharistic communion.',
          readingList: ['Serate Kidase Manual', 'Liturgical Theology Notes'],
          isDownloaded: true,
        ),
      ],
    ),
    RoadmapPhaseModel(
      id: 'phase-2',
      title: 'Patristics',
      description: 'Deep dive into the writings of the Early Church Fathers, desert spirituality, and ascetic practice.',
      status: RoadmapStatus.inProgress,
      progress: 0.45,
      instructor: 'Memhir Yohannes Kidan',
      batchYear: '2024',
      semester: 'Semester 2',
      prerequisites: ['Foundations of Faith'],
      weeklyLessons: [
        LessonModel(
          id: 'l3',
          title: 'Week 1: St. Athanasius on the Incarnation',
          summary: 'Exegesis of De Incarnatione Verbi Dei and victory over death.',
          readingList: [
            'On the Incarnation Chapters 1-4',
            'St. Cyril Letters to Nestorius',
          ],
          isDownloaded: false,
        ),
        LessonModel(
          id: 'l4',
          title: 'Week 2: The Desert Fathers & Asceticism',
          summary: 'Sayings of Abba Anthony, Macarius, and monastic spirituality in Christian fellowship.',
          readingList: [
            'Apophthegmata Patrum',
            'Spiritual Ladder of St. John Climacus',
          ],
          isDownloaded: false,
        ),
        LessonModel(
          id: 'l5',
          title: 'Week 3: Haymanote Abew (Faith of the Fathers)',
          summary: 'Compilation of patristic homilies and Christology preserved in Ge\'ez tradition.',
          readingList: ['Haymanote Abew Homily 12-18'],
          isDownloaded: false,
        ),
      ],
    ),
    RoadmapPhaseModel(
      id: 'phase-3',
      title: 'Church Tradition & Canon Law',
      description: 'Understanding iconology, hymnography (St. Yared), fasts, and the living tradition passed down through generations.',
      status: RoadmapStatus.locked,
      progress: 0.0,
      instructor: 'Dr. Lidia Solomon',
      batchYear: '2025',
      semester: 'Semester 1',
      prerequisites: ['Patristics'],
      weeklyLessons: [
        LessonModel(
          id: 'l6',
          title: 'Week 1: St. Yaredic Musical Notation & Deggua',
          summary: 'Introduction to Geez, Ezel, and Araray modes and Ethiopian hymnology.',
          readingList: ['Tsome Deggua Guide', 'Life of St. Yared'],
          isDownloaded: false,
        ),
      ],
    ),
    RoadmapPhaseModel(
      id: 'phase-4',
      title: 'Orthodox Dogmatics & Apologetics',
      description: 'Systematic theology, Holy Sacraments (Misteerat), and answering contemporary philosophical queries.',
      status: RoadmapStatus.locked,
      progress: 0.0,
      instructor: 'Archpriest Gebre Meskel',
      batchYear: '2025',
      semester: 'Semester 2',
      prerequisites: ['Church Tradition & Canon Law'],
      weeklyLessons: [],
    ),
  ];

  List<RoadmapPhaseModel> _roadmaps = defaultRoadmapPhases;
  List<RoadmapPhaseModel> get roadmaps => List.unmodifiable(_roadmaps);

  void toggleLessonDownload(String phaseId, String lessonId) {
    final pIndex = _roadmaps.indexWhere((p) => p.id == phaseId);
    if (pIndex != -1) {
      final phase = _roadmaps[pIndex];
      final lIndex = phase.weeklyLessons.indexWhere((l) => l.id == lessonId);
      if (lIndex != -1) {
        final lesson = phase.weeklyLessons[lIndex];
        final updatedLessons = List<LessonModel>.from(phase.weeklyLessons);
        final newDownloaded = !lesson.isDownloaded;
        updatedLessons[lIndex] = lesson.copyWith(isDownloaded: newDownloaded);
        _roadmaps[pIndex] = phase.copyWith(weeklyLessons: updatedLessons);
        notifyListeners();
        SharedPreferences.getInstance().then((prefs) {
          final list = prefs.getStringList('downloaded_lessons_v1') ?? [];
          if (newDownloaded) {
            if (!list.contains(lessonId)) list.add(lessonId);
          } else {
            list.remove(lessonId);
          }
          prefs.setStringList('downloaded_lessons_v1', list);
        }).catchError((_) {});
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

