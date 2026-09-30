import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class AdminMediaCurriculumScreen extends StatefulWidget {
  final FellowshipState state;
  final VoidCallback? onBackPressed;

  const AdminMediaCurriculumScreen({super.key, required this.state, this.onBackPressed});

  @override
  State<AdminMediaCurriculumScreen> createState() => _AdminMediaCurriculumScreenState();
}

class _AdminMediaCurriculumScreenState extends State<AdminMediaCurriculumScreen> {
  // Library Catalog Filter & Search State
  String _librarySearchQuery = '';
  LibraryCategory? _selectedCategoryFilter;

  // Emergency Broadcast Controllers
  final _broadcastTitleController = TextEditingController(text: 'Urgent Liturgy Venue Update');
  final _broadcastChurchController = TextEditingController(text: 'St. Mary\'s Orthodox Church');
  final _broadcastDescController = TextEditingController(text: 'Morning Kidase will start at 6:30 AM in the Main Sanctuary due to university semester examinations.');

  @override
  void dispose() {
    _broadcastTitleController.dispose();
    _broadcastChurchController.dispose();
    _broadcastDescController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // ADD BOOK MODAL
  // ----------------------------------------------------
  void _openAddBookDialog() {
    final titleCtrl = TextEditingController();
    final subCtrl = TextEditingController();
    final telegramCtrl = TextEditingController(text: 'https://t.me/WCU_Orthodox_Library/');
    final descCtrl = TextEditingController();
    final tagsCtrl = TextEditingController(text: 'Patristics, Amharic');
    LibraryCategory selectedCat = LibraryCategory.patristics;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final primaryAccent = theme.colorScheme.primary;
        final textCol = theme.colorScheme.onSurface;
        final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
        final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
        final borderCol = theme.dividerColor;
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: borderCol,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.menu_book, color: primaryAccent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Publish New Material',
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textCol,
                                ),
                              ),
                              Text(
                                'Add a Telegram book or hymn link to digital library',
                                style: TextStyle(fontSize: 12, color: textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Title
                    Text('Book Title', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      style: TextStyle(color: textCol, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. Haymanote Abew, Wudase Mariam',
                        hintStyle: TextStyle(color: textMuted.withOpacity(0.6), fontSize: 13),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle / Ge'ez Title
                    Text('Subtitle / Ge\'ez Name', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: subCtrl,
                      style: TextStyle(color: textCol, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. ሃይማኖተ አበው (Faith of the Fathers)',
                        hintStyle: TextStyle(color: textMuted.withOpacity(0.6), fontSize: 13),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category Selector
                    Text('Category', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<LibraryCategory>(
                          value: selectedCat,
                          isExpanded: true,
                          dropdownColor: cardBg,
                          icon: Icon(Icons.keyboard_arrow_down, color: primaryAccent),
                          items: LibraryCategory.values.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(
                                _categoryLabel(cat),
                                style: TextStyle(color: textCol, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedCat = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Telegram URL
                    Text('Telegram Resource Link', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: telegramCtrl,
                      style: TextStyle(color: textCol, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'https://t.me/WCU_Orthodox_Library/101',
                        hintStyle: TextStyle(color: textMuted.withOpacity(0.6), fontSize: 13),
                        prefixIcon: const Icon(Icons.telegram, color: Color(0xFF38A3E5)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tags
                    Text('Tags (comma separated)', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: tagsCtrl,
                      style: TextStyle(color: textCol, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Patristics, Amharic, Ge\'ez, Dogma',
                        hintStyle: TextStyle(color: textMuted.withOpacity(0.6), fontSize: 13),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text('Description / Overview', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      style: TextStyle(color: textCol, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Summary of text, chapters, or homilies...',
                        hintStyle: TextStyle(color: textMuted.withOpacity(0.6), fontSize: 13),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(modalCtx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: borderCol),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Cancel', style: TextStyle(color: textMuted)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (titleCtrl.text.trim().isEmpty || telegramCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter book title and Telegram link.')),
                                );
                                return;
                              }

                              final tags = tagsCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

                              widget.state.addLibraryBookLink(
                                title: titleCtrl.text.trim(),
                                subtitle: subCtrl.text.trim().isEmpty ? 'WCU Fellowship Edition' : subCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                category: selectedCat,
                                tags: tags.isEmpty ? ['Patristics'] : tags,
                                telegramUrl: telegramCtrl.text.trim(),
                              );

                              Navigator.pop(modalCtx);
                              setState(() {});

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: AppTheme.emerald, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Published "${titleCtrl.text.trim()}" to digital library!',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: cardBg,
                                ),
                              );
                            },
                            icon: Icon(Icons.add_link, color: isDark ? Colors.black : Colors.white),
                            label: Text(
                              'Publish Book Link',
                              style: TextStyle(
                                color: isDark ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryAccent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------
  // EDIT BOOK MODAL
  // ----------------------------------------------------
  void _openEditBookDialog(LibraryItemModel book) {
    final titleCtrl = TextEditingController(text: book.title);
    final subCtrl = TextEditingController(text: book.subtitle);
    final telegramCtrl = TextEditingController(text: book.telegramUrl);
    final descCtrl = TextEditingController(text: book.description);
    final tagsCtrl = TextEditingController(text: book.tags.join(', '));
    LibraryCategory selectedCat = book.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final primaryAccent = theme.colorScheme.primary;
        final textCol = theme.colorScheme.onSurface;
        final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
        final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
        final borderCol = theme.dividerColor;
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: borderCol,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.edit_note, color: primaryAccent, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Library Material',
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textCol,
                                ),
                              ),
                              Text(
                                'Update book details, Telegram link, or category',
                                style: TextStyle(fontSize: 12, color: textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Title
                    Text('Book Title', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      style: TextStyle(color: textCol, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Book Title',
                        hintStyle: TextStyle(color: textMuted.withOpacity(0.6), fontSize: 13),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle / Ge'ez Title
                    Text('Subtitle / Ge\'ez Name', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: subCtrl,
                      style: TextStyle(color: textCol, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ge\'ez subtitle or translation',
                        hintStyle: TextStyle(color: textMuted.withOpacity(0.6), fontSize: 13),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category Selector
                    Text('Category', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<LibraryCategory>(
                          value: selectedCat,
                          isExpanded: true,
                          dropdownColor: cardBg,
                          icon: Icon(Icons.keyboard_arrow_down, color: primaryAccent),
                          items: LibraryCategory.values.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(
                                _categoryLabel(cat),
                                style: TextStyle(color: textCol, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedCat = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Telegram URL
                    Text('Telegram Resource Link', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: telegramCtrl,
                      style: TextStyle(color: textCol, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'https://t.me/WCU_Orthodox_Library/...',
                        hintStyle: TextStyle(color: textMuted.withOpacity(0.6), fontSize: 13),
                        prefixIcon: const Icon(Icons.telegram, color: Color(0xFF38A3E5)),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tags
                    Text('Tags (comma separated)', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: tagsCtrl,
                      style: TextStyle(color: textCol, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Patristics, Amharic, Ge\'ez',
                        hintStyle: TextStyle(color: textMuted.withOpacity(0.6), fontSize: 13),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text('Description / Overview', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      style: TextStyle(color: textCol, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Summary of material contents...',
                        hintStyle: TextStyle(color: textMuted.withOpacity(0.6), fontSize: 13),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(modalCtx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: borderCol),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Cancel', style: TextStyle(color: textMuted)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (titleCtrl.text.trim().isEmpty || telegramCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter title and Telegram link.')),
                                );
                                return;
                              }

                              final tags = tagsCtrl.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

                              widget.state.updateLibraryBook(
                                id: book.id,
                                title: titleCtrl.text.trim(),
                                subtitle: subCtrl.text.trim().isEmpty ? book.subtitle : subCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                category: selectedCat,
                                tags: tags.isEmpty ? book.tags : tags,
                                telegramUrl: telegramCtrl.text.trim(),
                              );

                              Navigator.pop(modalCtx);
                              setState(() {});

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: AppTheme.emerald, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Updated "${titleCtrl.text.trim()}" in library!',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: cardBg,
                                ),
                              );
                            },
                            icon: Icon(Icons.save, color: isDark ? Colors.black : Colors.white),
                            label: Text(
                              'Save Changes',
                              style: TextStyle(
                                color: isDark ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryAccent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------
  // DELETE BOOK CONFIRMATION DIALOG
  // ----------------------------------------------------
  void _openDeleteBookDialog(LibraryItemModel book) {
    final theme = Theme.of(context);
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.crimson.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever, color: AppTheme.crimson, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Remove Material?',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textCol,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently remove this material from the Digital Library?',
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.crimson.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textCol),
                  ),
                  Text(
                    book.subtitle,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Category: ${_categoryLabel(book.category)} • ${book.tags.join(", ")}',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Students will immediately lose access to this Telegram link.',
              style: TextStyle(fontSize: 11, color: AppTheme.crimson.withOpacity(0.85), fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Keep Material', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.state.deleteLibraryBook(book.id);
              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.delete_sweep, color: AppTheme.crimson, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '"${book.title}" was removed from the digital library.',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: cardBg,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.crimson,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete Material', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _submitBroadcast() {
    if (_broadcastTitleController.text.trim().isEmpty || _broadcastDescController.text.trim().isEmpty) {
      return;
    }

    widget.state.postEmergencyScheduleBroadcast(
      title: _broadcastTitleController.text.trim(),
      description: _broadcastDescController.text.trim(),
      churchName: _broadcastChurchController.text.trim(),
    );

    _broadcastTitleController.clear();
    _broadcastDescController.clear();
    _broadcastChurchController.clear();
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Emergency broadcast pushed to all active devices in real time!'),
        backgroundColor: Theme.of(context).cardTheme.color,
      ),
    );
  }

  String _categoryLabel(LibraryCategory cat) {
    switch (cat) {
      case LibraryCategory.patristics:
        return 'Patristics (አበው)';
      case LibraryCategory.liturgical:
        return 'Liturgical (ቅዳሴ)';
      case LibraryCategory.mezmur:
        return 'Mezmur Audio (መዝሙር)';
      case LibraryCategory.dogma:
        return 'Dogma & Creed (ዶግማ)';
      case LibraryCategory.livesOfSaints:
        return 'Lives of Saints (ገድላት)';
      case LibraryCategory.scripture:
        return 'Scripture (መጽሐፍ ቅዱስ)';
      case LibraryCategory.canon:
        return 'Canon & Law (ቀኖና)';
      case LibraryCategory.general:
        return 'General (አጠቃላይ)';
    }
  }

  Color _categoryColor(LibraryCategory cat) {
    switch (cat) {
      case LibraryCategory.patristics:
        return const Color(0xFFD4AF37); // Gold
      case LibraryCategory.liturgical:
        return AppTheme.emerald;
      case LibraryCategory.mezmur:
        return const Color(0xFF38A3E5); // Azure
      case LibraryCategory.dogma:
        return const Color(0xFF9D4EDD); // Purple
      case LibraryCategory.livesOfSaints:
        return const Color(0xFFE056FD); // Rose
      case LibraryCategory.scripture:
        return const Color(0xFF20BF6B); // Teal
      case LibraryCategory.canon:
        return const Color(0xFFF39C12); // Bronze
      case LibraryCategory.general:
        return const Color(0xFF6C757D); // Slate
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;
    final isDark = theme.brightness == Brightness.dark;

    final state = widget.state;
    final allBooks = state.libraryItems;

    // Filter books by query and category
    final filteredBooks = allBooks.where((book) {
      if (_selectedCategoryFilter != null && book.category != _selectedCategoryFilter) {
        return false;
      }
      if (_librarySearchQuery.trim().isNotEmpty) {
        final q = _librarySearchQuery.trim().toLowerCase();
        final matchTitle = book.title.toLowerCase().contains(q);
        final matchSub = book.subtitle.toLowerCase().contains(q);
        final matchTags = book.tags.any((t) => t.toLowerCase().contains(q));
        final matchDesc = book.description.toLowerCase().contains(q);
        if (!matchTitle && !matchSub && !matchTags && !matchDesc) return false;
      }
      return true;
    }).toList();

    final volunteerApps = state.volunteerApplications;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Media & Programs Manager', style: TextStyle(color: textCol)),
          backgroundColor: cardBg,
          elevation: 0,
          leading: (Navigator.canPop(context) || widget.onBackPressed != null)
              ? IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: primaryAccent),
                  onPressed: () {
                    if (widget.onBackPressed != null) {
                      widget.onBackPressed!();
                    } else if (Navigator.canPop(context)) {
                      Navigator.of(context).pop();
                    }
                  },
                )
              : null,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: primaryAccent,
            labelColor: primaryAccent,
            unselectedLabelColor: textMuted,
            tabs: [
              Tab(text: 'Library Catalog (${allBooks.length})'),
              const Tab(text: 'Emergency Broadcast'),
              Tab(text: 'Volunteer Reviews (${volunteerApps.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ----------------------------------------------------
            // TAB 1: DIGITAL LIBRARY CATALOG (ADD, EDIT, DELETE)
            // ----------------------------------------------------
            Column(
              children: [
                // Top Control Bar: Search + Add Button
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    border: Border(bottom: BorderSide(color: borderCol)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Search Box
                          Expanded(
                            child: TextField(
                              onChanged: (val) => setState(() => _librarySearchQuery = val),
                              style: TextStyle(color: textCol, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search title, ge\'ez, or tags...',
                                hintStyle: TextStyle(color: textMuted.withOpacity(0.6), fontSize: 13),
                                prefixIcon: Icon(Icons.search, color: primaryAccent, size: 20),
                                suffixIcon: _librarySearchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear, color: textMuted, size: 16),
                                        onPressed: () => setState(() => _librarySearchQuery = ''),
                                      )
                                    : null,
                                filled: true,
                                fillColor: elevatedBg,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Add Book Button
                          ElevatedButton.icon(
                            onPressed: _openAddBookDialog,
                            icon: Icon(Icons.add, size: 18, color: isDark ? Colors.black : Colors.white),
                            label: Text(
                              'Add Material',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Category Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(
                              label: 'All (${allBooks.length})',
                              isSelected: _selectedCategoryFilter == null,
                              onTap: () => setState(() => _selectedCategoryFilter = null),
                              accentColor: primaryAccent,
                            ),
                            const SizedBox(width: 8),
                            ...LibraryCategory.values.map((cat) {
                              final count = allBooks.where((b) => b.category == cat).length;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildFilterChip(
                                  label: '${_categoryLabel(cat).split(" ").first} ($count)',
                                  isSelected: _selectedCategoryFilter == cat,
                                  onTap: () => setState(() => _selectedCategoryFilter = cat),
                                  accentColor: _categoryColor(cat),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Library Items List
                Expanded(
                  child: filteredBooks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: primaryAccent.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.menu_book, color: primaryAccent, size: 48),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Library Materials Found',
                                  style: TextStyle(
                                    fontFamily: 'serif',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textCol,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _librarySearchQuery.isNotEmpty
                                      ? 'No items match "$_librarySearchQuery". Try clearing filters.'
                                      : 'Tap "+ Add Material" above to publish Telegram book links to students.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: textMuted),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredBooks.length,
                          itemBuilder: (ctx, index) {
                            final book = filteredBooks[index];
                            final catColor = _categoryColor(book.category);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderCol),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Category Pill + Actions (Edit, Delete)
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: catColor.withOpacity(0.14),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: catColor.withOpacity(0.4)),
                                          ),
                                          child: Text(
                                            _categoryLabel(book.category).toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: catColor,
                                              letterSpacing: 0.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF38A3E5).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.telegram, size: 12, color: Color(0xFF38A3E5)),
                                              SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  'Telegram Linked',
                                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF38A3E5)),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),

                                      // Edit Button
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 18),
                                        color: primaryAccent,
                                        tooltip: 'Edit Material',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _openEditBookDialog(book),
                                      ),

                                      // Delete Button
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18),
                                        color: AppTheme.crimson,
                                        tooltip: 'Remove Material',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _openDeleteBookDialog(book),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Title & Subtitle
                                  Text(
                                    book.title,
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textCol,
                                    ),
                                  ),
                                  if (book.subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      book.subtitle,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: primaryAccent,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),

                                  // Description
                                  if (book.description.isNotEmpty) ...[
                                    Text(
                                      book.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, color: textMuted, height: 1.35),
                                    ),
                                    const SizedBox(height: 8),
                                  ],

                                  // Tags row + Telegram URL
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: book.tags.map((tag) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: elevatedBg,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                tag,
                                                style: TextStyle(fontSize: 10, color: textMuted),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        't.me/...',
                                        style: TextStyle(fontSize: 10, color: textMuted.withOpacity(0.6)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),

            // ----------------------------------------------------
            // TAB 2: EMERGENCY BROADCAST
            // ----------------------------------------------------
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Push Emergency Schedule Update',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Instantly broadcast schedule adjustments, feast alerts, or urgent announcements to all registered student screens.',
                    style: TextStyle(fontSize: 13, color: textMuted),
                  ),
                  const SizedBox(height: 18),

                  Text('Broadcast Title', style: TextStyle(color: textMuted, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _broadcastTitleController,
                    style: TextStyle(color: textCol, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. Schedule Change, Feast Alert',
                      hintStyle: TextStyle(color: textMuted.withOpacity(0.7), fontSize: 13),
                      filled: true,
                      fillColor: cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderCol),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text('Church / Sanctuary', style: TextStyle(color: textMuted, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _broadcastChurchController,
                    style: TextStyle(color: textCol, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. St. Mary\'s Orthodox Church',
                      hintStyle: TextStyle(color: textMuted.withOpacity(0.7), fontSize: 13),
                      filled: true,
                      fillColor: cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderCol),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text('Announcement Message', style: TextStyle(color: textMuted, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _broadcastDescController,
                    maxLines: 3,
                    style: TextStyle(color: textCol, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Detail the schedule change or announcement...',
                      hintStyle: TextStyle(color: textMuted.withOpacity(0.7), fontSize: 13),
                      filled: true,
                      fillColor: cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderCol),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: _submitBroadcast,
                    icon: const Icon(Icons.campaign, color: Colors.white),
                    label: const Text('Dispatch Push Broadcast', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.crimson,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ACTIVE EMERGENCY BROADCASTS IN DATABASE
                  Row(
                    children: [
                      const Icon(Icons.emergency_share, color: AppTheme.crimson, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Active Emergency Broadcasts in Database',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textCol,
                          fontFamily: 'serif',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Real-time broadcasts currently published to student devices. You can permanently delete them from here.',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                  const SizedBox(height: 14),

                  Builder(
                    builder: (context) {
                      final emergencyBroadcasts = widget.state.programs.where((p) => p.isEmergency).toList();
                      if (emergencyBroadcasts.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderCol),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: AppTheme.emerald, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No active emergency broadcasts in the database.',
                                  style: TextStyle(fontSize: 13, color: textMuted),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: emergencyBroadcasts.map((broadcast) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.crimson.withOpacity(0.5)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.crimson.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppTheme.crimson.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppTheme.crimson.withOpacity(0.4)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.campaign, color: AppTheme.crimson, size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            'ACTIVE BROADCAST',
                                            style: TextStyle(color: AppTheme.crimson, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete_forever, color: AppTheme.crimson, size: 20),
                                      tooltip: 'Delete Broadcast from Database',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            backgroundColor: cardBg,
                                            title: const Row(
                                              children: [
                                                Icon(Icons.delete_forever, color: AppTheme.crimson, size: 22),
                                                SizedBox(width: 8),
                                                Text('Delete Broadcast?'),
                                              ],
                                            ),
                                            content: Text(
                                              'Permanently delete "${broadcast.title}" from the cloud database? It will be removed from all student screens immediately in real time.',
                                              style: TextStyle(color: textMuted),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                child: Text('Cancel', style: TextStyle(color: textMuted)),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
                                                onPressed: () async {
                                                  Navigator.pop(ctx);
                                                  await widget.state.deleteEmergencyBroadcast(broadcast.id);
                                                  setState(() {});
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Emergency broadcast removed from database and all user screens.'),
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: const Text('Delete from DB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  broadcast.title,
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textCol),
                                ),
                                if (broadcast.churchName.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    broadcast.churchName,
                                    style: TextStyle(fontSize: 12, color: primaryAccent, fontWeight: FontWeight.w600),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  broadcast.description,
                                  style: TextStyle(fontSize: 13, color: textMuted, height: 1.3),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ----------------------------------------------------
            // TAB 3: VOLUNTEER REVIEWS
            // ----------------------------------------------------
            volunteerApps.isEmpty
                ? Center(
                    child: Text('No volunteer applications to review.', style: TextStyle(color: textMuted)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(18),
                    itemCount: volunteerApps.length,
                    itemBuilder: (ctx, index) {
                      final app = volunteerApps[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: app.status == ApplicationStatus.approved
                                ? AppTheme.emerald
                                : borderCol,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  app.studentName,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textCol),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: elevatedBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    app.status.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: app.status == ApplicationStatus.approved ? AppTheme.emerald : primaryAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Target Ministry: ${app.ministryTitle} • Dept: ${app.studentDept}',
                              style: TextStyle(fontSize: 12, color: primaryAccent),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Reason: "${app.reason}"',
                              style: TextStyle(fontSize: 12, color: textMuted, fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Experience: ${app.experience} | Availability: ${app.availability}',
                              style: TextStyle(fontSize: 11, color: textMuted.withOpacity(0.7)),
                            ),
                            if (app.status == ApplicationStatus.pending) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => state.rejectVolunteerApplication(app.id),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.crimson,
                                      side: const BorderSide(color: AppTheme.crimson),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                    child: const Text('Decline', style: TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: () => state.approveVolunteerApplication(app.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryAccent,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    ),
                                    child: Text(
                                      'Approve & Assign',
                                      style: TextStyle(
                                        color: isDark ? Colors.black : Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.18) : cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : theme.dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? accentColor : textMuted,
          ),
        ),
      ),
    );
  }
}
