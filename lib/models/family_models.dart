import 'user_models.dart';

class SpiritualParentModel {
  final String id;
  final String fullName;
  final String baptismalName;
  final String department;
  final String faculty;
  final String phoneNumber;
  final String roleTitle; // 'Spiritual Father' or 'Spiritual Mother'
  final String? avatarUrl;
  final String gender; // 'male' or 'female'

  SpiritualParentModel({
    required this.id,
    required this.fullName,
    required this.baptismalName,
    required this.department,
    required this.faculty,
    required this.phoneNumber,
    required this.roleTitle,
    this.avatarUrl,
    String? gender,
  }) : gender = gender ??
            ((roleTitle.toLowerCase().contains('mother') ||
                    roleTitle.contains('እናት') ||
                    UserModel.inferGender(fullName, baptismalName) == 'female')
                ? 'female'
                : 'male');

  bool get isFather => gender == 'male' || roleTitle.toLowerCase().contains('father') || roleTitle.contains('አባት');
  bool get isMother => gender == 'female' || roleTitle.toLowerCase().contains('mother') || roleTitle.contains('እናት');

  SpiritualParentModel copyWith({
    String? id,
    String? fullName,
    String? baptismalName,
    String? department,
    String? faculty,
    String? phoneNumber,
    String? roleTitle,
    String? avatarUrl,
    String? gender,
  }) {
    return SpiritualParentModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      baptismalName: baptismalName ?? this.baptismalName,
      department: department ?? this.department,
      faculty: faculty ?? this.faculty,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      roleTitle: roleTitle ?? this.roleTitle,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'baptismalName': baptismalName,
      'department': department,
      'faculty': faculty,
      'phoneNumber': phoneNumber,
      'roleTitle': roleTitle,
      'avatarUrl': avatarUrl,
      'gender': gender,
    };
  }

  factory SpiritualParentModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final name = map['fullName']?.toString() ?? '';
    final bap = map['baptismalName']?.toString() ?? '';
    final title = map['roleTitle']?.toString() ?? 'Spiritual Parent';
    final parsedGender = map['gender']?.toString().toLowerCase().trim();
    final gender = (parsedGender == 'male' || parsedGender == 'female')
        ? parsedGender!
        : ((title.toLowerCase().contains('mother') ||
                title.contains('እናት') ||
                UserModel.inferGender(name, bap) == 'female')
            ? 'female'
            : 'male');

    return SpiritualParentModel(
      id: docId ?? map['id'] ?? '',
      fullName: name,
      baptismalName: bap,
      department: map['department'] ?? '',
      faculty: map['faculty'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      roleTitle: title,
      avatarUrl: map['avatarUrl'],
      gender: gender,
    );
  }
}

class FamilyModel {
  final String id;
  final String name; // e.g. "Family of St. George"
  final String formedDate;
  final SpiritualParentModel spiritualFather;
  final SpiritualParentModel spiritualMother;
  final int maxCapacity;
  final String telegramGroupUrl;
  final String whatsappGroupUrl;
  final bool isPublished;
  final List<String> memberIds;

  FamilyModel({
    required this.id,
    required this.name,
    required this.formedDate,
    required this.spiritualFather,
    required this.spiritualMother,
    this.maxCapacity = 10,
    required this.telegramGroupUrl,
    required this.whatsappGroupUrl,
    this.isPublished = false,
    required this.memberIds,
  });

  int get memberCount => memberIds.length;

  FamilyModel copyWith({
    String? id,
    String? name,
    String? formedDate,
    SpiritualParentModel? spiritualFather,
    SpiritualParentModel? spiritualMother,
    int? maxCapacity,
    String? telegramGroupUrl,
    String? whatsappGroupUrl,
    bool? isPublished,
    List<String>? memberIds,
  }) {
    return FamilyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      formedDate: formedDate ?? this.formedDate,
      spiritualFather: spiritualFather ?? this.spiritualFather,
      spiritualMother: spiritualMother ?? this.spiritualMother,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      telegramGroupUrl: telegramGroupUrl ?? this.telegramGroupUrl,
      whatsappGroupUrl: whatsappGroupUrl ?? this.whatsappGroupUrl,
      isPublished: isPublished ?? this.isPublished,
      memberIds: memberIds ?? this.memberIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'formedDate': formedDate,
      'spiritualFather': spiritualFather.toMap(),
      'spiritualMother': spiritualMother.toMap(),
      'maxCapacity': maxCapacity,
      'telegramGroupUrl': telegramGroupUrl,
      'whatsappGroupUrl': whatsappGroupUrl,
      'isPublished': isPublished,
      'memberIds': memberIds,
    };
  }

  factory FamilyModel.fromMap(Map<String, dynamic> map, String docId) {
    return FamilyModel(
      id: docId.isNotEmpty ? docId : (map['id']?.toString() ?? ''),
      name: map['name'] ?? 'Orthodox Spiritual Family',
      formedDate: map['formedDate'] ?? '2024 E.C.',
      spiritualFather: map['spiritualFather'] is Map<String, dynamic>
          ? SpiritualParentModel.fromMap(Map<String, dynamic>.from(map['spiritualFather']))
          : SpiritualParentModel(
              id: 'sp-father',
              fullName: (map['spiritualFather'] is String && (map['spiritualFather'] as String).isNotEmpty)
                  ? map['spiritualFather']
                  : (map['spiritualFatherName']?.toString() ?? 'Spiritual Father (የመንፈስ አባት)'),
              baptismalName: map['fatherBaptismalName']?.toString() ?? 'Gebre Kristos',
              department: map['fatherDepartment']?.toString() ?? 'Theology & Apostolic Ministry',
              faculty: 'Campus Fellowship',
              phoneNumber: map['fatherPhone']?.toString() ?? '+251911000000',
              roleTitle: 'Spiritual Father',
            ),
      spiritualMother: map['spiritualMother'] is Map<String, dynamic>
          ? SpiritualParentModel.fromMap(Map<String, dynamic>.from(map['spiritualMother']))
          : SpiritualParentModel(
              id: 'sp-mother',
              fullName: (map['spiritualMother'] is String && (map['spiritualMother'] as String).isNotEmpty)
                  ? map['spiritualMother']
                  : (map['spiritualMotherName']?.toString() ?? 'Spiritual Mother (የመንፈስ እናት)'),
              baptismalName: map['motherBaptismalName']?.toString() ?? 'Walata Maryam',
              department: map['motherDepartment']?.toString() ?? 'Member Care & Charity',
              faculty: 'Campus Fellowship',
              phoneNumber: map['motherPhone']?.toString() ?? '+251922000000',
              roleTitle: 'Spiritual Mother',
            ),
      maxCapacity: (map['maxCapacity'] as num?)?.toInt() ?? 10,
      telegramGroupUrl: map['telegramGroupUrl'] ?? '',
      whatsappGroupUrl: map['whatsappGroupUrl'] ?? '',
      isPublished: map['isPublished'] ?? true,
      memberIds: (map['memberIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
