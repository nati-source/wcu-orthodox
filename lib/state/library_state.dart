part of 'fellowship_state.dart';

/// Feature slice managing Digital Library, Audio Mezmurs & Telegram Book Links.
class LibraryState extends ChangeNotifier {
  final FellowshipState root; LibraryState(this.root);
  void refresh() => notifyListeners();
}

mixin LibraryStateMixin on ChangeNotifier {
  FirestoreService get _firestoreService;

  // ----------------------------------------------------
  // DOMAIN 5: DIGITAL LIBRARY (WITH TELEGRAM LINKS)
  // ----------------------------------------------------
  List<LibraryItemModel> _libraryItems = [];
  String _librarySearchQuery = '';
  LibraryCategory? _selectedCategory;
  String? _selectedLanguageTag;
  LibraryItemModel? _activeAudioMezmur;
  bool _isAudioPlaying = false;
  double _audioProgress = 0.35;

  List<LibraryItemModel> get libraryItems => List.unmodifiable(_libraryItems);
  String get librarySearchQuery => _librarySearchQuery;
  LibraryCategory? get selectedCategory => _selectedCategory;
  String? get selectedLanguageTag => _selectedLanguageTag;
  LibraryItemModel? get activeAudioMezmur => _activeAudioMezmur;
  bool get isAudioPlaying => _isAudioPlaying;
  double get audioProgress => _audioProgress;

  List<LibraryItemModel> get filteredLibraryItems {
    return _libraryItems.where((item) {
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      if (_selectedLanguageTag != null && !item.tags.contains(_selectedLanguageTag)) {
        return false;
      }
      if (_librarySearchQuery.isNotEmpty) {
        final q = _librarySearchQuery.toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(q);
        final matchSub = item.subtitle.toLowerCase().contains(q);
        final matchTags = item.tags.any((t) => t.toLowerCase().contains(q));
        if (!matchTitle && !matchSub && !matchTags) return false;
      }
      return true;
    }).toList();
  }

  void setLibrarySearch(String query) {
    _librarySearchQuery = query;
    notifyListeners();
  }

  void setLibraryCategory(LibraryCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setLanguageTag(String? tag) {
    _selectedLanguageTag = tag;
    notifyListeners();
  }

  void addLibraryBookLink({
    required String title,
    required String subtitle,
    required String description,
    required LibraryCategory category,
    required List<String> tags,
    required String telegramUrl,
    String? sourceUrl,
    bool isRestricted = false,
  }) {
    final newItem = LibraryItemModel(
      id: 'lib-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: subtitle,
      description: description,
      category: category,
      tags: tags,
      telegramUrl: telegramUrl,
      sourceUrl: sourceUrl,
      isRestricted: isRestricted,
    );
    _libraryItems.insert(0, newItem);
    notifyListeners();

    try {
      FirebaseFirestore.instance.collection('library_items').doc(newItem.id).set(
        newItem.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore addLibraryBookLink notice: $e');
    }
  }

  void updateLibraryBook({
    required String id,
    required String title,
    required String subtitle,
    required String description,
    required LibraryCategory category,
    required List<String> tags,
    required String telegramUrl,
    String? sourceUrl,
    bool? isRestricted,
  }) {
    final index = _libraryItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      final existing = _libraryItems[index];
      _libraryItems[index] = existing.copyWith(
        title: title,
        subtitle: subtitle,
        description: description,
        category: category,
        tags: tags,
        telegramUrl: telegramUrl,
        sourceUrl: sourceUrl ?? existing.sourceUrl,
        isRestricted: isRestricted ?? existing.isRestricted,
      );
      if (_activeAudioMezmur?.id == id) {
        _activeAudioMezmur = _libraryItems[index];
      }
      notifyListeners();

      try {
        FirebaseFirestore.instance.collection('library_items').doc(id).set(
          _libraryItems[index].toMap(),
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('Firestore updateLibraryBook notice: $e');
      }
    }
  }

  void deleteLibraryBook(String bookId) {
    _libraryItems.removeWhere((item) => item.id == bookId);
    if (_activeAudioMezmur?.id == bookId) {
      _activeAudioMezmur = null;
      _isAudioPlaying = false;
    }
    notifyListeners();

    try {
      _firestoreService.deleteLibraryItem(bookId);
      FirebaseFirestore.instance.collection('library_items').doc(bookId).delete();
    } catch (e) {
      debugPrint('Firestore deleteLibraryBook notice: $e');
    }
  }

  void playMezmur(LibraryItemModel item) {
    _activeAudioMezmur = item;
    _isAudioPlaying = true;
    notifyListeners();
  }

  void toggleAudioPlayback() {
    _isAudioPlaying = !_isAudioPlaying;
    notifyListeners();
  }

  void setAudioProgress(double progress) {
    _audioProgress = progress.clamp(0.0, 1.0);
    notifyListeners();
  }

}

