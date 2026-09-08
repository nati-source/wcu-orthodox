import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class AdminMediaCurriculumScreen extends StatefulWidget {
  final FellowshipState state;

  const AdminMediaCurriculumScreen({super.key, required this.state});

  @override
  State<AdminMediaCurriculumScreen> createState() => _AdminMediaCurriculumScreenState();
}

class _AdminMediaCurriculumScreenState extends State<AdminMediaCurriculumScreen> {
  // Add Book Link Form Controllers
  final _bookTitleController = TextEditingController();
  final _bookSubtitleController = TextEditingController();
  final _bookTelegramUrlController = TextEditingController(text: 'https://t.me/WCU_Orthodox_Library/');
  final _bookDescController = TextEditingController();
  final _bookTagsController = TextEditingController(text: 'Patristics, Amharic');
  LibraryCategory _selectedCat = LibraryCategory.patristics;

  // Emergency Broadcast Controllers
  final _broadcastTitleController = TextEditingController(text: 'Urgent Liturgy Venue Update');
  final _broadcastChurchController = TextEditingController(text: 'St. Mary\'s Orthodox Church');
  final _broadcastDescController = TextEditingController(text: 'Morning Kidase will start at 6:30 AM in the Main Sanctuary due to university semester examinations.');

  @override
  void dispose() {
    _bookTitleController.dispose();
    _bookSubtitleController.dispose();
    _bookTelegramUrlController.dispose();
    _bookDescController.dispose();
    _bookTagsController.dispose();
    _broadcastTitleController.dispose();
    _broadcastChurchController.dispose();
    _broadcastDescController.dispose();
    super.dispose();
  }

  void _submitBookLink() {
    if (_bookTitleController.text.trim().isEmpty || _bookTelegramUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter book title and Telegram link.')),
      );
      return;
    }

    final tags = _bookTagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

    widget.state.addLibraryBookLink(
      title: _bookTitleController.text.trim(),
      subtitle: _bookSubtitleController.text.trim().isEmpty ? 'WCU Fellowship Edition' : _bookSubtitleController.text.trim(),
      description: _bookDescController.text.trim(),
      category: _selectedCat,
      tags: tags.isEmpty ? ['Patristics'] : tags,
      telegramUrl: _bookTelegramUrlController.text.trim(),
    );

    _bookTitleController.clear();
    _bookSubtitleController.clear();
    _bookDescController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('New book Telegram link added to Digital Library!'),
        backgroundColor: Theme.of(context).cardTheme.color,
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Emergency broadcast pushed to all active devices!'),
        backgroundColor: Theme.of(context).cardTheme.color,
      ),
    );
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
    final volunteerApps = state.volunteerApplications;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Media & Programs Manager', style: TextStyle(color: textCol)),
          backgroundColor: cardBg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: primaryAccent),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: primaryAccent,
            labelColor: primaryAccent,
            unselectedLabelColor: textMuted,
            tabs: const [
              Tab(text: 'Add Book Link'),
              Tab(text: 'Emergency Broadcast'),
              Tab(text: 'Volunteer Reviews'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Add Telegram Book Link
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Publish Material to Digital Library',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add direct Telegram channel or message links to liturgical texts, patristics books, and spiritual hymns.',
                    style: TextStyle(fontSize: 13, color: textMuted),
                  ),
                  const SizedBox(height: 18),

                  Text('Book / Material Title', style: TextStyle(color: textMuted, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _bookTitleController,
                    style: TextStyle(color: textCol, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. Haymanote Abew, Wudase Mariam',
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

                  Text('Subtitle / Ge\'ez Title', style: TextStyle(color: textMuted, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _bookSubtitleController,
                    style: TextStyle(color: textCol, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. ሃይማኖተ አበው (Faith of the Fathers)',
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

                  Text('Category', style: TextStyle(color: textMuted, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderCol),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<LibraryCategory>(
                        value: _selectedCat,
                        dropdownColor: cardBg,
                        icon: Icon(Icons.keyboard_arrow_down, color: primaryAccent),
                        items: LibraryCategory.values.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat.name.toUpperCase(), style: TextStyle(color: textCol, fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCat = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text('Telegram Link URL', style: TextStyle(color: textMuted, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _bookTelegramUrlController,
                    style: TextStyle(color: textCol, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'https://t.me/WCU_Orthodox_Library/101',
                      hintStyle: TextStyle(color: textMuted.withOpacity(0.7), fontSize: 13),
                      prefixIcon: const Icon(Icons.telegram, color: Color(0xFF38A3E5)),
                      filled: true,
                      fillColor: cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderCol),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text('Tags (comma separated)', style: TextStyle(color: textMuted, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _bookTagsController,
                    style: TextStyle(color: textCol, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Patristics, Ge\'ez / Amharic, Dogma',
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

                  Text('Description / Overview', style: TextStyle(color: textMuted, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _bookDescController,
                    maxLines: 2,
                    style: TextStyle(color: textCol, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Brief summary of contents, homilies or chapters...',
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
                    onPressed: _submitBookLink,
                    icon: Icon(Icons.add_link, color: isDark ? Colors.black : Colors.white),
                    label: Text(
                      'Add Telegram Book Link',
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
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Tab 2: Emergency Broadcast
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
                ],
              ),
            ),

            // Tab 3: Volunteer Reviews
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
}
