
enum RoadmapStatus { completed, inProgress, locked }

class LessonModel {
  final String id;
  final String title;
  final String summary;
  final List<String> readingList;
  final bool isDownloaded;
  final int durationMinutes;
  final String? audioLink;

  LessonModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.readingList,
    this.isDownloaded = false,
    this.durationMinutes = 45,
    this.audioLink,
  });

  LessonModel copyWith({
    String? id,
    String? title,
    String? summary,
    List<String>? readingList,
    bool? isDownloaded,
    int? durationMinutes,
    String? audioLink,
  }) {
    return LessonModel(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      readingList: readingList ?? this.readingList,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      audioLink: audioLink ?? this.audioLink,
    );
  }
}

class RoadmapPhaseModel {
  final String id;
  final String title;
  final String description;
  final RoadmapStatus status;
  final double progress; // 0.0 to 1.0
  final List<LessonModel> weeklyLessons;
  final List<String> prerequisites;
  final String instructor;
  final String batchYear;
  final String semester;

  RoadmapPhaseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.progress,
    required this.weeklyLessons,
    this.prerequisites = const [],
    required this.instructor,
    this.batchYear = '2024',
    this.semester = 'Semester 1',
  });

  RoadmapPhaseModel copyWith({
    String? id,
    String? title,
    String? description,
    RoadmapStatus? status,
    double? progress,
    List<LessonModel>? weeklyLessons,
    List<String>? prerequisites,
    String? instructor,
    String? batchYear,
    String? semester,
  }) {
    return RoadmapPhaseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      weeklyLessons: weeklyLessons ?? this.weeklyLessons,
      prerequisites: prerequisites ?? this.prerequisites,
      instructor: instructor ?? this.instructor,
      batchYear: batchYear ?? this.batchYear,
      semester: semester ?? this.semester,
    );
  }
}
