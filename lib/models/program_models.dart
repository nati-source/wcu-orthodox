
class ChurchProgramModel {
  final String id;
  final String title;
  final String churchName;
  final DateTime dateTime;
  final Duration initialDurationRemaining;
  final bool isEmergency;
  final bool reminderEnabled;
  final String description;
  final String? liveFeedUrl;
  final String category; // 'Liturgy', 'Feast', 'Prayer Meeting', 'Bible Study'

  ChurchProgramModel({
    required this.id,
    required this.title,
    required this.churchName,
    required this.dateTime,
    required this.initialDurationRemaining,
    this.isEmergency = false,
    this.reminderEnabled = true,
    required this.description,
    this.liveFeedUrl,
    this.category = 'Liturgy',
  });

  ChurchProgramModel copyWith({
    String? id,
    String? title,
    String? churchName,
    DateTime? dateTime,
    Duration? initialDurationRemaining,
    bool? isEmergency,
    bool? reminderEnabled,
    String? description,
    String? liveFeedUrl,
    String? category,
  }) {
    return ChurchProgramModel(
      id: id ?? this.id,
      title: title ?? this.title,
      churchName: churchName ?? this.churchName,
      dateTime: dateTime ?? this.dateTime,
      initialDurationRemaining: initialDurationRemaining ?? this.initialDurationRemaining,
      isEmergency: isEmergency ?? this.isEmergency,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      description: description ?? this.description,
      liveFeedUrl: liveFeedUrl ?? this.liveFeedUrl,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'churchName': churchName,
      'dateTime': dateTime.toIso8601String(),
      'isEmergency': isEmergency,
      'reminderEnabled': reminderEnabled,
      'description': description,
      'liveFeedUrl': liveFeedUrl,
      'category': category,
    };
  }

  factory ChurchProgramModel.fromMap(Map<String, dynamic> map, String docId) {
    final dt = map['dateTime'] != null ? DateTime.tryParse(map['dateTime']) ?? DateTime.now() : DateTime.now();
    final remaining = dt.isAfter(DateTime.now()) ? dt.difference(DateTime.now()) : Duration.zero;
    return ChurchProgramModel(
      id: docId,
      title: map['title'] ?? '',
      churchName: map['churchName'] ?? 'WCU Orthodox Campus Fellowship',
      dateTime: dt,
      initialDurationRemaining: remaining,
      isEmergency: map['isEmergency'] ?? false,
      reminderEnabled: map['reminderEnabled'] ?? true,
      description: map['description'] ?? '',
      liveFeedUrl: map['liveFeedUrl'],
      category: map['category'] ?? 'Liturgy',
    );
  }
}

// ============================================================================
// VOLUNTARY SERVING & 10 EOTC FELLOWSHIP DEPARTMENTS
// ============================================================================
