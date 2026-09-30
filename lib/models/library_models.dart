import 'user_models.dart';


enum LibraryCategory {
  patristics,
  liturgical,
  mezmur,
  dogma,
  livesOfSaints,
  scripture,
  canon,
  general,
}

class LibraryItemModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final LibraryCategory category;
  final List<String> tags; // e.g. ["Patristics", "Ge'ez / Amharic"]
  final String telegramUrl; // Direct Telegram Link to Book/Audio
  final String? sourceUrl;
  final bool isRestricted;
  final List<UserRole> allowedRoles;
  final String? readTime;
  final String? audioDuration;
  final String? coverAssetPath;
  final String? lyricsOrExcerpts;
  final bool isBookmarked;

  LibraryItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.tags,
    required this.telegramUrl,
    this.sourceUrl,
    this.isRestricted = false,
    this.allowedRoles = const [UserRole.student, UserRole.admin, UserRole.spiritualParent, UserRole.volunteerCoordinator],
    this.readTime,
    this.audioDuration,
    this.coverAssetPath,
    this.lyricsOrExcerpts,
    this.isBookmarked = false,
  });

  LibraryItemModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    LibraryCategory? category,
    List<String>? tags,
    String? telegramUrl,
    String? sourceUrl,
    bool? isRestricted,
    List<UserRole>? allowedRoles,
    String? readTime,
    String? audioDuration,
    String? coverAssetPath,
    String? lyricsOrExcerpts,
    bool? isBookmarked,
  }) {
    return LibraryItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      telegramUrl: telegramUrl ?? this.telegramUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      isRestricted: isRestricted ?? this.isRestricted,
      allowedRoles: allowedRoles ?? this.allowedRoles,
      readTime: readTime ?? this.readTime,
      audioDuration: audioDuration ?? this.audioDuration,
      coverAssetPath: coverAssetPath ?? this.coverAssetPath,
      lyricsOrExcerpts: lyricsOrExcerpts ?? this.lyricsOrExcerpts,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'category': category.name,
      'tags': tags,
      'telegramUrl': telegramUrl,
      'sourceUrl': sourceUrl,
      'isRestricted': isRestricted,
      'allowedRoles': allowedRoles.map((r) => r.name).toList(),
      'readTime': readTime,
      'audioDuration': audioDuration,
      'coverAssetPath': coverAssetPath,
      'lyricsOrExcerpts': lyricsOrExcerpts,
      'isBookmarked': isBookmarked,
    };
  }

  factory LibraryItemModel.fromMap(Map<String, dynamic> map, String docId) {
    final catName = map['category']?.toString() ?? 'general';
    final category = LibraryCategory.values.firstWhere(
      (c) => c.name == catName,
      orElse: () => LibraryCategory.general,
    );
    final rolesList = (map['allowedRoles'] as List?)?.map((r) {
      return UserRole.values.firstWhere((role) => role.name == r.toString(), orElse: () => UserRole.student);
    }).toList() ?? [UserRole.student, UserRole.admin, UserRole.spiritualParent, UserRole.volunteerCoordinator];

    return LibraryItemModel(
      id: docId,
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      description: map['description'] ?? '',
      category: category,
      tags: (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      telegramUrl: map['telegramUrl'] ?? '',
      sourceUrl: map['sourceUrl'],
      isRestricted: map['isRestricted'] ?? false,
      allowedRoles: rolesList,
      readTime: map['readTime'],
      audioDuration: map['audioDuration'],
      coverAssetPath: map['coverAssetPath'],
      lyricsOrExcerpts: map['lyricsOrExcerpts'],
      isBookmarked: map['isBookmarked'] ?? false,
    );
  }
}
